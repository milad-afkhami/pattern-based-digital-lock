> **[🇬🇧 English Version](top_level.md)**

# یکپارچه‌سازی سیستم سطح بالا

**فایل**: `src/top_level.vhd`
**تعداد خطوط**: ۱۵۴
**هدف**: یکپارچه‌سازی همه اجزا در یک سیستم کامل آماده برای سنتز

---

## فهرست مطالب

- [مقدمه](#مقدمه)
- [نمودار بلوکی سیستم](#نمودار-بلوکی-سیستم)
- [واسط موجودیت](#واسط-موجودیت)
- [معماری](#معماری)
- [اتصالات اجزا](#اتصالات-اجزا)
- [راهنمای پیکربندی](#راهنمای-پیکربندی)
- [نگاشت پایه‌های FPGA](#نگاشت-پایه‌های-fpga)
- [مثال‌های استفاده](#مثال‌های-استفاده)

---

## مقدمه

ماژول `top_level` سیستم قفل دیجیتال مبتنی بر الگوی کامل است. این ماژول متصل می‌کند:

1. **چهار حذف‌کننده نوسان دکمه**: پاک‌سازی ورودی‌های خام دکمه
2. **یک کنترلر ماشین حالت**: پردازش دکمه‌های حذف نوسان شده و مدیریت وضعیت قفل
3. **سیگنال‌های خروجی**: ارائه وضعیت قفل به LED یا سایر نشانگرها

این ماژولی است که سنتز می‌کنید و روی FPGA مستقر می‌نمایید.

<details>
<summary>ماژول سطح بالا چیست؟</summary>

در یک طراحی سخت‌افزاری، **ماژول سطح بالا** خارجی‌ترین ظرف است که:
- پایه‌هایی دارد که به دنیای بیرون متصل می‌شوند (دکمه‌ها، LEDها و غیره)
- همه ماژول‌های دیگر را به عنوان زیرمجموعه در بر می‌گیرد
- چیزی است که واقعاً سنتز می‌کنید و روی FPGA بارگذاری می‌نمایید

آن را مانند تابع «main()» در نرم‌افزار در نظر بگیرید - جایی است که همه چیز گرد هم می‌آید.

</details>

---

## نمودار بلوکی سیستم

```mermaid
flowchart LR
    subgraph ورودی‌ها
        clk[clk]
        reset[reset]
        btnA[button_A_raw]
        btnB[button_B_raw]
        btnC[button_C_raw]
        btnD[button_D_raw]
    end

    subgraph TOP_LEVEL
        subgraph حذف‌کننده‌های_نوسان
            debA[حذف‌کننده A]
            debB[حذف‌کننده B]
            debC[حذف‌کننده C]
            debD[حذف‌کننده D]
        end

        fsm[digital_lock\nکنترلر FSM]
    end

    subgraph خروجی‌ها
        lock[lock_status]
        led[led]
    end

    btnA --> debA
    btnB --> debB
    btnC --> debC
    btnD --> debD

    debA --> fsm
    debB --> fsm
    debC --> fsm
    debD --> fsm

    clk --> debA & debB & debC & debD & fsm
    reset --> debA & debB & debC & debD & fsm

    fsm --> lock
    fsm --> led
```

<details>
<summary>نمودار متنی (در صورت عدم نمایش Mermaid)</summary>

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              TOP_LEVEL                                       │
│                                                                              │
│  ┌─────────────┐    ┌─────────────────┐                                     │
│  │  button_A   │───▶│  حذف‌کننده A    │──┐                                  │
│  │   (خام)     │    └─────────────────┘  │                                  │
│  └─────────────┘                         │                                  │
│                                          │    ┌─────────────────────────┐   │
│  ┌─────────────┐    ┌─────────────────┐  │    │                         │   │
│  │  button_B   │───▶│  حذف‌کننده B    │──┼───▶│                         │   │
│  │   (خام)     │    └─────────────────┘  │    │                         │   │
│  └─────────────┘                         │    │     digital_lock        │   │  ┌─────────────┐
│                                          │    │        (FSM)            │───┼─▶│ lock_status │
│  ┌─────────────┐    ┌─────────────────┐  │    │                         │   │  │   (LED)     │
│  │  button_C   │───▶│  حذف‌کننده C    │──┼───▶│                         │   │  └─────────────┘
│  │   (خام)     │    └─────────────────┘  │    │                         │   │
│  └─────────────┘                         │    └─────────────────────────┘   │
│                                          │              ▲                   │
│  ┌─────────────┐    ┌─────────────────┐  │              │                   │
│  │  button_D   │───▶│  حذف‌کننده D    │──┘              │                   │
│  │   (خام)     │    └─────────────────┘                 │                   │
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

</details>

---

## واسط موجودیت

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

### پارامترهای عمومی

| پارامتر | نوع | مقدار پیش‌فرض | توضیحات |
|---------|-----|---------------|---------|
| `DEBOUNCE_TIME` | integer | ۱۰ | سیکل‌های کلاک برای حذف نوسان دکمه |
| `UNLOCK_TIME` | integer | ۵ | سیکل‌های کلاک قبل از قفل خودکار مجدد |

### پورت‌ها

| پورت | جهت | نوع | توضیحات |
|------|-----|-----|---------|
| `clk` | ورودی | std_logic | کلاک سیستم (مثلاً ۱۰۰ مگاهرتز از نوسان‌ساز FPGA) |
| `reset` | ورودی | std_logic | بازنشانی سیستم، فعال-بالا |
| `button_A_raw` | ورودی | std_logic | ورودی خام دکمه A (از دکمه فیزیکی) |
| `button_B_raw` | ورودی | std_logic | ورودی خام دکمه B |
| `button_C_raw` | ورودی | std_logic | ورودی خام دکمه C |
| `button_D_raw` | ورودی | std_logic | ورودی خام دکمه D (فریب‌دهنده) |
| `lock_status` | خروجی | std_logic | '1' = باز، '0' = قفل |
| `led` | خروجی | std_logic | همان lock_status (برای نشانگر LED) |

<details>
<summary>چرا دو خروجی یکسان (lock_status و led)؟</summary>

داشتن خروجی‌های جداگانه برای همان سیگنال فراهم می‌کند:
- **وضوح**: نام‌های مختلف برای اهداف مختلف
- **انعطاف‌پذیری**: می‌توان رفتارهای مختلف بعداً اضافه کرد
- **نگاشت FPGA**: ممکن است بخواهید به پایه‌های مختلف مسیریابی کنید

در پیاده‌سازی فعلی، هر دو یکسان هستند: `led <= lock_status`

</details>

---

## معماری

### سیگنال‌های داخلی

```vhdl
signal button_A_debounced : std_logic;
signal button_B_debounced : std_logic;
signal button_C_debounced : std_logic;
signal button_D_debounced : std_logic;
signal lock_status_internal : std_logic;
```

| سیگنال | توضیحات |
|--------|---------|
| `button_X_debounced` | سیگنال‌های تمیز و تک‌پالسی از حذف‌کننده‌های نوسان |
| `lock_status_internal` | وضعیت داخلی قفل (قبل از بافر خروجی) |

### اعلان‌های اجزا

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
<summary>اعلان‌های جزء چیست؟</summary>

در VHDL، قبل از اینکه بتوانید یک ماژول را استفاده (نمونه‌سازی) کنید، باید به کامپایلر بگویید که چه شکلی دارد. یک **اعلان جزء** مانند یک اعلان پیشرو در C است - می‌گوید «این چیز وجود دارد و این پورت‌ها را دارد.»

بعداً، جزء را **نمونه‌سازی** می‌کنید و یک نمونه واقعی از آن ایجاد می‌کنید.

</details>

---

## اتصالات اجزا

### نمونه‌سازی‌های حذف‌کننده نوسان

```vhdl
debounce_A: button_debouncer
    generic map (DEBOUNCE_TIME => DEBOUNCE_TIME)
    port map (
        clk        => clk,
        reset      => reset,
        button_in  => button_A_raw,
        button_out => button_A_debounced
    );

-- مشابه برای B، C، D...
```

**جریان داده**:
```
button_A_raw (نویزی) → حذف‌کننده A → button_A_debounced (پالس تمیز)
```

### نمونه‌سازی کنترلر ماشین حالت

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

### تخصیص‌های خروجی

```vhdl
lock_status <= lock_status_internal;
led <= lock_status_internal;
```

---

## راهنمای پیکربندی

### برای شبیه‌سازی

از مقادیر کوچک برای شبیه‌سازی سریع استفاده کنید:

```vhdl
-- در نمونه‌سازی تست‌بنچ
uut: entity work.top_level
    generic map (
        DEBOUNCE_TIME => 5,    -- ۵ سیکل کلاک
        UNLOCK_TIME   => 3     -- ۳ سیکل کلاک
    )
    port map (...);
```

### برای سخت‌افزار واقعی

مقادیر مناسب را بر اساس کلاک خود محاسبه کنید:

| کلاک | حذف نوسان (۲۰ میلی‌ثانیه) | باز کردن (۵ ثانیه) |
|------|---------------------------|-------------------|
| ۵۰ مگاهرتز | ۱٬۰۰۰٬۰۰۰ | ۲۵۰٬۰۰۰٬۰۰۰ |
| ۱۰۰ مگاهرتز | ۲٬۰۰۰٬۰۰۰ | ۵۰۰٬۰۰۰٬۰۰۰ |
| ۱۲۵ مگاهرتز | ۲٬۵۰۰٬۰۰۰ | ۶۲۵٬۰۰۰٬۰۰۰ |

<details>
<summary>فرمول‌های محاسبه</summary>

```
DEBOUNCE_TIME = ثانیه_حذف_نوسان × فرکانس_کلاک
UNLOCK_TIME = ثانیه_باز × فرکانس_کلاک
```

مثال برای کلاک ۱۰۰ مگاهرتز:
- حذف نوسان ۲۰ میلی‌ثانیه: ۰.۰۲۰ × ۱۰۰٬۰۰۰٬۰۰۰ = ۲٬۰۰۰٬۰۰۰
- باز کردن ۵ ثانیه: ۵.۰ × ۱۰۰٬۰۰۰٬۰۰۰ = ۵۰۰٬۰۰۰٬۰۰۰

</details>

---

## نگاشت پایه‌های FPGA

### محدودیت‌های Xilinx Vivado (مثال برای Basys3)

```tcl
# کلاک (نوسان‌ساز ۱۰۰ مگاهرتز)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 [get_ports clk]

# بازنشانی (دکمه مرکزی)
set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

# دکمه‌ها (دکمه‌های سمت راست)
set_property PACKAGE_PIN T18 [get_ports button_A_raw]
set_property PACKAGE_PIN W19 [get_ports button_B_raw]
set_property PACKAGE_PIN T17 [get_ports button_C_raw]
set_property PACKAGE_PIN U17 [get_ports button_D_raw]
set_property IOSTANDARD LVCMOS33 [get_ports button_*_raw]

# LEDها
set_property PACKAGE_PIN U16 [get_ports lock_status]
set_property PACKAGE_PIN E19 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports lock_status]
set_property IOSTANDARD LVCMOS33 [get_ports led]
```

<details>
<summary>نحوه ایجاد فایل محدودیت‌ها</summary>

1. یک فایل به نام `constraints.xdc` در پوشه `synthesis/` ایجاد کنید
2. نگاشت پایه‌ها را برای برد FPGA خاص خود اضافه کنید
3. در Vivado: Add Sources → Add or create constraints → فایل .xdc را اضافه کنید
4. سنتز و پیاده‌سازی را اجرا کنید

هر برد FPGA تخصیص پایه متفاوتی دارد - مستندات برد خود را بررسی کنید!

</details>

### محدودیت‌های Intel/Altera Quartus (مثال)

```tcl
# در یک فایل .qsf
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

## مثال‌های استفاده

### دستور سنتز (GHDL)

```bash
# بررسی قابلیت سنتز
ghdl --synth --std=08 top_level
```

### نمونه‌سازی تست‌بنچ

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
        led          => open  -- متصل نشده (مهم نیست)
    );
```

<details>
<summary>معنی «open» چیست؟</summary>

در VHDL، `open` به معنی «متصل نشده» یا «مهم نیست» است. از آن برای پورت‌های خروجی که نیاز به نظارت ندارید استفاده کنید.

```vhdl
led => open  -- نیازی به خواندن این خروجی نداریم
```

این فقط برای پورت‌های خروجی معتبر است، هرگز برای ورودی‌ها.

</details>

### ایجاد یک پوشش شبیه‌سازی

برای شبیه‌سازی با زمان‌بندی متفاوت:

```vhdl
-- در تست‌بنچ
constant SIM_DEBOUNCE : integer := 5;   -- سریع برای شبیه‌سازی
constant SIM_UNLOCK   : integer := 10;  -- تاخیر سریع

uut: entity work.top_level
    generic map (
        DEBOUNCE_TIME => SIM_DEBOUNCE,
        UNLOCK_TIME   => SIM_UNLOCK
    )
    port map (...);
```

---

## تصمیمات طراحی

### چرا پارامترهای عمومی در سطح بالا؟

ارسال پارامترهای عمومی از طریق سطح بالا:
- **نقطه پیکربندی واحد**: تغییر زمان‌بندی در یک مکان
- **تست آسان**: استفاده از مقادیر کوچک برای شبیه‌سازی
- **استقرار آسان**: استفاده از مقادیر واقع‌گرایانه برای سخت‌افزار
- **بدون تغییر کد**: همان منبع برای هر دو کار می‌کند

### چرا وضعیت قفل و LED جداگانه؟

انعطاف‌پذیری برای بهبودهای آینده:
- نشانگرهای مختلف برای خروجی‌های مختلف
- خط وضعیت به سایر سیستم‌های دیجیتال
- LED می‌تواند چشمک بزند یا الگوهای مختلف داشته باشد
- اصلاح آسان بدون تغییر ماشین حالت

### چرا از نمونه‌سازی مستقیم موجودیت استفاده نشد؟

کد از اعلان‌های جزء برای سازگاری استفاده می‌کند:
- با همه استانداردهای VHDL کار می‌کند (۸۷، ۹۳، ۲۰۰۸)
- برخی ابزارهای سنتز این سبک را ترجیح می‌دهند
- اعلان‌های صریح جزء واسط را مستند می‌کنند

نمونه‌سازی مستقیم (`entity work.module`) تمیزتر است اما نیاز به VHDL-93 یا بالاتر دارد.
