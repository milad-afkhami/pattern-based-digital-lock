> **[🇬🇧 English Version](digital_lock.md)**

# FSM Controller قفل دیجیتال

**فایل**: `src/digital_lock.vhd`
**تعداد خطوط**: ۱۵۶
**هدف**: FSM controller اصلی برای قفل دیجیتال مبتنی بر الگو

---

## فهرست مطالب

- [مقدمه](#مقدمه)
- [Entity Interface](#entity-interface)
- [Architecture](#architecture)
- [State Machine](#state-machine)
- [Process‌ها](#processها)
- [مثال استفاده](#مثال-استفاده)
- [Timing Diagram](#timing-diagram)
- [تصمیمات طراحی](#تصمیمات-طراحی)

---

## مقدمه

Module `digital_lock` هسته اصلی سیستم قفل مبتنی بر الگو است. این module یک FSM پنج state‌ای implement می‌کند که:

1. ورودی‌های دکمه را برای توالی صحیح unlock (A → B → C → A) بررسی می‌کند
2. با فشردن دکمه‌های صحیح بین state‌ها transition می‌کند
3. با فشردن دکمه اشتباه به state locked برمی‌گردد
4. پس از یک زمان قابل تنظیم به صورت خودکار auto-lock می‌شود

<details>
<summary>Module در VHDL چیست؟</summary>

یک **module** (که در VHDL به آن «entity» گفته می‌شود) مانند یک جعبه سیاه است که دارای:
- **Input‌ها**: signal‌هایی که وارد می‌شوند (دکمه‌ها، clock، reset)
- **Output‌ها**: signal‌هایی که خارج می‌شوند (lock status)
- **منطق داخلی**: نحوه پردازش input‌ها برای تولید output‌ها

Module‌ها می‌توانند مانند قطعات لِگو به یکدیگر متصل شوند تا سیستم‌های پیچیده بسازند.

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

### Generic Parameter‌ها

| Parameter | نوع | مقدار پیش‌فرض | توضیحات |
|---------|-----|---------------|---------|
| `UNLOCK_TIME` | integer | ۵ | Clock cycle‌ها قبل از auto-lock |

<details>
<summary>Generic Parameter چیست؟</summary>

**Generic parameter‌ها** مانند parameter‌های function هستند اما برای hardware module‌ها. آن‌ها امکان configure کردن یک module را بدون تغییر کد فراهم می‌کنند:

```vhdl
-- استفاده از تاخیر کوتاه برای simulation
uut: digital_lock generic map (UNLOCK_TIME => 5)

-- استفاده از تاخیر طولانی برای سخت‌افزار واقعی (۵ ثانیه در ۱۰۰ مگاهرتز)
real_lock: digital_lock generic map (UNLOCK_TIME => 500_000_000)
```

</details>

### Port‌ها

| Port | جهت | نوع | توضیحات |
|------|-----|-----|---------|
| `clk` | in | std_logic | System clock (rising edge triggered) |
| `reset` | in | std_logic | Asynchronous reset، active-high |
| `button_A` | in | std_logic | ورودی دکمه A (single-cycle pulse) |
| `button_B` | in | std_logic | ورودی دکمه B (single-cycle pulse) |
| `button_C` | in | std_logic | ورودی دکمه C (single-cycle pulse) |
| `button_D` | in | std_logic | ورودی دکمه D (decoy، همیشه اشتباه) |
| `lock_status` | out | std_logic | '1' = unlocked، '0' = locked |

<details>
<summary>std_logic چیست؟</summary>

`std_logic` نوع signal استاندارد در VHDL است که یک سیم منفرد را نشان می‌دهد. می‌تواند ۹ مقدار داشته باشد، اما رایج‌ترین‌ها عبارتند از:

- `'0'`: سطح منطقی پایین (ground، false)
- `'1'`: سطح منطقی بالا (voltage، true)
- `'U'`: Uninitialized (فقط simulation)
- `'X'`: Unknown/conflict (فقط simulation)
- `'Z'`: High impedance (tri-state)

</details>

---

## Architecture

### Internal Signal‌ها

```vhdl
type state_type is (STATE_LOCKED, STATE_FIRST, STATE_SECOND,
                    STATE_THIRD, STATE_UNLOCKED);

signal current_state : state_type := STATE_LOCKED;
signal next_state    : state_type;
signal unlock_timer  : integer range 0 to UNLOCK_TIME := 0;
signal timer_expired : std_logic := '0';
```

| Signal | نوع | توضیحات |
|--------|-----|---------|
| `current_state` | state_type | State فعلی FSM |
| `next_state` | state_type | State بعدی FSM (combinational) |
| `unlock_timer` | integer | Countdown counter برای auto-lock |
| `timer_expired` | std_logic | Flag زمانی که timer به UNLOCK_TIME می‌رسد |

<details>
<summary>درک Enumeration Type‌ها</summary>

```vhdl
type state_type is (STATE_LOCKED, STATE_FIRST, STATE_SECOND,
                    STATE_THIRD, STATE_UNLOCKED);
```

این یک custom type با دقیقاً ۵ مقدار ممکن ایجاد می‌کند. مانند enum در زبان‌های دیگر است. Synthesizer این را به صورت خودکار به binary تبدیل می‌کند (معمولاً ۳ بیت برای ۵ state).

</details>

---

## State Machine

### State Diagram

![State Diagram FSM](../presentation/assets/FSM-State-Diagram.png)

### Transition Table

| State فعلی | شرط | State بعدی |
|-----------|-----|-----------|
| STATE_LOCKED | button_A = '1' | STATE_FIRST |
| STATE_LOCKED | هر دکمه دیگر | STATE_LOCKED |
| STATE_FIRST | button_B = '1' | STATE_SECOND |
| STATE_FIRST | button_A/C/D = '1' | STATE_LOCKED |
| STATE_SECOND | button_C = '1' | STATE_THIRD |
| STATE_SECOND | button_A/B/D = '1' | STATE_LOCKED |
| STATE_THIRD | button_A = '1' | STATE_UNLOCKED |
| STATE_THIRD | button_B/C/D = '1' | STATE_LOCKED |
| STATE_UNLOCKED | timer_expired = '1' | STATE_LOCKED |
| STATE_UNLOCKED | not expired | STATE_UNLOCKED |
| هر state | reset = '1' | STATE_LOCKED |

---

## Process‌ها

Architecture از **الگوی Three-process FSM** استاندارد به علاوه یک process اضافی برای timer استفاده می‌کند:

### Process ۱: State Register (Sequential)

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

**هدف**: Update کردن state فعلی در هر clock edge. Handle کردن asynchronous reset.

<details>
<summary>چرا Asynchronous Reset؟</summary>

یک **asynchronous reset** (`if reset = '1' then`) بلافاصله اعمال می‌شود، صرف نظر از clock. این تضمین می‌کند که سیستم می‌تواند حتی اگر clock متوقف یا دچار اشکال شده باشد، reset شود.

یک **synchronous reset** (`if rising_edge(clk) then if reset = '1' then`) فقط روی clock edge‌ها کار می‌کند. ساده‌تر است اما در سخت‌افزار واقعی کمتر reliable است.

</details>

### Process ۲: Next State Logic (Combinational)

```vhdl
next_state_logic: process(current_state, button_A, button_B, button_C, button_D, timer_expired)
begin
    next_state <= current_state;  -- Default: ماندن در state فعلی

    case current_state is
        when STATE_LOCKED =>
            if button_A = '1' then
                next_state <= STATE_FIRST;
            end if;
            -- B، C، D در state LOCKED ignore می‌شوند

        when STATE_FIRST =>
            if button_B = '1' then
                next_state <= STATE_SECOND;
            elsif button_A = '1' or button_C = '1' or button_D = '1' then
                next_state <= STATE_LOCKED;  -- دکمه اشتباه!
            end if;
        -- ... مشابه برای سایر state‌ها
    end case;
end process;
```

**هدف**: تعیین next state بر اساس current state و input‌ها.

<details>
<summary>درک Sensitivity List</summary>

بخش `process(current_state, button_A, ...)` **sensitivity list** است. Process هر زمان که هر signal‌ای در این لیست تغییر کند، مجدداً execute می‌شود.

برای combinational logic (بدون clock)، همه signal‌های خوانده شده در process را شامل کنید. Signal‌های missing باعث simulation/synthesis mismatch می‌شوند.

</details>

### Process ۳: Output Logic (Combinational)

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

**هدف**: تولید output‌ها بر اساس current state (سبک Moore machine).

<details>
<summary>Moore Machine در مقابل Mealy Machine</summary>

- **Moore Machine**: Output‌ها فقط به current state بستگی دارند (در اینجا استفاده شده)
- **Mealy Machine**: Output‌ها به current state و input‌ها بستگی دارند

Moore machine‌ها ساده‌تر هستند و output‌های stable‌تری دارند. قفل از سبک Moore استفاده می‌کند زیرا `lock_status` فقط زمانی تغییر می‌کند که state تغییر کند.

</details>

### Process ۴: Unlock Timer (Sequential)

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

**هدف**: شمارش clock cycle‌ها در state unlocked. اعلام timeout برای auto-lock.

---

## مثال استفاده

### Instantiation پایه

```vhdl
lock_controller: entity work.digital_lock
    generic map (
        UNLOCK_TIME => 5  -- تاخیر کوتاه برای تست
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

### نکات مهم

1. **ورودی‌های دکمه باید debounce شده باشند**: FSM single-cycle pulse‌های تمیز انتظار دارد
2. **ورودی‌ها باید edge-detected باشند**: یک دکمه نگه‌داشته شده باید فقط یک بار register شود
3. **از module button_debouncer استفاده کنید**: این module هم debouncing و هم edge detection را انجام می‌دهد

---

## Timing Diagram

```
clk        ─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─
            └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘

button_A   ─────┐       ┌───────────────────────────┐
                └───────┘                           └───────────────
                   ▲                                    ▲
               Press A                             Press A (نهایی)

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
                                          Unlock      Timeout/Relock
```

---

## تصمیمات طراحی

### چرا الگوی Three-process FSM؟

الگوی ۳ process (register، next state logic، output logic) یک استاندارد صنعتی است زیرا:

1. **جداسازی واضح مسئولیت‌ها**: هر process یک کار دارد
2. **Synthesis قابل پیش‌بینی**: Synthesizer‌ها این الگو را به خوبی درک می‌کنند
3. **Debug آسان**: State و output می‌توانند به طور مستقل trace شوند
4. **قابلیت نگهداری**: اضافه کردن state‌ها یا تغییر transition‌ها آسان است

### چرا Asynchronous Reset؟

Asynchronous reset تضمین می‌کند که سیستم حتی اگر:
- Clock متوقف باشد
- Clock در هنگام power-on ناپایدار باشد
- سیستم نیاز به emergency shutdown داشته باشد

به یک state معلوم برسد.

### چرا Timer Process جداگانه؟

Timer می‌توانست در state register process ادغام شود، اما جداسازی:
- منطق timer را واضح‌تر می‌کند
- تغییر timing behavior را آسان‌تر می‌کند
- Process‌ها را متمرکز بر single responsibility نگه می‌دارد

### چرا دکمه D؟

دکمه D به عنوان یک «decoy» button عمل می‌کند که همیشه سیستم را به state LOCKED برمی‌گرداند. این:
- امنیت را افزایش می‌دهد (attacker باید بداند کدام دکمه‌ها مهم هستند)
- Error handling را در FSM تست می‌کند
- نحوه handle کردن invalid input‌ها را نشان می‌دهد
