import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
class Api {
 static const base=String.fromEnvironment('API_URL',defaultValue:'http://localhost:3000');
 String token='',name='';bool merchant=false;
 Future<dynamic> call(String route,[Map<String,dynamic>? data])async{
  final uri=Uri.parse('$base$route'),headers={'Content-Type':'application/json','Authorization':'Bearer $token'};
  final res=await (data==null?http.get(uri,headers:headers):http.post(uri,headers:headers,body:jsonEncode(data))).timeout(const Duration(seconds:20));
  if(res.statusCode>=400){Object? error;try{error=jsonDecode(res.body)['error'];}catch(_){}throw Exception(error??'Falha no serviço (${res.statusCode}).');}
  return jsonDecode(utf8.decode(res.bodyBytes));
 }
 Future<void> sign(bool register,String name,String email,String password)async{
  final r=await call('/auth/${register?'register':'login'}',{'name':name,'email':email,'password':password});
  token=r['token'];this.name=r['name'];merchant=r['merchant'];
 }
}
final api=Api();
String requestId(){final r=Random.secure();String hex(int n)=>List.generate(n,(_)=>r.nextInt(16).toRadixString(16)).join();return '${hex(8)}-${hex(4)}-4${hex(3)}-a${hex(3)}-${hex(12)}';}
