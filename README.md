# Meu Imóvel

App Flutter para gestão de aluguéis de pequenos proprietários (1–10 imóveis).
Backend: Supabase (Auth + Postgres com RLS).

## O que tem nesta primeira parte

- Login e cadastro por e-mail/senha (Supabase Auth)
- CRUD de imóveis (apelido, endereço, tipo, observações)
- Contratos por imóvel: inquilino, valor, dia de vencimento, início/fim
- Um contrato ativo por imóvel + histórico dos encerrados
- RLS: cada proprietário só vê os próprios dados

## Estrutura

```
lib/
  main.dart                 # init Supabase, tema, AuthGate
  supabase_client.dart
  models/                   # Imovel, Contrato
  data/                     # repositórios (acesso ao Supabase)
  screens/                  # login, lista, form e detalhe de imóvel, form de contrato
supabase/migrations/
  20261022000000_init.sql   # tabelas, índices e políticas RLS
```

## Baixar o APK

Cada push na `main` dispara o workflow **Build APK**, que publica o `app-release.apk`
em [Releases](../../releases).

`supabase.public.json` tem a URL e a anon key do projeto Supabase. A anon key é pública
por design (vai dentro do APK de qualquer jeito); a proteção dos dados é o RLS.

## Como rodar

1. **Supabase:** crie um projeto e rode `supabase/migrations/20261022000000_init.sql`
   no SQL Editor (ou `supabase db push` com a CLI).
   Para testar mais rápido, desative “Confirm email” em Authentication → Providers → Email.

2. **Pastas de plataforma** (este repositório só traz `lib/`):
   ```bash
   flutter create . --project-name meu_imovel --platforms android,ios
   flutter pub get
   ```

3. **Chaves:** crie `env.json` (já está no .gitignore):
   ```json
   { "SUPABASE_URL": "https://SEU-PROJETO.supabase.co", "SUPABASE_ANON_KEY": "sua-anon-key" }
   ```
   e rode:
   ```bash
   flutter run --dart-define-from-file=env.json
   ```

## Próximos passos

- Cobranças mensais (geração a partir do contrato + baixa manual de pagamento)
- Alerta de atraso
- Inquilinos como entidade própria (reaproveitar entre contratos)
- Vistoria (fotos via Supabase Storage) e chamados de manutenção
