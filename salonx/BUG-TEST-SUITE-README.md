# BUG Test Suite - SalonX Staff App Regression Tests

This test suite contains automated regression tests for bugs tracked in the SalonX Phase 2 Tracker.
These tests verify that previously identified and fixed bugs do not regress.

## Test Cases

| Test ID | Bug ID | Title | Platform | Priority |
|---------|--------|-------|----------|----------|
| BUG-001 | recoLUkZ5g | Failed to send reset email on Forgot Password | Android, iOS | P1 |
| BUG-002 | recvmhqRel | Calendar date headers displayed in English (should be Japanese) | iOS | P2 |
| BUG-003 | rec3VgMdyn | Raw validation keys on Password Change screen | iOS | P1 |
| BUG-004 | recSjfpCDm | App hard-locks on Switch Store modal (no stores assigned) | iOS | P1 |
| BUG-005 | recT2RoD0W | Date filter boundary error (midnight appointments) | iOS, Android | P2 |
| BUG-006 | reccpDVQQI | App crashes when switching business entities | Android | P0 |
| BUG-007 | rec773LGpw | Photo upload fails silently without error feedback | iOS, Android | P1 |

## Prerequisites

### General Requirements
- Maestro CLI installed
- SalonX Staff Dev App installed (`com.storehub.salonx.staff.dev`)
- Valid test credentials

### Test-Specific Requirements

#### BUG-004 (No Store Assigned)
Requires a special test account with NO stores assigned:
- Create a staff account in Web Admin
- Do NOT assign any stores/locations to the account
- Update the environment variables in the test file:
  ```yaml
  env:
    NO_STORE_USER_EMAIL: "your-no-store-account@test.com"
    NO_STORE_USER_PASSWORD: "your-password"
  ```

## Running Tests

### Run All Bug Tests
```bash
maestro test salonx/BUG-*.yaml
```

### Run Individual Test
```bash
maestro test salonx/BUG-001-forgot-password-error.yaml
```

### Run by Priority
```bash
# P0 (Critical) tests
maestro test salonx/BUG-006-business-switch-crash.yaml

# P1 (High) tests
maestro test --tags=P1 salonx/BUG-*.yaml

# P2 (Medium) tests
maestro test --tags=P2 salonx/BUG-*.yaml
```

### Run by Tag
```bash
# All localization bugs
maestro test --tags=localization salonx/BUG-*.yaml

# All crash-related bugs
maestro test --tags=crash salonx/BUG-*.yaml
```

## Test Details

### BUG-001: Forgot Password Error
**Issue:** System shows "Failed to send reset email" error instead of sending verification code.

**Verification:**
- Navigates to Forgot Password screen
- Enters registered email address
- Submits request
- Verifies NO error message appears
- Confirms verification code screen is reached

---

### BUG-002: Calendar Date Localization
**Issue:** Date headers show English (e.g., "Friday, December 26") when language is set to Japanese.

**Verification:**
- Sets language to Japanese
- Navigates to Booking tab
- Scrolls through appointment list
- Verifies English day names (Monday, Tuesday, etc.) are NOT visible
- Confirms Japanese date format is displayed

---

### BUG-003: Password Validation Keys
**Issue:** Raw technical strings like `validation.password.currentRequired` shown instead of localized messages.

**Verification:**
- Navigates to Change Password screen
- Leaves fields blank and taps Save
- Verifies raw validation keys are NOT visible
- Confirms proper localized error messages appear

---

### BUG-004: No Store Assigned Edge Case
**Issue:** App hard-locks on blank modal when user has no stores assigned.

**Verification:**
- Logs in with account that has no stores
- Verifies proper error message is displayed
- Confirms logout/exit option is available (not stuck)

---

### BUG-005: Date Filter Boundary
**Issue:** Filtering from date X incorrectly shows date X-1 header for midnight appointments.

**Verification:**
- Opens appointment list
- Applies date filter
- Verifies previous day header does not appear

---

### BUG-006: Business Switch Crash (Android)
**Issue:** App crashes with `IllegalStateException` when switching between business entities.

**Verification:**
- Navigates to Switch Business option
- Selects a different store
- Confirms selection
- Verifies NO crash/exception occurs
- Confirms app remains functional

---

### BUG-007: Photo Upload Silent Failure
**Issue:** Photo upload fails without showing any error message.

**Verification:**
- Navigates to booking's Photos tab
- Attempts to upload photo
- Verifies either:
  - Photo uploads successfully, OR
  - Clear error message is displayed (not silent failure)

## Bugs NOT Automated

The following bugs from the tracker were NOT automated:

| Bug ID | Title | Reason |
|--------|-------|--------|
| recq4ItxD6 | Keyboard covers input fields | Visual overlap issue - partially automatable but keyboard overlay detection is unreliable |
| recVPjUxnu | Logo overlaps header | Pure visual/UI issue - requires visual regression tools like Applitools |
| receCIkDFM | Data discrepancy between Web Admin and Staff App | Requires cross-platform API comparison, complex setup |

## Source

Bug list extracted from: [SalonX Phase 2 Tracker](https://storehub.sg.larksuite.com/wiki/LyN0w7ukQiLZ70k3yMclfCy7gwc)

Criteria:
- Status: Released
- Product: Staff App
- Repro Steps: Not empty
