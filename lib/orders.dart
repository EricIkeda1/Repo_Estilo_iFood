import 'dart:async';
import 'package:flutter/material.dart';
import 'api.dart';
import 'ui.dart';
import 'main.dart';
typedef Order=Map<String,dynamic>;
mixin Feed<T extends StatefulWidget> on State<T>{
 List<Order> orders=[];String? error;bool fetching=false;Timer? timer;
 @override void initState(){super.initState();refresh();timer=Timer.periodic(const Duration(seconds:8),(_)=>refresh());}
 Future<void> refresh()async{if(fetching)return;fetching=true;try{final data=await api.call('/orders');if(mounted)setState((){orders=List<Order>.from(data);error=null;});}catch(e){if(mounted)setState(()=>error=e.toString());}finally{fetching=false;}}
 @override void dispose(){timer?.cancel();super.dispose();}
 Widget feedback()=>error==null?const SizedBox.shrink():TextButton(onPressed:refresh,child:Text('$error · Tentar novamente'));
}
class OrderList extends StatefulWidget{const OrderList({super.key});@override State<OrderList> createState()=>_Orders();}
class _Orders extends State<OrderList> with Feed<OrderList>{
 @override Widget build(BuildContext c)=>Column(children:[feedback(),if(orders.isEmpty)Text(fetching?'Carregando…':'Você ainda não tem pedidos.'),for(final o in orders)Card(child:ListTile(onTap:()=>open(c,Tracking(o)),leading:const Icon(Icons.receipt_long),title:Text('Pedido #${o['id']} · Casa do Smash'),subtitle:Text(o['status']),trailing:Text(money(o['total']))))]);
}
class Tracking extends StatefulWidget{final Order order;const Tracking(this.order,{super.key});@override State<Tracking> createState()=>_Tracking();}
class _Tracking extends State<Tracking> with Feed<Tracking>{
 @override Widget build(BuildContext c){
 final o=orders.firstWhere((e)=>e['id']==widget.order['id'],orElse:()=>widget.order);
 final status=o['status'], moving=status=='Saiu para entrega',done=status=='Entregue';
 return PageBody([title('EYI Food',34),gap(),backTitle(c,'Rastreio do pedido'),const Text('Acompanhe as atualizações da entrega'),gap(),ClipRRect(borderRadius:BorderRadius.circular(22),child:AspectRatio(aspectRatio:1.08,child:Stack(fit:StackFit.expand,children:[CustomPaint(painter:RouteMap()),const Positioned(left:14,top:20,child:Chip(avatar:Icon(Icons.restaurant),label:Text('Casa do Smash'))),const Positioned(right:10,top:0,child:Chip(label:Text('Ibiporã PR'))),Align(alignment:Alignment(done ? 0.60 : moving ? -0.08 : -0.69,done ? 0.64 : moving ? 0.05 : -0.42),child:const CircleAvatar(backgroundColor:grey,child:Icon(Icons.delivery_dining,color:ink))),const Align(alignment:Alignment(.67,.59),child:Icon(Icons.home,size:32)),const Positioned(left:12,bottom:8,child:Text('Trajeto ilustrativo',style:TextStyle(fontSize:11)))]))),gap(),panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Center(child:SizedBox(width:48,child:Divider(thickness:4))),gap(),const Text('Status do pedido'),title(status,32),gap(),ListTile(leading:const Icon(Icons.delivery_dining),title:const Text('Entrega'),subtitle:Text(o['address'])),const Divider(),pair('Pedido #${o['id']}','Casa do Smash'),pair('Entrega',money(500))])),feedback()]);
 }}
