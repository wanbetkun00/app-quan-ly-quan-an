# Role-based Login Test Cases

## 1) Login flow

- Login with valid `manager` account -> app opens manager navigation with 4 tabs: waiter, cashier, kitchen, manager.
- Login with valid `cashier` account -> app opens cashier dashboard only.
- Login with valid `waiter` account -> app opens waiter dashboard only.
- Login with invalid password -> show error snackbar and stay on login screen.
- Login with inactive account (`isActive = false`) -> login fails and user stays on login screen.

## 2) Manager permissions

- Manager can open `ManagerDashboardScreen`.
- Manager can open reports tab and generate/export report.
- Manager can open employee tab and create employee with role `manager`, `cashier`, `waiter`.
- Manager can still access waiter and cashier modules from bottom navigation.

## 3) Cashier permissions

- Cashier sees only cashier dashboard after login.
- Cashier sees only tables with `paymentPending` status.
- Cashier can open payment dialog and complete payment successfully.
- Cashier cannot access manager dashboard directly (role guard blocks unauthorized access).

## 4) Waiter permissions

- Waiter sees only waiter dashboard after login.
- Waiter can create new order for available table.
- Waiter can view occupied table details.
- Waiter cannot process payment: tapping a `paymentPending` table shows blocked-permission message.

## 5) Backward compatibility

- Legacy account `staff/1234` logs in successfully and is mapped to waiter role.
- Existing employee docs with role `staff` are mapped to `waiter` role in app.

## 6) Logout and session behavior

- Logout from each role returns to login screen.
- After logout, back navigation does not restore protected screens.
