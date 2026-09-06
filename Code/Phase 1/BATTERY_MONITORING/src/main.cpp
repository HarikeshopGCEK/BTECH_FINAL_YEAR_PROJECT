// ============================================================
// 3S Li-Ion / LiPo Battery Pack – Voltage & Current Monitor
// Platform       : ESP32 DevKit V1 (12-bit ADC, 3.3 V reference)
// Current Sensor : INA226 (I2C)
//
// Wiring:
// 1. Voltage-divider taps → ESP32 ADC pins:
//   ONE_S_PIN   (GPIO 34) – B- to B1 tap  (Cell 1 bottom)
//   TWO_S_PIN   (GPIO 35) – B- to B2 tap  (Cell 1+2 combined)
//   THREE_S_PIN (GPIO 32) – B- to B+ tap  (full pack voltage)
//
// 2. INA226 Current Sensor → ESP32 I2C:
//   VCC  → ESP32 3.3V
//   GND  → ESP32 GND (common ground with battery B-)
//   SDA  → ESP32 GPIO 21
//   SCL  → ESP32 GPIO 22
//
// 3. INA226 Power Path (High-Side Sensing):
//   IN+  → Battery Pack Positive terminal (B+)
//   IN-  → System Load / Charger Positive terminal
//   VBUS → Connect to IN+ (measures pack bus voltage up to 36V)
// ============================================================

#include <Arduino.h>
#include <Wire.h>
#include <INA226.h>

// ─── ADC Pin Assignments ─────────────────────────────────────
// NOTE: This project targets classic ESP32 DevKit V1.
// Prefer ADC1 pins to avoid ADC2/Wi-Fi conflicts on ESP32.
// ADC1 pins on ESP32 are GPIO32..GPIO39.
#define ONE_S_PIN    34   // Cell-1 tap   (B- → B1)
#define TWO_S_PIN    35   // Cell-1+2 tap (B- → B2)
#define THREE_S_PIN  32   // Full-pack tap (B- → B+)

// ─── I2C & INA226 Configuration ──────────────────────────────
#define I2C_SDA_PIN       21    // Default ESP32 I2C SDA
#define I2C_SCL_PIN       22    // Default ESP32 I2C SCL
#define INA226_I2C_ADDR   0x40  // Default I2C address (A0=GND, A1=GND)

// ─── Shunt Resistor & Current Calibration ────────────────────
// Check the large resistor marked on your INA226 breakout module:
//   "R100" = 0.100 Ω (Common on purple CJMCU modules, max ~0.82 A)
//   "R010" = 0.010 Ω (Common on 10A modules, max ~8.19 A)
//   "R002" = 0.002 Ω (Common on 20A-40A modules, max ~40 A)
#define INA226_SHUNT_OHMS    0.100f  // Shunt resistor value in Ohms

// Maximum expected current in Amperes (used for calibration):
// Note: INA226 max shunt differential voltage is ±81.92 mV.
// Ensure (INA226_MAX_CURRENT_A * INA226_SHUNT_OHMS) <= 0.0819 V.
#define INA226_MAX_CURRENT_A 0.800f  // Adjust for your specific shunt & load

// ─── Voltage Divider Resistor Values (Ohms) ──────────────────
// Adjust to match the resistors you physically soldered.
// Each tap can use a different divider if needed.
#define R_TOP_C1   100000.0f   // R_top for Cell-1 tap (Ω)
#define R_TOP_C2   100000.0f   // R_top for Cell-1+2 tap (Ω)
#define R_TOP_C3   100000.0f   // R_top for full-pack tap (Ω)
#define PRESET_R_BOT 33000.0f  // 50 kΩ preset measured/set to 33 kΩ (Ω)

#define R_BOT_C1 PRESET_R_BOT
#define R_BOT_C2 PRESET_R_BOT
#define R_BOT_C3 PRESET_R_BOT

// ─── ADC Parameters ──────────────────────────────────────────
#define ADC_RESOLUTION  4095.0f    // 12-bit ESP32 ADC
#define ADC_VREF           3.3f    // ESP32 reference voltage (V)
#define NUM_SAMPLES           10   // Oversample count for noise reduction

// ─── Li-Ion Cell Voltage Thresholds (per cell) ───────────────
#define CELL_FULL     4.20f   // 100 % SoC
#define CELL_NOMINAL  3.70f   // ~50 % SoC
#define CELL_LOW      3.30f   // Low voltage warning
#define CELL_CUTOFF   3.00f   // Under-voltage cutoff

// ─── Sample Interval ─────────────────────────────────────────
#define SAMPLE_INTERVAL_MS  1000   // Print report every 1 second

// ─── Macro: compute voltage-divider ratio ────────────────────
// V_real = V_adc * (R_top + R_bot) / R_bot
#define DIVIDER_RATIO(rt, rb)  (((rt) + (rb)) / (rb))

// ─── Global State & Objects ──────────────────────────────────
INA226 ina(INA226_I2C_ADDR);
bool ina226_ready = false;
unsigned long last_sample_time = 0;
float accumulated_mah = 0.0f; // Coulomb counter (net charge transferred)

