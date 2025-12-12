> **[🇮🇷 نسخه فارسی](digital_lock-fa.md)**

# Digital Lock FSM Controller

**File**: `src/digital_lock.vhd`
**Lines**: 156
**Purpose**: Main Finite State Machine controller for the pattern-based digital lock

---

## Table of Contents

- [Overview](#overview)
- [Entity Interface](#entity-interface)
- [Architecture](#architecture)
- [State Machine](#state-machine)
- [Processes](#processes)
- [Usage Example](#usage-example)
- [Timing Diagram](#timing-diagram)
- [Design Decisions](#design-decisions)

---

## Overview

The `digital_lock` module is the core of the pattern-based lock system. It implements a 5-state FSM that:

1. Monitors button inputs for the correct unlock sequence (A → B → C → A)
2. Transitions through states as correct buttons are pressed
3. Returns to LOCKED state on wrong button presses
4. Automatically re-locks after a configurable timeout

<details>
<summary>What is a module in VHDL?</summary>

A **module** (called an "entity" in VHDL) is like a black box with:
- **Inputs**: Signals going in (buttons, clock, reset)
- **Outputs**: Signals coming out (lock_status)
- **Internal logic**: How inputs are processed to generate outputs

Modules can be connected together like LEGO blocks to build complex systems.

</details>

---

## Entity Interface

```vhdl
entity digital_lock is
    Generic (
        UNLOCK_TIME : integer := 5
    );
    Port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        button_A     : in  std_logic;
        button_B     : in  std_logic;
        button_C     : in  std_logic;
        button_D     : in  std_logic;
        lock_status  : out std_logic
    );
end digital_lock;
```

### Generic Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `UNLOCK_TIME` | integer | 5 | Clock cycles before auto-relock |

<details>
<summary>What are generics?</summary>

**Generics** are like function parameters but for hardware modules. They let you configure a module without changing its code:

```vhdl
-- Use short timeout for simulation
uut: digital_lock generic map (UNLOCK_TIME => 5)

-- Use long timeout for real hardware (5 seconds at 100MHz)
real_lock: digital_lock generic map (UNLOCK_TIME => 500_000_000)
```

</details>

### Ports

| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk` | in | std_logic | System clock (rising-edge triggered) |
| `reset` | in | std_logic | Asynchronous reset, active-high |
| `button_A` | in | std_logic | Button A input (single-cycle pulse) |
| `button_B` | in | std_logic | Button B input (single-cycle pulse) |
| `button_C` | in | std_logic | Button C input (single-cycle pulse) |
| `button_D` | in | std_logic | Button D input (decoy, always wrong) |
| `lock_status` | out | std_logic | '1' = unlocked, '0' = locked |

<details>
<summary>What is std_logic?</summary>

`std_logic` is the standard signal type in VHDL representing a single wire. It can have 9 values, but the most common are:

- `'0'`: Logic low (ground, false)
- `'1'`: Logic high (voltage, true)
- `'U'`: Uninitialized (simulation only)
- `'X'`: Unknown/conflict (simulation only)
- `'Z'`: High impedance (tri-state)

</details>

---

## Architecture

### Internal Signals

```vhdl
type state_type is (STATE_LOCKED, STATE_FIRST, STATE_SECOND,
                    STATE_THIRD, STATE_UNLOCKED);

signal current_state : state_type := STATE_LOCKED;
signal next_state    : state_type;
signal unlock_timer  : integer range 0 to UNLOCK_TIME := 0;
signal timer_expired : std_logic := '0';
```

| Signal | Type | Description |
|--------|------|-------------|
| `current_state` | state_type | Current FSM state |
| `next_state` | state_type | Next FSM state (combinational) |
| `unlock_timer` | integer | Countdown for auto-relock |
| `timer_expired` | std_logic | Flag when timer reaches UNLOCK_TIME |

<details>
<summary>Understanding enumerated types</summary>

```vhdl
type state_type is (STATE_LOCKED, STATE_FIRST, STATE_SECOND,
                    STATE_THIRD, STATE_UNLOCKED);
```

This creates a custom type with exactly 5 possible values. It's like an enum in other languages. The synthesizer converts this to binary automatically (usually 3 bits for 5 states).

</details>

---

## State Machine

### State Diagram

![FSM State Diagram](../presentation/assets/FSM-State-Diagram.png)

### Transition Table

| Current State | Condition | Next State |
|---------------|-----------|------------|
| STATE_LOCKED | button_A = '1' | STATE_FIRST |
| STATE_LOCKED | any other | STATE_LOCKED |
| STATE_FIRST | button_B = '1' | STATE_SECOND |
| STATE_FIRST | button_A/C/D = '1' | STATE_LOCKED |
| STATE_SECOND | button_C = '1' | STATE_THIRD |
| STATE_SECOND | button_A/B/D = '1' | STATE_LOCKED |
| STATE_THIRD | button_A = '1' | STATE_UNLOCKED |
| STATE_THIRD | button_B/C/D = '1' | STATE_LOCKED |
| STATE_UNLOCKED | timer_expired = '1' | STATE_LOCKED |
| STATE_UNLOCKED | not expired | STATE_UNLOCKED |
| ANY STATE | reset = '1' | STATE_LOCKED |

---

## Processes

The architecture uses a standard **3-process FSM pattern** plus one additional process for the timer:

### Process 1: State Register (Sequential)

```vhdl
state_register: process(clk, reset)
begin
    if reset = '1' then
        current_state <= STATE_LOCKED;
    elsif rising_edge(clk) then
        current_state <= next_state;
    end if;
end process;
```

**Purpose**: Updates the current state on each clock edge. Handles asynchronous reset.

<details>
<summary>Why asynchronous reset?</summary>

An **asynchronous reset** (`if reset = '1' then`) takes effect immediately, regardless of the clock. This ensures the system can be reset even if the clock is stopped or malfunctioning.

A **synchronous reset** (`if rising_edge(clk) then if reset = '1' then`) only works on clock edges. It's simpler but less reliable in real hardware.

</details>

### Process 2: Next State Logic (Combinational)

```vhdl
next_state_logic: process(current_state, button_A, button_B, button_C, button_D, timer_expired)
begin
    next_state <= current_state;  -- Default: stay in current state

    case current_state is
        when STATE_LOCKED =>
            if button_A = '1' then
                next_state <= STATE_FIRST;
            end if;
            -- B, C, D are ignored in LOCKED state

        when STATE_FIRST =>
            if button_B = '1' then
                next_state <= STATE_SECOND;
            elsif button_A = '1' or button_C = '1' or button_D = '1' then
                next_state <= STATE_LOCKED;  -- Wrong button!
            end if;
        -- ... similar for other states
    end case;
end process;
```

**Purpose**: Determines what the next state should be based on current state and inputs.

<details>
<summary>Understanding sensitivity lists</summary>

The `process(current_state, button_A, ...)` part is the **sensitivity list**. The process re-executes whenever any signal in this list changes.

For combinational logic (no clock), include ALL signals read in the process. Missing signals cause simulation/synthesis mismatches.

</details>

### Process 3: Output Logic (Combinational)

```vhdl
output_logic: process(current_state)
begin
    case current_state is
        when STATE_UNLOCKED =>
            lock_status <= '1';  -- Unlocked!
        when others =>
            lock_status <= '0';  -- Locked
    end case;
end process;
```

**Purpose**: Generates outputs based on current state (Moore machine style).

<details>
<summary>Moore vs Mealy machines</summary>

- **Moore machine**: Outputs depend only on current state (used here)
- **Mealy machine**: Outputs depend on current state AND inputs

Moore machines are simpler and have more stable outputs. The lock uses Moore style because `lock_status` only changes when the state changes.

</details>

### Process 4: Unlock Timer (Sequential)

```vhdl
unlock_timer_proc: process(clk, reset)
begin
    if reset = '1' then
        unlock_timer <= 0;
        timer_expired <= '0';
    elsif rising_edge(clk) then
        if current_state = STATE_UNLOCKED then
            if unlock_timer >= UNLOCK_TIME then
                timer_expired <= '1';
            else
                unlock_timer <= unlock_timer + 1;
            end if;
        else
            unlock_timer <= 0;
            timer_expired <= '0';
        end if;
    end if;
end process;
```

**Purpose**: Counts clock cycles when unlocked. Signals timeout for auto-relock.

---

## Usage Example

### Basic Instantiation

```vhdl
lock_controller: entity work.digital_lock
    generic map (
        UNLOCK_TIME => 5  -- Quick timeout for testing
    )
    port map (
        clk         => system_clock,
        reset       => system_reset,
        button_A    => debounced_btn_a,
        button_B    => debounced_btn_b,
        button_C    => debounced_btn_c,
        button_D    => debounced_btn_d,
        lock_status => led_output
    );
```

### Important Notes

1. **Button inputs must be debounced**: The FSM expects clean, single-cycle pulses
2. **Inputs must be edge-detected**: A held button should only register once
3. **Use the button_debouncer module**: It handles both debouncing and edge detection

---

## Timing Diagram

```
clk        ─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─
            └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘

button_A   ─────┐       ┌───────────────────────────┐
                └───────┘                           └───────────────
                   ▲                                    ▲
                Press A                              Press A (final)

button_B   ─────────────┐
                        └───────────────────────────────────────────
                           ▲
                        Press B

button_C   ─────────────────────┐
                                └───────────────────────────────────
                                   ▲
                                Press C

state      ═LOCKED═╪═FIRST═╪═SECOND═╪═THIRD═╪═══════UNLOCKED═══════╪═LOCKED═

lock_status ─────────────────────────────────┐           ┌──────────
                                             └───────────┘
                                             ▲           ▲
                                          Unlock    Timeout/Relock
```

---

## Design Decisions

### Why 3-Process FSM Pattern?

The 3-process pattern (register, next-state logic, output logic) is an industry standard because:

1. **Clear separation of concerns**: Each process has one job
2. **Predictable synthesis**: Synthesizers understand this pattern well
3. **Easy debugging**: State and output can be traced independently
4. **Maintainability**: Easy to add states or modify transitions

### Why Asynchronous Reset?

Asynchronous reset ensures the system reaches a known state even if:
- The clock is stopped
- The clock is unstable at power-up
- The system needs emergency shutdown

### Why Separate Timer Process?

The timer could be integrated into the state register process, but separation:
- Makes the timer logic clearer
- Allows easier modification of timing behavior
- Keeps processes focused on single responsibilities

### Why Button D?

Button D serves as a "decoy" button that always returns the system to LOCKED state. This:
- Increases security (attacker must know which buttons matter)
- Tests error handling in the FSM
- Demonstrates handling of invalid inputs
