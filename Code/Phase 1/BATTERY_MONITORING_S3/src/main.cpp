// ============================================================
// 3S Li-Ion / LiPo Battery Pack – NASA Dataset CSV & Real-Time Monitor
// Platform       : ESP32-S3 DevKit
// Current Sensor : INA226 (I2C)
//
// Voltage measurement:
//   Tap 1  → GPIO 4  (Cell 1 bottom)
//   Tap 2  → GPIO 5  (Cell 1+2 combined)
//   Tap 3  → GPIO 6  (Full pack tap)
//
// NTC temperature sensors:
//   Cell 1 → GPIO 1
//   Cell 2 → GPIO 2
//   Cell 3 → GPIO 7
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

// NTC divider ADC inputs
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

#define INA226_SHUNT_OHMS 0.100f
#define INA226_MAX_CURRENT_A 0.800f

// ============================================================
// VOLTAGE DIVIDER RESISTORS
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

#define NTC_FIXED_OHMS 10000.0f
#define NTC_NOMINAL_OHMS 10000.0f
#define NTC_NOMINAL_TEMP_C 25.0f
#define NTC_BETA 3950.0f
#define NTC_SUPPLY_MV 3300.0f

// ============================================================
// ADC VOLTAGE CALIBRATION EQUATIONS
// ============================================================

#define TAP1_A -1.404856e-07f
#define TAP1_B 0.00189009f
#define TAP1_C -0.775924f

#define TAP2_A -2.672302e-07f
#define TAP2_B 0.00380713f
#define TAP2_C -1.370929f

#define TAP3_A -3.830651e-07f
#define TAP3_B 0.00550616f
#define TAP3_C -1.916985f

// ============================================================
// ADC PARAMETERS
// ============================================================

#define ADC_RESOLUTION 4095.0f
#define ADC_VREF 3.3f
#define NUM_SAMPLES 20

// ============================================================
// LI-ION CELL VOLTAGE THRESHOLDS
// ============================================================

#define CELL_FULL 4.20f
#define CELL_NOMINAL 3.70f
#define CELL_LOW 3.30f
#define CELL_CUTOFF 3.00f

// ============================================================
// OUTPUT MODES & STATE VARIABLES
// ============================================================

enum OutputMode
{
    MODE_HUMAN,
    MODE_CSV
};

INA226 ina(INA226_I2C_ADDR);
bool ina226_ready = false;

// Timing & Control
unsigned long last_sample_time = 0;
unsigned long sample_interval_ms = 1000;
unsigned long cycle_start_time = 0;
bool logging_active = true;
OutputMode current_output_mode = MODE_CSV; // Default to CSV output mode as requested

// NASA Dataset Tracking Metadata
String battery_id = "B0001";
uint32_t current_cycle = 1;
float cycle_capacity_mah = 0.0f;
float total_capacity_mah = 0.0f;

// Command parser buffer
String serialCommandBuffer = "";

// Forward declarations
void printHelp();
void printHeader();
void processCommand(String cmd);
void startCycle(uint32_t cycleNum);

// ============================================================
// INA226 INITIALIZATION
// ============================================================

bool initINA226()
{
    if (!ina.begin())
    {
        return false;
    }

    float maxCurrent = INA226_MAX_CURRENT_A;
    if ((maxCurrent * INA226_SHUNT_OHMS) > 0.0819f)
    {
        maxCurrent = 0.080f / INA226_SHUNT_OHMS;
    }

    int err = ina.setMaxCurrentShunt(maxCurrent, INA226_SHUNT_OHMS);
    if (err != INA226_ERR_NONE)
    {
        Serial.printf("[INA226] Calibration failed code: 0x%04X\n", err);
        return false;
    }

    ina.setAverage(INA226_16_SAMPLES);
    ina.setBusVoltageConversionTime(INA226_1100_us);
    ina.setShuntVoltageConversionTime(INA226_1100_us);
    ina.setModeShuntBusContinuous();
    return true;
}

// ============================================================
// AVERAGED ADC READ
// ============================================================

uint16_t adcAveraged(uint8_t pin, uint8_t samples = NUM_SAMPLES)
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
    float ntc_ohms = NTC_FIXED_OHMS * voltage_mv / (NTC_SUPPLY_MV - voltage_mv);
    float temperature_kelvin = 1.0f / ((1.0f / (NTC_NOMINAL_TEMP_C + 273.15f)) +
                                       (logf(ntc_ohms / NTC_NOMINAL_OHMS) / NTC_BETA));
    return temperature_kelvin - 273.15f;
}

// ============================================================
// SIMPLE LINEAR SOC ESTIMATION
// ============================================================

float estimateSoC(float cellV)
{
    if (cellV >= CELL_FULL)
        return 100.0f;
    if (cellV <= CELL_CUTOFF)
        return 0.0f;
    return ((cellV - CELL_CUTOFF) / (CELL_FULL - CELL_CUTOFF)) * 100.0f;
}

