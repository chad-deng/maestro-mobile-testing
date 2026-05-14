# LINE Booking Test Suite

## Overview

End-to-end automation for the SalonX booking flow through the LINE Mini App (LIFF).

## Prerequisites

- Android device/emulator with LINE app installed and logged in
- LINE test account with access to the SalonX Official Account
- LIFF deep link URL configured in `subflow/line-open-liff.yaml`

## Test Flows

| Flow | Priority | Description |
|------|----------|-------------|
| LINE-001-booking-e2e.yaml | P0 | Happy-path end-to-end booking |

## How to Run

```bash
maestro test salonx/LINE-001-booking-e2e.yaml
```

## Setup

1. Open LINE on the test device and log in with the test account
2. Update the LIFF URL in `subflow/line-open-liff.yaml` with the correct deep link
3. Run the flow

## Selector Calibration

Selectors are based on English/Japanese LIFF UI patterns. If selectors fail:
1. Run `maestro record` against the LINE app to capture real element attributes
2. Update selectors in `subflow/line-booking-steps.yaml`
3. Re-run to verify

## Architecture

```
LINE-001-booking-e2e.yaml
├── subflow/line-open-liff.yaml      # Launch + LIFF deep link
└── subflow/line-booking-steps.yaml  # Store → Service → Stylist → Date → Info → Confirm
```
