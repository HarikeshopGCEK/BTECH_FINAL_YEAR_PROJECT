// ============================================================
// 3S Li-Ion / LiPo Battery Pack – Voltage & Load Current Monitor
// Platform       : ESP32-S3 DevKit
// Current Sensor : INA226 (I2C)
//
// Voltage measurement:
//   Tap 1  → GPIO 4
//   Tap 2  → GPIO 5
//   Tap 3  → GPIO 6
//
// INA226:
//   SDA → GPIO 8
//   SCL → GPIO 9
//
// ============================================================

#include <Arduino.h>
#include <INA226.h>
#include <Wire.h>

// ============================================================
// ADC PIN ASSIGNMENTS
// ============================================================

#define ONE_S_PIN 4   // Cell-1 tap: B- → B1
#define TWO_S_PIN 5   // Cell-1+2 tap: B- → B2
#define THREE_S_PIN 6 // Full pack tap: B- → B+

// NTC divider ADC inputs. Keep these separate from the voltage taps and I2C pins.
#define NTC_CELL1_PIN 1
#define NTC_CELL2_PIN 2
#define NTC_CELL3_PIN 7

// ============================================================
// I2C & INA226 CONFIGURATION
// ============================================================

#define I2C_SDA_PIN 8
#define I2C_SCL_PIN 9

#define INA226_I2C_ADDR 0x40

// ============================================================
// COMPATIBILITY
// ============================================================

#ifndef ADC_ATTEN_DB_11
#define ADC_ATTEN_DB_11 ADC_11db
#endif

// ============================================================
// INA226 SHUNT CONFIGURATION
// ============================================================
//
// R100 = 0.100 Ω
//
// INA226 maximum shunt voltage:
// ±81.92 mV
//
// At 0.100 Ω:
// 0.8 A × 0.100 Ω = 80 mV
//
// Therefore 0.8 A is approximately the safe maximum
// for this configuration.
// ============================================================

#define INA226_SHUNT_OHMS 0.100f
#define INA226_MAX_CURRENT_A 0.800f

// ============================================================
// VOLTAGE DIVIDER RESISTORS
// ============================================================
//
// IMPORTANT:
// These are the ACTUAL physical resistor values.
//
// Tap 1:
//   Top    = 22 kΩ
//   Bottom = 50 kΩ
//
// Tap 2:
//   Top    = 100 kΩ
//   Bottom = 33 kΩ
//
// Tap 3:
//   Top    = 100 kΩ
//   Bottom = 33 kΩ
//
// These resistor values are kept here for documentation.
// The actual voltage calculation uses the experimentally
// measured calibration equations below.
// ============================================================

#define R_TOP_C1 22000.0f
#define R_BOT_C1 48600.0f

#define R_TOP_C2 100000.0f
#define R_BOT_C2 49500.0f

#define R_TOP_C3 100000.0f
#define R_BOT_C3 28700.0f

// ============================================================
// NTC CONFIGURATION
// ============================================================
//
// Divider wiring for each NTC:
//   3.3 V -> 10 kΩ fixed resistor -> ADC pin -> NTC -> GND
//
// The pictured NTC is marked 10, so its nominal resistance is
// assumed to be 10 kΩ at 25 °C. Confirm the beta value from its
// datasheet for better temperature accuracy.
//

#define NTC_FIXED_OHMS 10000.0f
#define NTC_NOMINAL_OHMS 10000.0f
#define NTC_NOMINAL_TEMP_C 25.0f
#define NTC_BETA 3950.0f
#define NTC_SUPPLY_MV 3300.0f

// ============================================================
// ADC VOLTAGE CALIBRATION
// ============================================================
//
// Experimentally measured calibration equations.
//
// ------------------------------------------------------------
// TAP 1
//
// 2.7 V → ADC 2130
// 3.1 V → ADC 2504
// 3.5 V → ADC 2845
// 3.9 V → ADC 3228
// 4.2 V → ADC 3565
//
// Maximum error ≈ 31.5 mV
// ------------------------------------------------------------

#define TAP1_A -1.404856e-07f
#define TAP1_B 0.00189009f
#define TAP1_C -0.775924f

// ------------------------------------------------------------
// TAP 2
//
// 5.4 V → ADC 2069
// 6.2 V → ADC 2364
// 7.0 V → ADC 2685
// 7.8 V → ADC 3031
// 8.4 V → ADC 3308
//
// Maximum error ≈ 56 mV
// ------------------------------------------------------------

