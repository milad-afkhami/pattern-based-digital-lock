> **[🇬🇧 English Version](top_level.md)**

# یکپارچه‌سازی سیستم Top Level

**فایل**: `src/top_level.vhd`
**تعداد خطوط**: ۱۵۴
**هدف**: Integration همه component‌ها در یک سیستم کامل آماده برای synthesis

---

## فهرست مطالب

- [مقدمه](#مقدمه)
- [System Block Diagram](#system-block-diagram)
- [Entity Interface](#entity-interface)
- [Architecture](#architecture)
- [Component Connection‌ها](#component-connectionها)
- [راهنمای Configuration](#راهنمای-configuration)
- [FPGA Pin Mapping](#fpga-pin-mapping)
- [مثال‌های استفاده](#مثال‌های-استفاده)

---

## مقدمه

Module `top_level` سیستم قفل دیجیتال مبتنی بر الگوی کامل است. این module connect می‌کند:

1. **چهار Button Debouncer**: پاک‌سازی ورودی‌های raw دکمه
2. **یک FSM Controller**: پردازش دکمه‌های debounce شده و مدیریت lock state
3. **Output Signal‌ها**: ارائه lock status به LED یا سایر indicator‌ها

این module‌ای است که synthesis می‌کنید و روی FPGA deploy می‌نمایید.

<details>
<summary>Top Level Module چیست؟</summary>

در یک hardware design، **top level module** خارجی‌ترین container است که:
- Pin‌هایی دارد که به دنیای بیرون connect می‌شوند (دکمه‌ها، LED‌ها و غیره)
- همه module‌های دیگر را به عنوان sub-component در بر می‌گیرد
- چیزی است که واقعاً synthesis می‌کنید و روی FPGA load می‌نمایید

آن را مانند function «main()» در نرم‌افزار در نظر بگیرید - جایی است که همه چیز گرد هم می‌آید.

</details>

---

## System Block Diagram

![System Block Diagram](../presentation/assets/System-Block-Diagram.png)

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

### Generic Parameter‌ها

| Parameter | نوع | مقدار پیش‌فرض | توضیحات |
|---------|-----|---------------|---------|
| `DEBOUNCE_TIME` | integer | ۱۰ | Clock cycle‌ها برای button debounce |
| `UNLOCK_TIME` | integer | ۵ | Clock cycle‌ها قبل از auto-lock |

### Port‌ها

| Port | جهت | نوع | توضیحات |
|------|-----|-----|---------|
| `clk` | in | std_logic | System clock (مثلاً ۱۰۰ مگاهرتز از FPGA oscillator) |
| `reset` | in | std_logic | System reset، active-high |
| `button_A_raw` | in | std_logic | ورودی raw دکمه A (از physical button) |
| `button_B_raw` | in | std_logic | ورودی raw دکمه B |
| `button_C_raw` | in | std_logic | ورودی raw دکمه C |
| `button_D_raw` | in | std_logic | ورودی raw دکمه D (decoy) |
| `lock_status` | out | std_logic | '1' = unlocked، '0' = locked |
| `led` | out | std_logic | همان lock_status (برای LED indicator) |

<details>
<summary>چرا دو output یکسان (lock_status و led)؟</summary>

داشتن output‌های جداگانه برای همان signal فراهم می‌کند:
- **Clarity**: نام‌های مختلف برای purpose‌های مختلف
- **Flexibility**: می‌توان behavior‌های مختلف بعداً اضافه کرد
- **FPGA Mapping**: ممکن است بخواهید به pin‌های مختلف route کنید

در implementation فعلی، هر دو یکسان هستند: `led <= lock_status`

</details>

---

## Architecture

### Internal Signal‌ها

```vhdl
signal button_A_debounced : std_logic;
signal button_B_debounced : std_logic;
signal button_C_debounced : std_logic;
signal button_D_debounced : std_logic;
signal lock_status_internal : std_logic;
```

| Signal | توضیحات |
|--------|---------|
| `button_X_debounced` | Signal‌های تمیز و single-pulse از debouncer‌ها |
| `lock_status_internal` | Internal lock status (قبل از output buffer) |

### Component Declaration‌ها

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
<summary>Component Declaration چیست؟</summary>

در VHDL، قبل از اینکه بتوانید یک module را استفاده (instantiate) کنید، باید به compiler بگویید که چه شکلی دارد. یک **component declaration** مانند یک forward declaration در C است - می‌گوید «این چیز وجود دارد و این port‌ها را دارد.»

بعداً، component را **instantiate** می‌کنید و یک actual instance از آن ایجاد می‌کنید.

</details>

---

## Component Connection‌ها

### Debouncer Instantiation‌ها

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

### Output Assignment‌ها

```vhdl
lock_status <= lock_status_internal;
led <= lock_status_internal;
```

---

## راهنمای Configuration

### برای Simulation

از مقادیر کوچک برای simulation سریع استفاده کنید:

```vhdl
-- در testbench instantiation
uut: entity work.top_level
    generic map (
        DEBOUNCE_TIME => 5,    -- ۵ clock cycle
        UNLOCK_TIME   => 3     -- ۳ clock cycle
    )
    port map (...);
```

### برای سخت‌افزار واقعی

مقادیر مناسب را بر اساس clock خود محاسبه کنید:

| Clock | Debounce (۲۰ میلی‌ثانیه) | Unlock (۵ ثانیه) |
|------|---------------------------|-------------------|
| ۵۰ مگاهرتز | ۱٬۰۰۰٬۰۰۰ | ۲۵۰٬۰۰۰٬۰۰۰ |
| ۱۰۰ مگاهرتز | ۲٬۰۰۰٬۰۰۰ | ۵۰۰٬۰۰۰٬۰۰۰ |
| ۱۲۵ مگاهرتز | ۲٬۵۰۰٬۰۰۰ | ۶۲۵٬۰۰۰٬۰۰۰ |

<details>
<summary>فرمول‌های محاسبه</summary>

```
DEBOUNCE_TIME = debounce_seconds × clock_frequency
UNLOCK_TIME = unlock_seconds × clock_frequency
```

مثال برای clock ۱۰۰ مگاهرتز:
- Debounce ۲۰ میلی‌ثانیه: ۰.۰۲۰ × ۱۰۰٬۰۰۰٬۰۰۰ = ۲٬۰۰۰٬۰۰۰
- Unlock ۵ ثانیه: ۵.۰ × ۱۰۰٬۰۰۰٬۰۰۰ = ۵۰۰٬۰۰۰٬۰۰۰

</details>

---

## FPGA Pin Mapping

### Xilinx Vivado Constraint‌ها (مثال برای Basys3)

```tcl
# Clock (۱۰۰ مگاهرتز oscillator)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 [get_ports clk]

# Reset (دکمه مرکزی)
set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

# Button‌ها (دکمه‌های سمت راست)
set_property PACKAGE_PIN T18 [get_ports button_A_raw]
set_property PACKAGE_PIN W19 [get_ports button_B_raw]
set_property PACKAGE_PIN T17 [get_ports button_C_raw]
set_property PACKAGE_PIN U17 [get_ports button_D_raw]
set_property IOSTANDARD LVCMOS33 [get_ports button_*_raw]

# LED‌ها
set_property PACKAGE_PIN U16 [get_ports lock_status]
set_property PACKAGE_PIN E19 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports lock_status]
set_property IOSTANDARD LVCMOS33 [get_ports led]
```

<details>
<summary>نحوه ایجاد Constraint File</summary>

1. یک فایل به نام `constraints.xdc` در پوشه `synthesis/` ایجاد کنید
2. Pin mapping‌ها را برای FPGA board خاص خود اضافه کنید
3. در Vivado: Add Sources → Add or create constraints → فایل .xdc را اضافه کنید
4. Synthesis و Implementation را run کنید

هر FPGA board تخصیص pin متفاوتی دارد - مستندات board خود را بررسی کنید!

</details>

### Intel/Altera Quartus Constraint‌ها (مثال)

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

### Synthesis Command (GHDL)

```bash
# بررسی synthesizability
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
        led          => open  -- Unconnected (don't care)
    );
```

<details>
<summary>معنی «open» چیست؟</summary>

در VHDL، `open` به معنی «unconnected» یا «don't care» است. از آن برای output port‌هایی که نیاز به monitor ندارید استفاده کنید.

```vhdl
led => open  -- نیازی به خواندن این output نداریم
```

این فقط برای output port‌ها valid است، هرگز برای input‌ها.

</details>

### ایجاد یک Simulation Wrapper

برای simulation با timing متفاوت:

```vhdl
-- در testbench
constant SIM_DEBOUNCE : integer := 5;   -- سریع برای simulation
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

### چرا Generic Parameter‌ها در Top Level؟

Pass کردن generic parameter‌ها از طریق top level:
- **Single Configuration Point**: تغییر timing در یک مکان
- **تست آسان**: استفاده از مقادیر کوچک برای simulation
- **Deploy آسان**: استفاده از مقادیر realistic برای سخت‌افزار
- **بدون تغییر کد**: همان source برای هر دو کار می‌کند

### چرا lock_status و LED جداگانه؟

Flexibility برای بهبودهای آینده:
- Indicator‌های مختلف برای output‌های مختلف
- Status line به سایر digital system‌ها
- LED می‌تواند blink کند یا pattern‌های مختلف داشته باشد
- Modify آسان بدون تغییر FSM

### چرا از Direct Entity Instantiation استفاده نشد؟

کد از component declaration‌ها برای compatibility استفاده می‌کند:
- با همه VHDL standard‌ها کار می‌کند (۸۷، ۹۳، ۲۰۰۸)
- برخی synthesis tool‌ها این style را prefer می‌کنند
- Explicit component declaration‌ها interface را document می‌کنند

Direct instantiation (`entity work.module`) تمیزتر است اما نیاز به VHDL-93 یا بالاتر دارد.
