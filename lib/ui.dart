import 'package:flutter/material.dart';
const red=Color(0xffc51d22), grey=Color(0xfff0f1f2), ink=Color(0xff222325);
String money(int cents)=>'R\$ '+(cents/100).toStringAsFixed(2).replaceAll('.',',');
Widget title(String s,[double size=24])=>Text(s,style:TextStyle(fontSize:size,fontWeight:FontWeight.w800,height:1.1,letterSpacing:-.6));
Widget gap([double h=12])=>SizedBox(height:h);
Widget panel(Widget child,{double pad=14,Color color=grey})=>Container(width:double.infinity,padding:EdgeInsets.all(pad),decoration:BoxDecoration(color:color,borderRadius:BorderRadius.circular(18)),child:child);
Widget action(String s,VoidCallback? on,{IconData? icon})=>SizedBox(width:double.infinity,child:FilledButton(onPressed:on,style:FilledButton.styleFrom(backgroundColor:red,minimumSize:const Size(0,52)),child:Wrap(crossAxisAlignment:WrapCrossAlignment.center,spacing:10,children:[if(icon!=null)Icon(icon),Text(s,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700))])));
Widget photo(String file,double height)=>ClipRRect(borderRadius:BorderRadius.circular(18),child:Image.asset('assets/$file.jpg',width:double.infinity,height:height,fit:BoxFit.cover,errorBuilder:(_,error,stack)=>Container(height:height,color:const Color(0xff352018),alignment:Alignment.center,child:Text("🍔",style:TextStyle(fontSize:height*.66)))));
Widget pair(String a,String b)=>Padding(padding:const EdgeInsets.symmetric(vertical:4),child:Row(children:[Expanded(child:Text(a)),Text(b,style:const TextStyle(fontWeight:FontWeight.bold))]));
class PageBody extends StatelessWidget{
 final List<Widget> children;final Widget? bottom;
 const PageBody(this.children,{super.key,this.bottom});
 @override Widget build(BuildContext c)=>Scaffold(bottomNavigationBar:bottom,body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:560),child:ListView(padding:const EdgeInsets.all(16),children:children)))));
}
Future<T?> open<T>(BuildContext c,Widget page)=>Navigator.push<T>(c,MaterialPageRoute(builder:(_)=>page));
void notice(BuildContext c,String s)=>ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(s)));
Widget backTitle(BuildContext c,String s)=>Row(children:[IconButton.filledTonal(onPressed:()=>Navigator.pop(c),icon:const Icon(Icons.arrow_back)),const SizedBox(width:12),Expanded(child:title(s))]);
