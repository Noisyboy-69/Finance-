
import 'package:flutter/material.dart';
import 'data/app_database.dart';
import 'models/models.dart';
import 'services/financial_engine.dart';
import 'screens/movements_page.dart';
import 'screens/budget_page.dart';
import 'screens/goals_page.dart';
import 'screens/investments_page.dart';
import 'screens/assistant_page.dart';

const green = Color(0xFF356B4D);
const bg = Color(0xFFF6F3EC);

String euro(double v) => '€ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestore Finanze',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: green, brightness: Brightness.light),
        cardTheme: const CardThemeData(color: Colors.white, elevation: 0, margin: EdgeInsets.zero),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
      home: const Startup(),
    );
  }
}

class Startup extends StatefulWidget {
  const Startup({super.key});
  @override State<Startup> createState() => _StartupState();
}
class _StartupState extends State<Startup> {
  bool loading = true;
  bool configured = false;
  @override void initState() { super.initState(); _check(); }
  Future<void> _check() async {
    final done = await AppDatabase.instance.getSetting('onboarding_done');
    if (!mounted) return;
    setState(() { configured = done == '1'; loading = false; });
  }
  @override Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return configured ? const Shell() : const Onboarding();
  }
}

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});
  @override State<Onboarding> createState() => _OnboardingState();
}
class _OnboardingState extends State<Onboarding> {
  final salary = TextEditingController();
  final balance = TextEditingController(text: '0');
  final overdraft = TextEditingController(text: '500');
  final salaryDay = TextEditingController(text: '27');
  int step = 0;
  String incomeStatus = 'estimated';

