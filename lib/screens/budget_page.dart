
import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../models/models.dart';
import '../main.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});
  @override State<BudgetPage> createState()=>_BudgetPageState();
}
class _BudgetPageState extends State<BudgetPage> {
  List<Movement> movements=[];
  List<RecurringExpense> recurring=[];
  @override void initState(){super.initState();load();}
  Future<void> load() async {
    final x=await AppDatabase.instance.movements();
    final r=await AppDatabase.instance.recurring();
    if(mounted)setState(()=>{movements=x,recurring=r});
  }
  Future<void> addRecurring() async {
    final name=TextEditingController();
    final amount=TextEditingController();
    String category='Casa';
    Recurrence recurrence=Recurrence.monthly;
    await showDialog(context:context,builder:(c)=>StatefulBuilder(builder:(c,setLocal)=>AlertDialog(
      title:const Text('Spesa ricorrente'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,decoration:const InputDecoration(labelText:'Nome')),
        const SizedBox(height:12),
        TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Importo reale')),
        const SizedBox(height:12),
        DropdownButtonFormField<Recurrence>(value:recurrence,decoration:const InputDecoration(labelText:'Frequenza'),items:Recurrence.values.map((r)=>DropdownMenuItem(value:r,child:Text(_recurrence(r)))).toList(),onChanged:(v)=>setLocal(()=>recurrence=v??Recurrence.monthly)),
        const SizedBox(height:12),
        DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'Categoria'),items:categories.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setLocal(()=>category=v??'Casa')),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Annulla')),FilledButton(onPressed:()async{
        final v=double.tryParse(amount.text.replaceAll(',','.'))??0;
        if(v<=0||name.text.trim().isEmpty)return;
        await AppDatabase.instance.addRecurring(RecurringExpense(name:name.text.trim(),amount:v,recurrence:recurrence,category:category));
        if(c.mounted)Navigator.pop(c); await load();
      },child:const Text('Salva'))],
    )));
  }
  String _recurrence(Recurrence r)=>switch(r){Recurrence.monthly=>'Ogni mese',Recurrence.everyTwoMonths=>'Ogni 2 mesi',Recurrence.quarterly=>'Trimestrale',Recurrence.yearly=>'Annuale',Recurrence.oneOff=>'Una volta'};
  @override Widget build(BuildContext context){
    final totals=<String,double>{};
    for(final m in movements.where((m)=>m.amount>0)){totals[m.category]=(totals[m.category]??0)+m.amount;}
    final monthly=recurring.fold(0.0,(s,r)=>s+r.monthlyEquivalent);
    return Scaffold(
      backgroundColor:bg,
      floatingActionButton:FloatingActionButton.extended(onPressed:addRecurring,backgroundColor:green,foregroundColor:Colors.white,icon:const Icon(Icons.add),label:const Text('Spesa ricorrente')),
      body:ListView(padding:const EdgeInsets.fromLTRB(20,22,20,100),children:[
        const Text('Budget',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800)),
        const SizedBox(height:5),const Text('Le spese periodiche vengono normalizzate su base mensile.',style:TextStyle(color:Colors.black54)),
        const SizedBox(height:14),
        Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:const Color(0xFFDDE9DF),borderRadius:BorderRadius.circular(22)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('Costi ricorrenti mensili equivalenti',style:TextStyle(fontWeight:FontWeight.w600)),
          const SizedBox(height:6),Text(euro(monthly),style:const TextStyle(fontSize:28,fontWeight:FontWeight.w800)),
        ])),
        const SizedBox(height:14),
        const Text('Categorie',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
        const SizedBox(height:8),
        ...categories.map((cat){
          final value=totals[cat]??0;
          final limit=cat=='Alimentari'?300.0:150.0;
          final ratio=(value/limit).clamp(0,1).toDouble();
          final warning=value>limit*.9;
          return Container(margin:const EdgeInsets.only(bottom:9),padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),child:Column(children:[
            Row(children:[Expanded(child:Text(cat,style:const TextStyle(fontWeight:FontWeight.w700))),Text('${euro(value)} / ${euro(limit)}')]),
            const SizedBox(height:8),LinearProgressIndicator(value:ratio,minHeight:7,borderRadius:BorderRadius.circular(8)),
            if(warning) ...[const SizedBox(height:6),Align(alignment:Alignment.centerLeft,child:Text('Attenzione: ritmo di spesa vicino al limite.',style:TextStyle(fontSize:12,fontWeight:FontWeight.w600)))],
          ]));
        }),
        const SizedBox(height:10),
        const Text('Spese ricorrenti',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
        const SizedBox(height:8),
        if(recurring.isEmpty)_empty('Nessuna spesa ricorrente. Aggiungi assicurazione, bollo, bollette, carburante, rate o abbonamenti.'),
        ...recurring.map((r)=>Dismissible(key:ValueKey(r.id),background:Container(color:Colors.red.shade50),onDismissed:(_){if(r.id!=null)AppDatabase.instance.deleteRecurring(r.id!);},child:Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),child:Row(children:[
          const Icon(Icons.repeat,color:green),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(r.name,style:const TextStyle(fontWeight:FontWeight.w700)),Text('${r.category} · ${r.recurrenceLabel}',style:const TextStyle(color:Colors.black54))])),Column(crossAxisAlignment:CrossAxisAlignment.end,children:[Text(euro(r.amount),style:const TextStyle(fontWeight:FontWeight.w700)),Text('${euro(r.monthlyEquivalent)}/mese',style:const TextStyle(color:Colors.black54,fontSize:12))]),
        ])))),
      ]),
    );
  }
  Widget _empty(String text)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),child:Text(text));
}
