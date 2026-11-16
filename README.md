# EYI Food
App Flutter da Casa do Smash em Ibiporã. As sete telas usam widgets Material. O cliente acessa uma função HTTPS no Neon para cadastrar usuários, verificar senhas e consultar pedidos. A função usa a conexão PostgreSQL fornecida pela plataforma. Credenciais do banco ficam no servidor.

## Abrir no Windows
Na pasta que contém pubspec.yaml, com Flutter instalado:
~~~powershell
flutter pub get
flutter run -d chrome
~~~
O Chrome abre a tela de login. No primeiro acesso, toque em **Criar conta**, informe nome, e-mail e senha com pelo menos oito caracteres. A conta é gravada no banco. Para testar o login, abra o Perfil, saia e entre novamente com o mesmo e-mail e senha.

Para Android ou iOS, quem já gerou os runners pode usar diretamente **flutter run** e selecionar o dispositivo. Em um clone novo, gere uma vez o runner com o próprio SDK:
~~~sh
flutter create --platforms=android,ios --project-name=eyi_food --org br.com.ericyikeda .
flutter devices
flutter run
~~~
Para distribuir no Android, declare android.permission.INTERNET no manifesto principal (android/app/src/main/AndroidManifest.xml) antes de compilar o APK release. O template de testes que flutter create adicionar pode ser substituído por testes próprios do app.

## Banco de dados
Projeto Neon **eyi-food-api**, branch **main**. As tabelas food_users e food_sessions guardam o cadastro, o hash da senha e o hash do token de sessão. A sessão do aplicativo fica em memória. O endpoint público padrão está em lib/api.dart. O app permite substituir a URL com --dart-define=API_URL para desenvolvimento.

## Loja
Para acessar o painel, cadastre uma segunda conta e promova somente essa conta pelo SQL Editor do projeto:
~~~sql
UPDATE food_users SET merchant = true WHERE email = 'email-da-loja@exemplo.com';
~~~
Após novo login, o lojista pode aceitar pedidos e atualizar a entrega. O acompanhamento consulta as mudanças a cada oito segundos. O mapa é ilustrativo. Pix e cartão registram a preferência de pagamento.

## Código
- lib/main.dart contém cadastro e login.
- lib/shop.dart contém catálogo, produto e checkout.
- lib/orders.dart contém pedidos, acompanhamento e painel.
- web/ inicia o app pelo Flutter Web.
- cloud/index.mjs contém a função hospedada. api/schema.sql contém o esquema SQL.
- assets/ aceita featured.jpg e smash.jpg como fotografias opcionais.
