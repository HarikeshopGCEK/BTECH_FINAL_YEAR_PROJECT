// ============================================================
// ESP32-S3 DevKit C - ADC Calibration Tool
//
// Pin Assignments (ADC1 on ESP32-S3):
//   ONE_S_PIN   (GPIO 4) - Cell 1 tap  (B- to B1)
//   TWO_S_PIN   (GPIO 5) - Cell 2 tap  (B- to B2)
//   THREE_S_PIN (GPIO 6) - Cell 3 tap  (B- to B+)
// ============================================================

#include <Arduino.h>

// Compatibility macro for ESP32 core attenuation definitions
#ifndef ADC_ATTEN_DB_11
#define ADC_ATTEN_DB_11 ADC_11db
#endif

// ESP32-S3 ADC1 Pin Assignments for 3S Taps
#define ONE_S_PIN 4   // GPIO 4
#define TWO_S_PIN 5   // GPIO 5
#define THREE_S_PIN 6 // GPIO 6

void setup() {
  Serial.begin(115200);
  delay(1000); // Allow USB CDC serial to stabilize on ESP32-S3

  analogReadResolution(12);              // 12-bit resolution (0-4095)
  analogSetAttenuation(ADC_ATTEN_DB_11); // Full 0 - 3.3V measurement range

  Serial.println("\n--- ESP32-S3 DevKit C ADC Calibration ---");
  Serial.printf("Pins assigned: Tap1=GPIO%d, Tap2=GPIO%d, Tap3=GPIO%d\n",
                ONE_S_PIN, TWO_S_PIN, THREE_S_PIN);
}

int readRawADC(int pin, int samples = 64) {
  long sum = 0;
  for (int i = 0; i < samples; i++) {
    sum += analogRead(pin);
    delayMicroseconds(100);
  }
  return sum / samples;
}

void loop() {
  int raw1 = readRawADC(ONE_S_PIN);
  int raw2 = readRawADC(TWO_S_PIN);
  int raw3 = readRawADC(THREE_S_PIN);

  float v1_adc = (raw1 / 4095.0f) * 3.3f;
  float v2_adc = (raw2 / 4095.0f) * 3.3f;
  float v3_adc = (raw3 / 4095.0f) * 3.3f;

  Serial.printf("Tap1 (GPIO %d): raw=%4d, V_adc=%.3fV | ", ONE_S_PIN, raw1,
                v1_adc);
  Serial.printf("Tap2 (GPIO %d): raw=%4d, V_adc=%.3fV | ", TWO_S_PIN, raw2,
                v2_adc);
  Serial.printf("Tap3 (GPIO %d): raw=%4d, V_adc=%.3fV\n", THREE_S_PIN, raw3,
                v3_adc);

  delay(2000);
}