#define TAP2_A -2.672302e-07f
#define TAP2_B 0.00380713f
#define TAP2_C -1.370929f

// ------------------------------------------------------------
// TAP 3
//
// 8.1 V  → ADC 2117
// 9.3 V  → ADC 2435
// 10.5 V → ADC 2645
// 11.7 V → ADC 3117
// 12.6 V → ADC 3424
//
// Maximum error ≈ 410 mV
//
// NOTE:
// Tap 3 calibration currently has considerably more error
// than Tap 1 and Tap 2.
// ------------------------------------------------------------

#define TAP3_A -3.830651e-07f
#define TAP3_B 0.00550616f
#define TAP3_C -1.916985f

// ============================================================
// ADC PARAMETERS
// ============================================================

#define ADC_RESOLUTION 4095.0f
#define ADC_VREF 3.3f

// Number of ADC samples averaged
#define NUM_SAMPLES 20

// ============================================================
// LI-ION CELL VOLTAGE THRESHOLDS
// ============================================================

#define CELL_FULL 4.20f
#define CELL_NOMINAL 3.70f
#define CELL_LOW 3.30f
#define CELL_CUTOFF 3.00f

// ============================================================
// SAMPLE INTERVAL
// ============================================================

#define SAMPLE_INTERVAL_MS 1000

// ============================================================
// GLOBAL OBJECTS / VARIABLES
// ============================================================

INA226 ina(INA226_I2C_ADDR);

bool ina226_ready = false;

unsigned long last_sample_time = 0;

float accumulated_load_mah = 0.0f;

// ============================================================
// INA226 INITIALIZATION
// ============================================================

bool initINA226()
{
    // Check whether INA226 is connected
    if (!ina.begin())
    {
        return false;
    }

    // --------------------------------------------------------
    // Ensure maximum current stays within INA226 shunt range
    // --------------------------------------------------------

    float maxCurrent = INA226_MAX_CURRENT_A;

    if ((maxCurrent * INA226_SHUNT_OHMS) > 0.0819f)
    {
        maxCurrent = 0.080f / INA226_SHUNT_OHMS;
    }

    // Configure INA226 calibration
    int err = ina.setMaxCurrentShunt(
        maxCurrent,
        INA226_SHUNT_OHMS);

    if (err != INA226_ERR_NONE)
    {
        Serial.printf(
            "[INA226] Calibration failed with code: 0x%04X\n",
            err);

        return false;
    }

    // --------------------------------------------------------
    // INA226 averaging
    // --------------------------------------------------------

    ina.setAverage(INA226_16_SAMPLES);

    ina.setBusVoltageConversionTime(
        INA226_1100_us);

    ina.setShuntVoltageConversionTime(
        INA226_1100_us);

    ina.setModeShuntBusContinuous();

    return true;
}

// ============================================================
// AVERAGED ADC READ
// ============================================================

uint16_t adcAveraged(
    uint8_t pin,
    uint8_t samples = NUM_SAMPLES)
{
    uint32_t sum = 0;

    for (uint8_t i = 0; i < samples; i++)
    {
        sum += analogRead(pin);

        delayMicroseconds(200);
    }

    return (uint16_t)(sum / samples);
}

// ============================================================
// CALIBRATED TAP VOLTAGE FUNCTIONS
// ============================================================

float tap1Voltage(uint16_t raw)
{
    return (TAP1_A * raw * raw) + (TAP1_B * raw) + TAP1_C;
}

float tap2Voltage(uint16_t raw)
{
    return (TAP2_A * raw * raw) + (TAP2_B * raw) + TAP2_C;
}

float tap3Voltage(uint16_t raw)
{
    return (TAP3_A * raw * raw) + (TAP3_B * raw) + TAP3_C;
}

float ntcVoltageMv(uint8_t pin)
{
    uint32_t voltage_sum_mv = 0;

    for (uint8_t sample = 0; sample < NUM_SAMPLES; sample++)
    {
        voltage_sum_mv += analogReadMilliVolts(pin);
        delayMicroseconds(200);
    }

    return voltage_sum_mv / (float)NUM_SAMPLES;
}

