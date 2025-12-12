# Top-Level System Integration

**File**: `src/top_level.vhd`
**Lines**: 154
**Purpose**: Integrates all components into a complete, ready-to-synthesize system

---

## Table of Contents

- [Overview](#overview)
- [System Block Diagram](#system-block-diagram)
- [Entity Interface](#entity-interface)
- [Architecture](#architecture)
- [Component Connections](#component-connections)
- [Configuration Guide](#configuration-guide)
- [FPGA Pin Mapping](#fpga-pin-mapping)
- [Usage Examples](#usage-examples)

---

## Overview

The `top_level` module is the complete pattern-based digital lock system. It connects:

1. **Four button debouncers**: Clean up raw button inputs
2. **One FSM controller**: Process the debounced buttons and manage lock state
3. **Output signals**: Provide lock status to LEDs or other indicators

This is the module you synthesize and deploy to an FPGA.

<details>
<summary>What is a top-level module?</summary>

In a hardware design, the **top-level module** is the outermost container that:
- Has pins that connect to the outside world (buttons, LEDs, etc.)
- Contains all other modules as subcomponents
- Is what you actually synthesize and load onto the FPGA

Think of it like the "main()" function in software - it's where everything comes together.

</details>

---

## System Block Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              TOP_LEVEL                                       │
│                                                                              │
│  ┌─────────────┐    ┌─────────────────┐                                     │
│  │  button_A   │───▶│   Debouncer A   │──┐                                  │
│  │   (raw)     │    └─────────────────┘  │                                  │
│  └─────────────┘                         │                                  │
│                                          │    ┌─────────────────────────┐   │
│  ┌─────────────┐    ┌─────────────────┐  │    │                         │   │
│  │  button_B   │───▶│   Debouncer B   │──┼───▶│                         │   │
│  │   (raw)     │    └─────────────────┘  │    │                         │   │
│  └─────────────┘                         │    │     digital_lock        │   │  ┌─────────────┐
│                                          │    │        (FSM)            │───┼─▶│ lock_status │
│  ┌─────────────┐    ┌─────────────────┐  │    │                         │   │  │   (LED)     │
│  │  button_C   │───▶│   Debouncer C   │──┼───▶│                         │   │  └─────────────┘
│  │   (raw)     │    └─────────────────┘  │    │                         │   │
│  └─────────────┘                         │    └─────────────────────────┘   │
│                                          │              ▲                   │
│  ┌─────────────┐    ┌─────────────────┐  │              │                   │
│  │  button_D   │───▶│   Debouncer D   │──┘              │                   │
│  │   (raw)     │    └─────────────────┘                 │                   │
│  └─────────────┘                                        │                   │
│                                                         │                   │
│  ┌─────────────┐                                        │                   │
│  │    clk      │────────────────────────────────────────┤                   │
│  └─────────────┘                                        │                   │
│                                                         │                   │
│  ┌─────────────┐                                        │                   │
│  │   reset     │────────────────────────────────────────┘                   │
│  └─────────────┘                                                            │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Entity Interface

```vhdl
entity top_level is
    Generic (
        DEBOUNCE_TIME : integer := 10;
        UNLOCK_TIME   : integer := 5
    );
    Port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        button_A_raw : in  std_logic;
        button_B_raw : in  std_logic;
        button_C_raw : in  std_logic;
        button_D_raw : in  std_logic;
        lock_status  : out std_logic;
        led          : out std_logic
    );
end top_level;
```

### Generic Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `DEBOUNCE_TIME` | integer | 10 | Clock cycles for button debouncing |
| `UNLOCK_TIME` | integer | 5 | Clock cycles before auto-relock |

### Ports

| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk` | in | std_logic | System clock (e.g., 100 MHz from FPGA oscillator) |
| `reset` | in | std_logic | System reset, active-high |
| `button_A_raw` | in | std_logic | Raw button A input (from physical button) |
| `button_B_raw` | in | std_logic | Raw button B input |
| `button_C_raw` | in | std_logic | Raw button C input |
| `button_D_raw` | in | std_logic | Raw button D input (decoy) |
| `lock_status` | out | std_logic | '1' = unlocked, '0' = locked |
| `led` | out | std_logic | Same as lock_status (for LED indicator) |

<details>
<summary>Why two identical outputs (lock_status and led)?</summary>

Having separate outputs for the same signal provides:
- **Clarity**: Different names for different purposes
- **Flexibility**: Can add different behaviors later
- **FPGA mapping**: May want to route to different pins

In the current implementation, both are identical: `led <= lock_status`

</details>

---

## Architecture

### Internal Signals

```vhdl
signal button_A_debounced : std_logic;
signal button_B_debounced : std_logic;
signal button_C_debounced : std_logic;
signal button_D_debounced : std_logic;
signal lock_status_internal : std_logic;
```

| Signal | Description |
|--------|-------------|
| `button_X_debounced` | Clean, single-pulse signals from debouncers |
| `lock_status_internal` | Internal lock status (before output buffering) |

### Component Declarations

```vhdl
component button_debouncer
    Generic (DEBOUNCE_TIME : integer := 10);
    Port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        button_in  : in  std_logic;
        button_out : out std_logic
    );
end component;

component digital_lock
    Generic (UNLOCK_TIME : integer := 5);
    Port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        button_A     : in  std_logic;
        button_B     : in  std_logic;
        button_C     : in  std_logic;
        button_D     : in  std_logic;
        lock_status  : out std_logic
    );
end component;
```

<details>
<summary>What are component declarations?</summary>

In VHDL, before you can use (instantiate) a module, you need to tell the compiler what it looks like. A **component declaration** is like a forward declaration in C - it says "this thing exists and has these ports."

Later, you **instantiate** the component, creating an actual instance of it.

</details>

---

## Component Connections

### Debouncer Instantiations

```vhdl
debounce_A: button_debouncer
    generic map (DEBOUNCE_TIME => DEBOUNCE_TIME)
    port map (
        clk        => clk,
        reset      => reset,
        button_in  => button_A_raw,
        button_out => button_A_debounced
    );

-- Similar for B, C, D...
```

**Data Flow**:
```
button_A_raw (noisy) → Debouncer A → button_A_debounced (clean pulse)
```

### FSM Controller Instantiation

```vhdl
lock_fsm: digital_lock
    generic map (UNLOCK_TIME => UNLOCK_TIME)
    port map (
        clk          => clk,
        reset        => reset,
        button_A     => button_A_debounced,
        button_B     => button_B_debounced,
        button_C     => button_C_debounced,
        button_D     => button_D_debounced,
        lock_status  => lock_status_internal
    );
```

### Output Assignments

```vhdl
lock_status <= lock_status_internal;
led <= lock_status_internal;
```

---

## Configuration Guide

### For Simulation

Use small values for fast simulation:

```vhdl
-- In testbench instantiation
uut: entity work.top_level
    generic map (
        DEBOUNCE_TIME => 5,    -- 5 clock cycles
        UNLOCK_TIME   => 3     -- 3 clock cycles
    )
    port map (...);
```

### For Real Hardware

Calculate proper values based on your clock:

| Clock | Debounce (20ms) | Unlock (5s) |
|-------|-----------------|-------------|
| 50 MHz | 1,000,000 | 250,000,000 |
| 100 MHz | 2,000,000 | 500,000,000 |
| 125 MHz | 2,500,000 | 625,000,000 |

<details>
<summary>Calculation formulas</summary>

```
DEBOUNCE_TIME = debounce_seconds × clock_frequency
UNLOCK_TIME = unlock_seconds × clock_frequency
```

Example for 100 MHz clock:
- 20ms debounce: 0.020 × 100,000,000 = 2,000,000
- 5 second unlock: 5.0 × 100,000,000 = 500,000,000

</details>

---

## FPGA Pin Mapping

### Xilinx Vivado Constraints (Example for Basys3)

```tcl
# Clock (100 MHz oscillator)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 [get_ports clk]

# Reset (center button)
set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

# Buttons (right-side buttons)
set_property PACKAGE_PIN T18 [get_ports button_A_raw]
set_property PACKAGE_PIN W19 [get_ports button_B_raw]
set_property PACKAGE_PIN T17 [get_ports button_C_raw]
set_property PACKAGE_PIN U17 [get_ports button_D_raw]
set_property IOSTANDARD LVCMOS33 [get_ports button_*_raw]

# LEDs
set_property PACKAGE_PIN U16 [get_ports lock_status]
set_property PACKAGE_PIN E19 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports lock_status]
set_property IOSTANDARD LVCMOS33 [get_ports led]
```

<details>
<summary>How to create constraints file</summary>

1. Create a file named `constraints.xdc` in the `synthesis/` folder
2. Add the pin mappings for your specific FPGA board
3. In Vivado: Add Sources → Add or create constraints → Add the .xdc file
4. Run synthesis and implementation

Each FPGA board has different pin assignments - check your board's documentation!

</details>

### Intel/Altera Quartus Constraints (Example)

```tcl
# In a .qsf file
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

## Usage Examples

### Synthesis Command (GHDL)

```bash
# Check synthesizability
ghdl --synth --std=08 top_level
```

### Testbench Instantiation

```vhdl
uut: entity work.top_level
    generic map (
        DEBOUNCE_TIME => 5,
        UNLOCK_TIME   => 3
    )
    port map (
        clk          => clk,
        reset        => reset,
        button_A_raw => test_button_A,
        button_B_raw => test_button_B,
        button_C_raw => test_button_C,
        button_D_raw => test_button_D,
        lock_status  => test_lock_status,
        led          => open  -- Not connected (don't care)
    );
```

<details>
<summary>What does "open" mean?</summary>

In VHDL, `open` means "not connected" or "don't care." Use it for output ports you don't need to monitor.

```vhdl
led => open  -- We don't need to read this output
```

This is only valid for output ports, never inputs.

</details>

### Creating a Simulation Wrapper

For simulation with different timing:

```vhdl
-- In testbench
constant SIM_DEBOUNCE : integer := 5;   -- Quick for simulation
constant SIM_UNLOCK   : integer := 10;  -- Quick timeout

uut: entity work.top_level
    generic map (
        DEBOUNCE_TIME => SIM_DEBOUNCE,
        UNLOCK_TIME   => SIM_UNLOCK
    )
    port map (...);
```

---

## Design Decisions

### Why Generic Parameters at Top Level?

Passing generics through the top level:
- **Single configuration point**: Change timing in one place
- **Easy testing**: Use small values for simulation
- **Easy deployment**: Use realistic values for hardware
- **No code changes**: Same source works for both

### Why Separate Lock Status and LED?

Provides flexibility for future enhancements:
- Different indicators for different outputs
- Status line to other digital systems
- LED could blink or have different patterns
- Easy to modify without changing FSM

### Why Not Use Direct Entity Instantiation?

The code uses component declarations for compatibility:
- Works with all VHDL standards (87, 93, 2008)
- Some synthesis tools prefer this style
- Explicit component declarations document the interface

Direct instantiation (`entity work.module`) is cleaner but requires VHDL-93 or later.
