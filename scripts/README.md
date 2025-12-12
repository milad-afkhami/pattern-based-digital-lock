# Scripts (`scripts/`)

Shell scripts for building, testing, and managing the digital lock project.

---

## Quick Reference

| Script | Purpose | Common Usage |
|--------|---------|--------------|
| `install.sh` | Install GHDL and GTKWave | `./scripts/install.sh` |
| `build.sh` | Compile source files | `./scripts/build.sh` |
| `test.sh` | Run testbenches | `./scripts/test.sh` |
| `synth.sh` | Check synthesizability | `./scripts/synth.sh` |
| `wave.sh` | Open waveform viewer | `./scripts/wave.sh tb_digital_lock` |
| `clean.sh` | Remove generated files | `./scripts/clean.sh` |

---

## Detailed Usage

### install.sh

Installs GHDL (simulator) and GTKWave (waveform viewer).

```bash
# Auto-detect OS and install
./scripts/install.sh
```

Supported systems:
- Ubuntu/Debian (apt)
- Fedora (dnf)
- Arch Linux (pacman)
- macOS (Homebrew)

---

### build.sh

Compiles all VHDL source files in the correct dependency order.

```bash
# Normal build
./scripts/build.sh

# Clean build (remove old artifacts first)
./scripts/build.sh --clean
```

---

### test.sh

Runs one or all testbenches with optional waveform generation.

```bash
# Run all tests (with waveforms)
./scripts/test.sh

# Run all tests (faster, no waveforms)
./scripts/test.sh --no-wave

# Run specific testbench
./scripts/test.sh tb_digital_lock
./scripts/test.sh tb_top_level
./scripts/test.sh tb_fsm_coverage
./scripts/test.sh tb_edge_cases
./scripts/test.sh tb_debouncer

# Run specific testbench without waveform
./scripts/test.sh tb_digital_lock --no-wave
```

---

### synth.sh

Verifies the design can be synthesized for FPGA.

```bash
./scripts/synth.sh
```

This checks all components for synthesizability issues before you invest time in vendor tools.

---

### wave.sh

Opens GTKWave to view simulation waveforms.

```bash
# View default (tb_digital_lock)
./scripts/wave.sh

# View specific testbench
./scripts/wave.sh tb_top_level
./scripts/wave.sh tb_fsm_coverage
```

Note: Run `test.sh` first to generate waveform files.

---

### clean.sh

Removes generated files.

```bash
# Remove build artifacts (keep waveforms)
./scripts/clean.sh

# Remove everything including waveforms
./scripts/clean.sh --all
```

---

## Typical Workflow

```bash
# 1. First-time setup
./scripts/install.sh

# 2. Build the project
./scripts/build.sh

# 3. Run all tests
./scripts/test.sh

# 4. View waveforms if debugging needed
./scripts/wave.sh tb_digital_lock

# 5. Check synthesizability before FPGA work
./scripts/synth.sh

# 6. Clean up when done
./scripts/clean.sh
```

---

## Exit Codes

All scripts use standard exit codes:
- `0` - Success
- `1` - Error (missing dependency, test failure, etc.)

This makes them suitable for CI/CD pipelines:

```bash
./scripts/test.sh || echo "Tests failed!"
```

---

## Making Scripts Executable

If you get "permission denied" errors:

```bash
chmod +x scripts/*.sh
```

Or run with bash directly:

```bash
bash scripts/test.sh
```
