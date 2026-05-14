# LINE LIFF Booking Flow Automation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a Maestro end-to-end test that completes a salon booking through the LINE Mini App (LIFF) via deep link launch.

**Architecture:** Three Maestro flow files — a main E2E flow, a LIFF launch subflow, and a reusable booking steps subflow. The main flow composes the subflows and handles verification. Deep link launches the LIFF app directly inside LINE, bypassing chat navigation.

**Tech Stack:** Maestro mobile automation, YAML flow definitions, LINE Android app (`jp.naver.line.android`)

---

## File Map

| File | Responsibility |
|------|---------------|
| `salonx/subflow/line-open-liff.yaml` | Launch LINE and open LIFF deep link, wait for WebView load |
| `salonx/subflow/line-booking-steps.yaml` | Reusable booking steps: store → service → stylist → datetime → customer info → confirm |
| `salonx/LINE-001-booking-e2e.yaml` | Main E2E flow that composes subflows + success verification |
| `salonx/LINE-TEST-SUITE-README.md` | Documentation for the LINE test suite |

---

## Pre-Implementation: Gather LIFF URL and Calibrate Selectors

Before writing the flows, we need the user to provide:
1. **LIFF deep link URL** (e.g., `https://liff.line.me/xxxx-xxxx`)
2. **Run the LIFF app once manually** so we can calibrate exact selectors

The flows below use selector patterns based on the design spec. A calibration pass after initial creation will refine these against the real UI.

---

### Task 1: Create LIFF Launch Subflow

**Files:**
- Create: `salonx/subflow/line-open-liff.yaml`

- [ ] **Step 1: Write the LIFF launch subflow**

```yaml
appId: jp.naver.line.android
tags:
  - line
  - subflow
---
- launchApp:
    appId: "jp.naver.line.android"
    clearState: false
    stopApp: true
    permissions:
      all: "allow"
- extendedWaitUntil:
    visible: "LINE"
    timeout: 15000
- openLink: "https://liff.line.me/REPLACE_WITH_LIFF_ID"
- extendedWaitUntil:
    visible: ".*[Bb]ook.*|.*予約.*|.*[Ss]tore.*|.*店舗.*|.*[Ss]ervice.*|.*サービス.*"
    timeout: 30000
- waitForAnimationToEnd:
    timeout: 5000
```

- [ ] **Step 2: Commit**

```bash
git add salonx/subflow/line-open-liff.yaml
git commit -m "feat: add LINE LIFF launch subflow"
```

---

### Task 2: Create Booking Steps Subflow

**Files:**
- Create: `salonx/subflow/line-booking-steps.yaml`

- [ ] **Step 1: Write the booking steps subflow**

```yaml
appId: jp.naver.line.android
tags:
  - line
  - subflow
---
# Step 1: Store selection
- runFlow:
    when:
      visible: ".*[Ss]tore.*|.*店舗.*|.*[Ll]ocation.*|.*場所.*"
    commands:
      - tapOn:
          index: 0
      - waitForAnimationToEnd:
          timeout: 3000

# Step 2: Service selection
- runFlow:
    when:
      visible: ".*[Ss]ervice.*|.*サービス.*|.*[Cc]ategory.*"
    commands:
      - tapOn:
          index: 0
      - waitForAnimationToEnd:
          timeout: 3000

# Step 3: Stylist selection
- runFlow:
    when:
      visible: ".*[Ss]taff.*|.*スタッフ.*|.*[Ss]tylist.*|.*Any.*|.*指定なし.*"
    commands:
      - tapOn:
          index: 0
      - waitForAnimationToEnd:
          timeout: 3000

# Step 4: Date selection — tap first available date
- runFlow:
    when:
      visible: ".*[Dd]ate.*|.*日付.*|.*[Cc]alendar.*|.*カレンダー.*"
    commands:
      - tapOn:
          index: 1
      - waitForAnimationToEnd:
          timeout: 2000

# Step 4b: Time slot selection — tap first available time
- runFlow:
    when:
      visible: ".*[Tt]ime.*|.*時間.*|.*[0-9]+:[0-9]+.*"
    commands:
      - tapOn:
          index: 0
      - waitForAnimationToEnd:
          timeout: 2000

# Step 5: Customer info — name
- runFlow:
    when:
      visible: ".*[Nn]ame.*|.*名前.*|.*お名前.*"
    commands:
      - tapOn: ".*[Nn]ame.*|.*名前.*|.*お名前.*"
      - inputText: "Test Customer"
      - waitForAnimationToEnd:
          timeout: 1000

# Step 5b: Customer info — phone
- runFlow:
    when:
      visible: ".*[Pp]hone.*|.*電話.*|.*TEL.*|.*携帯.*"
    commands:
      - tapOn: ".*[Pp]hone.*|.*電話.*|.*TEL.*|.*携帯.*"
      - inputText: "09012345678"
      - waitForAnimationToEnd:
          timeout: 1000

# Step 5c: Customer info — email
- runFlow:
    when:
      visible: ".*[Ee]mail.*|.*メール.*|.*@.*"
    commands:
      - tapOn: ".*[Ee]mail.*|.*メール.*|.*@.*"
      - inputText: "test.customer@example.com"
      - waitForAnimationToEnd:
          timeout: 1000

# Step 6: Confirm/Submit booking
- tapOn: "Book|予約|Confirm|確認|Submit|送信|Next|次へ"
- waitForAnimationToEnd:
    timeout: 5000
```

