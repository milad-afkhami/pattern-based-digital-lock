> **[🇬🇧 English Version](README.md)**

# فایل‌های Testbench (`testbench/`)

این دایرکتوری حاوی testbench‌های VHDL برای verification سیستم قفل دیجیتال است.

---

## فایل‌ها

| فایل | تست‌ها | هدف |
|------|--------|-----|
| [tb_digital_lock.vhd](tb_digital_lock.vhd) | ۶ | Unit test FSM |
| [tb_top_level.vhd](tb_top_level.vhd) | ۱۱ | Integration test کامل سیستم |
| [tb_fsm_coverage.vhd](tb_fsm_coverage.vhd) | ۱۸ | State/transition coverage |
| [tb_edge_cases.vhd](tb_edge_cases.vhd) | ۲۲ | Edge case‌ها |
| [tb_debouncer.vhd](tb_debouncer.vhd) | ۴ | Unit test debouncer |

**مجموع: ۶۱ assertion در ۵ testbench**

---

## شروع سریع

### اجرای همه تست‌ها

```bash
# از دایرکتوری root پروژه
cd /path/to/pattern-based-digital-lock

# ابتدا کامپایل source‌ها
ghdl -a --std=08 src/digital_lock.vhd
ghdl -a --std=08 src/button_debouncer.vhd
ghdl -a --std=08 src/top_level.vhd

# اجرای هر testbench
for tb in tb_digital_lock tb_top_level tb_fsm_coverage tb_edge_cases tb_debouncer; do
    ghdl -a --std=08 testbench/$tb.vhd
    ghdl -e --std=08 $tb
    ghdl -r --std=08 $tb --wave=simulation/$tb.ghw
done
```

### اجرای تست تکی

```bash
ghdl -a --std=08 testbench/tb_digital_lock.vhd
ghdl -e --std=08 tb_digital_lock
ghdl -r --std=08 tb_digital_lock --wave=simulation/tb_digital_lock.ghw
```

---

## توضیحات تست‌ها

### tb_digital_lock.vhd

**Unit test برای FSM controller**

تست منطق اصلی قفل بدون debouncing:
- TC1: عملکرد reset
- TC2: توالی صحیح unlock (A→B→C→A)
- TC3: تشخیص توالی اشتباه (A→B→D)
- TC4: بازیابی از دکمه اول اشتباه
- TC5: Auto-lock timer
- TC6: Reset حین توالی

---

### tb_top_level.vhd

**Integration test برای سیستم کامل**

تست سیستم کامل شامل debouncer‌ها:
- TC1-TC6: عملکرد پایه (مشابه unit test)
- TC7: توالی‌های unlock تکراری
- TC8: نگه داشتن دکمه (تست edge detection)
- TC9: چندین دکمه همزمان
- TC10: فشردن سریع دکمه‌ها
- BONUS: تست دکمه فریب D

---

### tb_fsm_coverage.vhd

**۱۰۰٪ State و Transition Coverage**

تأیید اینکه هر state قابل دسترسی و هر transition کار می‌کند:
- همه ۵ state بازدید شده
- همه transition‌های صحیح تست شده
- همه transition‌های خطا تست شده (دکمه‌های اشتباه)

---

### tb_edge_cases.vhd

**Edge Case‌ها و Stress Test**

تست سناریوهای غیرمعمول:
- Reset حین unlock
- چندین reset متوالی
- مرزهای timing دکمه
- فشردن همزمان دکمه‌ها
- Stress test توالی سریع (۱۰ بار)
- شرایط مرزی timer
- Error recovery

---

### tb_debouncer.vhd

**Unit test برای module debouncer**

تست فیلتر bounce و edge detection:
- فشردن تمیز دکمه
- Simulation دکمه bouncy
- فیلتر فشردن کوتاه
- دکمه نگه داشته شده (single pulse)

---

## خروجی مورد انتظار

### موفقیت

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

### شکست

```
tb_digital_lock.vhd:138:9:@150ns:(assertion error):
    TC2 FAILED: Lock should be UNLOCKED after correct sequence!
```

<details>
<summary>Debugging شکست تست</summary>

1. Timestamp را یادداشت کنید (مثلاً `@150ns`)
2. Waveform را باز کنید: `gtkwave simulation/tb_digital_lock.ghw`
3. به زمان شکست navigate کنید
4. مقادیر signal را بررسی کنید
5. به عقب trace کنید تا root cause را پیدا کنید

</details>

---

## فایل‌های Waveform

پس از اجرای تست‌ها، فایل‌های waveform در `simulation/` ذخیره می‌شوند:

```bash
# مشاهده waveform‌ها
gtkwave simulation/tb_digital_lock.ghw
```

---

## مستندات تفصیلی

[docs/testbenches.md](../docs/testbenches.md) را برای موارد زیر ببینید:
- توضیحات تفصیلی test case‌ها
- نوشتن تست‌های خودتان
- درک خروجی assertion
- الگوها و helper function‌های تست
