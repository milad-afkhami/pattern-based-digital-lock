> **[🇮🇷 نسخه فارسی](README-fa.md)**

# Testbench Files (`testbench/`)

This directory contains VHDL testbenches for verifying the digital lock system.

---

## Files

| File | Tests | Purpose |
|------|-------|---------|
| [tb_digital_lock.vhd](tb_digital_lock.vhd) | 6 | FSM unit testing |
| [tb_top_level.vhd](tb_top_level.vhd) | 11 | Full system integration |
| [tb_fsm_coverage.vhd](tb_fsm_coverage.vhd) | 18 | State/transition coverage |
| [tb_edge_cases.vhd](tb_edge_cases.vhd) | 22 | Boundary conditions |
| [tb_debouncer.vhd](tb_debouncer.vhd) | 4 | Debouncer unit testing |

**Total: 61 assertions across 5 testbenches**

---

## Quick Start

### Run All Tests

```bash
# From project root directory
cd /path/to/pattern-based-digital-lock

# Compile sources first
ghdl -a --std=08 src/digital_lock.vhd
ghdl -a --std=08 src/button_debouncer.vhd
ghdl -a --std=08 src/top_level.vhd

# Run each testbench
for tb in tb_digital_lock tb_top_level tb_fsm_coverage tb_edge_cases tb_debouncer; do
    ghdl -a --std=08 testbench/$tb.vhd
    ghdl -e --std=08 $tb
    ghdl -r --std=08 $tb --wave=simulation/$tb.ghw
done
```

### Run Single Test

```bash
ghdl -a --std=08 testbench/tb_digital_lock.vhd
ghdl -e --std=08 tb_digital_lock
ghdl -r --std=08 tb_digital_lock --wave=simulation/tb_digital_lock.ghw
```

---

## Test Descriptions

### tb_digital_lock.vhd

**Unit test for the FSM controller**

Tests the core lock logic without debouncing:
- TC1: Reset functionality
- TC2: Correct unlock sequence (A→B→C→A)
- TC3: Wrong sequence detection (A→B→D)
- TC4: Recovery from wrong first button
- TC5: Auto-relock timer
- TC6: Reset during sequence

---

### tb_top_level.vhd

**Integration test for complete system**

Tests the full system including debouncers:
- TC1-TC6: Basic functionality (same as unit test)
- TC7: Repeated unlock sequences
- TC8: Button held down (edge detection)
- TC9: Multiple simultaneous buttons
- TC10: Rapid button presses
- BONUS: D button decoy test

---

### tb_fsm_coverage.vhd

**100% state and transition coverage**

Verifies every state is reachable and every transition works:
- All 5 states visited
- All correct transitions tested
- All error transitions tested (wrong buttons)

---

### tb_edge_cases.vhd

**Boundary conditions and stress testing**

Tests unusual scenarios:
- Reset during unlock
- Multiple consecutive resets
- Button timing boundaries
- Simultaneous button presses
- Rapid sequence stress test (10x)
- Timer boundary conditions
- Error recovery

---

### tb_debouncer.vhd

**Unit test for debouncer module**

Tests bounce filtering and edge detection:
- Clean button press
- Bouncy button simulation
- Short press filtering
- Held button (single pulse)

---

## Expected Output

### Success

```
=== Starting Digital Lock Testbench ===
TC1: Testing reset functionality
TC1 PASSED: Reset works correctly
TC2: Testing correct sequence A->B->C->A
TC2 PASSED: Correct sequence unlocks the system
...
=== All Test Cases Completed ===
=== Digital Lock Testbench PASSED ===
```

### Failure

```
tb_digital_lock.vhd:138:9:@150ns:(assertion error):
    TC2 FAILED: Lock should be UNLOCKED after correct sequence!
```

<details>
<summary>Debugging test failures</summary>

1. Note the timestamp (e.g., `@150ns`)
2. Open waveform: `gtkwave simulation/tb_digital_lock.ghw`
3. Navigate to the failure time
4. Examine signal values
5. Trace back to find the root cause

</details>

---

## Waveform Files

After running tests, waveform files are saved to `simulation/`:

```bash
# View waveforms
gtkwave simulation/tb_digital_lock.ghw
```

---

## Detailed Documentation

See [docs/testbenches.md](../docs/testbenches.md) for:
- Detailed test case descriptions
- Writing your own tests
- Understanding assertion output
- Test patterns and helpers