// ============================================================
// CELL STATUS
// ============================================================

const char *cellStatus(float cellV)
{
    if (cellV >= CELL_FULL)
        return "FULL";
    if (cellV >= CELL_NOMINAL)
        return "OK";
    if (cellV >= CELL_LOW)
        return "LOW";
    if (cellV >= CELL_CUTOFF)
        return "CRITICAL";
    return "UNDER-VOLTAGE!";
}

// ============================================================
// SERIAL COMMAND INTERFACE
// ============================================================

void printHeader()
{
    Serial.println("battery_id,cycle,t_s,voltage,current,temperature,soc,cell1_v,cell2_v,cell3_v,temp1_c,temp2_c,temp3_c,cycle_capacity_Ah");
}

void printHelp()
{
    Serial.println(F("\n--- BATTERY MONITORING SERIAL COMMANDS ---"));
    Serial.println(F("  START [cycle]  : Start logging CSV data (resets cycle timer/capacity). E.g. START or START 1"));
    Serial.println(F("  STOP           : Pause CSV data logging output"));
    Serial.println(F("  CYCLE <n>      : Set current cycle number (e.g. CYCLE 2)"));
    Serial.println(F("  NEXT           : Advance to next cycle (cycle++, resets cycle time & capacity)"));
    Serial.println(F("  CSV            : Switch output format to CSV stream"));
    Serial.println(F("  HUMAN / TEXT   : Switch output format to Human-Readable dashboard"));
    Serial.println(F("  HEADER         : Print CSV header row"));
    Serial.println(F("  ID <name>      : Set battery ID string (e.g. ID B0001)"));
    Serial.println(F("  INTERVAL <ms>  : Set sampling interval in milliseconds (e.g. INTERVAL 1000)"));
    Serial.println(F("  HELP / ?       : Display this command list"));
    Serial.println(F("-------------------------------------------\n"));
}

void startCycle(uint32_t cycleNum)
{
    current_cycle = cycleNum;
    cycle_start_time = millis();
    cycle_capacity_mah = 0.0f;
    logging_active = true;
    current_output_mode = MODE_CSV;
    Serial.printf("[CMD] Started Cycle %u for Battery %s\n", current_cycle, battery_id.c_str());
    printHeader();
}

void processCommand(String cmd)
{
    cmd.trim();
    if (cmd.length() == 0)
        return;

    String upperCmd = cmd;
    upperCmd.toUpperCase();

    if (upperCmd == "HELP" || upperCmd == "?")
    {
        printHelp();
    }
    else if (upperCmd == "HEADER")
    {
        printHeader();
    }
    else if (upperCmd == "CSV")
    {
        current_output_mode = MODE_CSV;
        logging_active = true;
        Serial.println(F("[CMD] Output mode set to CSV"));
        printHeader();
    }
    else if (upperCmd == "HUMAN" || upperCmd == "TEXT" || upperCmd == "DASHBOARD")
    {
        current_output_mode = MODE_HUMAN;
        Serial.println(F("[CMD] Output mode set to HUMAN"));
    }
    else if (upperCmd == "STOP")
    {
        logging_active = false;
        Serial.println(F("[CMD] Logging output STOPPED"));
    }
    else if (upperCmd == "NEXT" || upperCmd == "N")
    {
        startCycle(current_cycle + 1);
    }
    else if (upperCmd.startsWith("START"))
    {
        int spaceIdx = cmd.indexOf(' ');
        if (spaceIdx > 0)
        {
            uint32_t c = cmd.substring(spaceIdx + 1).toInt();
            if (c == 0)
                c = 1;
            startCycle(c);
        }
        else
        {
            startCycle(current_cycle);
        }
    }
    else if (upperCmd.startsWith("CYCLE ") || upperCmd.startsWith("C "))
    {
        int spaceIdx = cmd.indexOf(' ');
        uint32_t c = cmd.substring(spaceIdx + 1).toInt();
        if (c > 0)
        {
            current_cycle = c;
            Serial.printf("[CMD] Cycle set to %u\n", current_cycle);
        }
        else
        {
            Serial.println(F("[ERR] Invalid cycle number"));
        }
    }
    else if (upperCmd.startsWith("ID "))
    {
        battery_id = cmd.substring(3);
        battery_id.trim();
        Serial.printf("[CMD] Battery ID set to: %s\n", battery_id.c_str());
    }
    else if (upperCmd.startsWith("INTERVAL "))
    {
        long val = cmd.substring(9).toInt();
        if (val >= 100)
        {
            sample_interval_ms = val;
            Serial.printf("[CMD] Sampling interval set to %lu ms\n", sample_interval_ms);
        }
        else
        {
            Serial.println(F("[ERR] Interval must be >= 100 ms"));
        }
    }
    else
    {
        Serial.printf("[ERR] Unknown command: '%s'. Type HELP for commands.\n", cmd.c_str());
    }
}