float ntcTemperatureC(uint8_t pin)
{
    float voltage_mv = ntcVoltageMv(pin);

    if (voltage_mv <= 0.0f || voltage_mv >= NTC_SUPPLY_MV)
    {
        return NAN;
    }

    // For 3.3 V -> fixed resistor -> ADC -> NTC -> GND:
    // R_ntc = R_fixed * V_adc / (V_supply - V_adc)
    float ntc_ohms =
        NTC_FIXED_OHMS * voltage_mv /
        (NTC_SUPPLY_MV - voltage_mv);

    float temperature_kelvin =
        1.0f /
        ((1.0f / (NTC_NOMINAL_TEMP_C + 273.15f)) +
         (logf(ntc_ohms / NTC_NOMINAL_OHMS) / NTC_BETA));

    return temperature_kelvin - 273.15f;
}

// ============================================================
// SIMPLE LINEAR SOC ESTIMATION
// ============================================================

float estimateSoC(float cellV)
{
    if (cellV >= CELL_FULL)
    {
        return 100.0f;
    }

    if (cellV <= CELL_CUTOFF)
    {
        return 0.0f;
    }

    return (
               (cellV - CELL_CUTOFF) /
               (CELL_FULL - CELL_CUTOFF)) *
           100.0f;
}

// ============================================================
// CELL STATUS
// ============================================================

const char *cellStatus(float cellV)
{
    if (cellV >= CELL_FULL)
    {
        return "FULL";
    }

    if (cellV >= CELL_NOMINAL)
    {
        return "OK";
    }

    if (cellV >= CELL_LOW)
    {
        return "LOW";
    }

    if (cellV >= CELL_CUTOFF)
    {
        return "CRITICAL";
    }

    return "UNDER-VOLTAGE!";
}

// ============================================================
// SETUP
// ============================================================

void setup()
{
    Serial.begin(115200);

    // --------------------------------------------------------
    // Wait briefly for serial monitor
    // --------------------------------------------------------

    unsigned long serial_wait_start = millis();

    while (
        !Serial &&
        (millis() - serial_wait_start < 2000))
    {
        delay(10);
    }

    Serial.println();
    Serial.println(
        "Booting battery monitor (ESP32-S3)...");

    // --------------------------------------------------------
    // ADC pins
    // --------------------------------------------------------

    pinMode(ONE_S_PIN, INPUT);
    pinMode(TWO_S_PIN, INPUT);
    pinMode(THREE_S_PIN, INPUT);
    pinMode(NTC_CELL1_PIN, INPUT);
    pinMode(NTC_CELL2_PIN, INPUT);
    pinMode(NTC_CELL3_PIN, INPUT);

    // 12-bit ADC
    analogReadResolution(12);

    // 11 dB attenuation
    analogSetAttenuation(
        ADC_ATTEN_DB_11);

    // --------------------------------------------------------
    // I2C
    // --------------------------------------------------------

    Wire.begin(
        I2C_SDA_PIN,
        I2C_SCL_PIN);

    // --------------------------------------------------------
    // INA226
    // --------------------------------------------------------

    ina226_ready = initINA226();

    if (ina226_ready)
    {
        Serial.printf(
            "[INA226] Detected at 0x%02X "
            "(Shunt: %.3f Ω, "
            "MaxLoadCurrent: %.2f A)\n",

            INA226_I2C_ADDR,
            INA226_SHUNT_OHMS,
            INA226_MAX_CURRENT_A);
    }
    else
    {
        Serial.printf(
            "[INA226] WARNING: Sensor not detected "
            "on I2C! Check wiring "
            "(SDA=%d, SCL=%d).\n",

            I2C_SDA_PIN,
            I2C_SCL_PIN);
    }

    // --------------------------------------------------------
    // Startup information
    // --------------------------------------------------------

    Serial.println(
        "===========================================");

    Serial.println(
        " 3S Battery Pack – Voltage & Load Monitor");

    Serial.println(
        "===========================================");

    Serial.println(
        "Voltage calibration:");

    Serial.printf(
        "Tap 1: V = %.8e * ADC^2 + %.8f * ADC + %.6f\n",
        TAP1_A,
        TAP1_B,
        TAP1_C);

    Serial.printf(
        "Tap 2: V = %.8e * ADC^2 + %.8f * ADC + %.6f\n",
        TAP2_A,
        TAP2_B,
        TAP2_C);

    Serial.printf(
        "Tap 3: V = %.8e * ADC^2 + %.8f * ADC + %.6f\n",
        TAP3_A,
        TAP3_B,
        TAP3_C);

    Serial.println("-------------------------------------------");

    Serial.printf(
        "Cell 1 divider: %.0f Ω / %.0f Ω\n",
        R_TOP_C1,
        R_BOT_C1);

    Serial.printf(
        "Cell 2 divider: %.0f Ω / %.0f Ω\n",
        R_TOP_C2,
        R_BOT_C2);

    Serial.printf(
        "Cell 3 divider: %.0f Ω / %.0f Ω\n",
        R_TOP_C3,
        R_BOT_C3);

    Serial.println("-------------------------------------------");

    last_sample_time = millis();
}

