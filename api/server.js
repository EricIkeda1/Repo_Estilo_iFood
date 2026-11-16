import express from 'express';
import cors from 'cors';
import {rateLimit} from 'express-rate-limit';
import {randomBytes,scrypt as derive,createHash,timingSafeEqual} from 'node:crypto';
import {promisify} from 'node:util';
import {db} from './db.js';
const scrypt=promisify(derive), app=express();
const prices={'Queijo extra':400,'Bacon crocante':500,'Cebola caramelizada':300,'Picles':200};
const hash=value=>createHash('sha256').update(value).digest('hex');
app.use(cors(),express.json({limit:'8kb'}));
app.get('/health',async(req,res)=>{await db.query('SELECT 1');res.json({ok:true});});
app.use('/auth',rateLimit({windowMs:600000,limit:50,message:{error:'Tente novamente em alguns minutos.'}}));
app.post('/auth/:action',async(req,res)=>{
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
 res.json({token,name:user.name,merchant:user.merchant});
});
app.use(async(req,res,next)=>{
 const raw=req.get('authorization')??'';
 const row=(await db.query('SELECT u.id,u.merchant FROM food_sessions s JOIN food_users u ON u.id=s.user_id WHERE token_hash=$1 AND expires>now()',[hash(raw.replace(/^Bearer /,''))])).rows[0];
 if(!row)return res.status(401).json({error:'Entre novamente.'});req.user=row;next();
});
app.get('/orders',async(req,res)=>{
 const q=req.user.merchant?'SELECT * FROM food_orders ORDER BY id DESC':'SELECT * FROM food_orders WHERE user_id=$1 ORDER BY id DESC';
 res.json((await db.query(q,req.user.merchant?[]:[req.user.id])).rows);
});
app.post('/orders',async(req,res)=>{
 const {quantity,extras,address,payment,request_id}=req.body??{};
 if(!Number.isInteger(quantity)||quantity<1||quantity>20||!Array.isArray(extras)||extras.some(x=>!Object.hasOwn(prices,x))||new Set(extras).size!==extras.length||typeof address!=='string'||!address.trim()||!['Pix','Cartão'].includes(payment)||!/^\w{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}$/i.test(request_id))return res.status(400).json({error:'Confira os dados do pedido.'});
 const total=(3290+extras.reduce((s,x)=>s+prices[x],0))*quantity+500;
 const result=await db.query('INSERT INTO food_orders(user_id,request_id,quantity,extras,address,payment,total) VALUES($1,$2,$3,$4,$5,$6,$7) ON CONFLICT(user_id,request_id) DO UPDATE SET request_id=excluded.request_id RETURNING *',[req.user.id,request_id,quantity,extras,address,payment,total]);
 res.json(result.rows[0]);
});
app.post('/orders/:id/advance',async(req,res)=>{
 if(!req.user.merchant)return res.sendStatus(403);
 const steps={Recebido:'Em preparo','Em preparo':'Saiu para entrega','Saiu para entrega':'Entregue'};
 const from=req.body.status;if(!Object.hasOwn(steps,from))return res.sendStatus(400);
 const r=await db.query('UPDATE food_orders SET status=$1 WHERE id=$2 AND status=$3 RETURNING *',[steps[from],req.params.id,from]);
 if(!r.rowCount)return res.status(409).json({error:'Atualize a fila.'});res.json(r.rows[0]);
});
app.use((err,req,res,next)=>{console.error(err.code??err.name);res.status(500).json({error:'Falha ao acessar o serviço.'});});
app.listen(Number(process.env.PORT??3000),'0.0.0.0');
