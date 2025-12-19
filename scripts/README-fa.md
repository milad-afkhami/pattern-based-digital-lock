> **[🇬🇧 English Version](README.md)**

# Script‌ها (`scripts/`)

Shell script‌ها برای build، test و مدیریت پروژه قفل دیجیتال.

---

## مرجع سریع

| Script | هدف | استفاده رایج |
|---------|-----|--------------|
| `install.sh` | نصب GHDL و GTKWave | `./scripts/install.sh` |
| `build.sh` | کامپایل فایل‌های source | `./scripts/build.sh` |
| `test.sh` | اجرای testbench‌ها | `./scripts/test.sh` |
| `synth.sh` | بررسی قابلیت synthesis | `./scripts/synth.sh` |
| `wave.sh` | باز کردن waveform viewer | `./scripts/wave.sh tb_digital_lock` |
| `clean.sh` | حذف فایل‌های generated | `./scripts/clean.sh` |

---

## استفاده تفصیلی

### install.sh

نصب GHDL (simulator) و GTKWave (waveform viewer).

```bash
# تشخیص خودکار سیستم‌عامل و نصب
./scripts/install.sh
```

سیستم‌های پشتیبانی شده:
- Ubuntu/Debian (apt)
- Fedora (dnf)
- Arch Linux (pacman)
- macOS (Homebrew)

---

### build.sh

کامپایل همه فایل‌های source VHDL به ترتیب dependency صحیح.

```bash
# Build معمولی
./scripts/build.sh

# Clean build (ابتدا حذف artifact‌های قدیمی)
./scripts/build.sh --clean
```

---

### test.sh

اجرای یک یا همه testbench‌ها با تولید waveform اختیاری.

```bash
# اجرای همه تست‌ها (با waveform)
./scripts/test.sh

# اجرای همه تست‌ها (سریع‌تر، بدون waveform)
./scripts/test.sh --no-wave

# اجرای testbench خاص
./scripts/test.sh tb_digital_lock
./scripts/test.sh tb_top_level
./scripts/test.sh tb_fsm_coverage
./scripts/test.sh tb_edge_cases
./scripts/test.sh tb_debouncer

# اجرای testbench خاص بدون waveform
./scripts/test.sh tb_digital_lock --no-wave
```

---

### synth.sh

تأیید اینکه design می‌تواند برای FPGA synthesis شود.

```bash
./scripts/synth.sh
```

این همه component‌ها را قبل از صرف وقت در vendor tool‌ها برای مشکلات synthesizability بررسی می‌کند.

---

### wave.sh

باز کردن GTKWave برای مشاهده waveform‌های simulation.

```bash
# مشاهده پیش‌فرض (tb_digital_lock)
./scripts/wave.sh

# مشاهده testbench خاص
./scripts/wave.sh tb_top_level
./scripts/wave.sh tb_fsm_coverage
```

توجه: ابتدا `test.sh` را برای تولید فایل‌های waveform اجرا کنید.

---

### clean.sh

حذف فایل‌های generated.

```bash
# حذف build artifact‌ها (نگه داشتن waveform‌ها)
./scripts/clean.sh

# حذف همه چیز شامل waveform‌ها
./scripts/clean.sh --all
```

---

## Workflow معمول

```bash
# 1. راه‌اندازی بار اول
./scripts/install.sh

# 2. Build پروژه
./scripts/build.sh

# 3. اجرای همه تست‌ها
./scripts/test.sh

# 4. مشاهده waveform‌ها در صورت نیاز به debugging
./scripts/wave.sh tb_digital_lock

# 5. بررسی قابلیت synthesis قبل از کار FPGA
./scripts/synth.sh

# 6. پاک‌سازی پس از اتمام
./scripts/clean.sh
```

---

## Exit Code‌ها

همه script‌ها از exit code‌های استاندارد استفاده می‌کنند:
- `0` - موفقیت
- `1` - خطا (dependency گمشده، شکست تست و غیره)

این آنها را مناسب CI/CD pipeline‌ها می‌کند:

```bash
./scripts/test.sh || echo "Tests failed!"
```

---

## اجرایی کردن Script‌ها

اگر خطای "permission denied" دریافت کردید:

```bash
chmod +x scripts/*.sh
```

یا مستقیماً با bash اجرا کنید:

```bash
bash scripts/test.sh
```
