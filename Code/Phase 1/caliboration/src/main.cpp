#include <Arduino.h>

void setup() {
  Serial.begin(115200);
  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);
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
  Serial.printf("raw=%d\n", readRawADC(34)); // change pin per tap being tested
  delay(2000);
}