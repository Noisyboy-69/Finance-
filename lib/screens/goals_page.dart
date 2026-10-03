
import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../models/models.dart';
import '../main.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});
  @override State<GoalsPage> createState()=>_GoalsPageState();
}
class _GoalsPageState extends State<GoalsPage> {
  List<Goal> goals=[];
  @override void initState(){super.initState();load();}
  Future<void> load() async { final x=await AppDatabase.instance.goals(); if(mounted)setState(()=>goals=x); }
  Future<void> addGoal() async {
    final name=TextEditingController(),target=TextEditingController(),current=TextEditingController(text:'0'),monthly=TextEditingController(text:'0');
    await showDialog(context:context,builder:(c)=>AlertDialog(
      title:const Text('Nuovo obiettivo'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,decoration:const InputDecoration(labelText:'Nome')),
        const SizedBox(height:12),TextField(controller:target,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Importo obiettivo')),
        const SizedBox(height:12),TextField(controller:current,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Già accantonato')),
        const SizedBox(height:12),TextField(controller:monthly,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Contributo mensile')),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Annulla')),FilledButton(onPressed:()async{
        final t=double.tryParse(target.text.replaceAll(',','.'))??0;if(t<=0||name.text.trim().isEmpty)return;
        await AppDatabase.instance.saveGoal(Goal(id:'g_${DateTime.now().microsecondsSinceEpoch}',name:name.text.trim(),target:t,current:double.tryParse(current.text.replaceAll(',','.'))??0,monthlyContribution:double.tryParse(monthly.text.replaceAll(',','.'))??0));
        if(c.mounted)Navigator.pop(c);await load();
      },child:const Text('Salva'))],
    ));
  }
  Future<void> updateCurrent(Goal g) async {
    final v=TextEditingController(text:g.current.toStringAsFixed(2));
    await showDialog(context:context,builder:(c)=>AlertDialog(title:Text(g.name),content:TextField(controller:v,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Accantonato ora')),actions:[
      TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Annulla')),FilledButton(onPressed:()async{await AppDatabase.instance.saveGoal(Goal(id:g.id,name:g.name,target:g.target,current:double.tryParse(v.text.replaceAll(',','.'))??g.current,monthlyContribution:g.monthlyContribution));if(c.mounted)Navigator.pop(c);await load();},child:const Text('Aggiorna'))
    ]));
  }
  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:bg,
    floatingActionButton:FloatingActionButton.extended(onPressed:addGoal,backgroundColor:green,foregroundColor:Colors.white,icon:const Icon(Icons.add),label:const Text('Obiettivo')),
    body:ListView(padding:const EdgeInsets.fromLTRB(20,22,20,100),children:[
      const Text('Obiettivi',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800)),
      const SizedBox(height:5),const Text('Traguardi separati dal budget quotidiano.',style:TextStyle(color:Colors.black54)),
      const SizedBox(height:16),
      if(goals.isEmpty)Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:const Text('Crea un obiettivo: casa, vacanza, auto, acquisto importante o altro.')),
      ...goals.map((g) => GestureDetector(
        onTap: () => updateCurrent(g),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      g.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text('${(g.progress * 100).toStringAsFixed(0)}%'),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: g.progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 8),
              Text(
                '${euro(g.current)} di ${euro(g.target)} · ${euro(g.monthlyContribution)}/mese',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 5),
              const Text(
                'Tocca per aggiornare',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      )),
    ]),
  );
}