- [ ] **Step 2: Commit**

```bash
git add salonx/subflow/line-booking-steps.yaml
git commit -m "feat: add LINE booking steps subflow"
```

---

### Task 3: Create Main E2E Flow

**Files:**
- Create: `salonx/LINE-001-booking-e2e.yaml`

- [ ] **Step 1: Write the main E2E flow**

```yaml
appId: jp.naver.line.android
tags:
  - line
  - booking
  - e2e
  - P0
---
# Launch LINE and open LIFF app via deep link
- runFlow: subflow/line-open-liff.yaml

# Complete booking steps
- runFlow: subflow/line-booking-steps.yaml

# Verify booking success
- extendedWaitUntil:
    visible: ".*[Ss]uccess.*|.*完了.*|.*[Cc]onfirmed.*|.*予約完了.*|.*[Bb]ooking.*[Dd]etail.*|.*予約詳細.*|.*[Tt]hank.*"
    timeout: 20000

# Capture evidence
- takeScreenshot: "LINE-booking-success"

# Final assertion — at least one success indicator must be visible
- assertVisible: ".*[Ss]uccess.*|.*完了.*|.*[Cc]onfirmed.*|.*予約完了.*|.*[Bb]ooking.*[Dd]etail.*|.*予約詳細.*|.*[Tt]hank.*"
```

- [ ] **Step 2: Commit**

```bash
git add salonx/LINE-001-booking-e2e.yaml
git commit -m "feat: add LINE booking E2E flow"
```

---

### Task 4: Create LINE Test Suite README

**Files:**
- Create: `salonx/LINE-TEST-SUITE-README.md`

- [ ] **Step 1: Write the README**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add salonx/LINE-TEST-SUITE-README.md
git commit -m "docs: add LINE test suite README"
```

---

### Task 5: Calibration — Replace Placeholder LIFF URL

**Files:**
- Modify: `salonx/subflow/line-open-liff.yaml`

This task requires the user to provide the actual LIFF deep link URL.

- [ ] **Step 1: Replace `REPLACE_WITH_LIFF_ID` with the real LIFF URL**

In `salonx/subflow/line-open-liff.yaml`, change:
```yaml
- openLink: "https://liff.line.me/REPLACE_WITH_LIFF_ID"
```
to:
```yaml
- openLink: "https://liff.line.me/<actual-liff-id>"
```

- [ ] **Step 2: Run the flow against a real device**

```bash
maestro test salonx/LINE-001-booking-e2e.yaml
```

Expected: LINE opens, LIFF app loads, booking flow completes, success screen verified.

- [ ] **Step 3: Calibrate selectors if needed**

If any step fails:
1. Check `salonx/.maestro/screenshots/` for failure screenshots
2. Run `maestro record` to capture actual element attributes
3. Update selectors in `subflow/line-booking-steps.yaml`
4. Re-run until the full flow passes

- [ ] **Step 4: Commit calibrated selectors**

```bash
git add salonx/
git commit -m "fix: calibrate LINE booking selectors against real LIFF UI"
```
