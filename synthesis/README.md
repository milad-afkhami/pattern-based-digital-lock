> **[🇮🇷 نسخه فارسی](README-fa.md)**

# Synthesis Files (`synthesis/`)

This directory is for synthesis outputs when targeting an FPGA.

---

## Purpose

When you synthesize the design for real hardware, output files go here:
- Constraint files (`.xdc`, `.qsf`)
- Netlists
- Bitstreams
- Reports

---

## Quick Start: Check Synthesizability

```bash
# Verify the design can be synthesized
ghdl --synth --std=08 -e top_level
```

If this completes without errors, the design is synthesizable.

<details>
<summary>What is synthesis?</summary>

**Synthesis** converts VHDL code into actual hardware:

1. **Analysis**: Parse VHDL code
2. **Elaboration**: Expand generics, connect components
3. **Synthesis**: Map to logic gates (LUTs, flip-flops)
4. **Place & Route**: Assign to physical FPGA resources
5. **Bitstream Generation**: Create file to program FPGA

GHDL's `--synth` checks steps 1-3. Full synthesis requires vendor tools like Vivado or Quartus.

</details>

---

## FPGA Vendor Tools

### Xilinx Vivado (Recommended for Xilinx FPGAs)

1. Create new project
2. Add source files from `src/`
3. Set `top_level` as top module
4. Add constraints file (see below)
5. Run Synthesis → Implementation → Generate Bitstream

### Intel Quartus (For Intel/Altera FPGAs)

1. Create new project
2. Add source files from `src/`
3. Set `top_level` as top entity
4. Add constraints (`.qsf` file)
5. Run Compile

---

## Constraint Files

### Xilinx (.xdc format)

Create `constraints.xdc`:

```tcl
# Clock (100 MHz)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 [get_ports clk]

# Reset button
set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

# Button A
set_property PACKAGE_PIN T18 [get_ports button_A_raw]
set_property IOSTANDARD LVCMOS33 [get_ports button_A_raw]

# Button B
set_property PACKAGE_PIN W19 [get_ports button_B_raw]
set_property IOSTANDARD LVCMOS33 [get_ports button_B_raw]

# Button C
set_property PACKAGE_PIN T17 [get_ports button_C_raw]
set_property IOSTANDARD LVCMOS33 [get_ports button_C_raw]

# Button D
set_property PACKAGE_PIN U17 [get_ports button_D_raw]
set_property IOSTANDARD LVCMOS33 [get_ports button_D_raw]

# Lock status LED
set_property PACKAGE_PIN U16 [get_ports lock_status]
set_property IOSTANDARD LVCMOS33 [get_ports lock_status]

# LED output
set_property PACKAGE_PIN E19 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports led]
```

<details>
<summary>How to find pin assignments for your board</summary>

Each FPGA board has different pin mappings. Find yours:

1. Check board documentation/schematic
2. Look for "Master XDC" or "Pin Constraints" file
3. Search for "[board name] xdc file"

Common boards:
- Basys 3: [Digilent Reference](https://digilent.com/reference/programmable-logic/basys-3/start)
- Nexys A7: [Digilent Reference](https://digilent.com/reference/programmable-logic/nexys-a7/start)
- DE10-Lite: [Terasic Resources](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=1021)

</details>

### Intel Quartus (.qsf format)

```tcl
set_location_assignment PIN_R8 -to clk
set_location_assignment PIN_J15 -to reset
set_location_assignment PIN_H21 -to button_A_raw
set_location_assignment PIN_H22 -to button_B_raw
set_location_assignment PIN_G20 -to button_C_raw
set_location_assignment PIN_G21 -to button_D_raw
set_location_assignment PIN_L21 -to lock_status
set_location_assignment PIN_L22 -to led
```

---

## Configuring for Real Hardware

Before synthesis, update `top_level.vhd` generics:

```vhdl
-- For 100 MHz clock:
DEBOUNCE_TIME => 2_000_000,  -- 20ms debounce
UNLOCK_TIME   => 500_000_000 -- 5 second unlock
```

<details>
<summary>Timing calculations</summary>

Formula: `cycles = seconds × frequency`

**100 MHz clock** (10ns period):
- 20ms debounce: 0.020 × 100,000,000 = 2,000,000
- 5s unlock: 5.0 × 100,000,000 = 500,000,000

**50 MHz clock** (20ns period):
- 20ms debounce: 0.020 × 50,000,000 = 1,000,000
- 5s unlock: 5.0 × 50,000,000 = 250,000,000

</details>

---

## Expected Resources

Approximate resource usage (varies by FPGA):

| Resource | Usage |
|----------|-------|
| LUTs | ~50-100 |
| Flip-Flops | ~30-50 |
| Clock Frequency | >200 MHz |

This is a very small design - it will fit on any FPGA.

---

## Output Files

After synthesis, you'll have:

| File Type | Description |
|-----------|-------------|
| `.bit` (Xilinx) | Bitstream to program FPGA |
| `.sof` (Intel) | SRAM Object File |
| `.rpt` | Resource/timing reports |
| `.dcp` | Design checkpoint |

---

## Troubleshooting

### "Cannot find entity"

Compile source files before synthesis:
```bash
ghdl -a --std=08 src/digital_lock.vhd
ghdl -a --std=08 src/button_debouncer.vhd
ghdl -a --std=08 src/top_level.vhd
```

### "Timing not met"

The design is simple and should easily meet timing. If not:
- Check clock constraint is correct
- Ensure clock period matches your FPGA's oscillator

### "Pin not found"

Pin assignments are board-specific. Check your board's documentation for correct pin numbers.