class RouteMap extends CustomPainter{
 @override void paint(Canvas canvas,Size s){canvas.scale(s.width/400,s.height/380);canvas.drawRect(const Rect.fromLTWH(0,0,400,380),Paint()..color=const Color(0xfffafafa));final street=Paint()..color=const Color(0xffe5e7e8)..strokeWidth=4..style=PaintingStyle.stroke;
 for(int i=-2;i<9;i++){final x=i*63.0;canvas.drawPath(Path()..moveTo(x,-5)..lineTo(x-30,95)..lineTo(x-6,180)..lineTo(x-39,282)..lineTo(x-60,385),street);}
 for(int i=0;i<7;i++){final y=i*65.0;canvas.drawPath(Path()..moveTo(0,y)..lineTo(95,y+17)..lineTo(200,y-5)..lineTo(300,y+23)..lineTo(405,y-4),street);}
 final path=Path()..moveTo(61,112)..cubicTo(155,111,35,195,118,195)..cubicTo(248,195,174,284,243,285)..lineTo(326,309);
 canvas.drawPath(path,Paint()..color=red..strokeWidth=7..strokeCap=StrokeCap.round..style=PaintingStyle.stroke);for(final p in [const Offset(61,112),const Offset(326,309)]){canvas.drawCircle(p,9,Paint()..color=Colors.white);canvas.drawCircle(p,6,Paint()..color=red);}}
 @override bool shouldRepaint(RouteMap old)=>false;
}
class Dashboard extends StatefulWidget{const Dashboard({super.key});@override State<Dashboard> createState()=>_Dashboard();}
class _Dashboard extends State<Dashboard> with Feed<Dashboard>{
 int page=0;final pending=<int>{};
 Future<void> advance(Order o)async{final id=o['id'] as int;if(!pending.add(id))return;setState((){});try{await api.call('/orders/$id/advance',{'status':o['status']});await refresh();}catch(e){if(mounted)notice(context,e.toString());}finally{pending.remove(id);if(mounted)setState((){});}}
 Widget queue(){final active=orders.where((o)=>o['status']!='Entregue').toList();return panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[title('Fila de pedidos'),Text('${active.length} pedidos em andamento'),gap(),for(final o in active)Card(color:Colors.white,child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[title('#${o['id']}   ·   ${o['status']}',17),gap(),Text("${o['quantity']}× Duplo Smash"),Text((o['extras'] as List).join(', ')),const Divider(),Text(o['address']),pair('Entrega',money(500)),action(switch(o['status']){'Recebido'=>'Aceitar pedido','Em preparo'=>'Enviar para entrega',_=>'Concluir entrega'},pending.contains(o['id'])?null:()=>advance(o))]))),if(active.isEmpty)const Text('Nenhum pedido na fila.') ]));}
 Widget overview(){final now=DateTime.now(),hours=List.filled(24,0);final today=orders.where((o){final d=DateTime.parse(o['created']).toLocal();return DateUtils.isSameDay(now,d);}).toList();for(final o in today){hours[DateTime.parse(o['created']).toLocal().hour]++;}final accepted=today.where((o)=>o['status']!='Recebido').toList(),total=accepted.fold<int>(0,(sum,o)=>sum+(o['total'] as int));final peak=hours.fold<int>(1,(a,b)=>a>b?a:b);
 return Column(children:[panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Valor dos pedidos aceitos hoje'),gap(),title(money(total),36),const Align(alignment:Alignment.centerRight,child:Icon(Icons.storefront,size:48))])),gap(),Wrap(spacing:8,runSpacing:8,children:[for(final v in [('Pedidos','${today.length}',Icons.shopping_bag_outlined),('Ticket médio',money(accepted.isEmpty?0:total~/accepted.length),Icons.groups),('Entregas','${today.where((o)=>o['status']=='Entregue').length}',Icons.delivery_dining),('Avaliação','4,8',Icons.star)])SizedBox(width:125,child:panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(v.$3),title(v.$2,17),Text(v.$1)])))]),gap(),panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[title('Vendas por hora'),Text('Pedidos realizados hoje (total: ${today.length})'),gap(),SizedBox(height:112,child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[for(int i=0;i<24;i++)Expanded(child:Tooltip(message:'${i}h · ${hours[i]} pedidos',child:Container(height:2+100*hours[i]/peak,margin:const EdgeInsets.symmetric(horizontal:1),color:hours[i]==peak?red:Colors.grey)))])),pair('0h','23h')]))]);}
 @override Widget build(BuildContext c){final wide=MediaQuery.sizeOf(c).width>=900;final navigation=Column(crossAxisAlignment:CrossAxisAlignment.start,children:[title('EYI Food'),gap(24),for(final a in ['Início','Pedidos','Vendas'])ListTile(selected:page==['Início','Pedidos','Vendas'].indexOf(a),title:Text(a),onTap:()=>setState(()=>page=['Início','Pedidos','Vendas'].indexOf(a))),TextButton(onPressed:(){api.token='';Navigator.pushReplacement(c,MaterialPageRoute(builder:(_)=>const AuthScreen()));},child:const Text('Sair'))]);
 return Scaffold(appBar:wide?null:AppBar(title:const Text('Painel da loja')),drawer:wide?null:Drawer(child:SafeArea(child:navigation)),body:SafeArea(child:Row(children:[if(wide)SizedBox(width:170,child:panel(navigation)),Expanded(child:ListView(padding:const EdgeInsets.all(18),children:[const Text('Dashboard da loja'),title('Casa do Smash',32),const Text('📍 Ibiporã, PR      •      Entrega R\$ 5,00'),gap(),feedback(),if(page==0&&wide)Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(flex:3,child:overview()),const SizedBox(width:12),Expanded(flex:2,child:queue())])else ...[if(page!=1)overview(),gap(),if(page!=2)queue()]]))])));}
}