// ─── Initialize / Calibrate INA226 ───────────────────────────
bool initINA226() {
    if (!ina.begin()) {
        return false;
    }

    // Ensure max current does not exceed INA226 81.92 mV limit
    float maxCurrent = INA226_MAX_CURRENT_A;
    if (maxCurrent * INA226_SHUNT_OHMS > 0.0819f) {
        maxCurrent = 0.080f / INA226_SHUNT_OHMS;
    }

    int err = ina.setMaxCurrentShunt(maxCurrent, INA226_SHUNT_OHMS);
    if (err != INA226_ERR_NONE) {
        Serial.printf("[INA226] Calibration failed with code: 0x%04X\n", err);
        return false;
    }

    // Configure 16 samples averaging for smooth, low-noise readings
    ina.setAverage(INA226_16_SAMPLES);
    ina.setBusVoltageConversionTime(INA226_1100_us);
    ina.setShuntVoltageConversionTime(INA226_1100_us);
    ina.setModeShuntBusContinuous();

    return true;
}

// ─── Averaged ADC read (reduces noise) ───────────────────────
uint16_t adcAveraged(uint8_t pin, uint8_t samples = NUM_SAMPLES) {
    uint32_t sum = 0;
    for (uint8_t i = 0; i < samples; i++) {
        sum += analogRead(pin);
        delayMicroseconds(200);
    }
    return (uint16_t)(sum / samples);
}

// ─── Convert raw ADC count to real voltage ───────────────────
float adcToVoltage(uint16_t raw, float dividerRatio) {
    float v_adc = (raw / ADC_RESOLUTION) * ADC_VREF;
    return v_adc * dividerRatio;
}

// ─── Simple linear SoC estimate (%) ─────────────────────────
float estimateSoC(float cellV) {
    if (cellV >= CELL_FULL)   return 100.0f;
    if (cellV <= CELL_CUTOFF) return 0.0f;
    return ((cellV - CELL_CUTOFF) / (CELL_FULL - CELL_CUTOFF)) * 100.0f;
}

// ─── Human-readable cell status ──────────────────────────────
const char* cellStatus(float cellV) {
    if (cellV >= CELL_FULL)    return "FULL";
    if (cellV >= CELL_NOMINAL) return "OK";
    if (cellV >= CELL_LOW)     return "LOW";
    if (cellV >= CELL_CUTOFF)  return "CRITICAL";
    return "UNDER-VOLTAGE!";
}

// ============================================================
void setup() {
    Serial.begin(115200);
    // Avoid indefinite wait for host terminal
    unsigned long serial_wait_start = millis();
    while (!Serial && (millis() - serial_wait_start < 2000)) {
        delay(10);
    }

    Serial.println("\nBooting battery monitor...");

    // Configure ADC pins as inputs
    pinMode(ONE_S_PIN,   INPUT);
    pinMode(TWO_S_PIN,   INPUT);
    pinMode(THREE_S_PIN, INPUT);

    analogReadResolution(12);
    // 11 dB attenuation → full-scale ≈ 3.1 V input
    analogSetAttenuation(ADC_11db);

    // Initialize I2C bus
    Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);

    // Initialize INA226 current sensor
    ina226_ready = initINA226();
    if (ina226_ready) {
        Serial.printf("[INA226] Detected at 0x%02X (Shunt: %.3f Ω, MaxCurrent: %.2f A)\n",
                      INA226_I2C_ADDR, INA226_SHUNT_OHMS, INA226_MAX_CURRENT_A);
    } else {
        Serial.println("[INA226] WARNING: Sensor not detected on I2C! Check wiring (SDA=21, SCL=22).");
    }

    Serial.println("===========================================");
    Serial.println("   3S Battery Pack – Voltage & Current Mon  ");
    Serial.println("===========================================");
    Serial.printf("Divider ratios: C1=%.3f  C2=%.3f  C3=%.3f\n",
                  DIVIDER_RATIO(R_TOP_C1, R_BOT_C1),
                  DIVIDER_RATIO(R_TOP_C2, R_BOT_C2),
                  DIVIDER_RATIO(R_TOP_C3, R_BOT_C3));
    Serial.println("-------------------------------------------");

    last_sample_time = millis();
}

