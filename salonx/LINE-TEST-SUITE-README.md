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
4. Pre-load the clipboard with katakana text before each test run:
   ```bash
   adb shell service call clipboard 1 i32 1 s16 "テスト"
   ```
5. Run the flow:
   ```bash
   maestro test salonx/LINE-001-booking-e2e.yaml
   ```

## Test Flows

| Flow | Priority | Description |
|------|----------|-------------|
| LINE-001-booking-e2e.yaml | P0 | Happy-path end-to-end booking |

## Architecture

```
LINE-001-booking-e2e.yaml
├── subflow/line-open-liff.yaml      # Launch + LIFF deep link + ANR handling
└── subflow/line-booking-steps.yaml  # Service → Date/Time → Customer Info → Confirm
```

## Key Implementation Details

- **Conditional step handling**: Each booking step is wrapped in `runFlow when` so the test handles cached LIFF state (may start at Step 2, 3, or 4)
- **ANR dialog handling**: `line-open-liff.yaml` checks for and dismisses LINE "Not Responding" dialogs during LIFF load
- **Katakana input workaround**: Maestro's `inputText` does not support Unicode (issue #146). The フリガナ field is filled via `eraseText` + `pasteText` using pre-loaded clipboard content
- **Flexible success assertion**: Accepts either a post-booking success screen or the Step 4 confirmation page (depending on cached state)

## Selector Calibration

Selectors are based on English/Japanese LIFF UI patterns. If selectors fail:
1. Run `maestro record` against the LINE app to capture real element attributes
2. Update selectors in `subflow/line-booking-steps.yaml`
3. Re-run to verify
