"""
NASA Battery Dataset Extractor
--------------------------------
Reads every .mat file in an input folder (NASA PCoE battery dataset format),
extracts:
  1. Per-timestep discharge data with coulomb-counted SOC (0-100%)
  2. Per-cycle summary with capacity, SOH, and RUL labels

Usage:
    Just drop this script into the SAME folder as your .mat files and run:
        python extract_all_batteries.py
    It will read every .mat file in that folder and write both output CSVs
    right there alongside them.

    (Optional) To use different folders instead:
        python extract_all_batteries.py --input_dir path/to/mats --output_dir path/to/output

Outputs (written into the same folder as the .mat files, unless overridden):
    timeseries_soc.csv           -> battery_id, cycle, t_s, voltage, current, temperature, soc, cycle_capacity_Ah
    cycle_summary_soh_rul.csv    -> battery_id, cycle, capacity_Ah, soh, rul, max/min/mean voltage/current/temperature, discharge_time_s
"""

import argparse
import glob
import os

import numpy as np
import pandas as pd
import scipy.io as sio


def get_battery_key(mat_dict):
    """Return the top-level battery struct key (e.g. 'B0005'), ignoring MATLAB metadata keys."""
    for k in mat_dict.keys():
        if not k.startswith('__'):
            return k
    raise ValueError("No battery struct found in .mat file")


def extract_battery(mat_path):
    """Extract per-timestep SOC data and per-cycle summary for one battery .mat file."""
    d = sio.loadmat(mat_path, simplify_cells=True)
    battery_id = get_battery_key(d)
    cycles = d[battery_id]['cycle']

    timeseries_rows = []
    summary_rows = []
    discharge_idx = 0

    for c in cycles:
        if c.get('type') != 'discharge':
            continue
        discharge_idx += 1

        data = c['data']
        t = np.asarray(data['Time'], dtype=float)
        v = np.asarray(data['Voltage_measured'], dtype=float)
        i = np.asarray(data['Current_measured'], dtype=float)  # negative while discharging
        temp = np.asarray(data['Temperature_measured'], dtype=float)
        capacity_Ah = float(data['Capacity'])

        # Coulomb counting (trapezoidal integration of |current| over time)
        dt_hours = np.diff(t) / 3600.0
        i_avg = (np.abs(i[:-1]) + np.abs(i[1:])) / 2.0
        incremental_Ah = i_avg * dt_hours
        cum_Ah = np.concatenate(([0.0], np.cumsum(incremental_Ah)))

        soc = 100.0 * (1.0 - cum_Ah / capacity_Ah)
        soc = np.clip(soc, 0, 100)

        for k in range(len(t)):
            timeseries_rows.append({
                'battery_id': battery_id,
                'cycle': discharge_idx,
                't_s': t[k],
                'voltage': v[k],
                'current': i[k],
                'temperature': temp[k],
                'soc': soc[k],
                'cycle_capacity_Ah': capacity_Ah
            })

        summary_rows.append({
            'battery_id': battery_id,
            'cycle': discharge_idx,
            'capacity_Ah': capacity_Ah,
            'max_voltage_V': v.max(),
            'min_voltage_V': v.min(),
            'mean_voltage_V': v.mean(),
            'max_current_A': i.max(),
            'min_current_A': i.min(),
            'mean_current_A': i.mean(),
            'max_temperature_C': temp.max(),
            'min_temperature_C': temp.min(),
            'mean_temperature_C': temp.mean(),
            'discharge_time_s': t[-1] - t[0],
        })

    ts_df = pd.DataFrame(timeseries_rows)
    sum_df = pd.DataFrame(summary_rows)

    return ts_df, sum_df


def clean_summary(sum_df, glitch_threshold_ah=0.02, protocol_shift_soh_threshold=0.3):
    """Apply data-quality fixes discovered in the NASA battery dataset:
      1. Drop glitch cycles with near-zero measured capacity (corrupted/aborted tests).
      2. Compute a robust 'rated capacity' per battery (95th percentile of capacity_Ah)
         instead of using cycle 1, since first-cycle capacity is sometimes itself an
         anomaly (e.g. B0033's cycle 1 measured ~0.07 Ah vs ~1.2 Ah for every cycle after).
      3. Flag and drop cycles that belong to a different, shallower discharge protocol
         mixed into the same battery's log (e.g. B0041 cycles 1-42 measured ~0.05 Ah
         while cycles 43+ measured ~1.0 Ah -- not degradation, a different test regime).
      4. Recompute RUL as cycles remaining until the end of each battery's *valid* log.
    """
    if sum_df.empty:
        return sum_df

    glitch_mask = sum_df['capacity_Ah'] < glitch_threshold_ah
    sum_df = sum_df[~glitch_mask].copy()
    if sum_df.empty:
        return sum_df

    rated_capacity = sum_df['capacity_Ah'].quantile(0.95)
    sum_df['rated_capacity_Ah'] = rated_capacity
    sum_df['soh'] = sum_df['capacity_Ah'] / rated_capacity

    protocol_shift_mask = sum_df['soh'] < protocol_shift_soh_threshold
    sum_df = sum_df[~protocol_shift_mask].copy()
    if sum_df.empty:
        return sum_df

    max_valid_cycle = sum_df['cycle'].max()
    sum_df['rul'] = max_valid_cycle - sum_df['cycle']

    return sum_df


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))

    parser = argparse.ArgumentParser()
    parser.add_argument('--input_dir', default=script_dir,
                         help='Folder containing .mat files (default: same folder as this script)')
    parser.add_argument('--output_dir', default=script_dir,
                         help='Folder to write output CSVs (default: same folder as this script)')
    args = parser.parse_args()

    mat_files = sorted(glob.glob(os.path.join(args.input_dir, '*.mat')))
    if not mat_files:
        raise SystemExit(f"No .mat files found in {args.input_dir}")

    all_ts = []
    all_summary = []

    for path in mat_files:
        try:
            ts_df, sum_df = extract_battery(path)
            sum_df = clean_summary(sum_df)
            if not sum_df.empty:
                valid_cycles = set(sum_df['cycle'])
                ts_df = ts_df[ts_df['cycle'].isin(valid_cycles)].copy()
            all_ts.append(ts_df)
            all_summary.append(sum_df)
            battery_id = get_battery_key(sio.loadmat(path, simplify_cells=True))
            print(f"[OK] {os.path.basename(path)} -> battery {battery_id}, "
                  f"{sum_df['cycle'].max() if not sum_df.empty else 0} discharge cycles, "
                  f"{len(ts_df)} timesteps")
        except Exception as e:
            print(f"[SKIP] {os.path.basename(path)} -> {e}")

    os.makedirs(args.output_dir, exist_ok=True)

    ts_all = pd.concat(all_ts, ignore_index=True)
    summary_all = pd.concat(all_summary, ignore_index=True)

    ts_path = os.path.join(args.output_dir, 'timeseries_soc.csv')
    summary_path = os.path.join(args.output_dir, 'cycle_summary_soh_rul.csv')

    ts_all.to_csv(ts_path, index=False)
    summary_all.to_csv(summary_path, index=False)

    print(f"\nDone.")
    print(f"  {ts_path}  ({len(ts_all)} rows, {ts_all['battery_id'].nunique()} batteries)")
    print(f"  {summary_path}  ({len(summary_all)} rows, {summary_all['battery_id'].nunique()} batteries)")


if __name__ == '__main__':
    main()
