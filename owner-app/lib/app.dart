import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/dashboard/dashboard_screen.dart';

class TurboTronixApp extends StatelessWidget {
  const TurboTronixApp({super.key});
  @override Widget build(BuildContext context){
    final router=GoRouter(initialLocation:'/',redirect:(context,state){final initialized=Supabase.instance.client;final user=initialized.auth.currentUser;if(user==null&&state.uri.path!='/login')return '/login';return null;},routes:[GoRoute(path:'/login',builder:(context,state)=>const _LoginScreen()),GoRoute(path:'/',builder:(context,state)=>const DashboardScreen())]);
    return MaterialApp.router(title:'TurboTronix Owner',theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF1558B0)),useMaterial3:true),routerConfig:router);
  }
}
class _LoginScreen extends StatefulWidget{const _LoginScreen();@override State<_LoginScreen>createState()=>_LoginScreenState();}
class _LoginScreenState extends State<_LoginScreen>{final email=TextEditingController();final password=TextEditingController();String?error;bool busy=false;Future<void>login()async{setState(()=>busy=true);try{await Supabase.instance.client.auth.signInWithPassword(email:email.text,password:password.text);if(mounted)context.go('/');}catch(e){setState(()=>error=e.toString);}finally{if(mounted)setState(()=>busy=false);}}@override Widget build(BuildContext context)=>Scaffold(body:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:420),child:Card(margin:const EdgeInsets.all(24),child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('TurboTronix Owner',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:20),TextField(controller:email,decoration:const InputDecoration(labelText:'Email'),keyboardType:TextInputType.emailAddress),const SizedBox(height:12),TextField(controller:password,decoration:const InputDecoration(labelText:'Password'),obscureText:true),if(error!=null)Text(error!,style:const TextStyle(color:Colors.red)),const SizedBox(height:20),FilledButton(onPressed:busy?null:login,child:busy?const CircularProgressIndicator():const Text('Login'))]))))));}