// ============================================================
void loop() {
    unsigned long now = millis();

    // ── 1. Read tap voltages (averaged for noise reduction) ──
    uint16_t raw_tap1   = adcAveraged(ONE_S_PIN);
    uint16_t raw_tap12  = adcAveraged(TWO_S_PIN);
    uint16_t raw_tap123 = adcAveraged(THREE_S_PIN);

    // ── 2. Convert raw ADC to real tap voltages ───────────────
    //   v_tap1   = B- → B1  (= Cell-1 voltage)
    //   v_tap12  = B- → B2  (= Cell-1 + Cell-2)
    //   v_tap123 = B- → B+  (= full pack voltage)
    float v_tap1   = adcToVoltage(raw_tap1,   DIVIDER_RATIO(R_TOP_C1, R_BOT_C1));
    float v_tap12  = adcToVoltage(raw_tap12,  DIVIDER_RATIO(R_TOP_C2, R_BOT_C2));
    float v_tap123 = adcToVoltage(raw_tap123, DIVIDER_RATIO(R_TOP_C3, R_BOT_C3));

    // ── 3. Derive individual cell voltages by subtraction ─────
    float cell1_v = v_tap1;             // Bottom cell
    float cell2_v = v_tap12  - v_tap1;  // Middle cell
    float cell3_v = v_tap123 - v_tap12; // Top cell
    float pack_v  = v_tap123;           // Full pack voltage (from ADC divider)

    // ── 4. Clamp negative noise to 0 ─────────────────────────
    cell1_v = max(cell1_v, 0.0f);
    cell2_v = max(cell2_v, 0.0f);
    cell3_v = max(cell3_v, 0.0f);

    // ── 5. Estimate SoC per cell ─────────────────────────────
    float soc1    = estimateSoC(cell1_v);
    float soc2    = estimateSoC(cell2_v);
    float soc3    = estimateSoC(cell3_v);
    float avg_soc = (soc1 + soc2 + soc3) / 3.0f;

    // ── 6. Cell imbalance (max spread in mV) ─────────────────
    float v_max = max({cell1_v, cell2_v, cell3_v});
    float v_min = min({cell1_v, cell2_v, cell3_v});
    float imbalance_mv = (v_max - v_min) * 1000.0f;

    // ── 7. Read INA226 Current, Bus Voltage & Power ──────────
    // Attempt re-detection if INA226 wasn't ready at startup
    if (!ina226_ready) {
        ina226_ready = initINA226();
    } else if (!ina.isConnected()) {
        ina226_ready = false;
    }

    float current_ma = 0.0f;
    float current_a  = 0.0f;
    float power_w    = 0.0f;
    float shunt_mv   = 0.0f;
    float bus_v      = 0.0f;
    const char* flow_status = "DISCONNECTED";

    if (ina226_ready) {
        current_ma = ina.getCurrent_mA();
        current_a  = ina.getCurrent();
        power_w    = ina.getPower();
        shunt_mv   = ina.getShuntVoltage_mV();
        bus_v      = ina.getBusVoltage();

        // Coulomb Counting: integrate current over time (mAh)
        float dt_hours = (now - last_sample_time) / 3600000.0f;
        accumulated_mah += (current_ma * dt_hours);

        // Current flow state (threshold ±10 mA to ignore noise)
        if (current_ma > 10.0f) {
            flow_status = "DISCHARGING";
        } else if (current_ma < -10.0f) {
            flow_status = "CHARGING";
        } else {
            flow_status = "STANDBY / IDLE";
        }
    }

    // ── 8. Print formatted report ─────────────────────────────
    Serial.println("===========================================");
    Serial.printf("Pack Voltage (ADC) : %.3f V\n", pack_v);
    Serial.printf("Avg Pack SoC       : %.1f %%\n", avg_soc);
    Serial.printf("Cell Imbalance     : %.1f mV%s\n",
                  imbalance_mv,
                  (imbalance_mv > 100.0f) ? "  *** IMBALANCE ***" : "");
    Serial.println("-------------------------------------------");
    Serial.printf("Cell 1 (Bot): %.3f V | SoC: %5.1f%% | %s\n",
                  cell1_v, soc1, cellStatus(cell1_v));
    Serial.printf("Cell 2 (Mid): %.3f V | SoC: %5.1f%% | %s\n",
                  cell2_v, soc2, cellStatus(cell2_v));
    Serial.printf("Cell 3 (Top): %.3f V | SoC: %5.1f%% | %s\n",
                  cell3_v, soc3, cellStatus(cell3_v));
    Serial.println("-------------------------------------------");

    if (ina226_ready) {
        Serial.printf("Pack Current       : %+.2f mA (%+.3f A) [%s]\n",
                      current_ma, current_a, flow_status);
        Serial.printf("Pack Power         : %.3f W (%.1f mW)\n",
                      power_w, power_w * 1000.0f);
        Serial.printf("Shunt Voltage      : %+.3f mV\n", shunt_mv);
        Serial.printf("INA226 Bus Voltage : %.3f V\n", bus_v);
        Serial.printf("Net Charge (Ah)    : %+.3f mAh\n", accumulated_mah);
    } else {
        Serial.println("Pack Current       : [INA226 SENSOR NOT DETECTED]");
        Serial.println("  -> Check VCC(3.3V), GND, SDA(GPIO21), SCL(GPIO22)");
    }

    Serial.println("-------------------------------------------");
    // Raw ADC debug (comment out after calibration)
    Serial.printf("[RAW ADC] tap1=%d  tap12=%d  tap123=%d\n",
                  raw_tap1, raw_tap12, raw_tap123);
    Serial.println("===========================================\n");

    last_sample_time = now;
    delay(SAMPLE_INTERVAL_MS);
}
