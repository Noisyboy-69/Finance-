import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../models/models.dart';
import '../services/financial_engine.dart';
import '../main.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});
  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  FinancialStatus status = FinancialStatus.stable;
  double spendable = 0, weekly = 0, income = 0, spent = 0, recurring = 0, balance = 0, recovery = 0;
  int days = 1;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final db = AppDatabase.instance;
    final now = DateTime.now();
    final inc = await db.income(now.year, now.month) ??
        const MonthIncome(year: 0, month: 0, amount: 0, status: IncomeStatus.estimated);
    final acc = await db.account() ??
        const CurrentAccountStatus(currentBalance: 0, overdraftLimit: 500);
    final recurringExpenses = await db.recurring();
    final movements = await db.movements(year: now.year, month: now.month);
    final day = int.tryParse(await db.getSetting('salary_day') ?? '27') ?? 27;
    final plan = FinancialEngine.build(
      income: inc,
      account: acc,
      recurring: recurringExpenses,
      movements: movements,
      salaryDay: day,
    );
    if (!mounted) return;
    setState(() {
      status = plan.status;
      spendable = plan.spendableUntilSalary;
      weekly = plan.weeklySpendable;
      income = plan.income;
      spent = plan.spentThisMonth;
      recurring = plan.recurringMonthly;
      balance = plan.currentBalance;
      recovery = plan.recoveryAmount;
      days = plan.daysUntilSalary;
    });
  }

  @override
  Widget build(BuildContext context) {
    final advice = switch (status) {
      FinancialStatus.recovery =>
        'Il saldo è sotto zero. Dai priorità alle spese essenziali e al rientro; evita nuovi impegni discrezionali finché la situazione non migliora.',
      FinancialStatus.critical =>
        'Lo scoperto è vicino al limite autorizzato. Controlla subito le prossime uscite, proteggi le spese essenziali e rimanda gli investimenti non necessari.',
      FinancialStatus.attention =>
        'Il margine disponibile è basso rispetto all’entrata del mese. Riduci temporaneamente le spese discrezionali e verifica le prossime scadenze.',
      FinancialStatus.stable =>
        'Usa il margine calcolato come tetto prudente: prima copri le scadenze e gli obiettivi prioritari, poi valuta la spesa libera.',
    };

    final budgetTip = spendable <= 0
        ? 'Il calcolo non rileva denaro libero fino alla prossima entrata. Prima di spendere, controlla che entrata, movimenti e spese ricorrenti siano aggiornati.'
        : 'Come riferimento prudente, prova a non superare ${euro(weekly)} a settimana nei prossimi $days giorni. Se arriva una spesa imprevista, sottraila dal margine prima di pianificare altro.';

    final monthRatio = income > 0 ? (spent / income * 100) : 0.0;
    final expenseTip = income <= 0
        ? 'Inserisci l’entrata del mese nella Home per ottenere un budget personalizzato.'
        : 'Hai registrato spese pari al ${monthRatio.toStringAsFixed(0)}% dell’entrata mensile. Il dato si aggiorna quando aggiungi o elimini movimenti.';

    final recoveryTip = balance >= 0
        ? 'Il saldo inserito non è negativo: al momento non viene calcolata una quota di rientro dallo scoperto.'
        : 'È prevista una quota prudenziale di ${euro(recovery)} per il rientro. Verifica il saldo reale e il limite di scoperto dopo ogni aggiornamento.';

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
          children: [
            const Text('Assistente', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            const Text(
              'Coach finanziario offline: usa i dati salvati sul dispositivo, senza account o chiavi API.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            _card('Lettura del momento', Text(advice, style: const TextStyle(height: 1.4))),
            const SizedBox(height: 10),
            _card('Numeri aggiornati', Column(children: [
              _line('Entrata del mese', euro(income)),
              _line('Spese registrate', euro(spent)),
              _line('Ricorrenti ancora da riservare', euro(recurring)),
              _line('Saldo reale del conto', euro(balance)),
              _line('Margine fino alla prossima entrata', euro(spendable)),
              _line('Indicazione settimanale', euro(weekly)),
            ])),
            const SizedBox(height: 10),
            _card('Quanto puoi spendere', Text(budgetTip, style: const TextStyle(height: 1.4))),
            const SizedBox(height: 10),
            _card('Andamento delle spese', Text(expenseTip, style: const TextStyle(height: 1.4))),
            const SizedBox(height: 10),
            _card('Se il saldo è in rosso', Text(recoveryTip, style: const TextStyle(height: 1.4))),
            const SizedBox(height: 10),
            _card(
              'Investimenti',
              const Text(
                'Questa schermata non invia ordini e non fornisce previsioni garantite. Prima di aumentare un PAC, assicurati che il margine resti positivo e che le spese necessarie siano coperte.',
                style: TextStyle(height: 1.4),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Suggerimenti automatici basati sui dati inseriti, non consulenza finanziaria professionale.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, Widget child) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 9),
            child,
          ],
        ),
      );

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );
}
