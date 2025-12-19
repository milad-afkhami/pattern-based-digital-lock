> **[🇬🇧 English Version](button_debouncer.md)**

# Button Debouncer Module

**فایل**: `src/button_debouncer.vhd`
**تعداد خطوط**: ۹۳
**هدف**: Filter کردن bounce مکانیکی دکمه و ارائه single-cycle output pulse‌های تمیز

---

## فهرست مطالب

- [مقدمه](#مقدمه)
- [مشکل: Button Bounce](#مشکل-button-bounce)
- [Entity Interface](#entity-interface)
- [Architecture](#architecture)
- [نحوه کار](#نحوه-کار)
- [مثال استفاده](#مثال-استفاده)
- [Timing Diagram](#timing-diagram)
- [Configuration](#configuration)
- [تصمیمات طراحی](#تصمیمات-طراحی)

---

## مقدمه

Module `button_debouncer` دو مشکل critical را با mechanical button‌ها حل می‌کند:

1. **Bounce Filtering**: Ignore کردن rapid on/off transition‌های ناشی از mechanical contact bounce
2. **Edge Detection**: تولید دقیقاً یک output pulse به ازای هر button press، صرف نظر از مدت نگه‌داری دکمه

<details>
<summary>چرا به Debouncing نیاز داریم؟</summary>

وقتی یک physical button را فشار می‌دهید، metal contact‌ها connection تمیزی برقرار نمی‌کنند. آن‌ها «bounce» می‌کنند - به سرعت برای چند میلی‌ثانیه connect و disconnect می‌شوند قبل از اینکه settle شوند. بدون debouncing، یک button press ممکن است به صورت ۱۰ تا ۵۰ rapid press register شود!

</details>

---

## مشکل: Button Bounce

### Raw Button Signal (Bouncy)

```
رویداد فشردن دکمه:

Physical      ____________________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\____
Action           ↑                                                ↑
              Press                                            Release

Raw          ____/‾\_/‾‾\_/‾‾‾‾\__/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_/‾‾\_/‾\_____
Signal            ↑                                    ↑
               Bounce                                Bounce
             (۵-۲۰ms)                              (۵-۲۰ms)
```

### آنچه FSM بدون Debouncing می‌بیند

بدون debouncing، FSM چندین button press می‌بیند:
- کاربر یک بار A را فشار می‌دهد ← FSM ۵-۱۰ بار A pressed می‌بیند
- کاربر A، B، C، A را فشار می‌دهد ← FSM A، A، A، B، B، C، C، A، A، A می‌بیند
- نتیجه: Unpredictable behavior، وارد کردن unlock sequence غیرممکن است

### راه‌حل: Debounced و Edge-detected Output

![Bouncy Signal در مقابل Debounced Signal](../presentation/assets/Bounce-vs-Debounced-Signal.png)

```
Debounced    ________________________________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\______
(Stable)

Output       ________________________________/‾\__________________________
(Pulse)                                       ↑
                                   Single-cycle pulse
```

---

## Entity Interface

```vhdl
entity button_debouncer is
    Generic (
        DEBOUNCE_TIME : integer := 10
    );
    Port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        button_in  : in  std_logic;
        button_out : out std_logic
    );
end button_debouncer;
```

### Generic Parameter‌ها

| Parameter | نوع | مقدار پیش‌فرض | توضیحات |
|---------|-----|---------------|---------|
| `DEBOUNCE_TIME` | integer | ۱۰ | Clock cycle‌ها برای stability |

<details>
<summary>نحوه محاسبه DEBOUNCE_TIME</summary>

فرمول: `DEBOUNCE_TIME = debounce_period × clock_frequency`

مثال‌ها:
- Debounce ۱۰ میلی‌ثانیه در ۱۰۰ مگاهرتز: ۰.۰۱۰ × ۱۰۰٬۰۰۰٬۰۰۰ = ۱٬۰۰۰٬۰۰۰
- Debounce ۲۰ میلی‌ثانیه در ۵۰ مگاهرتز: ۰.۰۲۰ × ۵۰٬۰۰۰٬۰۰۰ = ۱٬۰۰۰٬۰۰۰

برای simulation، از مقادیر کوچک (۱۰-۱۰۰) برای سریع نگه داشتن simulation استفاده کنید.

مقادیر معمول real-world: ۱۰-۲۰ میلی‌ثانیه (۱-۲ میلیون cycle در ۱۰۰ مگاهرتز)

</details>

### Port‌ها

| Port | جهت | نوع | توضیحات |
|------|-----|-----|---------|
| `clk` | in | std_logic | System clock |
| `reset` | in | std_logic | Asynchronous reset، active-high |
| `button_in` | in | std_logic | Raw button input (ممکن است bounce داشته باشد) |
| `button_out` | out | std_logic | Clean single-cycle output pulse |

---

## Architecture

### Internal Signal‌ها

```vhdl
signal counter       : integer range 0 to DEBOUNCE_TIME := 0;
signal button_sync   : std_logic_vector(1 downto 0) := "00";
signal button_stable : std_logic := '0';
signal button_prev   : std_logic := '0';
```

| Signal | نوع | توضیحات |
|--------|-----|---------|
| `counter` | integer | Stability counter (در حالی که input stable است count می‌کند) |
| `button_sync` | std_logic_vector(1:0) | Two-stage synchronizer برای metastability |
| `button_stable` | std_logic | Debounced button state |
| `button_prev` | std_logic | Previous stable state (برای edge detection) |

<details>
<summary>Metastability چیست؟</summary>

**Metastability** زمانی رخ می‌دهد که یک signal دقیقاً همزمان با رسیدن clock edge تغییر کند. Flip-flop نمی‌تواند بین ۰ و ۱ تصمیم بگیرد و unstable output تولید می‌کند.

یک **synchronizer** (دو flip-flop به صورت series) به signal دو clock cycle می‌دهد تا قبل از استفاده settle شود و عملاً metastability issue‌ها را eliminate می‌کند.

```
button_in → [FF1] → [FF2] → button_sync(0)
             ↑        ↑
          May be    Stable
         unstable
```

</details>

---

## نحوه کار

### Processing Flow

![Processing Flow](../presentation/assets/Processing-Flow.png)

### Stage ۱: Synchronization

```vhdl
-- Two-stage synchronizer برای metastability protection
button_sync <= button_sync(0) & button_in;
```

Raw button input از دو flip-flop عبور می‌کند تا از affect شدن downstream logic توسط metastability جلوگیری شود.

### Stage ۲: Debounce Counting

```vhdl
-- Count stability time
if button_sync(1) /= button_stable then
    -- Input تغییر کرده، شروع counting
    if counter >= DEBOUNCE_TIME then
        button_stable <= button_sync(1);  -- Accept مقدار جدید
        counter <= 0;
    else
        counter <= counter + 1;  -- ادامه counting
    end if;
else
    counter <= 0;  -- Input با stable match دارد، reset counter
end if;
```

Counter فقط زمانی increment می‌شود که input با stable output متفاوت باشد. اگر input برای `DEBOUNCE_TIME` cycle متفاوت بماند، به عنوان مقدار stable جدید accept می‌شود.

### Stage ۳: Edge Detection

```vhdl
-- به خاطر سپردن previous stable state
button_prev <= button_stable;

-- تولید pulse روی rising edge
if button_stable = '1' and button_prev = '0' then
    button_out <= '1';  -- Rising edge detected!
else
    button_out <= '0';
end if;
```

با compare کردن current stable state با previous stable state، لحظه دقیق transition دکمه از unpressed به pressed را detect می‌کنیم.

<details>
<summary>چرا Rising Edge Detection؟</summary>

بدون edge detection، نگه داشتن یک دکمه به طور مداوم '1' output می‌دهد. FSM همان دکمه را در هر clock cycle pressed می‌بیند و خیلی سریع بین state‌ها progress می‌کند.

با edge detection:
- فشردن و نگه داشتن دکمه A ← یک pulse تولید می‌شود
- Release کردن دکمه A ← pulse‌ای تولید نمی‌شود
- فشردن مجدد دکمه A ← یک pulse تولید می‌شود

این تضمین می‌کند که هر physical press = دقیقاً یک FSM transition.

</details>

---

## مثال استفاده

### Basic Instantiation

```vhdl
debounce_btn_a: entity work.button_debouncer
    generic map (
        DEBOUNCE_TIME => 1000000  -- ~۱۰ms در ۱۰۰ مگاهرتز
    )
    port map (
        clk        => system_clock,
        reset      => system_reset,
        button_in  => raw_button_a,  -- از physical button
        button_out => clean_button_a  -- به FSM
    );
```

### Multiple Button‌ها

```vhdl
-- ایجاد ۴ debounced button
gen_debouncers: for i in 0 to 3 generate
    debouncer: entity work.button_debouncer
        generic map (DEBOUNCE_TIME => DEBOUNCE_CYCLES)
        port map (
            clk        => clk,
            reset      => reset,
            button_in  => raw_buttons(i),
            button_out => clean_buttons(i)
        );
end generate;
```

---

## Timing Diagram

### Normal Button Press

```
clk          ─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─
              └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘

button_in    ──────────────┐                       ┌───────────────
(raw)                      └───────────────────────┘

counter           0   1   2   3   4   5   0   0   1   2   3   4   5

button_stable ────────────────────────────┐       ┌────────────────
(debounced)                               └───────┘

button_out   ─────────────────────────────┐ ┌─────────────────────
(pulse)                                   └─┘
                                          ↑
                                   Single-cycle pulse
                                   روی rising edge
```

### Bouncy Button Press (Filtered)

```
button_in    ──────┐ ┌─┐ ┌─┐ ┌──────────────────────────────────
(bouncy)           └─┘ └─┘ └─┘
                   ↑       ↑
                Bounce‌ها  Settle

counter           0 1 0 1 0 1 2 3 4 5
                  ↑   ↑
               با هر bounce reset می‌شود

button_stable ────────────────────────────┐
                                          └─ (پس از DEBOUNCE_TIME تغییر می‌کند)

button_out   ─────────────────────────────┐ ┌──
                                          └─┘
```

### Short Press (Filtered)

```
button_in    ──────────┐   ┌───────────────────────────────────
(خیلی کوتاه)           └───┘
                       ← 3 →  (کمتر از DEBOUNCE_TIME=5)

counter           0   1   2   3   0   0   0
                                  ↑
                           قبل از رسیدن به ۵ reset می‌شود

button_stable ─────────────────────────────────────────────────
                              (هرگز تغییر نمی‌کند)

button_out   ──────────────────────────────────────────────────
                              (pulse‌ای تولید نمی‌شود)
```

---

## Configuration

### Simulation Setting‌ها

```vhdl
-- Simulation سریع (realistic نیست اما fast)
DEBOUNCE_TIME => 5
```

### Real Hardware Setting‌ها

| Clock Frequency | Debounce Period | DEBOUNCE_TIME |
|-------------|----------------|---------------|
| ۵۰ مگاهرتز | ۱۰ میلی‌ثانیه | ۵۰۰٬۰۰۰ |
| ۵۰ مگاهرتز | ۲۰ میلی‌ثانیه | ۱٬۰۰۰٬۰۰۰ |
| ۱۰۰ مگاهرتز | ۱۰ میلی‌ثانیه | ۱٬۰۰۰٬۰۰۰ |
| ۱۰۰ مگاهرتز | ۲۰ میلی‌ثانیه | ۲٬۰۰۰٬۰۰۰ |

<details>
<summary>نحوه انتخاب Debounce Period</summary>

Typical mechanical button‌ها برای ۵-۲۰ میلی‌ثانیه bounce دارند. توصیه‌ها:

- **۱۰ میلی‌ثانیه**: خوب برای high-quality button‌ها، faster response
- **۲۰ میلی‌ثانیه**: Safe برای اکثر button‌ها، slightly slower response
- **۵۰ میلی‌ثانیه**: بسیار conservative، noticeable delay

با ۲۰ میلی‌ثانیه شروع کنید و بر اساس specific button‌های خود adjust کنید. اگر گاهی double-press‌ها می‌بینید، debounce time را افزایش دهید.

</details>

---

## تصمیمات طراحی

### چرا Counter-based Approach؟

Counter-based debouncing:
- **Simple**: درک و implement آسان
- **Predictable**: Fixed debounce time، deterministic behavior
- **Resource Efficient**: فقط یک counter به ازای هر button
- **Configurable**: تغییر timing با یک single generic parameter

Alternative approach‌ها (shift register‌ها، analog RC filter‌ها) پیچیده‌تر هستند بدون significant benefit برای این application.

### چرا Two-stage Synchronizer؟

یک two-stage synchronizer احتمال metastability را به سطوح negligible کاهش می‌دهد:
- Single flip-flop: ~۱۰٪ chance of propagating metastable output
- Two flip-flop‌ها: ~۰.۰۱٪ chance
- برای critical application‌ها، می‌توان از ۳ stage استفاده کرد

### چرا Edge Detection داخل Debouncer؟

Integrate کردن edge detection در debouncer:
- تعداد external component‌ها را کاهش می‌دهد
- تضمین می‌کند که output همیشه یک clean single pulse است
- FSM را simplify می‌کند (نیاز به edge detection logic نیست)
- با FSM expectation‌ها match می‌کند (یک pulse به ازای هر press)

### چرا از Separate Debounce و Edge Detection Module‌ها استفاده نشد؟

در حالی که modular design خوب است، combine کردن آن‌ها:
- Potential timing issue‌ها بین module‌ها را کاهش می‌دهد
- Atomic operation را تضمین می‌کند (debounce + edge detect با هم happen می‌شوند)
- Top-level design را simplify می‌کند
- Common industry practice برای button interface‌ها است
