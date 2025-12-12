> **[🇬🇧 English Version](README.md)**

# فایل‌های سنتز (`synthesis/`)

این دایرکتوری برای خروجی‌های سنتز هنگام هدف‌گذاری FPGA است.

---

## هدف

هنگام سنتز طراحی برای سخت‌افزار واقعی، فایل‌های خروجی اینجا قرار می‌گیرند:
- فایل‌های محدودیت (`.xdc`، `.qsf`)
- Netlists
- Bitstreams
- گزارش‌ها

---

## شروع سریع: بررسی قابلیت سنتز

```bash
# تأیید اینکه طراحی قابل سنتز است
ghdl --synth --std=08 -e top_level
```

اگر این بدون خطا کامل شود، طراحی قابل سنتز است.

<details>
<summary>سنتز چیست؟</summary>

**سنتز** کد VHDL را به سخت‌افزار واقعی تبدیل می‌کند:

1. **تحلیل**: تجزیه کد VHDL
2. **توسعه**: گسترش generics، اتصال کامپوننت‌ها
3. **سنتز**: نگاشت به گیت‌های منطقی (LUT، فلیپ‌فلاپ)
4. **Place & Route**: تخصیص به منابع فیزیکی FPGA
5. **تولید Bitstream**: ایجاد فایل برای برنامه‌ریزی FPGA

`--synth` GHDL مراحل ۱-۳ را بررسی می‌کند. سنتز کامل نیاز به ابزارهای تولیدکننده مانند Vivado یا Quartus دارد.

</details>

---

## ابزارهای تولیدکنندگان FPGA

### Xilinx Vivado (پیشنهادی برای FPGAهای Xilinx)

1. پروژه جدید ایجاد کنید
2. فایل‌های منبع از `src/` را اضافه کنید
3. `top_level` را به عنوان ماژول بالا تنظیم کنید
4. فایل محدودیت اضافه کنید (به زیر مراجعه کنید)
5. Synthesis → Implementation → Generate Bitstream را اجرا کنید

### Intel Quartus (برای FPGAهای Intel/Altera)

1. پروژه جدید ایجاد کنید
2. فایل‌های منبع از `src/` را اضافه کنید
3. `top_level` را به عنوان entity بالا تنظیم کنید
4. محدودیت‌ها (فایل `.qsf`) را اضافه کنید
5. Compile را اجرا کنید

---

## فایل‌های محدودیت

### Xilinx (فرمت .xdc)

فایل `constraints.xdc` ایجاد کنید:

```tcl
# کلاک (100 مگاهرتز)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 [get_ports clk]

# دکمه ریست
set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

# دکمه A
set_property PACKAGE_PIN T18 [get_ports button_A_raw]
set_property IOSTANDARD LVCMOS33 [get_ports button_A_raw]

# دکمه B
set_property PACKAGE_PIN W19 [get_ports button_B_raw]
set_property IOSTANDARD LVCMOS33 [get_ports button_B_raw]

# دکمه C
set_property PACKAGE_PIN T17 [get_ports button_C_raw]
set_property IOSTANDARD LVCMOS33 [get_ports button_C_raw]

# دکمه D
set_property PACKAGE_PIN U17 [get_ports button_D_raw]
set_property IOSTANDARD LVCMOS33 [get_ports button_D_raw]

# LED وضعیت قفل
set_property PACKAGE_PIN U16 [get_ports lock_status]
set_property IOSTANDARD LVCMOS33 [get_ports lock_status]

# خروجی LED
set_property PACKAGE_PIN E19 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports led]
```

<details>
<summary>چگونه تخصیص پین‌ها را برای برد خود پیدا کنید</summary>

هر برد FPGA نگاشت پین متفاوتی دارد. پیدا کنید:

1. مستندات/شماتیک برد را بررسی کنید
2. فایل "Master XDC" یا "Pin Constraints" را جستجو کنید
3. "[نام برد] xdc file" را جستجو کنید

بردهای رایج:
- Basys 3: [مرجع Digilent](https://digilent.com/reference/programmable-logic/basys-3/start)
- Nexys A7: [مرجع Digilent](https://digilent.com/reference/programmable-logic/nexys-a7/start)
- DE10-Lite: [منابع Terasic](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=1021)

</details>

### Intel Quartus (فرمت .qsf)

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

## پیکربندی برای سخت‌افزار واقعی

قبل از سنتز، generics `top_level.vhd` را به‌روز کنید:

```vhdl
-- برای کلاک 100 مگاهرتز:
DEBOUNCE_TIME => 2_000_000,  -- debounce 20 میلی‌ثانیه
UNLOCK_TIME   => 500_000_000 -- باز بودن 5 ثانیه
```

<details>
<summary>محاسبات زمان‌بندی</summary>

فرمول: `سیکل = ثانیه × فرکانس`

**کلاک 100 مگاهرتز** (پریود 10 نانوثانیه):
- debounce 20 میلی‌ثانیه: 0.020 × 100,000,000 = 2,000,000
- باز بودن 5 ثانیه: 5.0 × 100,000,000 = 500,000,000

**کلاک 50 مگاهرتز** (پریود 20 نانوثانیه):
- debounce 20 میلی‌ثانیه: 0.020 × 50,000,000 = 1,000,000
- باز بودن 5 ثانیه: 5.0 × 50,000,000 = 250,000,000

</details>

---

## منابع مورد انتظار

تخمین استفاده از منابع (متفاوت بر اساس FPGA):

| منبع | استفاده |
|------|---------|
| LUT | ~50-100 |
| فلیپ‌فلاپ | ~30-50 |
| فرکانس کلاک | >200 مگاهرتز |

این یک طراحی بسیار کوچک است - روی هر FPGA جا می‌شود.

---

## فایل‌های خروجی

پس از سنتز، خواهید داشت:

| نوع فایل | توضیحات |
|----------|---------|
| `.bit` (Xilinx) | Bitstream برای برنامه‌ریزی FPGA |
| `.sof` (Intel) | فایل SRAM Object |
| `.rpt` | گزارش‌های منابع/زمان‌بندی |
| `.dcp` | نقطه بازرسی طراحی |

---

## عیب‌یابی

### "Cannot find entity"

فایل‌های منبع را قبل از سنتز کامپایل کنید:
```bash
ghdl -a --std=08 src/digital_lock.vhd
ghdl -a --std=08 src/button_debouncer.vhd
ghdl -a --std=08 src/top_level.vhd
```

### "Timing not met"

طراحی ساده است و باید به راحتی زمان‌بندی را رعایت کند. اگر نه:
- محدودیت کلاک را بررسی کنید
- مطمئن شوید پریود کلاک با اسیلاتور FPGA شما مطابقت دارد

### "Pin not found"

تخصیص پین‌ها مختص برد است. مستندات برد خود را برای شماره پین‌های صحیح بررسی کنید.