void checkSerialInput()
{
    while (Serial.available())
    {
        char c = (char)Serial.read();
        if (c == '\n' || c == '\r')
        {
            if (serialCommandBuffer.length() > 0)
            {
                processCommand(serialCommandBuffer);
                serialCommandBuffer = "";
            }
        }
        else
        {
            if (serialCommandBuffer.length() < 64)
            {
                serialCommandBuffer += c;
            }
        }
    }
}

// ============================================================
// SETUP
// ============================================================

void setup()
{
    Serial.begin(115200);

    unsigned long serial_wait_start = millis();
    while (!Serial && (millis() - serial_wait_start < 2000))
    {
        delay(10);
    }

    Serial.println();
    Serial.println(F("Booting Battery Monitoring System (ESP32-S3 NASA Dataset Logging)..."));

    // ADC pins
    pinMode(ONE_S_PIN, INPUT);
    pinMode(TWO_S_PIN, INPUT);
    pinMode(THREE_S_PIN, INPUT);
    pinMode(NTC_CELL1_PIN, INPUT);
    pinMode(NTC_CELL2_PIN, INPUT);
    pinMode(NTC_CELL3_PIN, INPUT);

    analogReadResolution(12);
    analogSetAttenuation(ADC_ATTEN_DB_11);

    // I2C & INA226
    Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
    ina226_ready = initINA226();

    if (ina226_ready)
    {
        Serial.printf("[INA226] Detected at 0x%02X (Shunt: %.3f Ω, MaxLoadCurrent: %.2f A)\n",
                      INA226_I2C_ADDR, INA226_SHUNT_OHMS, INA226_MAX_CURRENT_A);
    }
    else
    {
        Serial.printf("[INA226] WARNING: Sensor not detected on I2C (SDA=%d, SCL=%d)\n",
                      I2C_SDA_PIN, I2C_SCL_PIN);
    }

    cycle_start_time = millis();
    last_sample_time = millis();

    printHelp();
    printHeader();
}

// ============================================================
// MAIN LOOP
// ============================================================

