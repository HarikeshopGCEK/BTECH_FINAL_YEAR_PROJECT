// ============================================================
// ESP32-S3 DevKit C - ADC Calibration Tool (v2)
//
// Trigger-based, glitch-resistant calibration data capture.
//
// Pin Assignments (ADC1 on ESP32-S3):
//   ONE_S_PIN   (GPIO 4) - Cell 1 tap  (B- to B1)
//   TWO_S_PIN   (GPIO 5) - Cell 2 tap  (B- to B2)
//   THREE_S_PIN (GPIO 6) - Cell 3 tap  (B- to B+)
//
// USAGE:
//   1. Open Serial Monitor at 115200 baud, line ending = "Newline"
//   2. Type a tap number (1, 2, or 3) + Enter to select which tap you're calibrating
//   3. Connect that tap's divider input to your bench supply at a known reference voltage
//   4. Type the reference voltage (e.g. "3.500") + Enter to capture
//   5. Copy the printed CSV line straight into Calib.csv
//   6. Repeat for all 5 reference voltages per tap, then switch taps
// ============================================================

#include <Arduino.h>

#ifndef ADC_ATTEN_DB_11
#define ADC_ATTEN_DB_11 ADC_11db
#endif

#define ONE_S_PIN 4
#define TWO_S_PIN 5
#define THREE_S_PIN 6

int activeTap = 3;
int activePin = THREE_S_PIN;

void printActiveTap();

void setup()
{
  Serial.begin(115200);
  delay(1000);

  analogReadResolution(12);
  analogSetAttenuation(ADC_ATTEN_DB_11);

  Serial.println("\n--- ESP32-S3 ADC Calibration Tool v2 ---");
  Serial.println("Commands:");
  Serial.println("  1 / 2 / 3          -> select active tap");
  Serial.println("  <number> (e.g 3.5) -> capture at this reference voltage");
  printActiveTap();
}

void printActiveTap()
{
  Serial.printf(">> Active: Tap%d (GPIO %d)\n", activeTap, activePin);
}

// One batch = 64-sample oversampled mean
long readBatch(int pin, int samples = 64)
{
  long sum = 0;
  for (int i = 0; i < samples; i++)
  {
    sum += analogRead(pin);
    delayMicroseconds(100);
  }
  return sum / samples;
}

// Median of 5 batches -- rejects a single glitchy batch instead of
// averaging it into the result. This directly targets the noisy-read
// problem seen in earlier calibration attempts.
int readRawADC_robust(int pin)
{
  long batches[5];
  for (int i = 0; i < 5; i++)
  {
    batches[i] = readBatch(pin);
    delay(20);
  }
  // simple insertion sort (5 elements, not worth a library call)
  for (int i = 1; i < 5; i++)
  {
    long key = batches[i];
    int j = i - 1;
    while (j >= 0 && batches[j] > key)
    {
      batches[j + 1] = batches[j];
      j--;
    }
    batches[j + 1] = key;
  }
  long median = batches[2];

  // Dispersion check: warn if batches disagree by more than ~2 ADC counts
  long spread = batches[4] - batches[0];
  if (spread > 3)
  {
    Serial.printf("  [WARNING] batch spread=%ld raw counts -- connection may be unstable. "
                  "Recommend recapturing this point.\n",
                  spread);
  }
  return (int)median;
}

void loop()
{
  if (Serial.available())
  {
    String input = Serial.readStringUntil('\n');
    input.trim();
    if (input.length() == 0)
      return;

    if (input == "1")
    {
      activeTap = 1;
      activePin = ONE_S_PIN;
      printActiveTap();
      return;
    }
    if (input == "2")
    {
      activeTap = 2;
      activePin = TWO_S_PIN;
      printActiveTap();
      return;
    }
    if (input == "3")
    {
      activeTap = 3;
      activePin = THREE_S_PIN;
      printActiveTap();
      return;
    }

    // otherwise treat input as the reference voltage to capture against
    float refVoltage = input.toFloat();
    if (refVoltage <= 0)
    {
      Serial.println("  [ERROR] Not a valid tap command (1/2/3) or voltage. Try again.");
      return;
    }

    Serial.println("  Settling...");
    delay(500); // let the connection settle before capturing

    int raw = readRawADC_robust(activePin);
    Serial.printf("%.3f,%d\n", refVoltage, raw); // <-- copy this line straight into Calib.csv
  }
}