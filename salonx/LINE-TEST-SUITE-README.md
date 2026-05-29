# LINE Booking Test Suite

## Overview

End-to-end automation for the SalonX booking flow through the LINE Mini App (LIFF).

## Prerequisites

- Android device/emulator with LINE app installed and logged in
- LINE test account with access to the SalonX Official Account
- LIFF deep link URL configured in `subflow/line-open-liff.yaml`
- [ADBKeyboard](https://github.com/senzhk/ADBKeyBoard) installed and set as default IME on the test device (required for katakana input)

## Setup

1. Open LINE on the test device and log in with the test account
2. Update the LIFF URL in `subflow/line-open-liff.yaml` with the correct deep link
3. Install ADBKeyboard and set as default IME:
   ```bash
   adb install ADBKeyboard.apk
   adb shell ime set com.android.adbkeyboard/.AdbIME
   ```
4. Run the flow:
   ```bash
   maestro test salonx/LINE-001-booking-e2e.yaml
   ```

Note: The E2E flow automatically pre-loads the clipboard with katakana before each run.

## Test Flows

| Flow | Priority | Description |
|------|----------|-------------|
| LINE-001-booking-e2e.yaml | P0 | Happy-path end-to-end booking |

## Architecture

```
LINE-001-booking-e2e.yaml
├── subflow/line-open-liff.yaml      # Launch + LIFF deep link + ANR handling
└── subflow/line-booking-steps.yaml  # Store Info → Service → Staff → Date/Time → Customer Info → Confirm
```

## Booking Flow Steps

| Step | Page | Action |
|------|------|--------|
| 0 | 店舗情報 (Store Info) | Scroll + tap 続ける |
| 1 | メニュー選択 (Service) | Tap service text label at 54%,74% → 続ける |
| 2a | スタッフ選択 (Staff) | Accept default 指名なし → 続ける |
| 2b | 日時選択 (Date/Time) | Scroll to time grid → tap time text (e.g. "13:00") → 続ける |
| 3 | 情報入力 (Customer Info) | Erase + paste katakana in フリガナ → 続ける |
| 4 | 予約確認 (Confirmation) | Scroll + tap confirm button at 50%,94% |

## Key Implementation Details

- **WebView interaction**: LIFF renders in a WebView where standard point-based taps fail on interactive elements (checkboxes, grid cells, buttons). Three workarounds are used:
  - **Text-based taps**: `tapOn: "13:00"` uses accessibility text to interact with WebView time slot cells
  - **Service text label tap**: Tapping the service name text (not the checkbox icon) checks the checkbox
  - **Offset button tap**: The confirm button responds to taps on its upper portion (94% y) but not its center
- **Conditional step handling**: Each booking step is wrapped in `runFlow when` so the test handles cached LIFF state (may start at any step)
- **ANR dialog handling**: `line-open-liff.yaml` checks for and dismisses LINE "Not Responding" dialogs during LIFF load
- **Katakana input workaround**: Maestro's `inputText` does not support Unicode (issue #146). The フリガナ field is filled via `eraseText` + `pasteText` using clipboard pre-loaded by the E2E flow
- **Fresh vs cached state**: Base LIFF URL (without `/services`) starts from store info page; cached state may skip directly to any step

## Selector Calibration

Selectors are based on the LIFF WebView's accessibility text. If selectors fail:
1. Run `adb shell uiautomator dump /sdcard/ui.xml && adb pull /sdcard/ui.xml` to capture the current element hierarchy
2. Note that WebView elements may have different text than what's visually rendered
3. Time slot availability varies by date — if "13:00" is unavailable, try another time string
4. Service names change in the test environment — the point-based tap (54%,74%) targets the mid-list service position
