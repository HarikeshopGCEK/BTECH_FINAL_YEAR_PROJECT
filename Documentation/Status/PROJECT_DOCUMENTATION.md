# EDGE AI Based Smart Battery Monitoring System

**Project:** On-device estimation of Battery State of Charge (SOC), State of Health (SOH), and Remaining Useful Life (RUL) on an ESP32-S3, trained on the NASA Li-ion Battery Degradation Dataset.

**Institution:** Government College of Engineering Kannur (GCEK)

---

## 1. Project Overview

The goal is a real-time, on-device battery monitoring system that estimates:
- **SOC** (0–100%) — how full the battery is right now
- **SOH** — long-term capacity health relative to rated capacity
- **RUL** — cycles remaining before end-of-life

Target hardware: **ESP32-S3**, powered from the same battery pack it monitors, using **WiFi only** (no BLE). Cell voltages are measured via 3 calibrated voltage dividers on a 3S pack (no dedicated BMS AFE chip — direct ADC measurement approach), with an NTC thermistor per cell for temperature.

Modeling approach: a **comparative study** across a complexity ladder — a classical non-ML baseline, then three ML models (Random Forest, MLP, LSTM) — trained on the NASA PCoE battery dataset and evaluated for eventual TFLite Micro deployment.

---

## 2. Data Pipeline

### 2.1 Source Data
NASA's Li-ion battery degradation dataset (`.mat` format), 34 batteries, each containing hundreds of charge/discharge/impedance cycles with per-timestep voltage, current, and temperature.

### 2.2 Extraction (`extract_all_batteries.py`)
A custom script parses every `.mat` file in a folder and produces two CSVs:
- **`timeseries_soc.csv`** — per-timestep voltage/current/temperature/SOC for every discharge cycle
- **`cycle_summary_soh_rul.csv`** — per-cycle capacity/SOH/RUL summary

**SOC ground truth** is computed via coulomb counting: integrating current over time within each discharge cycle (`SOC = 100 × (1 − cumulative_Ah / cycle_capacity)`), anchored at 100% at the start of discharge.

### 2.3 Data Cleaning — Issues Found and Fixed

Three real data-quality problems were discovered and corrected during this project:

