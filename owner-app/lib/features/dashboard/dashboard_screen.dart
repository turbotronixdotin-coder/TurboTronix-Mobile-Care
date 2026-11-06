import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String,dynamic> metrics={'new':0,'ongoing':0,'revenue':0,'low':0};
  List<dynamic> recent=[];
  bool loading=true;
  String? error;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    try{
      final supabase=Supabase.instance.client;
      final bookings=await supabase.from('bookings').select('*').order('created_at',ascending:false);
      final inventory=await supabase.from('inventory').select('*');
      final repairs=await supabase.from('repairs').select('*');
      final low=(inventory as List).where((r)=>(r['quantity']??0)<=(r['minimum_stock']??0)).length;
      final ongoing=(repairs as List).where((r)=>r['repair_status']!='completed').length;
      final today=DateTime.now().toIso8601String().substring(0,10);
      final payments=await supabase.from('payments').select('*').eq('status','success').gte('paid_at','$today 00:00:00');
      double revenue=0;for(final p in payments as List){revenue+=double.tryParse('${p['amount']}')??0;}
      setState(()=>metrics={'new':(bookings as List).where((b)=>b['status']=='requested').length,'ongoing':ongoing,'revenue':revenue,'low':low,'recent':bookings.take(6).toList(),'loading':false});
      recent=(bookings as List).take(6).toList();
    }catch(e){setState(()=>error=e.toString());}
    finally{if(mounted)setState(()=>loading=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('TurboTronix Owner'),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh)),IconButton(onPressed:()=>Supabase.instance.client.auth.signOut(),icon:const Icon(Icons.logout))]),body:loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(16),children:[const Text('Owner Dashboard',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),if(error!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(error!,style:const TextStyle(color:Colors.red))),const SizedBox(height:16),Wrap(spacing:12,runSpacing:12,children:[_Metric('New bookings','${metrics['new']}'),_Metric('Ongoing repairs','${metrics['ongoing']}'),_Metric('Today revenue','₹${metrics['revenue'].toStringAsFixed(0)}'),_Metric('Low-stock parts','${metrics['low']}')]),const SizedBox(height:24),const Text('Recent bookings',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),...recent.map((b)=>Card(child:ListTile(title:Text(b['booking_number']??'Booking'),subtitle:Text('${b['status']} • ₹${b['estimated_total']}'),trailing:const Icon(Icons.chevron_right))))]));
}
class _Metric extends StatelessWidget{const _Metric(this.label,this.value);final String label,value;@override Widget build(BuildContext context)=>SizedBox(width:155,child:Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label),const SizedBox(height:16),Text(value,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold))]))));}
