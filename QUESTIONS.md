# QUESTIONS.md — Code Review & Architecture Audit

> **How to use this file**: Each question is numbered and categorized. Answer each one below its `**Answer:**` line. Once answered, the codebase will be improved based on your answers.
>
> **Status**: Awaiting answers

---

## 1. ARCHITECTURE & PROJECT STRUCTURE

### Q1 — Role of the `admgeral` feature vs `estabelecimento` admin
The folder is named `admgeral` (admin geral / platform admin) while `estabelecimento` has its own dashboard. Is `admgeral` meant to be a **super-admin** for the entire platform (Padoca Express operator), and the `estabelecimento` dashboard is for individual bakery owners? Are there any feature/permission overlaps that need to be explicitly guarded?

**Answer:**

---

### Q2 — Multi-tenancy model: how is data isolation enforced?
Each bakery (estabelecimento) has its own products, orders, settings, and financial data. Is data isolation enforced exclusively via **Row Level Security (RLS) on Supabase**, or are there application-level checks too? Where is the RLS policy definition stored (migrations, SQL.md)? Is there a risk that a malicious estabelecimento owner could access another store's data by crafting requests directly to the Supabase API?

**Answer:**

---

### Q3 — `SQL.md` references in auth_repository.dart
There are multiple comments saying "Ajuste conforme SQL.md" in `auth_repository.dart`. This implies there is a canonical database schema document. Does this file exist in the repo? Should it be committed? Is the schema in Supabase up to date with what the code expects? Are there pending migrations that haven't been run yet?

**Answer:**

---

### Q4 — `dados_bancarios` table structure
Comments in the codebase reference a future `dados_bancarios` table structure. Is the bank data currently stored directly on the `estabelecimentos` table (embedded fields), or in a separate table? This has security implications — bank account details should be stored in a separate, more restricted table with tighter RLS. What is the final intended structure?

**Answer:**

---

### Q5 — Desktop platform support (macOS, Linux)
The project includes `macos/` and `linux/` platform configurations, and `pubspec.lock` lists desktop dependencies. Is desktop a first-class supported platform, or is it just scaffolding? Which platforms are actually in production or planned for release? This affects which conditional platform code paths need to be tested.

**Answer:**

---

### Q6 — Web vs Mobile feature parity
Geolocation uses different implementations (`web_geolocation_helper.dart` vs `mobile_geolocation_helper.dart`). Google Sign-In uses different methods (web popup vs native OAuth). Is there a feature parity document? Are there any features that are intentionally web-only or mobile-only? Is the web version meant for store owners (dashboard) while the mobile app is for customers?

**Answer:**

---

## 2. AUTHENTICATION & AUTHORIZATION

### Q7 — Google Sign-In client ID is hardcoded
In `auth_repository.dart`, the Google OAuth client ID (`330398810543-noqpc71p7c0jo5k5mt2udkp9k3hhjb0s.apps.googleusercontent.com`) is hardcoded in source code. This should be an environment variable or build config. Is this intentional? Is this the production client ID?

**Answer:**

---

### Q8 — `validar_sessao_e_rota` RPC: what does it validate exactly?
The router calls a Supabase RPC `validar_sessao_e_rota()` to determine which dashboard to route the user to. What exactly does this function check? Does it validate the JWT, check the user's `tipo_usuario`, and return the route? If this RPC returns an unexpected value or throws, the user is stuck — is there a fallback? Is this RPC protected by an auth check inside the SQL function itself?

**Answer:**

---