  Future<void> finish() async {
    final s = double.tryParse(salary.text.replaceAll(',', '.')) ?? 0;
    final b = double.tryParse(balance.text.replaceAll(',', '.')) ?? 0;
    final o = double.tryParse(overdraft.text.replaceAll(',', '.')) ?? 0;
    final day = (int.tryParse(salaryDay.text) ?? 27).clamp(1, 28);
    final now = DateTime.now();
    await AppDatabase.instance.saveIncome(MonthIncome(year: now.year, month: now.month, amount: s, status: incomeStatus == 'actual' ? IncomeStatus.actual : IncomeStatus.estimated));
    await AppDatabase.instance.saveAccount(CurrentAccountStatus(currentBalance:b, overdraftLimit:o));
    await AppDatabase.instance.setting('salary_day', '$day');
    await AppDatabase.instance.setting('onboarding_done', '1');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const Shell()));
  }

  @override Widget build(BuildContext context) {
    final titles = ['Partiamo dal tuo mese', 'Saldo e scoperto', 'Spese ricorrenti'];
    final subs = [
      'Inserisci lo stipendio del mese. Può essere una stima e potrai correggerlo quando arriva.',
      'Il saldo reale e il limite di scoperto restano distinti: lo scoperto non viene trattato come denaro disponibile.',
      'Potrai aggiungere qui assicurazione, bollo, bollette bimestrali, carburante, rate e abbonamenti.'
    ];
    return Scaffold(
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 42, 24, 30),
        children: [
          const Text('Gestore Finanze', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: green)),
          const SizedBox(height: 8),
          Text(titles[step], style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8), Text(subs[step], style: const TextStyle(color: Colors.black54, height: 1.35)),
          const SizedBox(height: 28),
          if (step == 0) ...[
            TextField(controller: salary, keyboardType: const TextInputType.numberWithOptions(decimal:true), decoration: const InputDecoration(labelText:'Entrata mensile')),
            const SizedBox(height:14),
            TextField(controller: salaryDay, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Giorno di accredito abituale (1–28)')),
            const SizedBox(height:14),
            SegmentedButton<String>(segments: const [
              ButtonSegment(value:'estimated', label:Text('Previsto')),
              ButtonSegment(value:'actual', label:Text('Effettivo')),
            ], selected:{incomeStatus}, onSelectionChanged:(v)=>setState(()=>incomeStatus=v.first)),
          ],
          if (step == 1) ...[
            TextField(controller: balance, keyboardType: const TextInputType.numberWithOptions(decimal:true, signed:true), decoration: const InputDecoration(labelText:'Saldo attuale')),
            const SizedBox(height:14),
            TextField(controller: overdraft, keyboardType: const TextInputType.numberWithOptions(decimal:true), decoration: const InputDecoration(labelText:'Limite di scoperto autorizzato')),
          ],
          if (step == 2) ...[
            _onboardInfo('Esempi', 'Assicurazione auto €600/anno → €50/mese\nBolletta €180 ogni 2 mesi → €90/mese\nAbbonamento €15/mese → €15/mese'),
            const SizedBox(height:14),
            _onboardInfo('La logica', 'Prima stabilità e spese necessarie, poi obiettivi e investimenti. Le proposte restano sempre modificabili e richiedono conferma.'),
          ],
          const SizedBox(height:30),
          FilledButton(
            onPressed: step < 2 ? () => setState(() => step++) : finish,
            child: Text(step < 2 ? 'Continua' : 'Entra nella tua dashboard'),
          ),
          if (step > 0) TextButton(onPressed:()=>setState(()=>step--), child:const Text('Indietro')),
        ],
      )),
    );
  }
  Widget _onboardInfo(String title, String text) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
    child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Text(title,style:const TextStyle(fontWeight:FontWeight.w700,fontSize:17)),
      const SizedBox(height:8), Text(text,style:const TextStyle(height:1.4)),
    ]),
  );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override State<Shell> createState() => _ShellState();
}
class _ShellState extends State<Shell> {
  int index = 0;
  late final pages = const [HomePage(), MovementsPage(), BudgetPage(), GoalsPage(), InvestmentsPage(), AssistantPage()];
  @override Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex:index, onDestinationSelected:(i)=>setState(()=>index=i),
        destinations:const [
          NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Home'),
          NavigationDestination(icon:Icon(Icons.receipt_long_outlined),selectedIcon:Icon(Icons.receipt_long),label:'Movimenti'),
          NavigationDestination(icon:Icon(Icons.pie_chart_outline),selectedIcon:Icon(Icons.pie_chart),label:'Budget'),
          NavigationDestination(icon:Icon(Icons.flag_outlined),selectedIcon:Icon(Icons.flag),label:'Obiettivi'),
          NavigationDestination(icon:Icon(Icons.trending_up),selectedIcon:Icon(Icons.trending_up),label:'Investimenti'),
          NavigationDestination(icon:Icon(Icons.auto_awesome_outlined),selectedIcon:Icon(Icons.auto_awesome),label:'Assistente'),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  FinancialPlan? plan;
  CurrentAccountStatus? account;
  MonthIncome? income;
  bool loading = true;

  @override void initState(){super.initState();load();}
  Future<void> load() async {
    final db = AppDatabase.instance;
    final now = DateTime.now();
    final inc = await db.income(now.year, now.month) ?? const MonthIncome(year:0,month:0,amount:0,status:IncomeStatus.estimated);
    final acc = await db.account() ?? const CurrentAccountStatus(currentBalance:0,overdraftLimit:500);
    final recurring = await db.recurring();
    final movements = await db.movements(year:now.year, month:now.month);
    final day = int.tryParse(await db.getSetting('salary_day') ?? '27') ?? 27;
    final p = FinancialEngine.build(income:inc, account:acc, recurring:recurring, movements:movements, salaryDay:day);
    if (!mounted) return;
    setState(() { plan=p; account=acc; income=inc; loading=false; });
  }

  Future<void> editMonth() async {
    final now=DateTime.now();
    final salary=TextEditingController(text:(income?.amount ?? 0).toStringAsFixed(2));
    String status=income?.status==IncomeStatus.actual?'actual':'estimated';
    await showDialog(context:context,builder:(c)=>AlertDialog(
      title:const Text('Entrata del mese'),
      content:StatefulBuilder(builder:(c,setLocal)=>Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:salary,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Importo')),
        const SizedBox(height:12),
        SegmentedButton<String>(segments:const[ButtonSegment(value:'estimated',label:Text('Previsto')),ButtonSegment(value:'actual',label:Text('Effettivo'))],selected:{status},onSelectionChanged:(v)=>setLocal(()=>status=v.first)),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Annulla')),FilledButton(onPressed:()async{
        final value=double.tryParse(salary.text.replaceAll(',','.'))??0;
        await AppDatabase.instance.saveIncome(MonthIncome(year:now.year,month:now.month,amount:value,status:status=='actual'?IncomeStatus.actual:IncomeStatus.estimated));
        if(c.mounted)Navigator.pop(c); await load();
      },child:const Text('Salva'))],
    ));
  }

  Future<void> editAccount() async {
    final b=TextEditingController(text:(account?.currentBalance??0).toStringAsFixed(2));
    final o=TextEditingController(text:(account?.overdraftLimit??500).toStringAsFixed(2));
    await showDialog(context:context,builder:(c)=>AlertDialog(
      title:const Text('Saldo e scoperto'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:b,keyboardType:const TextInputType.numberWithOptions(decimal:true,signed:true),decoration:const InputDecoration(labelText:'Saldo reale')),
        const SizedBox(height:12),
        TextField(controller:o,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Limite scoperto')),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Annulla')),FilledButton(onPressed:()async{
        await AppDatabase.instance.saveAccount(CurrentAccountStatus(currentBalance:double.tryParse(b.text.replaceAll(',','.'))??0,overdraftLimit:double.tryParse(o.text.replaceAll(',','.'))??0));
        if(c.mounted)Navigator.pop(c); await load();
      },child:const Text('Salva'))],
    ));
  }

  @override Widget build(BuildContext context) {
    if (loading) return const Center(child:CircularProgressIndicator());
    final p=plan!;
    final acc=account!;
    final statusText=switch(p.status){FinancialStatus.recovery=>'Recupero in corso',FinancialStatus.critical=>'Attenzione allo scoperto',FinancialStatus.attention=>'Serve un po’ di prudenza',FinancialStatus.stable=>'Situazione sotto controllo'};
    return RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.fromLTRB(20,22,20,30),children:[
      Row(children:[const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Buongiorno 👋',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800)),SizedBox(height:4),Text('Il tuo quadro finanziario',style:TextStyle(color:Colors.black54))])),IconButton(onPressed:editAccount,icon:const Icon(Icons.account_balance_wallet_outlined))]),
      const SizedBox(height:18),
      Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:const Color(0xFFDDE9DF),borderRadius:BorderRadius.circular(28)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Puoi spendere davvero',style:TextStyle(fontSize:16,fontWeight:FontWeight.w600)),
        const SizedBox(height:7),Text(euro(p.spendableUntilSalary),style:const TextStyle(fontSize:36,fontWeight:FontWeight.w800)),
        const SizedBox(height:5),Text('${euro(p.weeklySpendable)} a settimana · ${p.daysUntilSalary} giorni alla prossima entrata'),
        const SizedBox(height:12),Text(statusText,style:const TextStyle(fontWeight:FontWeight.w700)),
      ])),
      const SizedBox(height:12),
      Row(children:[
        _mini('Entrata',euro(p.income),Icons.south_west),
        const SizedBox(width:10),_mini('Spese',euro(p.spentThisMonth),Icons.north_east),
      ]),
      const SizedBox(height:12),
      _card('Situazione',Column(children:[
        _line('Ricorrenti mensili',euro(p.recurringMonthly)),
        _line('Quota rientro',euro(p.recoveryAmount)),
        _line('Saldo reale',euro(p.currentBalance)),
        _line('Scoperto residuo',euro(acc.overdraftRemaining)),
      ])),
      const SizedBox(height:12),
      _card('Entrata del mese',Row(children:[
        Expanded(child:Text('${euro(p.income)} · ${income?.status==IncomeStatus.actual?'Effettiva':'Prevista'}')),
        OutlinedButton(onPressed:editMonth,child:const Text('Modifica')),
      ])),
      const SizedBox(height:12),
      _card('Piano suggerito',Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(p.status==FinancialStatus.recovery
          ? 'Prima rientro graduale dallo scoperto e spese essenziali. Poi risparmio e investimenti.'
          : 'Prima spese e stabilità; poi obiettivi, risparmio e investimenti. Il margine libero resta disponibile per te.'),
        const SizedBox(height:10),
        const Text('Nessun trasferimento o investimento viene eseguito automaticamente.',style:TextStyle(fontWeight:FontWeight.w600)),
      ])),
    ]));
  }
  Widget _mini(String a,String b,IconData icon)=>Expanded(child:Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:Row(children:[Icon(icon,size:20,color:green),const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(color:Colors.black54)),Text(b,style:const TextStyle(fontWeight:FontWeight.w700))]))])));
  Widget _card(String title,Widget child)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w700)),const SizedBox(height:10),child]));
  Widget _line(String a,String b)=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[Expanded(child:Text(a)),Text(b,style:const TextStyle(fontWeight:FontWeight.w600))]));
}
