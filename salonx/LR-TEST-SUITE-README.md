# Leave Request (LR) Test Suite

## Overview
This test suite covers the **Leave Request / Sick Leave** functionality in the SalonX Staff application. The tests are designed based on the video recording at `/Users/chad/Library/Application Support/LarkInternational/screenshot/20260109180227_rec_.mp4`.

## Test Cases

### LR-001: [核心] 正常提交 Sick Leave 申请
**File**: `LR-001-submit-sick-leave.yaml`  
**Priority**: P0  
**Risk Dimension**: 业务影响 (Business Impact)

**Description**: Submit a normal sick leave request

**Expected Results**:
- Status becomes "Pending"
- New record appears in the leave request list
- Leave balance is deducted (pre-deducted)

**Test Steps**:
1. Login to the application
2. Navigate to Leave Request section
3. Create a new sick leave request
4. Select dates and add reason
5. Submit the request
6. Verify status is "Pending"
7. Verify balance is deducted

---

### LR-002: [边界] 申请日期与已有申请重叠
**File**: `LR-002-overlapping-dates.yaml`  
**Priority**: P1  
**Risk Dimension**: 变更风险 (Change Risk)

**Description**: Submit a leave request with dates that overlap with an existing request

**Expected Results**:
- System shows error message
- Submission is blocked
- Prevents data conflict

**Test Steps**:
1. Login to the application
2. Ensure there's an existing leave request
3. Try to create a new request with overlapping dates
4. Verify error message appears
5. Verify submission is prevented

---

### LR-003: [异常] 请假天数超过可用余额
**File**: `LR-003-insufficient-balance.yaml`  
**Priority**: P0  
**Risk Dimension**: 核心指标 (Core Metrics)

**Description**: Submit a leave request with days exceeding available balance

**Expected Results**:
- Submission fails
- Shows "Insufficient balance" or similar error message

**Test Steps**:
1. Login to the application
2. Navigate to Leave Request section
3. Check current leave balance
4. Try to submit a request exceeding the balance
5. Verify error message appears
6. Verify submission is blocked

---

### LR-004: [状态机] 撤回 Pending 状态的申请
**File**: `LR-004-cancel-pending-request.yaml`  
**Priority**: P0  
**Risk Dimension**: 逻辑回退 (Logic Rollback)

**Description**: Withdraw/Cancel a Pending leave request [录屏 00:37]

**Expected Results**:
- Status immediately changes to "Cancelled"
- Pre-deducted balance is released/restored

**Test Steps**:
1. Login to the application
2. Navigate to Leave Request section
3. Find a pending leave request
4. Click Cancel/Withdraw button
5. Confirm cancellation
6. Verify status changes to "Cancelled"
7. Verify balance is restored

---

### LR-005: [非功能] 快速连点"Submit Request"
**File**: `LR-005-idempotency-test.yaml`  
**Priority**: P1  
**Risk Dimension**: 技术复杂度 (Technical Complexity)

**Description**: Rapidly click Submit Request button multiple times

**Expected Results**:
- Backend only processes ONE request (idempotency check)
- Avoids creating multiple duplicate records

**Test Steps**:
1. Login to the application
2. Navigate to Leave Request section
3. Fill in leave request form
4. Rapidly click Submit button 5 times
5. Verify only ONE request is created
6. Verify no duplicate records exist

---

### LR-006: [隔离] 切换至其他门店（Tenant）账号
**File**: `LR-006-data-isolation.yaml`  
**Priority**: P0  
**Risk Dimension**: 数据隔离 (Data Isolation)

**Description**: Switch to another store/tenant account

**Expected Results**:
- Cannot view the previous employee's leave history
- Data isolation is enforced between tenants

**Test Steps**:
1. Login as User A (owner@demo.com) in Store A
2. View User A's leave requests
3. Logout from User A
4. Login as User B (staff@demo.com) in Store B
5. Navigate to Leave Request section
6. Verify User B cannot see User A's leave requests
7. Verify data isolation is working

---

## Running the Tests

### Run Individual Tests
```bash
maestro test salonx/LR-001-submit-sick-leave.yaml
maestro test salonx/LR-002-overlapping-dates.yaml
maestro test salonx/LR-003-insufficient-balance.yaml
maestro test salonx/LR-004-cancel-pending-request.yaml
maestro test salonx/LR-005-idempotency-test.yaml
maestro test salonx/LR-006-data-isolation.yaml
```

### Run All Leave Request Tests
```bash
maestro test salonx/LR-*.yaml
```

### Recommended Test Execution Order
```bash
maestro test \
  salonx/LR-001-submit-sick-leave.yaml \
  salonx/LR-004-cancel-pending-request.yaml \
  salonx/LR-002-overlapping-dates.yaml \
  salonx/LR-003-insufficient-balance.yaml \
  salonx/LR-005-idempotency-test.yaml \
  salonx/LR-006-data-isolation.yaml
```

## Prerequisites

1. **App Installed**: `com.storehub.salonx.staff.dev`
2. **Test Accounts**:
   - User A: `owner@demo.com` / `password123`
   - User B: `staff@demo.com` / `password123`
3. **Test Data**: At least 2 different stores/tenants available
4. **Leave Balance**: Ensure test accounts have some leave balance

## Notes

- Tests use flexible regex patterns to support both English and Japanese UI
- Screenshots are captured at key verification points
- Tests handle conditional flows for different app states
- `clearState: false` is used to preserve login sessions between tests

