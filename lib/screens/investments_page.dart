
import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../models/models.dart';
import '../services/investment_engine.dart';
import '../main.dart';
import 'package:url_launcher/url_launcher.dart';

class InvestmentsPage extends StatefulWidget {
  const InvestmentsPage({super.key});
  @override State<InvestmentsPage> createState()=>_InvestmentsPageState();
}
class _InvestmentsPageState extends State<InvestmentsPage> {
  List<InvestmentPosition> positions=[];
  @override void initState(){super.initState();load();}
  Future<void> load() async {final x=await AppDatabase.instance.investments();if(mounted)setState(()=>positions=x);}
  Future<void> addInvestment() async {
    final name=TextEditingController(),invested=TextEditingController(),value=TextEditingController(),pac=TextEditingController(text:'0'),platform=TextEditingController();
    InvestmentType type=InvestmentType.etf;
    await showDialog(context:context,builder:(c)=>StatefulBuilder(builder:(c,setLocal)=>AlertDialog(
      title:const Text('Aggiungi investimento'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,decoration:const InputDecoration(labelText:'Nome / ticker')),
        const SizedBox(height:12),
        DropdownButtonFormField<InvestmentType>(value:type,decoration:const InputDecoration(labelText:'Tipo'),items:InvestmentType.values.map((x)=>DropdownMenuItem(value:x,child:Text(_type(x)))).toList(),onChanged:(v)=>setLocal(()=>type=v??InvestmentType.etf)),
        const SizedBox(height:12),TextField(controller:invested,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Totale investito')),
        const SizedBox(height:12),TextField(controller:value,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Valore attuale')),
        const SizedBox(height:12),TextField(controller:pac,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'PAC mensile (opzionale)')),
        const SizedBox(height:12),TextField(controller:platform,decoration:const InputDecoration(labelText:'Piattaforma (opzionale)')),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Annulla')),FilledButton(onPressed:()async{
        final inv=double.tryParse(invested.text.replaceAll(',','.'))??0,cur=double.tryParse(value.text.replaceAll(',','.'))??0;
        if(name.text.trim().isEmpty||inv<0)return;
        await AppDatabase.instance.saveInvestment(InvestmentPosition(id:'i_${DateTime.now().microsecondsSinceEpoch}',name:name.text.trim(),type:type,invested:inv,currentValue:cur,monthlyPac:double.tryParse(pac.text.replaceAll(',','.'))??0,platform:platform.text.trim().isEmpty?null:platform.text.trim()));
        if(c.mounted)Navigator.pop(c);await load();
      },child:const Text('Salva'))],
    )));
  }
  String _type(InvestmentType t)=>switch(t){InvestmentType.etf=>'ETF',InvestmentType.stock=>'Azione',InvestmentType.crypto=>'Crypto',InvestmentType.other=>'Altro'};
  Future<void> openRevolut() async {
    final ok=await launchUrl(Uri.parse('revolut://'),mode:LaunchMode.externalApplication);
    if(!ok&&mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Revolut non è disponibile sul dispositivo.')));
  }
  @override Widget build(BuildContext context){
    final total=positions.fold(0.0,(s,p)=>s+p.currentValue);
    final invested=positions.fold(0.0,(s,p)=>s+p.invested);
    final analyses=InvestmentEngine.analyze(positions);
    return Scaffold(
      backgroundColor:bg,
      floatingActionButton:FloatingActionButton.extended(onPressed:addInvestment,backgroundColor:green,foregroundColor:Colors.white,icon:const Icon(Icons.add),label:const Text('Investimento')),
      body:ListView(padding:const EdgeInsets.fromLTRB(20,22,20,100),children:[
        const Text('Investimenti',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800)),
        const SizedBox(height:5),const Text('ETF, azioni e crypto restano separati dal budget ordinario.',style:TextStyle(color:Colors.black54)),
        const SizedBox(height:16),
        Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:const Color(0xFFDDE9DF),borderRadius:BorderRadius.circular(24)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('Valore portafoglio',style:TextStyle(fontWeight:FontWeight.w600)),const SizedBox(height:5),Text(euro(total),style:const TextStyle(fontSize:32,fontWeight:FontWeight.w800)),
          const SizedBox(height:4),Text('Investito ${euro(invested)} · risultato ${euro(total-invested)}'),
        ])),
        const SizedBox(height:14),
        if(positions.isEmpty)Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:const Text('Nessun investimento inserito. Puoi aggiungerne uno con il pulsante in basso.')),
        ...analyses.map((a)=>_analysis(a)),
        const SizedBox(height:8),
        Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('Azioni assistite',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800)),
          const SizedBox(height:7),const Text('L’app può registrare il piano che hai scelto e aprire Revolut. Non compra, vende o trasferisce denaro automaticamente.'),
          const SizedBox(height:10),OutlinedButton.icon(onPressed:openRevolut,icon:const Icon(Icons.open_in_new),label:const Text('Apri Revolut')),
        ])),
      ]),
    );
  }
  Widget _analysis(InvestmentAnalysis a)=>Dismissible(
    key:ValueKey(a.position.id),background:Container(color:Colors.red.shade50),
    onDismissed:(_)=>AppDatabase.instance.deleteInvestment(a.position.id),
    child:Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:Text(a.position.name,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800))),Text('${a.position.gainPercent>=0?'+':''}${a.position.gainPercent.toStringAsFixed(1)}%')]),
      const SizedBox(height:7),Text('Peso ${a.weight.toStringAsFixed(1)}% · Rischio ${a.risk} · Trend ${a.trend}'),
      const SizedBox(height:9),Text(a.summary),
      if(a.risks.isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Text('Attenzione: ${a.risks.join(' · ')}',style:const TextStyle(fontWeight:FontWeight.w700))),
      const SizedBox(height:9),
      ExpansionTile(title:const Text('Scenari'),tilePadding:EdgeInsets.zero,children:a.scenarios.map((s)=>Align(alignment:Alignment.centerLeft,child:Padding(padding:const EdgeInsets.only(bottom:6),child:Text(s)))).toList()),
    ])),
  );
}