**(a) SOH baseline was fragile.** Initially computed against each battery's *first-cycle* capacity, but some batteries' first cycle is itself an anomaly (e.g., one battery's cycle 1 measured 0.068 Ah while every subsequent cycle measured 1.1–1.3 Ah). This inflated SOH to nonsensical values (up to 27×). **Fix:** rated capacity is now computed as the 95th percentile of that battery's own capacity distribution — robust to a single bad first reading.

**(b) Protocol-shift cycles.** Several batteries (B0041–B0044 and others) mixed in a large block of cycles run at a much shallower discharge depth — not gradual degradation, but a different test protocol entirely. **Decision:** these flagged cycles (identified as SOH < 0.3 relative to the robust baseline) were dropped, keeping the rest of each affected battery intact.

**(c) Trailing rest-phase samples polluting SOC=0 label.** After a cycle's coulomb count first reaches SOC=0%, some cycles kept logging additional "rest" samples where current drops to ~0 and voltage recovers upward — while SOC (correctly) stays at 0. This created a vertical smear of contradictory voltage readings all labeled "SOC=0%", which measurably degraded model training (visible as a systematic error artifact near SOC=0 in early model runs). **Fix:** each cycle is truncated at its *first* SOC=0 crossing, preserving legitimate mid-cycle rest periods (real signal for a device that idles between draws) while removing the ambiguous post-depletion tail.

Final cleaned dataset: **32 batteries**, ~2,500 cycles, ~740,000 timesteps.

---

## 3. Exploratory Data Analysis — Key Findings

1. **Current is only 4 discrete levels** (0, -1, -2, -4A) — NASA's tests used constant-current discharge protocols. This is a **known limitation**: it doesn't match the continuously variable current a real ESP32+WiFi device will draw. Real hardware data collection (variable/pulsed load) is planned to close this gap.

2. **Voltage-SOC hysteresis confirmed.** At a fixed SOC, voltage varies ~0.3–0.5V depending on discharge current (`V = OCV(SOC) − I×R_internal`). This proves **voltage alone cannot determine SOC** — current is a mandatory model input.

3. **Aging shifts the voltage-SOC curve.** A battery's curve visibly shifts downward across its life (rising internal resistance), converging only near 100% SOC. This creates an inherent accuracy ceiling for any SOC model with no notion of battery age — noted as a limitation and a direction for future work (cascading SOH output into the SOC model).

4. **Temperature has a secondary but real effect** on the voltage-SOC relationship, consistent with temperature-dependent internal resistance.

---

## 4. SOC Modeling — Comparative Study Results

**Train/test split:** at the *battery* level (entire batteries held out for testing), not a random row split — this measures generalization to a battery the model has never seen, the real deployment scenario.

**Models:**
1. **Coulomb Counting** (classical baseline) — uses each battery's *rated* capacity (known in advance), not that cycle's true capacity, matching what a real embedded coulomb counter can actually do
2. **Random Forest** — windowed statistical features (mean/min/max/last/delta per channel)
3. **MLP** — flattened window input, dropout + early stopping (added after an initial run showed severe overfitting — training loss kept falling while validation loss rose)
4. **LSTM** — raw sequence input, same dropout + early stopping treatment

### Results (full 32-battery training run)

| Model | MAE (%) | RMSE (%) | R² |
|---|---|---|---|
| Coulomb Counting | 4.27 | 7.54 | 0.927 |
| **Random Forest** | **3.59** | **5.15** | **0.966** |
| MLP | 6.19 | 7.89 | 0.921 |
| LSTM | 6.70 | 8.68 | 0.904 |

**Headline finding:** all three ML approaches beat classical coulomb counting on error metrics. Coulomb counting's error compounds with depth of discharge (a diagonal-fan pattern in its error plot — a textbook signature of integration drift), while ML models use instantaneous sensor readings and don't accumulate that drift.

**Random Forest currently leads** the ML comparison, though the gap versus MLP/LSTM narrowed substantially after fixing an early-training overfitting bug.

### Diagnostic Finding: Out-of-Distribution Batteries

Two held-out test batteries (B0038, B0054) showed a systematic error pattern (growing under-prediction through mid-range SOC) not seen in any other test battery. Investigation ruled out a missing current/temperature regime — a closely matching "twin" battery for each exists in the training set. The remaining explanation, consistent with the aging-curve-shift finding above, is **unit-to-unit aging variance**: individual battery cells degrade at different rates even under nominally identical test conditions, and the model has no signal to detect a specific unit's aging state. Documented as a known limitation rather than a data-split bug.

---

## 5. Hardware — Cell Voltage & Temperature Sensing

### 5.1 Design
3S pack, no dedicated BMS AFE chip — direct measurement via:
- **3 voltage dividers** (one per tap: Cell1 alone, Cell1+Cell2, full pack), each with a trim pot for coarse ratio adjustment
- **3 NTC thermistors** (10kΩ, B=3950, with 10kΩ series resistor), one per cell, wired independently to 3.3V/GND (not part of the series stack)
- Individual cell voltage computed in software: `Cell2 = Tap2 − Tap1`, `Cell3 = Tap3 − Tap2`

### 5.2 Tap1 Divider Change
Original 100kΩ/50kΩ divider only used ~1.4V of the ADC's 0–3.3V range at full charge (4.2V). Changed Tap1's top resistor to **22kΩ** (keeping 50kΩ bottom/pot), landing at ~2.92V at full charge — much better use of ADC resolution, comfortable margin below 3.3V.

### 5.3 Software Calibration Procedure
Two-stage approach: pot handles coarse ratio, software handles precision.
1. Disconnect battery; feed each tap's divider input directly (not the assembled pack) with 5 known reference voltages spanning that tap's real operating range (Tap1: 2.7–4.2V; Tap2: 5.4–8.4V; Tap3: 8.1–12.6V)
2. Log oversampled (64-sample averaged) raw ADC values at each reference point
3. Fit slope/offset (linear or quadratic) per channel via least-squares
4. Embed constants in firmware; verify against fresh, unused reference voltages
5. Re-calibrate any channel whose pot is physically re-adjusted afterward

### 5.4 Calibration Results (First Attempt)

| Tap | Fit | Max Error | Status |
|---|---|---|---|
| Tap1 | Quadratic | 22.0 mV | Needs re-measurement |
| Tap2 | Quadratic | 5.1 mV | **Good, in use** |
| Tap3 | Quadratic | 211.7 mV | Needs re-measurement |

Tap2's clean result confirms the method works when the input measurement is clean. Tap1 and Tap3's high errors were diagnosed (via leave-one-out residual analysis) as measurement noise — likely single un-averaged ADC reads or a loose connection during the sweep — not a fundamental curve-shape problem. **Action item: re-run Tap1 and Tap3 calibration sweeps using the oversampled reader and verify solid connections throughout.**

---

## 6. Known Limitations (for report/viva discussion)

1. Training data uses only 4 discrete current levels — a domain gap versus real variable-load operation. Mitigation: augment with real hardware-collected variable-load discharge data.
2. Unit-to-unit aging variance creates an SOC accuracy floor the current model can't resolve without a battery-age signal.
3. No dedicated BMS AFE (e.g., BQ76920) — direct ADC sensing requires careful calibration and lacks built-in protection features (over-voltage, over-current, balancing) that a dedicated AFE would provide.
4. NASA dataset is single-cell; pack-level effects (cell imbalance, thermal gradients across 3 cells) are not represented in training data.

---

## 7. Next Steps

1. Re-calibrate Tap1 and Tap3 with oversampled readings.
2. Collect real hardware data under variable/pulsed load to augment the constant-current NASA training set.
3. Apply the same pipeline pattern (protocol check → battery-level split → classical baseline → 3-model comparison) to **SOH** and **RUL**, using `cycle_summary_soh_rul_FINAL.csv`.
4. Investigate cascading the SOH model's output as an auxiliary input to the SOC model, to address the aging-variance accuracy floor.
5. Convert the winning SOC/SOH/RUL models to TFLite Micro (int8 quantized) for ESP32-S3 deployment; Random Forest requires a separate C-code export path (e.g. `emlearn`/`m2cgen`) since it has no native TFLite conversion.
