// ============================================================
// 3S Li-Ion / LiPo Battery Pack – Per-Cell Voltage Monitor
// Platform : ESP32 (12-bit ADC, 3.3 V reference)
//
// Wiring (voltage-divider taps → ESP32 ADC pins):
//   ONE_S_PIN   – B- to B1 tap  (Cell 1 bottom)
//   TWO_S_PIN   – B- to B2 tap  (Cell 1+2 combined)
//   THREE_S_PIN – B- to B+ tap  (full pack voltage)
//
// Each tap must be divided down below 3.3 V.
// Divider currently set with a 50 kΩ preset adjusted to 33 kΩ:
// R_top = 100 kΩ, R_bot = 33 kΩ
//   ratio ≈ 4.03  →  max measurable voltage ≈ 13.3 V (safe for 3S)
// ============================================================

#include <Arduino.h>

// ─── ADC Pin Assignments ─────────────────────────────────────
// NOTE: This project targets classic ESP32 DevKit V1.
// Prefer ADC1 pins to avoid ADC2/Wi-Fi conflicts on ESP32.
// ADC1 pins on ESP32 are GPIO32..GPIO39.
#define ONE_S_PIN    34   // Cell-1 tap   (B- → B1)
#define TWO_S_PIN    35   // Cell-1+2 tap (B- → B2)
#define THREE_S_PIN  32   // Full-pack tap (B- → B+)

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

    Serial.println("Booting battery monitor...");

    // Configure ADC pins as inputs
    pinMode(ONE_S_PIN,   INPUT);
    pinMode(TWO_S_PIN,   INPUT);
    pinMode(THREE_S_PIN, INPUT);

    analogReadResolution(12);

    // 11 dB attenuation → full-scale ≈ 3.1 V input
    analogSetAttenuation(ADC_11db);

    Serial.println("===========================================");
    Serial.println("  3S Battery Pack – Per-Cell Voltage Mon  ");
    Serial.println("===========================================");
    Serial.printf("Divider ratios: C1=%.3f  C2=%.3f  C3=%.3f\n",
                  DIVIDER_RATIO(R_TOP_C1, R_BOT_C1),
                  DIVIDER_RATIO(R_TOP_C2, R_BOT_C2),
                  DIVIDER_RATIO(R_TOP_C3, R_BOT_C3));
    Serial.println("-------------------------------------------");
}

// ============================================================
void loop() {
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
    float pack_v  = v_tap123;           // Full pack voltage

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

    // ── 7. Print formatted report ─────────────────────────────
    Serial.println("===========================================");
    Serial.printf("Pack Voltage  : %.3f V\n", pack_v);
    Serial.printf("Avg Pack SoC  : %.1f %%\n", avg_soc);
    Serial.printf("Cell Imbalance: %.1f mV%s\n",
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
    // Raw ADC debug (comment out after calibration)
    Serial.printf("[RAW] tap1=%d  tap12=%d  tap123=%d\n",
                  raw_tap1, raw_tap12, raw_tap123);
    Serial.println("===========================================\n");

    delay(SAMPLE_INTERVAL_MS);
}
