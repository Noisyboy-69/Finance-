
import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../models/models.dart';
import '../services/financial_engine.dart';
import '../main.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});
  @override State<AssistantPage> createState()=>_AssistantPageState();
}
class _AssistantPageState extends State<AssistantPage> {
  FinancialStatus status=FinancialStatus.stable;
  double spendable=0, income=0, spent=0, recurring=0, balance=0;
  @override void initState(){super.initState();load();}
  Future<void> load() async {
    final db=AppDatabase.instance; final now=DateTime.now();
    final inc=await db.income(now.year,now.month)??const MonthIncome(year:0,month:0,amount:0,status:IncomeStatus.estimated);
    final acc=await db.account()??const CurrentAccountStatus(currentBalance:0,overdraftLimit:500);
    final r=await db.recurring(); final m=await db.movements(year:now.year,month:now.month);
    final day=int.tryParse(await db.getSetting('salary_day')??'27')??27;
    final p=FinancialEngine.build(income:inc,account:acc,recurring:r,movements:m,salaryDay:day);
    if(mounted)setState(()=>{status=p.status,spendable=p.spendableUntilSalary,income=p.income,spent=p.spentThisMonth,recurring=p.recurringMonthly,balance=p.currentBalance});
  }
  @override Widget build(BuildContext context){
    final advice=switch(status){
      FinancialStatus.recovery=>'Sei in recupero. Una quota prudente viene destinata al rientro; evita di aumentare il rischio finché il saldo non torna stabile.',
      FinancialStatus.critical=>'Lo scoperto è vicino al limite. Prima proteggi liquidità e spese essenziali; rimanda gli investimenti non necessari.',
      FinancialStatus.attention=>'Il margine libero è stretto rispetto all’entrata. Riduci le spese discrezionali e ricontrolla il budget prima di aumentare il PAC.',
      FinancialStatus.stable=>'Il quadro è stabile: puoi distribuire il margine tra obiettivi, risparmio, investimenti e spesa libera senza compromettere le spese necessarie.',
    };
    return Scaffold(backgroundColor:bg,body:ListView(padding:const EdgeInsets.fromLTRB(20,22,20,30),children:[
      const Text('Assistente',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800)),
      const SizedBox(height:5),const Text('Un coach locale che legge i dati che hai inserito.',style:TextStyle(color:Colors.black54)),
      const SizedBox(height:16),
      _card('Lettura del momento',Text(advice,style:const TextStyle(height:1.4))),
      const SizedBox(height:10),
      _card('Numeri chiave',Column(children:[
        _line('Entrata',euro(income)),_line('Spese registrate',euro(spent)),_line('Ricorrenti mensili',euro(recurring)),_line('Saldo',euro(balance)),_line('Margine fino alla prossima entrata',euro(spendable)),
      ])),
      const SizedBox(height:10),
      _card('Distribuzione prudente di un extra',const Text('Come punto di partenza, un’entrata extra può essere divisa tra stabilità, obiettivi e investimenti. Esempio: €150 → €50 casa/obiettivi, €50 risparmio, €50 investimenti. La proposta è sempre modificabile.')),
      const SizedBox(height:10),
      _card('Recupero dallo scoperto',const Text('Se il saldo è negativo, il piano usa una quota di rientro prudente e protegge prima le spese essenziali. Le categorie discrezionali sono quelle da rivedere per prime.')),
      const SizedBox(height:10),
      _card('Investimenti',const Text('Le analisi sono descrittive e basate sui dati inseriti: rendimento, peso, concentrazione, volatilità e scenari positivo/neutro/negativo. Non sono garanzie e non generano ordini automatici.')),
      const SizedBox(height:10),
      const Text('L’assistente suggerisce; la decisione resta sempre tua.',style:TextStyle(fontWeight:FontWeight.w700)),
    ]));
  }
  Widget _card(String t,Widget child)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800)),const SizedBox(height:9),child]));
  Widget _line(String a,String b)=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[Expanded(child:Text(a)),Text(b,style:const TextStyle(fontWeight:FontWeight.w700))]));
}