// ============================================================
// MAIN LOOP
// ============================================================

void loop()
{
    unsigned long now = millis();

    // ========================================================
    // 1. READ ADC TAPS
    // ========================================================

    uint16_t raw_tap1 =
        adcAveraged(ONE_S_PIN);

    uint16_t raw_tap12 =
        adcAveraged(TWO_S_PIN);

    uint16_t raw_tap123 =
        adcAveraged(THREE_S_PIN);

    // ========================================================
    // 2. CONVERT ADC TO CALIBRATED TAP VOLTAGES
    // ========================================================

    //
    // Tap 1:
    // B- → B1
    // = Cell 1 voltage
    //

    float v_tap1 =
        tap1Voltage(raw_tap1);

    //
    // Tap 2:
    // B- → B2
    // = Cell 1 + Cell 2
    //

    float v_tap12 =
        tap2Voltage(raw_tap12);

    //
    // Tap 3:
    // B- → B+
    // = Full pack voltage
    //

    float v_tap123 =
        tap3Voltage(raw_tap123);

    float temperature_cell1_c =
        ntcTemperatureC(NTC_CELL1_PIN);

    float temperature_cell2_c =
        ntcTemperatureC(NTC_CELL2_PIN);

    float temperature_cell3_c =
        ntcTemperatureC(NTC_CELL3_PIN);

    float ntc_voltage_cell1_mv =
        ntcVoltageMv(NTC_CELL1_PIN);

    float ntc_voltage_cell2_mv =
        ntcVoltageMv(NTC_CELL2_PIN);

    float ntc_voltage_cell3_mv =
        ntcVoltageMv(NTC_CELL3_PIN);

    // ========================================================
    // 3. CALCULATE INDIVIDUAL CELL VOLTAGES
    // ========================================================

    float cell1_v =
        v_tap1;

    float cell2_v =
        v_tap12 - v_tap1;

    float cell3_v =
        v_tap123 - v_tap12;

    float pack_v =
        v_tap123;

    // ========================================================
    // 4. PROTECT AGAINST NEGATIVE ADC NOISE
    // ========================================================

    cell1_v = max(cell1_v, 0.0f);
    cell2_v = max(cell2_v, 0.0f);
    cell3_v = max(cell3_v, 0.0f);

    // ========================================================
    // 5. SOC ESTIMATION
    // ========================================================

    float soc1 =
        estimateSoC(cell1_v);

    float soc2 =
        estimateSoC(cell2_v);

    float soc3 =
        estimateSoC(cell3_v);

    float avg_soc =
        (soc1 + soc2 + soc3) / 3.0f;

    // ========================================================
    // 6. CELL IMBALANCE
    // ========================================================

    float v_max =
        max(
            max(cell1_v, cell2_v),
            cell3_v);

    float v_min =
        min(
            min(cell1_v, cell2_v),
            cell3_v);

    float imbalance_mv =
        (v_max - v_min) * 1000.0f;

    // ========================================================
    // 7. INA226
    // ========================================================

    // Try reconnecting if sensor wasn't found
    if (!ina226_ready)
    {
        ina226_ready = initINA226();
    }
    else if (!ina.isConnected())
    {
        ina226_ready = false;
    }

    float load_current_ma = 0.0f;
    float load_current_a = 0.0f;
    float load_power_w = 0.0f;
    float shunt_mv = 0.0f;
    float bus_v = 0.0f;

    const char *load_status =
        "DISCONNECTED";

    // ========================================================
    // READ INA226
    // ========================================================

    if (ina226_ready)
    {
        float raw_current_ma =
            ina.getCurrent_mA();

        // Always display current magnitude
        load_current_ma =
            fabs(raw_current_ma);

        load_current_a =
            load_current_ma / 1000.0f;

        load_power_w =
            fabs(ina.getPower());

        shunt_mv =
            ina.getShuntVoltage_mV();

        bus_v =
            ina.getBusVoltage();

        // ----------------------------------------------------
        // Integrate current → mAh
        // ----------------------------------------------------

        float dt_hours =
            (now - last_sample_time) / 3600000.0f;

        accumulated_load_mah +=
            load_current_ma * dt_hours;

        // ----------------------------------------------------
        // Determine load state
        // ----------------------------------------------------

        if (load_current_ma > 5.0f)
        {
            load_status =
                "LOAD ACTIVE";
        }
        else
        {
            load_status =
                "IDLE (NO LOAD)";
        }
    }

    // ========================================================
    // 8. SERIAL REPORT
    // ========================================================

    Serial.println(
        "===========================================");

    Serial.printf(
        "Pack Voltage (ADC) : %.3f V\n",
        pack_v);

    Serial.printf(
        "Avg Pack SoC       : %.1f %%\n",
        avg_soc);

    Serial.printf(
        "Cell Imbalance     : %.1f mV%s\n",
        imbalance_mv,
        (imbalance_mv > 100.0f)
            ? "  *** IMBALANCE ***"
            : "");

    Serial.println(
        "-------------------------------------------");

    Serial.printf(
        "Cell temperatures: C1 %.1f C | C2 %.1f C | C3 %.1f C\n",
        temperature_cell1_c,
        temperature_cell2_c,
        temperature_cell3_c);

    Serial.printf(
        "NTC divider voltage: C1 %.0f mV | C2 %.0f mV | C3 %.0f mV\n",
        ntc_voltage_cell1_mv,
        ntc_voltage_cell2_mv,
        ntc_voltage_cell3_mv);

    Serial.println(
        "-------------------------------------------");

    Serial.printf(
        "Cell 1 (Bot): %.3f V | SoC: %5.1f%% | %s\n",
        cell1_v,
        soc1,
        cellStatus(cell1_v));

    Serial.printf(
        "Cell 2 (Mid): %.3f V | SoC: %5.1f%% | %s\n",
        cell2_v,
        soc2,
        cellStatus(cell2_v));

    Serial.printf(
        "Cell 3 (Top): %.3f V | SoC: %5.1f%% | %s\n",
        cell3_v,
        soc3,
        cellStatus(cell3_v));

    Serial.println(
        "-------------------------------------------");

    // ========================================================
    // INA226 REPORT
    // ========================================================

    if (ina226_ready)
    {
        Serial.printf(
            "Load Current       : %.2f mA (%.3f A) [%s]\n",
            load_current_ma,
            load_current_a,
            load_status);

        Serial.printf(
            "Load Power         : %.3f W (%.1f mW)\n",
            load_power_w,
            load_power_w * 1000.0f);

        Serial.printf(
            "Total Load Consumed: %.2f mAh\n",
            accumulated_load_mah);

        Serial.printf(
            "Shunt Voltage      : %+.3f mV\n",
            shunt_mv);

        Serial.printf(
            "INA226 Bus Voltage : %.3f V\n",
            bus_v);
    }
    else
    {
        Serial.println(
            "Load Current       : "
            "[INA226 SENSOR NOT DETECTED]");

        Serial.printf(
            "  -> Check VCC(3.3V), GND, "
            "SDA(GPIO%d), SCL(GPIO%d)\n",
            I2C_SDA_PIN,
            I2C_SCL_PIN);
    }

    // ========================================================
    // RAW ADC DEBUG
    // ========================================================

    Serial.println(
        "-------------------------------------------");

    Serial.printf(
        "[RAW ADC] tap1=%d  tap12=%d  tap123=%d\n",
        raw_tap1,
        raw_tap12,
        raw_tap123);

    // Also show calibrated tap voltages
    Serial.printf(
        "[TAPS] T1=%.3f V  T2=%.3f V  T3=%.3f V\n",
        v_tap1,
        v_tap12,
        v_tap123);

    Serial.println(
        "===========================================\n");

    // ========================================================
    // UPDATE TIMER
    // ========================================================

    last_sample_time = now;

    delay(SAMPLE_INTERVAL_MS);
}