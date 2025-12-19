> **[🇬🇧 English Version](README.md)**

# فایل‌های Source (`src/`)

این دایرکتوری حاوی فایل‌های source VHDL قابل synthesis برای قفل دیجیتال مبتنی بر الگو است.

---

## فایل‌ها

| فایل | خطوط | توضیحات |
|------|------|---------|
| [digital_lock.vhd](digital_lock.vhd) | ۱۵۶ | FSM controller اصلی |
| [button_debouncer.vhd](button_debouncer.vhd) | ۹۳ | مدار button debouncer |
| [top_level.vhd](top_level.vhd) | ۱۵۴ | یکپارچه‌سازی سیستم |

---

## ترتیب کامپایل

فایل‌ها باید به ترتیب dependency کامپایل شوند:

```bash
# ۱. ابتدا module‌های مستقل
ghdl -a --std=08 digital_lock.vhd
ghdl -a --std=08 button_debouncer.vhd

# ۲. top-level در آخر (وابسته به هر دو بالا)
ghdl -a --std=08 top_level.vhd
```

<details>
<summary>چرا ترتیب مهم است؟</summary>

VHDL به یک "work library" کامپایل می‌شود. وقتی یک فایل به component دیگری ارجاع می‌دهد، آن component باید قبلاً در library وجود داشته باشد. اگر به ترتیب نادرست کامپایل کنید، خطاهایی مانند زیر می‌بینید:

```
error: cannot find entity work.digital_lock
```

</details>

---

## Module Hierarchy

```
top_level
├── button_debouncer (×4 instance)
│   └── فیلتر bounce دکمه، ارائه pulse‌های تمیز
└── digital_lock (×1 instance)
    └── FSM controller، مدیریت state قفل
```

---

## مرجع سریع

### digital_lock.vhd

**هدف**: FSM پنج state‌ای پیاده‌سازی منطق توالی باز کردن

**Port‌ها**:
- `clk`, `reset` - Clock و reset
- `button_A/B/C/D` - ورودی‌های دکمه debounce شده
- `lock_status` - خروجی ('1' = unlocked)

**Generic**: `UNLOCK_TIME` - تأخیر auto-lock به clock cycle

---

### button_debouncer.vhd

**هدف**: فیلتر bounce مکانیکی، خروجی single-cycle pulse

**Port‌ها**:
- `clk`, `reset` - Clock و reset
- `button_in` - ورودی raw دکمه
- `button_out` - خروجی تمیز و edge-detected

**Generic**: `DEBOUNCE_TIME` - دوره پایداری به clock cycle

---

### top_level.vhd

**هدف**: سیستم کامل آماده برای synthesis

**Port‌ها**:
- `clk`, `reset` - System clock و reset
- `button_A/B/C/D_raw` - ورودی‌های raw دکمه
- `lock_status`, `led` - نشانگرهای خروجی

**Generic‌ها**: `DEBOUNCE_TIME`, `UNLOCK_TIME`

---

## مستندات تفصیلی

دایرکتوری [docs/](../docs/) را برای مستندات جامع ببینید:

- [digital_lock.md](../docs/digital_lock.md) - معماری و طراحی FSM
- [button_debouncer.md](../docs/button_debouncer.md) - عملکرد debouncer
- [top_level.md](../docs/top_level.md) - راهنمای یکپارچه‌سازی سیستم

---

## استانداردهای طراحی

همه فایل‌های source از این قراردادها پیروی می‌کنند:

- استاندارد **VHDL-2008** (`--std=08`)
- **IEEE std_logic_1164** برای انواع منطقی
- **الگوی Three-process FSM** برای state machine‌ها
- **Generic parameter‌ها** برای timing قابل تنظیم
- **Synchronous design** با asynchronous reset
- **کاملاً قابل Synthesis** - بدون ساختارهای simulation-only
