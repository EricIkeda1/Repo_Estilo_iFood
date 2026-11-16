import 'package:flutter/material.dart';
import 'api.dart';
import 'ui.dart';
import 'shop.dart';
import 'orders.dart';
void main()=>runApp(MaterialApp(debugShowCheckedModeBanner:false,title:'EYI Food',theme:ThemeData(useMaterial3:true,scaffoldBackgroundColor:Colors.white,colorScheme:ColorScheme.fromSeed(seedColor:red,primary:red,surface:Colors.white)),home:const AuthScreen()));
class AuthScreen extends StatefulWidget{
 const AuthScreen({super.key});@override State<AuthScreen> createState()=>_AuthState();
}
class _AuthState extends State<AuthScreen>{
 final fields=List.generate(4,(_)=>TextEditingController());
 bool register=false,busy=false,hide=true,confirmHide=true;
 @override void dispose(){for(final f in fields){f.dispose();}super.dispose();}
 Future<void> submit()async{
 if(fields[1].text.trim().isEmpty || fields[2].text.isEmpty){
   notice(context,'Informe seu e-mail e sua senha.');return;
 }
 if(register && (fields[0].text.trim().isEmpty || fields[2].text.length < 8)){
   notice(context,'Informe seu nome e use uma senha com pelo menos 8 caracteres.');return;
 }
 if(register&&fields[2].text!=fields[3].text){notice(context,'As senhas precisam coincidir.');return;}
 setState(()=>busy=true);
 try{await api.sign(register,fields[0].text,fields[1].text.trim(),fields[2].text);
 if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>api.merchant?const Dashboard():const ShopHome()));
 }catch(e){if(mounted)notice(context,e.toString());}finally{if(mounted)setState(()=>busy=false);}
 }
 Widget field(int i,String text,IconData icon)=>Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(controller:fields[i],keyboardType:i==1?TextInputType.emailAddress:TextInputType.text,obscureText:i==2?hide:i==3&&confirmHide,decoration:InputDecoration(labelText:text,filled:true,fillColor:grey,prefixIcon:Icon(icon),suffixIcon:i<2?null:IconButton(onPressed:()=>setState(()=>i==2?hide=!hide:confirmHide=!confirmHide),icon:Icon((i==2?hide:confirmHide)?Icons.visibility_outlined:Icons.visibility_off_outlined)),border:OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:BorderSide.none),contentPadding:const EdgeInsets.symmetric(vertical:22))));
 @override Widget build(BuildContext c)=>PageBody([gap(38),const Text.rich(TextSpan(text:'EYI ',children:[TextSpan(text:'Food',style:TextStyle(color:red))]),style:TextStyle(fontSize:42,fontWeight:FontWeight.w900)),gap(44),title(register?'Crie sua conta':'Entre na sua conta',34),gap(38),if(register)field(0,'Nome completo',Icons.person_outline),field(1,'E-mail',Icons.mail_outline),field(2,'Senha',Icons.lock_outline),if(register)field(3,'Confirmar senha',Icons.lock_outline),if(!register)Align(alignment:Alignment.centerRight,child:TextButton(onPressed:()=>notice(c,'Recuperação por e-mail ainda indisponível.'),child:const Text('Esqueci minha senha'))),gap(18),action(busy?'Aguarde…':register?'Criar conta':'Entrar',busy?null:submit),gap(28),panel(TextButton(onPressed:busy?null:()=>setState((){register=!register;fields[3].clear();}),child:Text(register?'Já tem uma conta?   Entrar':'Ainda não tem uma conta?   Criar conta')),pad:2)]);
}
