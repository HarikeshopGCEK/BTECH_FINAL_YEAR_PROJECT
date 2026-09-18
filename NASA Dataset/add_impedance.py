"""
Add internal impedance (Re, Rct) to the existing cycle_summary_soh_rul_FINAL.csv

Impedance is measured by NASA as separate 'impedance'-type cycle records
interleaved with charge/discharge (pattern: charge -> impedance -> discharge
-> impedance -> ...), not as a column inside discharge data itself. This
script walks each .mat file's raw cycle sequence once, and for every
discharge cycle grabs the Re/Rct from the impedance record immediately
following it in that sequence.

NOTE: NASA's early cycles (before interleaving started) have no impedance
measurement -- expect missing values for roughly the first 15-25 cycles of
each battery. These are left as NaN, not filled in, so you decide how to
handle them (drop those rows, or forward/backward-fill per battery).

Usage:
    Run in the same folder as your .mat files AND your existing
    cycle_summary_soh_rul_FINAL.csv (or point --summary_csv elsewhere).

    python add_impedance.py

Output:
    cycle_summary_soh_rul_WITH_IMPEDANCE.csv
"""

import argparse
import glob
import os

import numpy as np
import pandas as pd
import scipy.io as sio


def get_battery_key(mat_dict):
    for k in mat_dict.keys():
        if not k.startswith('__'):
            return k
    raise ValueError("No battery struct found in .mat file")


def extract_impedance_per_discharge(mat_path):
    d = sio.loadmat(mat_path, simplify_cells=True)
    battery_id = get_battery_key(d)
    cycles = d[battery_id]['cycle']

    rows = []
    discharge_idx = 0

    for i, c in enumerate(cycles):
        if c.get('type') != 'discharge':
            continue
        discharge_idx += 1

        re_val, rct_val = np.nan, np.nan
        if i + 1 < len(cycles) and cycles[i + 1].get('type') == 'impedance':
            re_val = cycles[i + 1]['data']['Re']
            rct_val = cycles[i + 1]['data']['Rct']

        rows.append({
            'battery_id': battery_id,
            'cycle': discharge_idx,
            'Re_ohm': re_val,
            'Rct_ohm': rct_val,
        })

    return pd.DataFrame(rows), battery_id


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))

    parser = argparse.ArgumentParser()
    parser.add_argument('--input_dir', default=script_dir)
    parser.add_argument('--summary_csv', default=os.path.join(script_dir, 'cycle_summary_soh_rul_FINAL.csv'))
    parser.add_argument('--output_csv', default=os.path.join(script_dir, 'cycle_summary_soh_rul_WITH_IMPEDANCE.csv'))
    args = parser.parse_args()

    mat_files = sorted(glob.glob(os.path.join(args.input_dir, '*.mat')))
    if not mat_files:
        raise SystemExit(f"No .mat files found in {args.input_dir}")

    all_imp = []
    for path in mat_files:
        try:
            imp_df, battery_id = extract_impedance_per_discharge(path)
            n_missing = imp_df['Re_ohm'].isna().sum()
            print(f"[OK] {os.path.basename(path)} -> {battery_id}, "
                  f"{len(imp_df)} cycles, {n_missing} missing impedance")
            all_imp.append(imp_df)
        except Exception as e:
            print(f"[SKIP] {os.path.basename(path)} -> {e}")

    imp_all = pd.concat(all_imp, ignore_index=True)

    summary = pd.read_csv(args.summary_csv)
    merged = summary.merge(imp_all, on=['battery_id', 'cycle'], how='left')

    print(f"\nMerged: {len(merged)} rows")
    print(f"Rows with impedance data: {merged['Re_ohm'].notna().sum()}")
    print(f"Rows missing impedance data: {merged['Re_ohm'].isna().sum()}")

    merged.to_csv(args.output_csv, index=False)
    print(f"\nSaved: {args.output_csv}")


if __name__ == '__main__':
    main()
