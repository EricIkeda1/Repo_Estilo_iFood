# EYI Food
Aplicativo Flutter de delivery da Casa do Smash em Ibiporã. As telas usam widgets Material editáveis e aceitam fotografias locais opcionais em assets/featured.jpg e assets/smash.jpg. O painel da loja adapta as colunas à largura disponível.

## Instalação
Instale Flutter estável com Dart 3.6 ou superior, Python 3.8+, Node.js 22+ e Git. Para Android, instale também o Android Studio, o SDK e um emulador. Execute `flutter doctor` e resolva os itens da plataforma desejada.

~~~sh
git clone https://github.com/EricIkeda1/Repo_Estilo_iFood.git
cd Repo_Estilo_iFood
python bootstrap.py
~~~

No Linux/macOS use python3. O script gera Android, iOS e Web com os templates oficiais da versão instalada e baixa as dependências do pubspec. Os componentes de interface ficam em lib/main.dart (acesso), shop.dart (vitrine, produto e checkout), orders.dart (pedidos, mapa e painel) e ui.dart (componentes comuns).

## API e Neon
O projeto Neon é eyi-food-flutter (fancy-sea-50456012). No console Neon, abra Connect e copie a URL PostgreSQL com SSL. Na pasta api copie .env.example para .env e substitua DATABASE_URL pela URL privada. Apenas o processo Node lê essa variável. As tabelas já foram criadas. A migração também pode ser repetida em outro banco vazio.

~~~sh
cd api
npm install
npm run migrate
npm start
~~~

A API escuta na porta 3000. Acesse http://localhost:3000/health para verificar a conexão com o Neon. Em outro terminal, na raiz, escolha uma plataforma.

~~~sh
flutter run -d chrome --dart-define=API_URL=http://localhost:3000
flutter run -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:3000
~~~

Use flutter devices para obter o ID correto. Em aparelho físico ou distribuição, use uma API hospedada em HTTPS acessível pelo aparelho. No macOS com Xcode, o runner iOS permite executar pelo simulador. Para gerar o APK de distribuição após configurar assinatura e hospedagem:

~~~sh
flutter build apk --release --dart-define=API_URL=https://SEU-HOST
~~~

## Experimentar o fluxo
Crie uma conta, escolha Casa do Smash, marque adicionais e informe o endereço antes de confirmar. A API recalcula o valor em centavos, guarda o pedido e impede que uma repetição da mesma confirmação duplique a compra. A sessão do cliente fica em memória. Para testar o painel, cadastre uma segunda conta e promova-a pelo SQL Editor no Neon, substituindo o e-mail:

~~~sql
UPDATE food_users SET merchant = true WHERE email = 'email-da-loja@exemplo.com';
~~~

Entre novamente com essa conta em outra janela. Aceite o pedido, envie para entrega e conclua. O acompanhamento do cliente consulta o status a cada oito segundos. O painel calcula os indicadores de pedidos com os registros disponíveis. O mapa é ilustrativo. A avaliação 4,8 vem da referência. Pix e cartão registram a preferência de pagamento. GPS, chat, cobrança e recuperação por e-mail exigem integrações adicionais.
