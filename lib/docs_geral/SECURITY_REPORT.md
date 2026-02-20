# 🔐 Relatório de Segurança — Padoca Express
**Data:** 20/02/2026  
**Analisado por:** Antigravity AI  
**Metodologia:** Análise estática de código + referência MDN HTTP Observatory

---

## 🚨 VULNERABILIDADES CRÍTICAS

### 1. ⚠️ `.env` incluído como asset Flutter (CRÍTICO)
**Arquivo:** `pubspec.yaml` linha 75

```yaml
flutter:
  assets:
    - assets/imagens/
    - .env   # ← PROBLEMA GRAVE!
```

**Por quê é perigoso?**  
Ao incluir `.env` como asset do Flutter Web, o arquivo fica **publicamente acessível** em produção no caminho:  
`https://seu-app.vercel.app/.env`  

Qualquer pessoa pode acessar a URL e obter sua **`SUPABASE_ANON_KEY`** completa.

**Solução imediata:**
```yaml
# REMOVER a linha `- .env` dos assets!
flutter:
  assets:
    - assets/imagens/
    # ← .env REMOVIDO
```

E usar variáveis de ambiente via `--dart-define` no build ou `flutter_dotenv` apenas para builds locais/mobile.

---

### 2. ⚠️ Chave Supabase Anon Key Exposta (CRÍTICO)
**Arquivo:** `.env` linha 3

```
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Status:** A `SUPABASE_ANON_KEY` é um JWT válido e real. Embora a Supabase Anon Key seja projetada para ser "pública", ela **deve ter Row Level Security (RLS) ativado** em todas as tabelas para ser segura. Sem RLS, qualquer pessoa com a chave pode ler/escrever dados diretamente.

**Verificações necessárias no Supabase:**
- ✅ Confirmar que RLS está habilitado em `usuarios`, `clientes`, `estabelecimentos`
- ✅ Confirmar que as políticas de RLS estão corretas

---

### 3. ⚠️ `build/` comitado no repositório (ALTA)
O commit `ae4b0fe` incluiu a pasta `build/web/` no repositório. Isso é problemático porque:
- Aumenta desnecessariamente o tamanho do repo
- Pode expor informações de build

**Solução:** Garantir que `/build/` está no `.gitignore` (já está) e remover os arquivos já comitados:
```bash
git rm -r --cached build/
git commit -m "fix: remove build artifacts from repo"
```

---

## ⚠️ VULNERABILIDADES MÉDIAS

### 4. Headers de Segurança HTTP Faltando (vercel.json)
Baseado no **MDN HTTP Observatory**, seu `vercel.json` atual está **incompleto**.

**Estado atual:**
```json
{
  "headers": [
    {
      "headers": [
        { "key": "Cross-Origin-Embedder-Policy", "value": "require-corp" },
        { "key": "Cross-Origin-Opener-Policy", "value": "same-origin" }
      ]
    }
  ]
}
```

**Headers FALTANDO (reprovaria no MDN Observatory):**

| Header | Status | Impacto |
|--------|--------|---------|
| `Content-Security-Policy` | ❌ Ausente | CRÍTICO — bloqueia XSS |
| `X-Frame-Options` | ❌ Ausente | Previne Clickjacking |
| `X-Content-Type-Options` | ❌ Ausente | Previne MIME sniffing |
| `Referrer-Policy` | ❌ Ausente | Controla dados de referência |
| `Permissions-Policy` | ❌ Ausente | Limita APIs do browser |
| `Strict-Transport-Security` | ❌ Ausente | Força HTTPS |

---

### 5. Dados Bancários Armazenados sem Criptografia (MÉDIA)
**Arquivo:** `cadastro_estabelecimento_state.dart`

Os dados bancários (`banco`, `agencia`, `conta`, `contaDigito`, `titularCpfCnpj`) ficam no estado Riverpod em memória durante o fluxo de 3 etapas. Embora sejam limpos ao sair, idealmente dados sensíveis não deveriam passar por múltiplos estados de UI.

---

### 6. Ausência de `ref.mounted` checks nos Controllers (MÉDIA)
**Arquivos afetados:**
- `login_controller.dart`
- `cadastro_cliente_controller.dart`

Após operações async, o provider pode estar disposed antes da atualização do estado, causando erros silenciosos. Padrão já apontado em conversas anteriores.

---

### 7. `catch (e)` expondo detalhes de erro ao usuário (MÉDIA)
**Arquivo:** `cadastro_estabelecimento_step3_screen.dart` linha 90

```dart
SnackBar(content: Text('Erro no cadastro: $e'))  // ← Expõe stack trace ao usuário!
```

Nunca exponha `$e` diretamente ao usuário — pode vazar informações internas do sistema.

---

### 8. `StorageService` usa `dart:io` (incompatível com Web) (MÉDIA)
**Arquivo:** `storage_service.dart` linha 1

```dart
import 'dart:io';  // ← Não funciona no Flutter Web!

Future<String> uploadCoverImage(File file, String userId) async {
```

O parâmetro `File` é `dart:io.File`, que não existe na Web. Isso vai quebrar o upload de imagem na versão Web.

---

### 9. `index.html` sem meta viewport (BAIXA)
**Arquivo:** `web/index.html`

Falta a tag `<meta name="viewport">` e a descrição está genérica.

---

## ✅ O QUE ESTÁ CORRETO

| Item | Status |
|------|--------|
| `.env` no `.gitignore` | ✅ Correto |
| `.env` nunca comitado diretamente | ✅ Correto |
| Supabase URL/Key via dotenv | ✅ Correto (exceto asset issue) |
| Senhas com `obscureText: true` | ✅ Correto |
| Regex de validação de senha no CadastroCliente | ✅ Correto |
| `SupabaseErrorHandler` com mensagens amigáveis | ✅ Correto |
| RLS patterns via Supabase client | ✅ Correto |
| `mounted` check na SplashScreen | ✅ Correto |
| `flutter_secure_storage` disponível no pubspec | ✅ Disponível (mas não usado) |
| Nenhum `print()` com dados sensíveis no código | ✅ Correto |

---

## 🔧 PLANO DE AÇÃO

### Prioridade IMEDIATA (hoje):
1. **Remover `.env` dos assets** em `pubspec.yaml`
2. **Adicionar headers de segurança** no `vercel.json`
3. **Corrigir mensagem de erro** no `step3_screen.dart`

### Prioridade ALTA (essa semana):
4. **Verificar RLS** no painel Supabase para todas as tabelas
5. **Corrigir `StorageService`** para usar `Uint8List` (compatível com Web)
6. **Adicionar `ref.mounted`** checks nos controllers

### Prioridade MÉDIA (próximas sprints):
7. **Implementar rate limiting** no Supabase (via edge functions)
8. **Adicionar validação de CPF/CNPJ** real (não apenas formato)
9. **Implementar logout automático** por inatividade

---

*Relatório gerado com base em análise estática do código-fonte e diretrizes do MDN HTTP Observatory*
