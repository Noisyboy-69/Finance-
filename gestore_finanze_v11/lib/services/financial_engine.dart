
import '../models/models.dart';

class FinancialEngine {
  static FinancialPlan build({
    required MonthIncome income,
    required CurrentAccountStatus account,
    required List<RecurringExpense> recurring,
    required List<Movement> movements,
    int salaryDay = 27,
    DateTime? now,
  }) {
    final d = now ?? DateTime.now();
    final recurringMonthly = recurring.fold(0.0, (s, e) => s + e.monthlyEquivalent);
    final spent = movements.fold(0.0, (s, m) => s + m.amount);
    final recovery = account.currentBalance < 0
        ? [150.0, income.amount * .10, account.currentBalance.abs()].reduce((a,b) => a < b ? a : b)
        : 0.0;
    final base = account.currentBalance > 0 ? account.currentBalance : 0.0;
    final raw = base - spent - recurringMonthly - recovery;
    final spendable = raw < 0 ? 0.0 : raw;
    DateTime next = DateTime(d.year, d.month, salaryDay.clamp(1,28));
    if (!next.isAfter(d)) next = DateTime(d.year, d.month + 1, salaryDay.clamp(1,28));
    final days = next.difference(d).inDays.clamp(1, 31);
    final weekly = spendable / (days / 7.0);
    FinancialStatus status = FinancialStatus.stable;
    if (account.currentBalance < 0) {
      status = account.overdraftLimit > 0 && account.currentBalance.abs() >= account.overdraftLimit * .9
          ? FinancialStatus.critical
          : FinancialStatus.recovery;
    } else if (income.amount > 0 && spendable < income.amount * .15) {
      status = FinancialStatus.attention;
    }
    return FinancialPlan(
      income: income.amount,
      recurringMonthly: recurringMonthly,
      spentThisMonth: spent,
      currentBalance: account.currentBalance,
      recoveryAmount: recovery,
      spendableUntilSalary: spendable,
      weeklySpendable: weekly,
      daysUntilSalary: days,
      status: status,
    );
  }
}
