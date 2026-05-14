# LINE LIFF Booking Flow Automation — Design Spec

## Summary

Automate the end-to-end salon booking flow through a LINE Mini App (LIFF) using Maestro. The happy-path flow launches the LIFF app via deep link, walks through store/service/stylist/datetime selection, fills customer info, and confirms the booking.

## Context

- **Project:** SalonX Maestro test suite at `/Users/chad/Downloads/maestro/salonx/`
- **App under test:** LINE Mini App (LIFF) for SalonX customer booking
- **LINE app package:** `jp.naver.line.android` (Android)
- **Existing test account:** Yes, authenticated LINE session available
- **Languages:** English + Japanese UI
- **Entry point:** Official Account chat rich menu → opens LIFF (but automation uses deep link directly)

## Approach: Deep Link Launch

Launch the LIFF app directly via deep link URL instead of navigating through LINE chat UI. This avoids fragile chat UI selectors (message timestamps, notification badges, chat ordering).

**Deep link format:** `line://app/{liff-id}` or `https://liff.line.me/{liff-id}` — exact URL TBD during implementation.

## File Structure

```
salonx/
  LINE-001-booking-e2e.yaml         # Main happy-path booking flow
  LINE-TEST-SUITE-README.md         # LINE test suite documentation
  subflow/
    line-booking-steps.yaml         # Reusable booking steps
    line-open-liff.yaml             # LIFF launch helper via deep link
```

## Flow Steps

### Main Flow: LINE-001-booking-e2e.yaml

1. **Launch LINE with LIFF deep link** — `launchApp` with LINE package + LIFF URL intent
2. **Wait for LIFF WebView load** — wait for booking UI content to render
3. **Run booking subflow** — `line-booking-steps.yaml`
4. **Verify booking success** — check for confirmation screen elements
5. **Take screenshot** — capture evidence of successful booking

### Subflow: line-open-liff.yaml

1. Launch LINE app
2. Open LIFF deep link URL
3. Wait for WebView to fully load
4. Verify booking UI is visible

### Subflow: line-booking-steps.yaml

1. **Store selection** — tap target store from list
2. **Service selection** — select service category, pick a service
3. **Stylist selection** — choose stylist or "any available"
4. **Date/time picker** — pick date on calendar, select time slot
5. **Customer info** — fill name, phone, email
6. **Confirm booking** — tap submit/book button

## Selector Strategy

| Element | Selector Pattern | Type |
|---------|-----------------|------|
| Navigation buttons | `"Next\|次へ"`, `"Confirm\|確認\|确定"` | Multi-language regex |
| Store/service items | `index: 0` (first item) | Index-based |
| Date picker | `point` coordinates or calendar text | Point-based |
| Time slots | `index: 0` (first available) | Index-based |
| Name input | `".*name.*\|.*名前.*"` | Multi-language regex |
| Phone input | `".*phone\|.*電話.*"` | Multi-language regex |
| Email input | `".*@.*\|.*email\|.*メール.*"` | Multi-language regex |
| Submit/confirm | `"Book\|予約\|Confirm\|確認"` | Multi-language regex |
| Success screen | `"success\|完了\|confirmed\|予約完了"` | Multi-language regex |

## Stability Patterns

- `clearState: false` — preserve LINE login session between runs
- `waitForAnimationToEnd` — after WebView page loads and screen transitions
- Point-based navigation for elements without stable text
- `index: 0` for selecting first available items in lists
- Screenshots at each key step for debugging
- Conditional flows for handling variable app states

## Tags & Metadata

```yaml
appId: jp.naver.line.android
tags:
  - line
  - booking
  - e2e
  - P0
```

## Out of Scope (Future Iterations)

- Chat navigation entry path (Official Account → rich menu → LIFF)
- Edge cases: booking conflicts, validation errors, required field checks
- Booking cancellation flow
- Reschedule flow
- Multi-store selection scenarios
- Performance testing

## Open Items (Resolved During Implementation)

1. **LIFF deep link URL** — exact URL format to be provided by user
2. **Selector calibration** — all selectors need validation against real LIFF UI
3. **Test data** — specific store name, service type, stylist name for happy path