### Q9 — `sessionRouteProvider` is `FutureProvider.autoDispose` — what happens on logout?
The session provider is `.autoDispose`, meaning it re-evaluates when the last listener detaches. On logout, is the Riverpod container explicitly invalidated? Is there a risk of stale session data persisting between user sessions (e.g., user A logs out, user B logs in on the same device and briefly sees user A's dashboard)?

**Answer:**

---

### Q10 — FlutterSecureStorage cleanup on logout
`auth_repository.dart` performs `FlutterSecureStorage` cleanup on logout. However, the cart (`carrinho_controller.dart`) also stores data in FlutterSecureStorage. Is the cart also cleared on logout? If a customer logs out and another customer logs in on the same device, would they inherit the previous user's cart?

**Answer:**

---

### Q11 — Email confirmation flow
`supabase_error_handler.dart` has a case for "email not confirmed" error. Is there a screen or flow to resend the confirmation email? If a user registers but doesn't confirm their email, what happens when they try to log in? Is there a UI state for "pending email confirmation"?

**Answer:**

---

### Q12 — Multi-role users
Can a single user (email) be both a `cliente` and an `entregador`? Can someone be a store owner AND a delivery driver? The `tipo_usuario` field seems to be a single value — does this limit scenarios where one person operates multiple roles? What is the intended behavior?

**Answer:**

---

### Q13 — Password reset flow
There is no visible password reset / "forgot my password" flow. Is this intentionally missing (not implemented yet), or is it handled entirely by Supabase's default email flow with no custom UI?

**Answer:**

---

## 3. SECURITY

### Q14 — `.env` file with production secrets in the repository
The `.env` file is listed in `gitStatus` as a deleted file (`D .env.example`) — but was there ever a real `.env` committed? Is `.env` in `.gitignore`? The `supabase_config.dart` uses `dotenv` for mobile builds, which means secrets are bundled in the app binary. Is the Supabase `publishable_key` (anon key) considered public, or does it have elevated privileges? What RLS policies protect it?

**Answer:**

---

### Q15 — Asaas API key exposure
`dio_provider.dart` sets the Asaas `access_token` as an HTTP header from env vars. On **mobile**, this means the Asaas API key is bundled in the app binary (via `--dart-define` or `dotenv`). Anyone who decompiles the APK/IPA can extract this key. Is there a backend proxy (Edge Function or server) that wraps Asaas calls so the key never leaves the server? Or is the Asaas key truly client-side?

**Answer:**

---

### Q16 — CSP uses `'unsafe-inline'` for scripts
`vercel.json` sets `Content-Security-Policy` with `script-src 'unsafe-inline'`. This is required for Flutter Web, but it significantly weakens XSS protection. Is there a nonce-based approach possible with Flutter Web, or is this an accepted trade-off? Has a security review been done on the deployed web app?

**Answer:**

---

### Q17 — No rate limiting on login endpoint
The login flow calls Supabase auth directly from the client. Supabase has built-in rate limiting, but is it configured? Is there any brute-force protection on the login form (e.g., lockout after N failed attempts, CAPTCHA)? This is especially important since the web app is publicly accessible.

**Answer:**

---

### Q18 — CNPJ/CPF validation is it done client-side only?
The cadastro_estabelecimento step 1 collects a CNPJ. Is there client-side validation of the CNPJ check digit algorithm? Is there server-side validation? A malicious actor could register with a fake CNPJ — is that a problem (e.g., for payment processing with Asaas)?

**Answer:**

---

### Q19 — Image upload: no file size or MIME type validation
`storage_service.dart` uploads images with no visible file size limits or MIME type validation. An attacker could upload very large files (exhausting Supabase Storage quota) or upload non-image files. Is there a Supabase Storage policy that restricts file types and sizes? Is there server-side validation?

**Answer:**

---

### Q20 — SQL injection via `buscar_estabelecimentos` RPC
The search calls RPC `buscar_estabelecimentos(termo)` passing raw user input. Is this RPC using parameterized queries internally (it should be, since it's a Postgres function), or does it use string interpolation? This needs verification — a look at the actual SQL function body is required.

**Answer:**

---

## 4. DATA LAYER & SUPABASE

### Q21 — `getProfile()` handles both array and map variations — why?
In `auth_repository.dart`, `getProfile()` handles two different response shapes: the join result sometimes comes back as a `List` and sometimes as a `Map`. This suggests schema inconsistency or that two different query patterns were tried. What is the canonical join approach? Should this defensive code be cleaned up once the query is stable?

**Answer:**

---

### Q22 — Upsert in `saveProduto` — is this safe for create vs update?
`produtos_repository.dart` uses Supabase `upsert` for both creating and updating products. Does the upsert rely on the `id` field being present? If a new product is created without an `id`, does Supabase auto-generate a UUID? Is there a risk of accidentally overwriting a product if the same name is used?

**Answer:**

---

### Q23 — Physical delete vs soft-delete for products
`produtos_repository.dart` uses physical delete (`delete`) for products. If an order exists referencing a deleted product (via JSONB embed), the historical data should be fine, but if products are referenced by FK in any table, deletion will fail. Is there a soft-delete requirement (set `ativo = false`) instead of physical delete? What happens to existing cart items referencing a deleted product?

**Answer:**

---

### Q24 — Order items stored as JSONB — is this intentional?
`pedidos_cliente_repository.dart` fetches `itens` as a JSONB array. Orders embed product snapshots at the time of purchase, which is good for historical accuracy (price/name won't change retroactively). But querying JSONB for analytics (e.g., "most ordered product") is harder. Is this a deliberate denormalization choice, or is there a normalized `pedido_items` table too?

**Answer:**

---

### Q25 — No pagination on any list query
All repository methods fetch entire result sets (e.g., `getPedidosCliente(clienteId)` fetches all orders, `fetchProdutos()` fetches all products). For a bakery with hundreds of orders or products, this will be slow and memory-intensive. Is pagination (cursor/offset) planned? Should we add `.range(offset, limit)` to Supabase queries?

**Answer:**

---

### Q26 — Realtime subscription management
`dashboard_controller.dart` references Supabase Realtime channels for live order updates. Are channels explicitly unsubscribed when the dashboard is disposed (`.autoDispose` triggers `dispose()`)? Leaked subscriptions can cause duplicate events and memory leaks. Is there a teardown in `dispose()`?

**Answer:**

---

### Q27 — `estabelecimento_repository.dart` — what does it expose?
The file is listed as modified (`M`) but not fully inventoried. What queries does it run? Does it expose store data publicly (for customer browsing), or is it only for owner operations? Are inactive/pending establishments accidentally exposed to customers?

**Answer:**

---

### Q28 — `fetch_admin_stats` RPC — performance on large datasets
The admin dashboard calls `fetch_admin_stats(periodo)` which calculates platform-wide metrics. On a large dataset (10k+ orders), is this RPC using indexed queries? Is it called on every navigation to the admin dashboard, or is it cached? Is there a risk of this RPC timing out?

**Answer:**

---

## 5. STATE MANAGEMENT & RIVERPOD

### Q29 — `sessionRouteProvider` is declared as `FutureProvider.autoDispose.family`?
The router uses `sessionRouteProvider` which appears to be a `FutureProvider.autoDispose`. If the provider is disposed between route redirects (because no widget is listening), GoRouter's `redirect` callback may trigger a rebuild with a loading state. Has this race condition been tested? What happens if `redirect` is called while the provider is in `AsyncLoading`?

**Answer:**

---

### Q30 — `LoginState` vs direct `ref.read` pattern
`login_controller.dart` uses a custom `LoginState` with a `success` flag and `targetRoute`. After login, the UI listens for `state.success` to navigate. However, GoRouter's `redirect` also fires on auth change. Is there a risk of double navigation (controller push + GoRouter redirect both triggering)?

**Answer:**

---

### Q31 — `_keep` sentinel in `AdminDashboardState.copyWith`
`admin_dashboard_state.dart` uses `const _keep = Object()` sentinel to distinguish "keep old nullable value" from "explicitly set to null" in `copyWith`. This is a known Dart pattern but creates maintenance overhead. Is `freezed` or `built_value` considered for immutable state classes to avoid this boilerplate?

**Answer:**

---

### Q32 — StateNotifier `mounted` check: does it exist?
In `login_controller.dart`, there appears to be an `if (!mounted) return;` guard, but `StateNotifier` does not have a `mounted` property — that belongs to `State<T>` in widgets. Does this code compile? Does it do anything useful? This may be dead code or a latent bug.

**Answer:**

---

### Q33 — `PedidosClienteController` uses `.autoDispose` — does it refetch on every tab switch?
The `meus_pedidos_screen.dart` tab uses a `.autoDispose` provider. Every time the user switches away from and back to the "Meus Pedidos" tab, the provider is disposed and recreated, triggering a new API call. Is this the intended behavior (always fresh data) or should the state be kept alive with `.keepAlive()`?

**Answer:**

---

## 6. PAYMENTS & FINANCIAL

### Q34 — Asaas integration: which payment flows are complete?
The codebase references PIX, credit card, and debit payments via Asaas, but the actual payment creation/confirmation flow is not fully visible. Specifically:
- Is the payment created **client-side** (calling Asaas directly from the app) or via a **Supabase Edge Function**?
- Is the PIX QR code generated and displayed in the app?
- Is there a webhook from Asaas to confirm payment and update order status?
- Is there a split payment setup (platform fee + establishment amount)?

**Answer:**

---

### Q35 — Financial reconciliation: who triggers `entregador_valor_total`?
`dashboard_controller.dart` for entregador sums `entregador_valor_total` for earnings. Who sets this value? Is it set when an order is marked as delivered? Is there a risk that it's never set (null) and earnings show as zero even though deliveries happened?

**Answer:**

---

### Q36 — Cupons (coupons): is validation server-side?
`cupons_repository.dart` manages coupons. When a customer applies a coupon at checkout, is the discount validated **server-side** (Supabase RPC or Edge Function) to prevent manipulation, or is the discount calculated client-side and trusted? A client-side coupon validation can be trivially bypassed.

**Answer:**

---

### Q37 — `quantidadeMaxima` and `usoAtual` race condition
Coupons have `quantidadeMaxima` and `usoAtual` fields. If multiple users apply the same coupon simultaneously, there is a race condition where both could see `usoAtual < quantidadeMaxima` and both succeed. Is there a database-level atomic increment with check (e.g., `UPDATE cupons SET uso_atual = uso_atual + 1 WHERE uso_atual < quantidade_maxima`)? Or is this handled by a transaction in a Supabase function?

**Answer:**

---

## 7. PERFORMANCE

### Q38 — `cached_network_image` usage: is a global cache size limit set?
`cached_network_image` is used throughout the app. Without a max cache size configured, it can grow unboundedly. For an app displaying many bakery logos and product images, this could exhaust device storage. Is `CacheManager` configured with a custom `stalePeriod` and `maxNrOfCacheObjects`?

**Answer:**

---

### Q39 — `google_fonts` runtime download: are fonts pre-cached?
`google_fonts` by default downloads fonts at runtime from Google's CDN. On first launch with no internet, the app will use fallback fonts. Are fonts bundled as assets, or is the runtime download accepted behavior? For a Brazilian market where data connectivity can be unreliable, this may affect UX.

**Answer:**

---

### Q40 — Google Maps: is the API key restricted?
`google_maps_flutter` requires a Google Maps API key. Is this key restricted by:
- Bundle ID / package name (Android/iOS)
- HTTP referrer (Web)
If unrestricted, the key can be extracted from the app and abused, resulting in unexpected billing.

**Answer:**

---

### Q41 — Build size: 184 dependencies for a delivery app
The `pubspec.lock` has 184 transitive dependencies. Some may be redundant (e.g., both `geolocator` and a web geolocation helper using `dart:js_interop`). Has a dependency audit been done? What is the current APK/IPA/web bundle size? Are there tree-shaking or deferred loading optimizations?

**Answer:**

---

### Q42 — Home screen: are establishments loaded all at once?
`home_content.dart` loads an establishment list. For a city with many bakeries, loading all at once is expensive. Is there:
- Pagination or infinite scroll?
- Geographic filtering (only show bakeries within X km)?
- Server-side filtering before returning results?

**Answer:**

---

## 8. ERROR HANDLING & RESILIENCE

### Q43 — No global error boundary / crash reporting
The app has per-screen error states but no global error boundary. Uncaught exceptions (e.g., in `initState`, in Riverpod providers, in background operations) will crash the app with a red screen. Is there:
- A `FlutterError.onError` handler?
- A `PlatformDispatcher.instance.onError` handler?
- Integration with Sentry, Firebase Crashlytics, or similar?

**Answer:**

---

### Q44 — Splash screen: what happens if `validar_sessao_e_rota` fails?
`splash_screen.dart` navigates after a 3-second animation. If the session validation RPC fails (network error, Supabase down), does the user get stuck on the splash screen, or do they land on `/login`? Is there a timeout or fallback?

**Answer:**

---

### Q45 — Cart persistence: what if FlutterSecureStorage is unavailable?
`carrinho_controller.dart` uses FlutterSecureStorage to persist the cart. On first launch or after a device reset, the storage may be empty. Is there graceful handling of null/missing cart data? What happens if decoding the stored JSON fails (e.g., corrupted data from an app update that changed the model)?

**Answer:**

---

### Q46 — `SupabaseErrorHandler`: what happens with unrecognized error codes?
`supabase_error_handler.dart` maps known error codes to Portuguese messages. For unrecognized codes (new Supabase error types, network timeout, SSL error, etc.), what does it return? Does it expose raw error messages to users (which may leak internal info)?

**Answer:**

---

### Q47 — Offline behavior: what happens when the device has no internet?
There is no visible offline queue or sync mechanism. If a customer adds items to cart and then loses connection before placing an order, the cart persists but the order cannot be placed. Is there a user-facing message when the app is offline? Is there a connectivity check before critical operations?

**Answer:**

---

## 9. REAL-TIME FEATURES

### Q48 — Supabase Realtime: is it fully implemented for the kanban board?
`pedidos_kanban_controller.dart` references real-time updates. For the establishment dashboard, order status changes from the driver side should update the kanban in real-time. Is the Realtime subscription set up to listen to `pedidos` table changes filtered by `estabelecimento_id`? Is it working end-to-end?

**Answer:**

---

### Q49 — Push notifications: Firebase integration is set up but is it working?
`firebase_core` and `firebase_messaging` are in `pubspec.lock`, and there is push notification infrastructure (`flutter_local_notifications`). Is Firebase Cloud Messaging (FCM) fully integrated? Are notifications sent:
- To customers when order status changes?
- To establishments when a new order arrives?
- To drivers when a delivery is assigned?
What is the trigger (Supabase Edge Function webhook → FCM)?

**Answer:**

---

### Q50 — Order tracking: is there a live map for customers?
`google_maps_flutter` is a dependency. Is there a live order tracking screen where customers see the driver's position on a map? If so, how often does the driver's location update (battery implications)? Is the driver's location streamed via Supabase Realtime?

**Answer:**

---

## 10. UX & FLOWS

### Q51 — Multi-step establishment registration: is state preserved on back navigation?
`cadastro_estabelecimento` has 3 steps managed by `CadastroEstabelecimentoState`. If the user navigates back from step 2 to step 1 to correct something, then forward again, is the step 2 data preserved? Is the state held in a Riverpod provider that survives navigation, or does it reset?

**Answer:**

---

### Q52 — What happens after establishment registration? Is there an approval flow?
After a bakery owner completes the 3-step registration, is the establishment immediately active and visible to customers, or is there an admin approval step? If approval is required, is the owner notified? Is there a "pending approval" screen? The admin dashboard has a "pending approvals" section — is this connected?

**Answer:**

---

### Q53 — Delivery driver registration: what documents are required?
`cadastro_entregador_screen.dart` collects vehicle details and availability. Are there document uploads (CNH, vehicle registration)? Is there a verification step? Can a driver start accepting deliveries immediately, or is there an approval flow (similar to establishments)?

**Answer:**

---

### Q54 — Customer home screen: what does `HomeContent` show when there are no bakeries nearby?
If no establishments are active or none match the customer's location, what does the home screen display? Is there an empty state, a suggestion to expand search radius, or does it just show an empty list?

**Answer:**

---

### Q55 — Cart: what happens when a product is removed from the establishment's menu while it's in a customer's cart?
If a customer adds a product to their cart, but the establishment then deletes or deactivates that product, what happens at checkout? Is there a validation step before finalizing the order that checks product availability and current prices?

**Answer:**

---

### Q56 — Order cancellation: who can cancel and at what stages?
The kanban has a `rejeitarPedido` action. Can customers also cancel orders? Up to which status can cancellation happen (only while pending, or also while confirmed)? What is the refund policy/flow for already-paid orders?

**Answer:**

---

### Q57 — `produto_variavel_dialog.dart`: how are variable product options structured?
Variable products have `opcoes` (list of `ProdutoOpcaoModel`). The dialog presumably shows radio buttons or checkboxes for options (size, toppings). Is there validation that required choices are made before adding to cart? How is the final price calculated with options (fixed addition, percentage, replacement)?

**Answer:**

---

## 11. SPECIFIC BUGS IDENTIFIED

### Q58 — Bug: String escaping in `pedidos_cliente_repository.dart`
Line ~26 has `throw Exception('Erro ao buscar pedidos: \$e')` — the backslash before `$e` means the exception message will literally contain `$e` instead of the actual error. This should be `$e` without the backslash. Is this confirmed?

**Answer:**

---

### Q59 — Bug: `StateNotifier.mounted` does not exist
In `login_controller.dart`, `if (!mounted) return;` is called inside a `StateNotifier` method. `StateNotifier` has no `mounted` property. This will either cause a compile error (if `mounted` is not defined anywhere in scope) or silently always evaluate to `true`/`false` if there's a parent class with a `mounted` getter. What is the actual behavior here?

**Answer:**

---

### Q60 — Bug: `PedidoClienteModel.isAtivo` may be missing
`pedidos_cliente_controller.dart` calls `.isAtivo` on `PedidoClienteModel` instances to separate active from past orders. If this getter is defined as a computed property in the model, this is fine; if it's missing, there's a compile error. Is `isAtivo` defined in `pedido_cliente_model.dart`?

**Answer:**

---

### Q61 — Potential bug: `getProfile()` inconsistent response shape
`auth_repository.dart`'s `getProfile()` method has defensive code to handle both `List` and `Map` responses from Supabase joins. This suggests that at some point in development, the query was changed and the defensive code was added. Has the root cause been identified? Is this a specific Supabase `.select()` syntax issue that should be standardized?

**Answer:**

---

### Q62 — Potential bug: `CadastroEstabelecimentoState` — cover image is XFile on mobile but what on web?
The establishment registration uses `image_picker` and `image_cropper` for the cover image, which works on mobile. On web, `XFile` comes from the browser's file input. Is the `StorageService.uploadCapa()` method tested on web? Does it correctly handle web `XFile` (which uses a blob URL) vs mobile `XFile` (which uses a file path)?

**Answer:**

---

### Q63 — Potential bug: GoRouter redirect loop
The router has redirect logic that calls `validar_sessao_e_rota`. If the RPC returns an unexpected route that is also a protected route (triggering another redirect), there could be an infinite redirect loop. Is there a guard against redirect loops (e.g., checking if `state.matchedLocation == targetRoute`)?

**Answer:**

---

## 12. TESTING

### Q64 — Test coverage: only 12 test files for 153 source files
The test suite covers ~8% of source files. Critical paths like payment processing, order creation, coupon validation, and the multi-step registration flow have no visible test coverage. What is the testing strategy — unit tests only, or also widget/integration tests? Is there a coverage threshold enforced in CI?

**Answer:**

---

### Q65 — Mocks: `MockAuthRepository` implements the full interface
Tests use hand-written mocks. As the auth interface grows, maintaining mocks becomes a burden. Is `mockito` or `mocktail` used for code-generated mocks? The `pubspec.yaml` should have these in `dev_dependencies`.

**Answer:**

---

### Q66 — Tests don't test GoRouter redirect logic
The routing logic in `app_router.dart` (the `redirect` callback calling `validar_sessao_e_rota`) is untested. A misconfigured redirect could lock users out of the app. Is there a plan to add integration tests for the routing logic?

**Answer:**

---

### Q67 — `widget_test.dart` is a placeholder
The default Flutter widget test (`test/widget_test.dart`) is a placeholder with no real tests. Should this be removed or replaced with meaningful widget tests for critical screens (e.g., login screen, home screen)?

**Answer:**

---

## 13. DEPLOYMENT & CONFIGURATION

### Q68 — `.env` for mobile: secrets in app binary
`supabase_config.dart` reads from `dotenv` on mobile. The `.env` file's contents are bundled in the app binary. Anyone with the APK can extract these values. For the Supabase anon key (publishable key), this is by design — RLS protects the data. But for `ASAAS_API_KEY`, this is a serious security concern. Is there a server-side proxy for Asaas?

**Answer:**

---

### Q69 — Vercel deployment: is there a CI/CD pipeline?
`build.sh` is a Vercel build script. Is there a GitHub Actions or similar CI pipeline that:
- Runs tests before deploy?
- Validates the Flutter build?
- Manages environment variables securely (not committed)?
Is deployment triggered automatically on push to `main`?

**Answer:**

---

### Q70 — `web/index.html` loads Cropper.js from CDN — is this in the CSP?
`web/index.html` loads `cropper.js` from `unpkg.com`. The CSP in `vercel.json` includes `unpkg.com` in `script-src`, which is good. But CDN dependencies are a supply chain risk — if the CDN is compromised, XSS is possible. Is there a plan to bundle Cropper.js locally instead of fetching from CDN? Is there an SRI (Subresource Integrity) hash on the CDN script tags?

**Answer:**

---

### Q71 — Multiple platform build targets: is there a single build pipeline?
The app targets iOS, Android, Web, macOS, and Linux. Are all platforms built and tested in CI, or only Web (Vercel) and Mobile (manual)? Is there a release process document?

**Answer:**

---

### Q72 — `SUPABASE_ANON_KEY` vs `SUPABASE_PUBLISHABLE_KEY` dual handling
`supabase_config.dart` supports both `SUPABASE_ANON_KEY` (legacy) and `SUPABASE_PUBLISHABLE_KEY` (new). Is this a migration in progress? Once all environments use the new key name, should the legacy fallback be removed?

**Answer:**

---

## 14. MISSING FEATURES & INCOMPLETE IMPLEMENTATIONS

### Q73 — Delivery tracking: is there a real-time driver location feature?
Is there a screen where customers can see the driver's location on a map in real-time? If not, is it planned? What is the mechanism — driver app sends location updates via Supabase Realtime, stored in a `posicao_entregador` table?

**Answer:**

---

### Q74 — Ratings & reviews: who rates whom?
The admin dashboard shows `avaliacaoMedia`. There are references to an `avaliacoes` table in the entregador dashboard. Can customers rate:
- Establishments (food quality, packaging)?
- Delivery drivers (speed, behavior)?
Can establishments rate customers (for fraud prevention)?
Is there a UI for leaving ratings after order completion?

**Answer:**

---

### Q75 — Notifications: are there in-app notifications beyond push?
The home screen has a notification icon in `ClienteAppBar`. Is there an in-app notification center (list of past notifications), or is the icon just decorative/placeholder? Are promotional notifications supported?

**Answer:**

---

### Q76 — Address management: saved addresses for customers
`perfil_user_screen.dart` has a "Meus Endereços" section. Is there a full CRUD for saved addresses? Is there a default/preferred delivery address? At checkout, can the customer select from saved addresses or enter a new one?

**Answer:**

---

### Q77 — Establishment operating hours: is this enforced?
`configuracoes_controller.dart` manages `horarios` (opening hours). When a customer views an establishment, is the "open/closed" status calculated from the current time vs the stored hours? Does the app prevent orders being placed to closed establishments? Is timezone handling correct (Brazil has multiple time zones)?

**Answer:**

---

### Q78 — Search: what does `buscar_estabelecimentos(termo)` actually search?
The search RPC receives a raw term. Does it search by:
- Establishment name?
- Product names?
- Category?
- Description?
Does it use full-text search (PostgreSQL `tsvector`/`tsquery`) or `ILIKE`? For a food delivery app, searching by product (e.g., "pão de queijo") to find which bakeries sell it is a key UX feature.

**Answer:**

---

### Q79 — Establishment categories (`categoria_estabelecimento`) vs menu categories (`categoria_cardapio`)
There are two category systems: `categoria_estabelecimento` (for browsing stores by type: bakeries, coffee shops, etc.) and `categoria_cardapio` (for menu organization within a store: breads, pastries, drinks). Is this distinction clear in the UI? Are both seeded with real data, or are they empty in production?

**Answer:**

---

### Q80 — `tipoProduto` (simples/variavel): is "variavel" fully implemented?
`produto_model.dart` has `tipoProduto` (simple/variable) and `opcoes` (list of option groups). The `produto_variavel_dialog.dart` exists. Is the variable product flow fully implemented end-to-end: creation in the establishment dashboard, display to customers, selection, and price calculation at checkout?

**Answer:**

---

## 15. CODE QUALITY & REFACTORING

### Q81 — `CadastroEstabelecimentoState` is a massive monolithic state class
The establishment registration state spans 3 screens with 100+ fields in one class. This makes it hard to test, maintain, and reason about. Should this be split into 3 step-specific state classes (Step1State, Step2State, Step3State) composed together, or is the monolithic approach intentional for easy final submission?

**Answer:**

---

### Q82 — Repository methods mix async patterns: `async/await` vs `.then()`
Some repository methods use `async/await` while others chain `.then()`. This inconsistency makes the code harder to follow. Should a style guide enforce one pattern?

**Answer:**

---

### Q83 — `PedidoKanbanModel` field naming: `q`, `n`, `p`, `at`, `tx`
`pedido_kanban_model.dart` uses extremely abbreviated field names (`q` for quantity, `n` for name, `p` for price, `at` for timestamp, `tx` for taxa/fee). While this minimizes payload size for JSON serialization, it severely hurts readability. Is this a deliberate optimization (e.g., for Realtime payload size) or an oversight?

**Answer:**

---

### Q84 — `home/models/estabelecimento_model.dart` vs `models/produto_model.dart` — are there duplicate establishment models?
There appears to be an `EstabelecimentoModel` in `cliente/home/models/` and potentially another in `estabelecimento/repositories/`. Are these the same model, or do they serve different purposes (customer-facing view vs owner-facing full record)? Duplicate models for the same entity lead to sync issues when the schema changes.

**Answer:**

---

### Q85 — `analysis_options.yaml`: is the linter configured strictly enough?
Flutter projects benefit from strict linting. Is `analysis_options.yaml` using `package:flutter_lints` or `package:lints`? Are strict mode rules enabled (`strict-casts`, `strict-inference`, `strict-raw-types`)? Are there currently any existing lint warnings in the codebase?

**Answer:**

---

### Q86 — `uuid` dependency listed as `any` version
`pubspec.yaml` has `uuid: any` (no version constraint). This is a bad practice — a major version bump could introduce breaking changes that fail the build silently on `pub upgrade`. Should this be pinned to a specific version range?

**Answer:**

---

### Q87 — `theme_provider.dart`: dark mode toggle persists to SharedPreferences, but is it respected system-wide?
The theme preference is stored in SharedPreferences and loaded on app start. If the user changes their OS theme (light → dark), does the app follow the system preference, or does it always use the stored preference? Is there a "follow system" option?

**Answer:**

---

## 16. LOCALIZATION & INTERNATIONALIZATION

### Q88 — `intl` package used for `pt_BR` — where are the ARB files?
`main.dart` sets up `pt_BR` and `en_US` locales. `pubspec.yaml` lists `intl`. But are there actual `.arb` localization files, or are all strings hardcoded in Portuguese in the widget files? Hardcoded strings make future internationalization impossible.

**Answer:**

---

### Q89 — Date formatting with `intl`: is the locale always set correctly?
`pedido_cliente_model.dart` uses `intl` for `dataFormatada`. Is `Intl.defaultLocale` set to `pt_BR` at app startup, or is the locale passed explicitly to each `DateFormat` call? Inconsistent locale setup can cause dates to display in English unexpectedly.

**Answer:**

---

### Q90 — Currency formatting: is `R$` always formatted correctly?
Prices are displayed throughout the app. Is there a centralized `formatCurrency()` utility using `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')`, or is formatting done ad-hoc with `.toStringAsFixed(2)` in each widget? The latter will not handle thousands separators or locale-specific decimal separators correctly.

**Answer:**

---

## 17. ACCESSIBILITY

### Q91 — Are there semantic labels on interactive elements?
For screen reader support (TalkBack on Android, VoiceOver on iOS), interactive elements (buttons, cards, icons) should have `Semantics` labels. Is accessibility a requirement for this app? Are there any `Semantics` widgets or `tooltip` properties on key interactive elements?

**Answer:**

---

### Q92 — Color contrast: orange primary on white background
The primary color is orange (`#FF7034`). On white backgrounds, orange text may not meet WCAG AA contrast ratio (4.5:1 for normal text, 3:1 for large text). Has a color contrast audit been done?

**Answer:**

---

## 18. OPERATIONAL & MONITORING

### Q93 — No application performance monitoring (APM)
There is no visible APM integration (e.g., Firebase Performance, Sentry, Datadog). For a production delivery app, slow queries and UI janks need to be detected in production. Is APM planned?

**Answer:**

---

### Q94 — Supabase logs: are they monitored?
Supabase provides query logs and auth logs. Is there a process to review these logs for errors, slow queries, or suspicious activity?

**Answer:**

---

### Q95 — What is the SLA / uptime expectation?
Is this app in production serving real customers? What is the expected uptime (99.9%, 99.99%)? Supabase free tier has no SLA — is the project on a paid Supabase plan?

**Answer:**

---

## 19. BUSINESS LOGIC

### Q96 — Delivery fee calculation: client-side or server-side?
The cart shows a delivery fee. Is this fee calculated client-side (from the establishment's `configEntrega.taxaEntrega` field) or server-side? A client-side calculation can be manipulated — a user could modify the fee before submitting the order. Is the final fee recalculated server-side at order creation?

**Answer:**

---

### Q97 — Platform commission: how is it configured and applied?
The admin dashboard tracks "platform revenue" (splits). What is the platform commission rate? Is it a fixed percentage, per-establishment negotiated rate, or tiered? Where is this rate stored? Is it applied automatically at order creation (Supabase trigger), or manually via the admin dashboard?

**Answer:**

---

### Q98 — Multiple establishments per user: is it supported?
A user with `tipo_usuario = 'estabelecimento'` looks up their establishment via `getEstabelecimentoId()`. This returns a single ID. Can one user own multiple establishments? If yes, the current data model and routing break. Is this a known limitation?

**Answer:**

---

### Q99 — Order lifecycle: what are all the status transitions?
The kanban has: `pendente → confirmado → preparando → pronto → em_entrega → entregue/cancelado`. Are all transitions valid in both directions (can a confirmed order go back to pending)? Who triggers each transition (establishment, driver, system)? Is there a state machine with explicit allowed transitions, or is any status change permitted?

**Answer:**

---

### Q100 — Entregador assignment: is it manual or automatic?
When an order is ready (`pronto`), how is a delivery driver assigned? Does the driver proactively accept orders from a list (marketplace model), or does the establishment/system assign a driver? Is there a notification sent to nearby available drivers?

**Answer:**

---

---

*Total questions: 100*
*Generated by code review — 2026-03-18*
*Answer each question and re-prompt to begin implementation.*
