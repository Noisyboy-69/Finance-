
enum IncomeStatus { estimated, actual }
enum Recurrence { monthly, everyTwoMonths, quarterly, yearly, oneOff }
enum FinancialStatus { stable, attention, recovery, critical }
enum InvestmentType { etf, stock, crypto, other }

const categories = <String>[
  'Alimentari', 'Casa', 'Trasporti', 'Carburante', 'Ristoranti',
  'Shopping', 'Abbonamenti', 'Tempo libero', 'Viaggi', 'Altro'
];

class MonthIncome {
  final int year, month;
  final double amount;
  final IncomeStatus status;
  const MonthIncome({required this.year, required this.month, required this.amount, required this.status});
  Map<String,Object?> toMap() => {'year': year, 'month': month, 'amount': amount, 'status': status.name};
  factory MonthIncome.fromMap(Map<String,Object?> m) => MonthIncome(
    year: m['year'] as int, month: m['month'] as int,
    amount: (m['amount'] as num).toDouble(),
    status: IncomeStatus.values.firstWhere((e) => e.name == m['status'], orElse: () => IncomeStatus.estimated),
  );
}

class CurrentAccountStatus {
  final double currentBalance, overdraftLimit;
  const CurrentAccountStatus({required this.currentBalance, required this.overdraftLimit});
  double get overdraftUsed => currentBalance < 0 ? currentBalance.abs() : 0;
  double get overdraftRemaining => (overdraftLimit - overdraftUsed).clamp(0, overdraftLimit);
}

class RecurringExpense {
  final int? id;
  final String name, category;
  final double amount;
  final Recurrence recurrence;
  const RecurringExpense({this.id, required this.name, required this.amount, required this.recurrence, required this.category});
  double get monthlyEquivalent {
    switch (recurrence) {
      case Recurrence.monthly: return amount;
      case Recurrence.everyTwoMonths: return amount / 2;
      case Recurrence.quarterly: return amount / 3;
      case Recurrence.yearly: return amount / 12;
      case Recurrence.oneOff: return 0;
    }
  }
  String get recurrenceLabel {
    switch (recurrence) {
      case Recurrence.monthly: return 'Ogni mese';
      case Recurrence.everyTwoMonths: return 'Ogni 2 mesi';
      case Recurrence.quarterly: return 'Trimestrale';
      case Recurrence.yearly: return 'Annuale';
      case Recurrence.oneOff: return 'Una volta';
    }
  }
  Map<String,Object?> toMap() => {'id': id, 'name': name, 'amount': amount, 'recurrence': recurrence.name, 'category': category};
  factory RecurringExpense.fromMap(Map<String,Object?> m) => RecurringExpense(
    id: m['id'] as int?, name: m['name'] as String, amount: (m['amount'] as num).toDouble(),
    recurrence: Recurrence.values.firstWhere((e) => e.name == m['recurrence']),
    category: m['category'] as String,
  );
}

class Movement {
  final String id, merchant, category, source, rawText;
  final DateTime date;
  final double amount;
  const Movement({required this.id, required this.date, required this.merchant, required this.amount, required this.category, required this.source, this.rawText = ''});
  Map<String,Object?> toMap() => {'id': id, 'date': date.toIso8601String(), 'merchant': merchant, 'amount': amount, 'category': category, 'source': source, 'raw_text': rawText};
  factory Movement.fromMap(Map<String,Object?> m) => Movement(
    id: m['id'] as String, date: DateTime.parse(m['date'] as String), merchant: m['merchant'] as String,
    amount: (m['amount'] as num).toDouble(), category: m['category'] as String,
    source: m['source'] as String, rawText: (m['raw_text'] as String?) ?? '',
  );
}

class Goal {
  final String id, name;
  final double target, current, monthlyContribution;
  const Goal({required this.id, required this.name, required this.target, required this.current, this.monthlyContribution = 0});
  double get progress => target <= 0 ? 0 : (current / target).clamp(0, 1);
  Map<String,Object?> toMap() => {'id': id, 'name': name, 'target': target, 'current': current, 'monthly_contribution': monthlyContribution};
  factory Goal.fromMap(Map<String,Object?> m) => Goal(
    id: m['id'] as String, name: m['name'] as String, target: (m['target'] as num).toDouble(),
    current: (m['current'] as num).toDouble(), monthlyContribution: (m['monthly_contribution'] as num).toDouble(),
  );
}

class InvestmentPosition {
  final String id, name;
  final InvestmentType type;
  final double invested, currentValue, monthlyPac;
  final String? platform;
  const InvestmentPosition({required this.id, required this.name, required this.type, required this.invested, required this.currentValue, this.monthlyPac = 0, this.platform});
  double get gain => currentValue - invested;
  double get gainPercent => invested == 0 ? 0 : gain / invested * 100;
  Map<String,Object?> toMap() => {'id': id, 'name': name, 'type': type.name, 'invested': invested, 'current_value': currentValue, 'monthly_pac': monthlyPac, 'platform': platform};
  factory InvestmentPosition.fromMap(Map<String,Object?> m) => InvestmentPosition(
    id: m['id'] as String, name: m['name'] as String,
    type: InvestmentType.values.firstWhere((e) => e.name == m['type']),
    invested: (m['invested'] as num).toDouble(), currentValue: (m['current_value'] as num).toDouble(),
    monthlyPac: (m['monthly_pac'] as num).toDouble(), platform: m['platform'] as String?,
  );
}

class InvestmentAnalysis {
  final InvestmentPosition position;
  final double weight;
  final String risk, trend, summary;
  final List<String> scenarios, risks;
  const InvestmentAnalysis({required this.position, required this.weight, required this.risk, required this.trend, required this.summary, required this.scenarios, required this.risks});
}

class FinancialPlan {
  final double income, recurringMonthly, spentThisMonth, currentBalance, recoveryAmount, spendableUntilSalary, weeklySpendable;
  final int daysUntilSalary;
  final FinancialStatus status;
  const FinancialPlan({required this.income, required this.recurringMonthly, required this.spentThisMonth, required this.currentBalance, required this.recoveryAmount, required this.spendableUntilSalary, required this.weeklySpendable, required this.daysUntilSalary, required this.status});
  double get overdraftLimit => 0;
}
