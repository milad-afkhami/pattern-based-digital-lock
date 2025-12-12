# Source Files (`src/`)

This directory contains the synthesizable VHDL source files for the pattern-based digital lock.

---

## Files

| File | Lines | Description |
|------|-------|-------------|
| [digital_lock.vhd](digital_lock.vhd) | 156 | Main FSM controller |
| [button_debouncer.vhd](button_debouncer.vhd) | 93 | Button debounce circuit |
| [top_level.vhd](top_level.vhd) | 154 | System integration |

---

## Compilation Order

Files must be compiled in dependency order:

```bash
# 1. Independent modules first
ghdl -a --std=08 digital_lock.vhd
ghdl -a --std=08 button_debouncer.vhd

# 2. Top-level last (depends on both above)
ghdl -a --std=08 top_level.vhd
```

<details>
<summary>Why does order matter?</summary>

VHDL compiles to a "work library." When a file references another component, that component must already exist in the library. If you compile out of order, you'll see errors like:

```
error: cannot find entity work.digital_lock
```

</details>

---

## Module Hierarchy

```
top_level
├── button_debouncer (×4 instances)
│   └── Filters button bounce, provides clean pulses
└── digital_lock (×1 instance)
    └── FSM controller, manages lock state
```

---

## Quick Reference

### digital_lock.vhd

**Purpose**: 5-state FSM implementing the unlock sequence logic

**Ports**:
- `clk`, `reset` - Clock and reset
- `button_A/B/C/D` - Debounced button inputs
- `lock_status` - Output ('1' = unlocked)

**Generic**: `UNLOCK_TIME` - Auto-relock delay in clock cycles

---

### button_debouncer.vhd

**Purpose**: Filters mechanical bounce, outputs single-cycle pulses

**Ports**:
- `clk`, `reset` - Clock and reset
- `button_in` - Raw button input
- `button_out` - Clean, edge-detected output

**Generic**: `DEBOUNCE_TIME` - Stability period in clock cycles

---

### top_level.vhd

**Purpose**: Complete system ready for synthesis

**Ports**:
- `clk`, `reset` - System clock and reset
- `button_A/B/C/D_raw` - Raw button inputs
- `lock_status`, `led` - Output indicators

**Generics**: `DEBOUNCE_TIME`, `UNLOCK_TIME`

---

## Detailed Documentation

See the [docs/](../docs/) directory for comprehensive documentation:

- [digital_lock.md](../docs/digital_lock.md) - FSM architecture and design
- [button_debouncer.md](../docs/button_debouncer.md) - Debouncer operation
- [top_level.md](../docs/top_level.md) - System integration guide

---

## Design Standards

All source files follow these conventions:

- **VHDL-2008** standard (`--std=08`)
- **IEEE std_logic_1164** for logic types
- **3-process FSM pattern** for state machines
- **Generic parameters** for configurable timing
- **Synchronous design** with asynchronous reset
- **Fully synthesizable** - no simulation-only constructs
