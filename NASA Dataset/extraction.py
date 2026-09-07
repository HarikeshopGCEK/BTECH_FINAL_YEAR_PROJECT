import os
import glob
import numpy as np
import pandas as pd
from scipy.io import loadmat


# ============================================================
# CONFIGURATION
# ============================================================

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

OUTPUT_FILE = os.path.join(
    BASE_DIR,
    "NASA_battery_cycle_summary.csv"
)


# ============================================================
# HELPER FUNCTIONS
# ============================================================

def get_field(struct, name):
    """
    Safely get a field from a MATLAB structured array.
    """
    try:
        return struct[name]
    except (ValueError, KeyError, IndexError):
        return None


def flatten_array(x):
    """
    Convert MATLAB/numpy array into a 1-D numpy array.
    """
    if x is None:
        return None

    return np.asarray(x).flatten()


# ============================================================
# PROCESS ONE BATTERY FILE
# ============================================================

def process_battery(mat_file):

    print(f"Processing: {mat_file}")

    try:
        mat = loadmat(mat_file)
    except Exception as e:
        print(f"  ERROR loading file: {e}")
        return []

    # Find the battery variable.
    battery_id = os.path.splitext(
        os.path.basename(mat_file)
    )[0]

    if battery_id not in mat:
        print(f"  Could not find variable {battery_id}")
        return []

    battery = mat[battery_id][0, 0]

    cycles = get_field(battery, "cycle")

    if cycles is None:
        print("  No cycle data found")
        return []

    cycles = cycles.flatten()

    results = []

    for cycle_index, cycle in enumerate(cycles, start=1):

        try:

            cycle_type = get_field(cycle, "type")

            if cycle_type is None:
                continue

            cycle_type = str(
                np.asarray(cycle_type).flatten()[0]
            ).lower()

            # We mainly want discharge cycles
            if "discharge" not in cycle_type:
                continue

            data = get_field(cycle, "data")

            if data is None:
                continue

            data = data[0, 0]

            # ------------------------------------------------
            # Extract measurements
            # ------------------------------------------------

            voltage = flatten_array(
                get_field(data, "Voltage_measured")
            )

            current = flatten_array(
                get_field(data, "Current_measured")
            )

            temperature = flatten_array(
                get_field(data, "Temperature_measured")
            )

            time = flatten_array(
                get_field(data, "Time")
            )

            capacity = get_field(data, "Capacity")

            # ------------------------------------------------
            # Check required data
            # ------------------------------------------------

            if voltage is None or len(voltage) == 0:
                continue

            if current is None or len(current) == 0:
                continue

            if temperature is None or len(temperature) == 0:
                continue

            # ------------------------------------------------
            # Convert to float
            # ------------------------------------------------

            voltage = voltage.astype(float)
            current = current.astype(float)
            temperature = temperature.astype(float)

            # ------------------------------------------------
            # Capacity
            # ------------------------------------------------

            if capacity is not None:

                capacity = float(
                    np.asarray(capacity).flatten()[0]
                )

            else:
                capacity = np.nan

            # ------------------------------------------------
            # Calculate cycle statistics
            # ------------------------------------------------

            max_voltage = np.max(voltage)
            min_voltage = np.min(voltage)
            mean_voltage = np.mean(voltage)

            max_current = np.max(current)
            min_current = np.min(current)
            mean_current = np.mean(current)

            max_temperature = np.max(temperature)
            min_temperature = np.min(temperature)
            mean_temperature = np.mean(temperature)

            # Discharge duration
            if time is not None and len(time) > 1:

                time = time.astype(float)

                discharge_time = (
                    np.max(time) - np.min(time)
                )

            else:

                discharge_time = np.nan

            # ------------------------------------------------
            # SOH
            # ------------------------------------------------
            #
            # We use the initial/reference capacity of each
            # battery later during preprocessing.
            #
            # For now we store capacity only.
            # ------------------------------------------------

            results.append({

                "battery": battery_id,

                "cycle": cycle_index,

                "capacity_Ah": capacity,

                "max_voltage_V": max_voltage,

                "min_voltage_V": min_voltage,

                "mean_voltage_V": mean_voltage,

                "max_current_A": max_current,

                "min_current_A": min_current,

                "mean_current_A": mean_current,

                "max_temperature_C": max_temperature,

                "min_temperature_C": min_temperature,

                "mean_temperature_C": mean_temperature,

                "discharge_time_s": discharge_time

            })

        except Exception as e:

            print(
                f"  Cycle {cycle_index} skipped: {e}"
            )

    print(
        f"  → {len(results)} discharge cycles extracted"
    )

    return results


# ============================================================
# FIND ALL MATLAB FILES
# ============================================================

mat_files = glob.glob(
    os.path.join(
        BASE_DIR,
        "**",
        "*.mat"
    ),
    recursive=True
)

print()
print("=" * 60)
print("NASA BATTERY DATA CONVERTER")
print("=" * 60)
print()

print(f"Found {len(mat_files)} MATLAB files.")
print()


# ============================================================
# PROCESS ALL FILES
# ============================================================

all_results = []

for mat_file in sorted(mat_files):

    battery_results = process_battery(mat_file)

    all_results.extend(battery_results)


# ============================================================
# CREATE DATAFRAME
# ============================================================

df = pd.DataFrame(all_results)


# ============================================================
# SORT
# ============================================================

if not df.empty:

    df = df.sort_values(
        by=["battery", "cycle"]
    ).reset_index(drop=True)


# ============================================================
# SAVE CSV
# ============================================================

df.to_csv(
    OUTPUT_FILE,
    index=False
)


# ============================================================
# SUMMARY
# ============================================================

print()
print("=" * 60)
print("CONVERSION COMPLETE")
print("=" * 60)

print()

print(f"Total rows: {len(df)}")

print()

if not df.empty:

    print("Batteries found:")

    print(
        df["battery"]
        .value_counts()
        .sort_index()
    )

    print()

    print("Columns:")

    for column in df.columns:
        print(f"  - {column}")

    print()

    print("First 5 rows:")

    print(
        df.head().to_string(
            index=False
        )
    )

print()

print(f"Saved to:")

print(OUTPUT_FILE)

print()