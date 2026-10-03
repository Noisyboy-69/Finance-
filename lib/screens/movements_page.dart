
import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../models/models.dart';
import '../main.dart';

class MovementsPage extends StatefulWidget {
  const MovementsPage({super.key});
  @override State<MovementsPage> createState()=>_MovementsPageState();
}
class _MovementsPageState extends State<MovementsPage> {
  List<Movement> items=[];
  String filter='Tutti';
  @override void initState(){super.initState();load();}
  Future<void> load() async { final x=await AppDatabase.instance.movements(); if(mounted)setState(()=>items=x); }
  Future<void> add() async {
    final merchant=TextEditingController();
    final amount=TextEditingController();
    String category='Altro';
    bool income=false;
    await showDialog(context:context,builder:(c)=>StatefulBuilder(builder:(c,setLocal)=>AlertDialog(
      title:Text(income?'Nuova entrata':'Nuova spesa'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        SegmentedButton<bool>(segments:const[ButtonSegment(value:false,label:Text('Spesa')),ButtonSegment(value:true,label:Text('Entrata'))],selected:{income},onSelectionChanged:(v)=>setLocal(()=>income=v.first)),
        const SizedBox(height:12),
        TextField(controller:merchant,decoration:const InputDecoration(labelText:'Descrizione')),
        const SizedBox(height:12),
        TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Importo')),
        const SizedBox(height:12),
        DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'Categoria'),items:categories.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setLocal(()=>category=v??'Altro')),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Annulla')),FilledButton(onPressed:()async{
        final v=double.tryParse(amount.text.replaceAll(',','.'))??0;
        if(v<=0||merchant.text.trim().isEmpty)return;
        await AppDatabase.instance.addMovement(Movement(id:'m_${DateTime.now().microsecondsSinceEpoch}',date:DateTime.now(),merchant:merchant.text.trim(),amount:income?-v:v,category:category,source:'manual'));
        if(c.mounted)Navigator.pop(c); await load();
      },child:const Text('Salva'))],
    )));
  }
  @override Widget build(BuildContext context){
    final list=filter=='Tutti'?items:items.where((x)=>x.category==filter).toList();
    final spent=list.where((x)=>x.amount>0).fold(0.0,(s,x)=>s+x.amount);
    final earned=list.where((x)=>x.amount<0).fold(0.0,(s,x)=>s+x.amount.abs());
    return Scaffold(
      backgroundColor:bg,
      floatingActionButton:FloatingActionButton.extended(onPressed:add,backgroundColor:green,foregroundColor:Colors.white,icon:const Icon(Icons.add),label:const Text('Movimento')),
      body:ListView(padding:const EdgeInsets.fromLTRB(20,22,20,100),children:[
        const Text('Movimenti',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800)),
        const SizedBox(height:5),const Text('Inserisci e correggi le operazioni manualmente.',style:TextStyle(color:Colors.black54)),
        const SizedBox(height:14),
        Row(children:[_stat('Spese',euro(spent)),const SizedBox(width:10),_stat('Entrate extra',euro(earned))]),
        const SizedBox(height:14),
        SizedBox(height:44,child:ListView(scrollDirection:Axis.horizontal,children:['Tutti',...categories].map((x)=>Padding(padding:const EdgeInsets.only(right:8),child:ChoiceChip(label:Text(x),selected:filter==x,onSelected:(_)=>setState(()=>filter=x))).toList())),
        const SizedBox(height:12),
        if(list.isEmpty) _empty('Nessun movimento registrato. Premi “Movimento” per inserirne uno.'),
        ...list.map((m)=>Dismissible(key:ValueKey(m.id),background:Container(color:Colors.red.shade50),onDismissed:(_)=>AppDatabase.instance.deleteMovement(m.id),child:Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),child:Row(children:[
          CircleAvatar(backgroundColor:m.amount<0?const Color(0xFFE2F0E5):const Color(0xFFF3E6DD),child:Icon(m.amount<0?Icons.south_west:Icons.north_east,color:green)),
          const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(m.merchant,style:const TextStyle(fontWeight:FontWeight.w700)),Text('${m.category} · ${m.date.day}/${m.date.month}',style:const TextStyle(color:Colors.black54))])),
          Text('${m.amount<0?'+':'-'} ${euro(m.amount.abs())}',style:TextStyle(fontWeight:FontWeight.w800,color:m.amount<0?green:Colors.black87)),
        ])))),
      ]),
    );
  }
  Widget _stat(String a,String b)=>Expanded(child:Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(color:Colors.black54)),Text(b,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:17))])));
  Widget _empty(String t)=>Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:Text(t));
}
