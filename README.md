# Metas Young

Painel de **metas semestrais** da Young — acompanhamento por pessoa e equipe, com semáforo
verde/vermelho, ranking e evolução no semestre. Feito para incentivar a bater a meta (não é planilha).

Duas versões neste repositório:

- **`web/index.html`** — o site que roda no **Railway** com domínio próprio, usando o **Supabase** da Young como banco, login Google e upload de fotos. É a versão "de produção".
- **`metas-young.html`** — a versão artifact do Claude (banco do próprio Claude). Mantida por histórico; a de produção é a `web/`.

## Arquitetura (versão web / Railway)

- **Frontend**: um único HTML estático (`web/index.html`), servido por `server.js` (Node puro, sem dependências).
- **Banco**: Supabase `young-workspace` (`vvtympzatclvjaqucebr`), schema próprio **`metas`**:
  - `metas.config` (semestre ativo e meses), `metas.people` (pessoas/fotos), `metas.goals` (as metas), `metas.admins` (allowlist de quem edita).
  - DDL completo em [`db/schema.sql`](db/schema.sql). A carga inicial dos dados foi aplicada via SQL (mantida fora deste repositório público).
  - O frontend usa `createClient(..., { db: { schema: 'metas' } })`.
  - **Leitura** restrita a contas `@youngempreendimentos.com.br` (ou admin); a chave publishable é pública e protegida por RLS.
- **Acesso** (RLS):
  - **Ler**: qualquer usuário **logado** (Google @young). Ninguém anônimo lê.
  - **Editar** (números, criar metas, pessoas, fotos): só quem está em `metas_admins` — adm e coordenador administrativo.
- **Fotos**: bucket de Storage `metas-fotos` (leitura pública; upload só admin), geridas pela tela de **Config**.

## Deploy no Railway

1. No Railway: **New Project → Deploy from GitHub repo** → `Young-Empreendimentos/metas-young`.
2. Railway detecta o Node pelo `package.json` e sobe com `npm start` (porta via `PORT`). Não há build nem dependências.
3. Em **Settings → Networking**, gere o domínio do Railway e, se quiser, adicione o **domínio personalizado** (ideal: um subdomínio `*.youngempreendimentos.com.br`, p/ futuramente compartilhar o login dos outros sistemas).
4. No **Supabase → Settings → API → Exposed schemas**, adicione **`metas`** à lista (ao lado de `public`, `graphql_public`, etc.). Sem isso a API REST não enxerga as tabelas do schema `metas`.
5. No **Supabase → Authentication → URL Configuration → Redirect URLs**, adicione a URL do painel (o domínio do Railway e o domínio personalizado). Sem isso o login Google não volta pro site.
6. Cadastre quem pode editar em `metas.admins` (ver o fim de `db/schema.sql`).

## Variáveis

A URL do Supabase e a **chave publishable** (pública, protegida por RLS) estão embutidas em `web/index.html`.
Nada secreto fica no repositório.

## Como atualizar

- **Mensal**: adm/coord entram, ativam **Modo edição** e preenchem o valor do mês em cada card.
- **Novas metas / novo semestre**: botão **+ Nova meta** e a tela de **Config**.

## Próximos passos

- Enviar o resumo no chat (WhatsApp/Chatwoot) todo fim de mês.
- Automatizar indicadores que já existem no Supabase (inadimplência, vendas, leads) — preencher sozinho.
- (Opcional) SSO por cookie compartilhado (`@supabase/ssr`) para login único entre todos os sistemas Young.
