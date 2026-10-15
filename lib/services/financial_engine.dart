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

    // Il budget mensile si basa sulle entrate e sulle uscite inserite.
    // Il saldo reale serve invece a valutare il rischio di scoperto: non va
    // sommato alle entrate né sottratto di nuovo per ogni movimento, perché
    // normalmente quei movimenti sono già riflessi nel saldo del conto.
    final expenses = movements
        .where((m) => m.amount > 0)
        .fold(0.0, (sum, m) => sum + m.amount);
    final extraIncome = movements
        .where((m) => m.amount < 0)
        .fold(0.0, (sum, m) => sum + m.amount.abs());

    // Se una spesa ricorrente risulta già registrata questo mese con la stessa
    // descrizione, non riserviamo una seconda volta il suo equivalente mensile.
    final paidNames = movements
        .where((m) => m.amount > 0)
        .map((m) => m.merchant.trim().toLowerCase())
        .toSet();
    final recurringMonthly = recurring.fold<double>(0.0, (sum, expense) {
      final alreadyRecorded = paidNames.contains(expense.name.trim().toLowerCase());
      return sum + (alreadyRecorded ? 0.0 : expense.monthlyEquivalent);
    });

    final recovery = account.currentBalance < 0
        ? [150.0, income.amount * .10, account.currentBalance.abs()]
            .reduce((a, b) => a < b ? a : b)
        : 0.0;

    final raw = income.amount + extraIncome - expenses - recurringMonthly - recovery;
    final spendable = raw > 0 ? raw : 0.0;

    final day = salaryDay.clamp(1, 28);
    DateTime nextIncome = DateTime(d.year, d.month, day);
    if (!nextIncome.isAfter(d)) {
      nextIncome = DateTime(d.year, d.month + 1, day);
    }
    final days = nextIncome.difference(d).inDays.clamp(1, 31);
    final weekly = spendable / (days / 7.0);

    FinancialStatus status = FinancialStatus.stable;
    if (account.currentBalance < 0) {
      status = account.overdraftLimit > 0 &&
              account.currentBalance.abs() >= account.overdraftLimit * .9
          ? FinancialStatus.critical
          : FinancialStatus.recovery;
    } else if (income.amount > 0 && spendable < income.amount * .15) {
      status = FinancialStatus.attention;
    }

    return FinancialPlan(
      income: income.amount,
      recurringMonthly: recurringMonthly,
      spentThisMonth: expenses,
      currentBalance: account.currentBalance,
      recoveryAmount: recovery,
      spendableUntilSalary: spendable,
      weeklySpendable: weekly,
      daysUntilSalary: days,
      status: status,
    );
  }
}
