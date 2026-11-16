import {randomBytes,scrypt as derive,createHash,timingSafeEqual} from 'node:crypto';
import {promisify} from 'node:util';
const scrypt=promisify(derive);
const database=process.env.DATABASE_URL;
const db={async query(query,params=[]){
 const host=new URL(database).hostname;
 const response=await fetch('https://'+host+'/sql',{method:'POST',headers:{'Content-Type':'application/json','Neon-Connection-String':database,'Neon-Raw-Text-Output':'false','Neon-Array-Mode':'false'},body:JSON.stringify({query,params:params.map(v=>Array.isArray(v)?'{'+v.map(x=>JSON.stringify(x)).join(',')+'}':v)})});
 if(!response.ok)throw Error('database');
 const result=await response.json();
 for(const row of result.rows){for(const key of ['id','user_id','quantity','total'])if(key in row)row[key]=Number(row[key]);if(typeof row.merchant==='string')row.merchant=['true','t'].includes(row.merchant);if(typeof row.extras==='string')row.extras=row.extras.slice(1,-1).split(',').filter(Boolean).map(x=>x.replace(/^"|"$/g,''));}
 return result;
}};
const prices={'Queijo extra':400,'Bacon crocante':500,'Cebola caramelizada':300,'Picles':200};
const hash=value=>createHash('sha256').update(value).digest('hex');
async function auth(req,res){
 const {name,email,password}=req.body??{}, action=req.params.action;
 if(!['login','register'].includes(action)||typeof email!=='string'||!/^\S+@\S+\.\S+$/.test(email)||typeof password!=='string'||password.length>256) return res.status(400).json({error:'Confira seu e-mail e senha.'});
 const address=email.trim().toLowerCase();
 let user;
 if(action==='register'){
  if(!name?.trim()||password.length<8)return res.status(400).json({error:'Informe o nome e uma senha com 8 caracteres ou mais.'});
  const salt=randomBytes(16).toString('hex'), key=await scrypt(password,salt,64);
  const result=await db.query('INSERT INTO food_users(name,email,digest) VALUES($1,$2,$3) ON CONFLICT DO NOTHING RETURNING *',[name.trim(),address,salt+'.'+key.toString('hex')]);
  user=result.rows[0];if(!user)return res.status(409).json({error:'E-mail já cadastrado.'});
 }else{
  user=(await db.query('SELECT * FROM food_users WHERE email=$1',[address])).rows[0];
  const [salt,key]=user?.digest.split('.')??['unknown','00'.repeat(64)];
  if(!timingSafeEqual(await scrypt(password,salt,64),Buffer.from(key,'hex'))||!user)return res.status(401).json({error:'E-mail ou senha incorretos.'});
 }
 const token=randomBytes(32).toString('hex');
 await db.query("INSERT INTO food_sessions VALUES($1,$2,now()+interval '7 days')",[hash(token),user.id]);
 return res.json({token,name:user.name,merchant:user.merchant});
}
async function orders(req,res){
 const q=req.user.merchant?'SELECT * FROM food_orders ORDER BY id DESC':'SELECT * FROM food_orders WHERE user_id=$1 ORDER BY id DESC';
 return res.json((await db.query(q,req.user.merchant?[]:[req.user.id])).rows);
}
async function place(req,res){
 const {quantity,extras,address,payment,request_id}=req.body??{};
 if(!Number.isInteger(quantity)||quantity<1||quantity>20||!Array.isArray(extras)||extras.some(x=>!Object.hasOwn(prices,x))||new Set(extras).size!==extras.length||typeof address!=='string'||!address.trim()||!['Pix','Cartão'].includes(payment)||!/^\w{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}$/i.test(request_id))return res.status(400).json({error:'Confira os dados do pedido.'});
 const total=(3290+extras.reduce((s,x)=>s+prices[x],0))*quantity+500;
 const result=await db.query('INSERT INTO food_orders(user_id,request_id,quantity,extras,address,payment,total) VALUES($1,$2,$3,$4,$5,$6,$7) ON CONFLICT(user_id,request_id) DO UPDATE SET request_id=excluded.request_id RETURNING *',[req.user.id,request_id,quantity,extras,address,payment,total]);
 return res.json(result.rows[0]);
}
async function advance(req,res){
 if(!req.user.merchant)return res.sendStatus(403);
 const steps={Recebido:'Em preparo','Em preparo':'Saiu para entrega','Saiu para entrega':'Entregue'};
 const from=req.body.status;if(!Object.hasOwn(steps,from))return res.sendStatus(400);
 const r=await db.query('UPDATE food_orders SET status=$1 WHERE id=$2 AND status=$3 RETURNING *',[steps[from],req.params.id,from]);
 if(!r.rowCount)return res.status(409).json({error:'Atualize a fila.'});return res.json(r.rows[0]);
}

const headers={'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization,content-type','Access-Control-Allow-Methods':'GET,POST,OPTIONS','Cache-Control':'no-store'};
function reply(data,status=200){return Response.json(data,{status,headers});}
export default {async fetch(request){
 const path=new URL(request.url).pathname.replace(/\/$/,'');
 if(request.method==='OPTIONS')return new Response(null,{status:204,headers});
 try{
 const res={code:200,status(n){this.code=n;return this;},json(data){return reply(data,this.code);},sendStatus(n){return reply({error:'Operação indisponível.'},n);}};
 const req={params:{},body:{}};
 if(request.method==='POST'){const raw=await request.text();if(raw.length>8192)return reply({},413);try{req.body=JSON.parse(raw);}catch{return reply({},400);}}
 if(path==='/health'){await db.query('SELECT 1');return reply({ok:true});}
 if(request.method==='POST'&&['/auth/login','/auth/register'].includes(path)){
 req.params.action=path.split('/').pop();
 const address=String(req.body?.email??'').trim().toLowerCase();
 const bucket=hash(address+':'+Math.floor(Date.now()/600000));
 const limit=await db.query("INSERT INTO food_auth_limits(bucket,expires) VALUES($1,now()+interval '10 minutes') ON CONFLICT(bucket) DO UPDATE SET attempts=food_auth_limits.attempts+1 RETURNING attempts",[bucket]);
 if(Number(limit.rows[0].attempts)>50)return reply({error:'Tente novamente em alguns minutos.'},429);
 return await auth(req,res);}
 const token=request.headers.get('authorization')??'';
 if(!/^Bearer [a-f0-9]{64}$/.test(token))return reply({error:'Entre novamente.'},401);
 req.user=(await db.query('SELECT u.id,u.merchant FROM food_sessions s JOIN food_users u ON u.id=s.user_id WHERE token_hash=$1 AND expires>now()',[hash(token.slice(7))])).rows[0];
 if(!req.user)return reply({error:'Entre novamente.'},401);
 if(path==='/orders'&&request.method==='GET')return await orders(req,res);
 if(path==='/orders'&&request.method==='POST')return await place(req,res);
 const match=path.match(/^\/orders\/(\d+)\/advance$/);
 if(match&&request.method==='POST'){req.params.id=match[1];return await advance(req,res);}
 return reply({},404);
 }catch{return reply({error:'Falha ao acessar o serviço.'},500);}
}};
