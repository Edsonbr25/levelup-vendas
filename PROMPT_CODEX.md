\# LEVELUP VENDAS



Crie a estrutura inicial completa do app LevelUp Vendas em Flutter Web.



\## STACK



\- Flutter Web

\- Dart

\- Riverpod

\- GoRouter

\- Supabase

\- Material 3

\- Responsivo mobile-first

\- Tema escuro moderno



\## OBJETIVO



O app será um dashboard pessoal de vendas e metas para uso diário.



O usuário irá:



\- cadastrar metas mensais e semanais

\- cadastrar vendas diárias

\- acompanhar percentual atingido

\- visualizar comissão estimada

\- visualizar evolução de nível

\- acompanhar metas da loja

\- registrar desafios ganhos



\## IDENTIDADE



Nome:

LevelUp Vendas



Usuário inicial:

Edson



Cargo:

Coordenador de Vendas — I Like Mobis Wallig



\## VISUAL



Criar interface moderna estilo:

\- app financeiro

\- gamificação

\- produtividade



Características:

\- dark mode

\- preto/cinza escuro

\- textos claros com alto contraste

\- cards arredondados

\- animações suaves

\- layout extremamente responsivo para celular

\- dashboard limpo



\## ESTRUTURA DE PASTAS



Criar arquitetura organizada:



lib/

&#x20; core/

&#x20;   theme/

&#x20;   constants/

&#x20;   utils/

&#x20; features/

&#x20;   dashboard/

&#x20;   metas/

&#x20;   vendas/

&#x20;   desafios/

&#x20;   gamificacao/

&#x20; shared/

&#x20;   widgets/

&#x20; routes/

&#x20; services/



\## TELAS



Criar inicialmente:



\### DashboardPage



Com:

\- resumo de vendas

\- resumo da loja

\- percentual mensal

\- percentual semanal

\- barra de progresso

\- card de comissão estimada

\- card de nível atual

\- card de pontos



\### MetasPage



Cadastrar:

\- meta mensal individual

\- meta semanal individual

\- meta mensal loja

\- meta semanal loja



Mostrar:

\- meta diária automática



\### VendasPage



Cadastrar:

\- venda individual diária

\- venda loja diária



Mostrar:

\- percentual atualizado

\- comissão atualizada



\### DesafiosPage



Cadastrar ganhos:

\- desafio meta loja

\- desafio p.a

\- desafio maior boleta



\## REGRAS DE COMISSÃO



\### Individual



< 90% = 0%



>= 90% = 3%



>= 100% = 5%



>= 120% = 6%



\### Loja



< 95% = 0%



>= 95% = 0.5%



>= 100% = 2%



>= 120% = 3%



\## GAMIFICAÇÃO



Criar sistema inicial de pontos:



\- atingir meta diária individual = +10 XP

\- atingir meta diária loja = +20 XP



Criar níveis:

\- Bronze

\- Prata

\- Ouro

\- Diamante

\- Lenda



\## RESPONSIVIDADE



Toda interface deve funcionar perfeitamente em mobile.



\## TEMA



Criar tema dark global usando Material 3.



\## ROTEAMENTO



Usar GoRouter.



\## GERENCIAMENTO



Usar Riverpod.



\## IMPORTANTE



\- código limpo

\- componentes reutilizáveis

\- evitar arquivos gigantes

\- separar widgets

\- deixar preparado para Supabase

\- não implementar login agora

\- gerar dados mockados inicialmente

\- criar navegação bottom navigation para mobile