void loop()
{
    // 1. Process serial commands instantly without blocking
    checkSerialInput();

    unsigned long now = millis();

    // 2. Check sampling timer
    if (now - last_sample_time < sample_interval_ms)
    {
        return;
    }

    float dt_hours = (now - last_sample_time) / 3600000.0f;
    last_sample_time = now;

    // ========================================================
    // READ ADC TAPS
    // ========================================================

    uint16_t raw_tap1 = adcAveraged(ONE_S_PIN);
    uint16_t raw_tap12 = adcAveraged(TWO_S_PIN);
    uint16_t raw_tap123 = adcAveraged(THREE_S_PIN);

    // Convert raw ADC to calibrated tap voltages
    float v_tap1 = tap1Voltage(raw_tap1);
    float v_tap12 = tap2Voltage(raw_tap12);
    float v_tap123 = tap3Voltage(raw_tap123);

    // NTC Temperatures
    float temp1_c = ntcTemperatureC(NTC_CELL1_PIN);
    float temp2_c = ntcTemperatureC(NTC_CELL2_PIN);
    float temp3_c = ntcTemperatureC(NTC_CELL3_PIN);

    // Calculate individual cell voltages
    float cell1_v = max(v_tap1, 0.0f);
    float cell2_v = max(v_tap12 - v_tap1, 0.0f);
    float cell3_v = max(v_tap123 - v_tap12, 0.0f);
    float pack_v = v_tap123;

    // SoC Estimation
    float soc1 = estimateSoC(cell1_v);
    float soc2 = estimateSoC(cell2_v);
    float soc3 = estimateSoC(cell3_v);
    float avg_soc = (soc1 + soc2 + soc3) / 3.0f;

    // Cell Imbalance
    float v_max = max(max(cell1_v, cell2_v), cell3_v);
    float v_min = min(min(cell1_v, cell2_v), cell3_v);
    float imbalance_mv = (v_max - v_min) * 1000.0f;

    // Average pack temperature
    float valid_temp_sum = 0.0f;
    int valid_temp_count = 0;
    if (!isnan(temp1_c)) { valid_temp_sum += temp1_c; valid_temp_count++; }
    if (!isnan(temp2_c)) { valid_temp_sum += temp2_c; valid_temp_count++; }
    if (!isnan(temp3_c)) { valid_temp_sum += temp3_c; valid_temp_count++; }
    float avg_temp_c = (valid_temp_count > 0) ? (valid_temp_sum / valid_temp_count) : 25.0f;

    // ========================================================
    // INA226 CURRENT & POWER
    // ========================================================

    if (!ina226_ready)
    {
        ina226_ready = initINA226();
    }
    else if (!ina.isConnected())
    {
        ina226_ready = false;
    }

    float raw_current_ma = 0.0f;
    float load_current_ma = 0.0f;
    float load_current_a = 0.0f;
    float load_power_w = 0.0f;
    float shunt_mv = 0.0f;
    float bus_v = 0.0f;
    const char *load_status = "DISCONNECTED";

    if (ina226_ready)
    {
        raw_current_ma = ina.getCurrent_mA();
        load_current_ma = fabs(raw_current_ma);
        load_current_a = load_current_ma / 1000.0f;
        load_power_w = fabs(ina.getPower());
        shunt_mv = ina.getShuntVoltage_mV();
        bus_v = ina.getBusVoltage();

        // Integrate load current into capacity (mAh)
        cycle_capacity_mah += load_current_ma * dt_hours;
        total_capacity_mah += load_current_ma * dt_hours;

        if (load_current_ma > 5.0f)
        {
            load_status = "LOAD ACTIVE";
        }
        else
        {
            load_status = "IDLE (NO LOAD)";
        }
    }

    // In NASA dataset, discharge current is convention as negative (-A)
    // If load is active, represent current as negative (or signed if raw_current_ma is signed)
    float current_nasa_a = (load_current_ma > 5.0f) ? -load_current_a : 0.0f;
    float cycle_capacity_ah = cycle_capacity_mah / 1000.0f;
    float t_s = (now - cycle_start_time) / 1000.0f;

    // ========================================================
    // OUTPUT REPORT
    // ========================================================

    if (!logging_active)
    {
        return;
    }

    if (current_output_mode == MODE_CSV)
    {
        // Output CSV matching NASA Dataset structure:
        // battery_id,cycle,t_s,voltage,current,temperature,soc,cell1_v,cell2_v,cell3_v,temp1_c,temp2_c,temp3_c,cycle_capacity_Ah
        Serial.printf("%s,%u,%.2f,%.3f,%.4f,%.2f,%.2f,%.3f,%.3f,%.3f,%.2f,%.2f,%.2f,%.4f\n",
                      battery_id.c_str(),
                      current_cycle,
                      t_s,
                      pack_v,
                      current_nasa_a,
                      avg_temp_c,
                      avg_soc,
                      cell1_v,
                      cell2_v,
                      cell3_v,
                      isnan(temp1_c) ? 0.0f : temp1_c,
                      isnan(temp2_c) ? 0.0f : temp2_c,
                      isnan(temp3_c) ? 0.0f : temp3_c,
                      cycle_capacity_ah);
    }
    else if (current_output_mode == MODE_HUMAN)
    {
        Serial.println(F("==========================================="));
        Serial.printf("Battery ID: %s | Cycle: %u | Time: %.1f s\n", battery_id.c_str(), current_cycle, t_s);
        Serial.printf("Pack Voltage (ADC) : %.3f V\n", pack_v);
        Serial.printf("Avg Pack SoC       : %.1f %%\n", avg_soc);
        Serial.printf("Cell Imbalance     : %.1f mV%s\n",
                      imbalance_mv, (imbalance_mv > 100.0f) ? "  *** IMBALANCE ***" : "");
        Serial.println(F("-------------------------------------------"));
        Serial.printf("Cell temps: C1 %.1f C | C2 %.1f C | C3 %.1f C (Avg: %.1f C)\n",
                      temp1_c, temp2_c, temp3_c, avg_temp_c);
        Serial.printf("Cell 1 (Bot): %.3f V | SoC: %5.1f%% | %s\n", cell1_v, soc1, cellStatus(cell1_v));
        Serial.printf("Cell 2 (Mid): %.3f V | SoC: %5.1f%% | %s\n", cell2_v, soc2, cellStatus(cell2_v));
        Serial.printf("Cell 3 (Top): %.3f V | SoC: %5.1f%% | %s\n", cell3_v, soc3, cellStatus(cell3_v));
        Serial.println(F("-------------------------------------------"));
        if (ina226_ready)
        {
            Serial.printf("Load Current       : %.2f mA (%.3f A) [%s]\n", load_current_ma, load_current_a, load_status);
            Serial.printf("Cycle Cap Consumed : %.4f Ah (%.2f mAh)\n", cycle_capacity_ah, cycle_capacity_mah);
            Serial.printf("Total Load Consumed: %.2f mAh\n", total_capacity_mah);
            Serial.printf("Shunt Voltage      : %+.3f mV | Bus Voltage: %.3f V\n", shunt_mv, bus_v);
        }
        else
        {
            Serial.println(F("Load Current       : [INA226 SENSOR NOT DETECTED]"));
        }
        Serial.println(F("===========================================\n"));
    }
}