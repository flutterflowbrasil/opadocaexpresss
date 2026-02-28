<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Public+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" rel="stylesheet"/>
<script id="tailwind-config">
  tailwind.config = {
    darkMode: "class",
    theme: {
      extend: {
        colors: {
          primary: "#ec5b13",
          "primary-light": "#fef0e8",
          "background-light": "#f8f6f6",
          "background-dark": "#221610",
        },
        fontFamily: { display: ["Public Sans", "sans-serif"] },
        borderRadius: { DEFAULT: "0.25rem", lg: "0.5rem", xl: "0.75rem", "2xl": "1rem", full: "9999px" },
      },
    },
  };
</script>
<title>Padoca Express - Configurações</title>
<style>
  body { min-height: 100dvh; }
  .tab-btn { transition: all .2s; }
  .tab-btn.active { background: #ec5b13; color: #fff; }
  .tab-btn:not(.active):hover { background: #fef0e8; color: #ec5b13; }
  .section-card { animation: fadeIn .3s ease; }
  @keyframes fadeIn { from { opacity:0; transform:translateY(8px); } to { opacity:1; transform:translateY(0); } }
  input[type=time]::-webkit-calendar-picker-indicator { filter: invert(0.5); }
  .toggle-input:checked ~ .toggle-track { background-color: #ec5b13; }
  .toggle-input:checked ~ .toggle-thumb { transform: translateX(1.25rem); }
  /* Custom scrollbar */
  ::-webkit-scrollbar { width: 6px; }
  ::-webkit-scrollbar-track { background: transparent; }
  ::-webkit-scrollbar-thumb { background: #e2e8f0; border-radius: 3px; }
</style>
</head>
<body class="bg-background-light dark:bg-background-dark font-display text-slate-900 dark:text-slate-100">
<div class="flex min-h-screen">

  <!-- Sidebar -->
  <aside class="hidden md:flex w-72 flex-col bg-white dark:bg-slate-900 border-r border-slate-200 dark:border-slate-800 sticky top-0 h-screen">
    <div class="p-6">
      <div class="flex items-center gap-3">
        <div class="size-10 bg-primary rounded-xl flex items-center justify-center text-white shadow-lg shadow-primary/30">
          <span class="material-symbols-outlined">bakery_dining</span>
        </div>
        <p class="text-xl font-bold tracking-tight">Padoca Express</p>
      </div>
    </div>
    <nav class="flex-1 px-4 space-y-1">
      <a class="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-primary/10 transition-colors text-slate-600 dark:text-slate-400" href="#">
        <span class="material-symbols-outlined text-xl">dashboard</span><span class="font-semibold">Dashboard</span>
      </a>
      <a class="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-primary/10 transition-colors text-slate-600 dark:text-slate-400" href="#">
        <span class="material-symbols-outlined text-xl">shopping_cart</span><span class="font-semibold">Pedidos</span>
      </a>
      <a class="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-primary/10 transition-colors text-slate-600 dark:text-slate-400" href="#">
        <span class="material-symbols-outlined text-xl">restaurant_menu</span><span class="font-semibold">Cardápio</span>
      </a>
      <a class="flex items-center gap-3 px-4 py-3 rounded-xl bg-primary/15 text-primary" href="#">
        <span class="material-symbols-outlined text-xl">settings</span><span class="font-semibold">Configurações</span>
      </a>
      <a class="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-primary/10 transition-colors text-slate-600 dark:text-slate-400" href="#">
        <span class="material-symbols-outlined text-xl">help</span><span class="font-semibold">Suporte</span>
      </a>
    </nav>
    <div class="p-4 border-t border-slate-200 dark:border-slate-800">
      <div class="flex items-center gap-3 px-4 py-2">
        <div class="size-8 rounded-full bg-primary/20 flex items-center justify-center text-primary font-bold text-sm">A</div>
        <div>
          <p class="text-sm font-bold">Admin Padoca</p>
          <p class="text-xs text-slate-500 cursor-pointer hover:text-primary">Sair</p>
        </div>
      </div>
    </div>
  </aside>

  <!-- Main -->
  <main class="flex-1 flex flex-col h-screen overflow-y-auto">

    <!-- Header -->
    <header class="sticky top-0 z-30 flex items-center justify-between bg-white/90 dark:bg-slate-900/90 backdrop-blur-md px-6 py-4 border-b border-slate-200 dark:border-slate-800">
      <div class="flex items-center gap-4">
        <button class="md:hidden p-2 text-slate-600 dark:text-slate-300">
          <span class="material-symbols-outlined">menu</span>
        </button>
        <div>
          <h1 class="text-xl font-bold">Configurações da Loja</h1>
          <p class="text-xs text-slate-500 hidden sm:block">Gerencie todas as informações do seu estabelecimento</p>
        </div>
      </div>
      <div class="flex items-center gap-3">
        <button class="relative p-2 text-slate-600 dark:text-slate-300 hover:text-primary transition-colors">
          <span class="material-symbols-outlined">notifications</span>
          <span class="absolute top-2 right-2 size-2 bg-primary rounded-full"></span>
        </button>
        <button onclick="saveChanges()" class="bg-primary text-white px-5 py-2.5 rounded-xl font-bold hover:brightness-110 transition-all shadow-lg shadow-primary/30 flex items-center gap-2">
          <span class="material-symbols-outlined text-sm">save</span>
          <span class="hidden sm:inline">Salvar Alterações</span>
          <span class="sm:hidden">Salvar</span>
        </button>
      </div>
    </header>

    <!-- Tab Navigation -->
    <div class="sticky top-[73px] z-20 bg-white/90 dark:bg-slate-900/90 backdrop-blur-md border-b border-slate-200 dark:border-slate-800 px-6">
      <div class="flex gap-1 overflow-x-auto pb-0 scrollbar-hide" id="tabNav">
        <button onclick="showTab('visual')" class="tab-btn active whitespace-nowrap px-4 py-3 rounded-t-lg text-sm font-semibold flex items-center gap-2" data-tab="visual">
          <span class="material-symbols-outlined text-base">palette</span>Identidade Visual
        </button>
        <button onclick="showTab('info')" class="tab-btn whitespace-nowrap px-4 py-3 rounded-t-lg text-sm font-semibold flex items-center gap-2" data-tab="info">
          <span class="material-symbols-outlined text-base">store</span>Informações
        </button>
        <button onclick="showTab('address')" class="tab-btn whitespace-nowrap px-4 py-3 rounded-t-lg text-sm font-semibold flex items-center gap-2" data-tab="address">
          <span class="material-symbols-outlined text-base">location_on</span>Endereço
        </button>
        <button onclick="showTab('hours')" class="tab-btn whitespace-nowrap px-4 py-3 rounded-t-lg text-sm font-semibold flex items-center gap-2" data-tab="hours">
          <span class="material-symbols-outlined text-base">schedule</span>Horários
        </button>
        <button onclick="showTab('delivery')" class="tab-btn whitespace-nowrap px-4 py-3 rounded-t-lg text-sm font-semibold flex items-center gap-2" data-tab="delivery">
          <span class="material-symbols-outlined text-base">local_shipping</span>Entrega
        </button>
        <button onclick="showTab('advanced')" class="tab-btn whitespace-nowrap px-4 py-3 rounded-t-lg text-sm font-semibold flex items-center gap-2" data-tab="advanced">
          <span class="material-symbols-outlined text-base">tune</span>Avançado
        </button>
        <button onclick="showTab('responsible')" class="tab-btn whitespace-nowrap px-4 py-3 rounded-t-lg text-sm font-semibold flex items-center gap-2" data-tab="responsible">
          <span class="material-symbols-outlined text-base">person</span>Responsável
        </button>
        <button onclick="showTab('banking')" class="tab-btn whitespace-nowrap px-4 py-3 rounded-t-lg text-sm font-semibold flex items-center gap-2" data-tab="banking">
          <span class="material-symbols-outlined text-base">account_balance</span>Dados Bancários
        </button>
      </div>
    </div>

    <div class="p-6 max-w-4xl mx-auto w-full pb-24 space-y-6">

      <!-- ===== TAB: IDENTIDADE VISUAL ===== -->
      <div id="tab-visual" class="section-card space-y-6">
        <div class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 overflow-hidden shadow-sm">
          <!-- Banner -->
          <div class="h-52 relative bg-slate-200 dark:bg-slate-800 group cursor-pointer"
            style='background-image:url("https://lh3.googleusercontent.com/aida-public/AB6AXuCs9h2ekg66EoLZHRsjHZ82iFEpjz9fLxVePUqm0vKe9e0IalYQTkAf--mgOqCsAci84C2uR75jAqjiiClrzOqhDOHIhy1ruew98A3Tw2LjzORbiLQyp3C5J8orsoRdMhJi4gP7iY2pVPH3_yMX0CMaCBn4Odi2Oo0nlrJOd_SN1dVfWCg0smz4dzpjdvpdG_bAnHCdF0w7hQSajmmY8z_FWklRv7tX6FYfaG1rlx89NE0gnTku0sP6eAHyNKrwAFHkGPnuOO6w");background-size:cover;background-position:center;'>
            <div class="absolute inset-0 bg-black/30 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
              <button class="bg-white/95 text-slate-900 px-5 py-2.5 rounded-xl font-bold flex items-center gap-2 shadow-lg">
                <span class="material-symbols-outlined text-base">photo_camera</span> Alterar Banner
              </button>
            </div>
            <div class="absolute top-3 right-3 bg-black/40 text-white text-xs px-3 py-1 rounded-full backdrop-blur-sm font-medium">
              Recomendado: 1200×400px
            </div>
          </div>
          <!-- Logo + Info -->
          <div class="px-8 pb-8 flex flex-col sm:flex-row items-end gap-6 -mt-14">
            <div class="relative group">
              <div class="size-28 rounded-2xl border-4 border-white dark:border-slate-900 bg-white dark:bg-slate-800 shadow-xl overflow-hidden cursor-pointer">
                <img alt="Logo" class="w-full h-full object-cover"
                  src="https://lh3.googleusercontent.com/aida-public/AB6AXuAKabNf9h3JKHnA19UVh9aiV2XGPZdQOJOCXiurcO1UhJ_Sm12irLuXHbhIIpTOuCj7QLn5i0LyPFsh3rF2LdEcRsGgVlj6Ag4OzDYDTQH5tmSBGxPVoQXr0c21wmNnbjb01U097DTlkxYao9todeTjvM35cVKt2N4zB9FxVRmuE3mkXP9hQ4Ixmr6Pk2oOPYpHfBTcCbQ7-NmsbTZzfuafe0rJTthRtvidSO3sYAecYrmdf8SHuMQ_UL5U6ftFGOfErVNHvQ56"/>
              </div>
              <button class="absolute -bottom-2 -right-2 bg-primary text-white p-1.5 rounded-full shadow-lg hover:brightness-110">
                <span class="material-symbols-outlined text-sm">edit</span>
              </button>
            </div>
            <div class="flex-1 mb-1">
              <h3 class="text-lg font-bold">Logo e Banner</h3>
              <p class="text-sm text-slate-500">Logo: mín. 200×200px. Banner: mín. 1200×400px. Formatos: JPG, PNG, WebP.</p>
            </div>
            <div class="flex gap-3 mb-1">
              <button class="border border-slate-200 dark:border-slate-700 px-4 py-2 rounded-lg font-semibold text-sm hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors">Remover Logo</button>
              <button class="bg-primary text-white px-4 py-2 rounded-lg font-semibold text-sm hover:brightness-110 transition-all">Alterar Logo</button>
            </div>
          </div>
        </div>

        <!-- Fotos do Estabelecimento -->
        <div class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm p-6">
          <h3 class="font-bold text-base mb-1">Fotos do Estabelecimento</h3>
          <p class="text-sm text-slate-500 mb-4">Adicione até 8 fotos para mostrar seu espaço e produtos. (campo <code class="text-xs bg-slate-100 dark:bg-slate-800 px-1 py-0.5 rounded">fotos_estabelecimento</code>)</p>
          <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
            <div class="aspect-square rounded-xl bg-slate-100 dark:bg-slate-800 border-2 border-dashed border-slate-300 dark:border-slate-700 flex flex-col items-center justify-center gap-1 cursor-pointer hover:border-primary hover:bg-primary/5 transition-colors">
              <span class="material-symbols-outlined text-2xl text-slate-400">add_photo_alternate</span>
              <span class="text-xs text-slate-400 font-medium">Adicionar foto</span>
            </div>
            <div class="aspect-square rounded-xl bg-slate-200 dark:bg-slate-700 overflow-hidden relative group cursor-pointer">
              <div class="w-full h-full bg-gradient-to-br from-amber-200 to-orange-300 flex items-center justify-center">
                <span class="material-symbols-outlined text-3xl text-white/70">bakery_dining</span>
              </div>
              <div class="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-2">
                <button class="bg-white/90 p-1.5 rounded-lg"><span class="material-symbols-outlined text-sm text-slate-800">delete</span></button>
              </div>
            </div>
            <div class="aspect-square rounded-xl bg-slate-200 dark:bg-slate-700 overflow-hidden relative group cursor-pointer">
              <div class="w-full h-full bg-gradient-to-br from-yellow-200 to-amber-300 flex items-center justify-center">
                <span class="material-symbols-outlined text-3xl text-white/70">coffee</span>
              </div>
              <div class="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-2">
                <button class="bg-white/90 p-1.5 rounded-lg"><span class="material-symbols-outlined text-sm text-slate-800">delete</span></button>
              </div>
            </div>
            <div class="aspect-square rounded-xl bg-slate-100 dark:bg-slate-800 border-2 border-dashed border-slate-300 dark:border-slate-700 flex flex-col items-center justify-center gap-1 cursor-pointer hover:border-primary hover:bg-primary/5 transition-colors">
              <span class="material-symbols-outlined text-2xl text-slate-400">add_photo_alternate</span>
              <span class="text-xs text-slate-400 font-medium">Adicionar foto</span>
            </div>
          </div>
        </div>
      </div>

      <!-- ===== TAB: INFORMAÇÕES GERAIS ===== -->
      <div id="tab-info" class="section-card space-y-6 hidden">
        <div class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm p-6 space-y-5">
          <h3 class="font-bold text-base text-slate-700 dark:text-slate-300 flex items-center gap-2">
            <span class="material-symbols-outlined text-primary">storefront</span> Dados Públicos
          </h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Nome Fantasia <span class="text-primary">*</span></label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm transition-all" type="text" value="Padoca Express - Unidade Central" placeholder="Nome exibido no marketplace"/>
              <p class="text-xs text-slate-400">Campo: <code>nome_fantasia</code></p>
            </div>
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Slug (URL) <span class="text-primary">*</span></label>
              <div class="flex items-center bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl overflow-hidden focus-within:ring-2 focus-within:ring-primary/30 focus-within:border-primary">
                <span class="px-3 text-slate-400 text-sm border-r border-slate-200 dark:border-slate-700 py-3 bg-slate-100 dark:bg-slate-700">padoca.app/</span>
                <input class="flex-1 bg-transparent px-3 py-3 text-sm outline-none" type="text" value="padoca-express-central"/>
              </div>
              <p class="text-xs text-slate-400">Campo: <code>slug</code></p>
            </div>
            <div class="space-y-1.5 md:col-span-2">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Categoria do Estabelecimento</label>
              <select class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm">
                <option>🥐 Padaria e Confeitaria</option>
                <option>🍕 Pizzaria</option>
                <option>🍔 Lanchonete</option>
                <option>🍣 Japonês</option>
                <option>🥗 Saudável / Natural</option>
              </select>
              <p class="text-xs text-slate-400">Campo: <code>categoria_estabelecimento_id</code></p>
            </div>
            <div class="space-y-1.5 md:col-span-2">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Tags</label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="text" value="pão, café da manhã, artesanal, delivery" placeholder="Ex: pão, café, orgânico"/>
              <p class="text-xs text-slate-400">Campo: <code>tags[]</code> — separe por vírgula</p>
            </div>
            <div class="space-y-1.5 md:col-span-2">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Descrição</label>
              <textarea class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm resize-none" rows="3">Pães fresquinhos a cada hora, cafés especiais e confeitaria artesanal no coração da cidade.</textarea>
              <p class="text-xs text-slate-400">Campo: <code>descricao</code></p>
            </div>
          </div>
        </div>

        <div class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm p-6 space-y-5">
          <h3 class="font-bold text-base text-slate-700 dark:text-slate-300 flex items-center gap-2">
            <span class="material-symbols-outlined text-primary">contacts</span> Contato Comercial
          </h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Telefone Comercial</label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="tel" placeholder="(86) 3232-0000"/>
              <p class="text-xs text-slate-400">Campo: <code>telefone_comercial</code></p>
            </div>
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">WhatsApp</label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="tel" placeholder="(86) 99999-0000"/>
              <p class="text-xs text-slate-400">Campo: <code>whatsapp</code></p>
            </div>
            <div class="space-y-1.5 md:col-span-2">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">E-mail Comercial</label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="email" placeholder="contato@padocaexpress.com.br"/>
              <p class="text-xs text-slate-400">Campo: <code>email_comercial</code></p>
            </div>
          </div>
        </div>

        <div class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm p-6 space-y-5">
          <h3 class="font-bold text-base text-slate-700 dark:text-slate-300 flex items-center gap-2">
            <span class="material-symbols-outlined text-primary">business</span> Dados Jurídicos
          </h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Razão Social</label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="text" placeholder="Padoca Express Alimentos LTDA"/>
              <p class="text-xs text-slate-400">Campo: <code>razao_social</code></p>
            </div>
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">CNPJ</label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="text" placeholder="00.000.000/0001-00"/>
              <p class="text-xs text-slate-400">Campo: <code>cnpj</code></p>
            </div>
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Inscrição Estadual</label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="text" placeholder="Opcional"/>
              <p class="text-xs text-slate-400">Campo: <code>inscricao_estadual</code></p>
            </div>
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Inscrição Municipal</label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="text" placeholder="Opcional"/>
              <p class="text-xs text-slate-400">Campo: <code>inscricao_municipal</code></p>
            </div>
          </div>
        </div>
      </div>

      <!-- ===== TAB: ENDEREÇO ===== -->
      <div id="tab-address" class="section-card space-y-6 hidden">
        <div class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm p-6 space-y-5">
          <h3 class="font-bold text-base text-slate-700 dark:text-slate-300 flex items-center gap-2">
            <span class="material-symbols-outlined text-primary">location_on</span> Endereço do Estabelecimento
          </h3>
          <p class="text-sm text-slate-500">Campos armazenados no objeto <code class="text-xs bg-slate-100 dark:bg-slate-800 px-1.5 py-0.5 rounded">endereco</code> (jsonb)</p>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">CEP <span class="text-primary">*</span></label>
              <div class="flex gap-2">
                <input class="flex-1 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="text" placeholder="64000-000"/>
                <button class="bg-primary/10 text-primary px-3 py-3 rounded-xl font-semibold text-sm hover:bg-primary/20 transition-colors">
                  <span class="material-symbols-outlined text-base">search</span>
                </button>
              </div>
            </div>
            <div class="space-y-1.5 md:col-span-2">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Logradouro <span class="text-primary">*</span></label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="text" placeholder="Rua, Avenida..."/>
            </div>
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Número <span class="text-primary">*</span></label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="text" placeholder="123"/>
            </div>
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Complemento</label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="text" placeholder="Sala, Loja..."/>
            </div>
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Bairro <span class="text-primary">*</span></label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="text" placeholder="Centro"/>
            </div>
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Cidade <span class="text-primary">*</span></label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="text" placeholder="Teresina"/>
            </div>
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Estado <span class="text-primary">*</span></label>
              <select class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm">
                <option>PI</option><option>AC</option><option>AL</option><option>AM</option><option>AP</option>
                <option>BA</option><option>CE</option><option>DF</option><option>ES</option><option>GO</option>
                <option>MA</option><option>MG</option><option>MS</option><option>MT</option><option>PA</option>
                <option>PB</option><option>PE</option><option>PR</option><option>RJ</option><option>RN</option>
                <option>RO</option><option>RR</option><option>RS</option><option>SC</option><option>SE</option>
                <option>SP</option><option>TO</option>
              </select>
            </div>
          </div>
        </div>

        <div class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm p-6 space-y-5">
          <h3 class="font-bold text-base text-slate-700 dark:text-slate-300 flex items-center gap-2">
            <span class="material-symbols-outlined text-primary">my_location</span> Coordenadas Geográficas
          </h3>
          <p class="text-sm text-slate-500">Usadas para calcular distância e exibir no mapa. Preenchidas automaticamente ao buscar o CEP.</p>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Latitude</label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm font-mono" type="text" placeholder="-5.0892"/>
              <p class="text-xs text-slate-400">Campo: <code>latitude</code></p>
            </div>
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Longitude</label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm font-mono" type="text" placeholder="-42.8019"/>
              <p class="text-xs text-slate-400">Campo: <code>longitude</code></p>
            </div>
          </div>
          <!-- Fake Map Placeholder -->
          <div class="h-44 rounded-xl bg-slate-100 dark:bg-slate-800 flex items-center justify-center relative overflow-hidden border border-slate-200 dark:border-slate-700">
            <div class="absolute inset-0 opacity-20" style="background-image: repeating-linear-gradient(0deg,#94a3b8 0,#94a3b8 1px,transparent 0,transparent 50%), repeating-linear-gradient(90deg,#94a3b8 0,#94a3b8 1px,transparent 0,transparent 50%); background-size: 30px 30px;"></div>
            <div class="text-center z-10">
              <span class="material-symbols-outlined text-4xl text-primary">location_on</span>
              <p class="text-sm font-semibold text-slate-500 mt-1">Mapa será exibido após inserir coordenadas</p>
            </div>
          </div>
        </div>
      </div>

      <!-- ===== TAB: HORÁRIOS ===== -->
      <div id="tab-hours" class="section-card hidden">
        <div class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
          <div class="p-6 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between">
            <div>
              <h3 class="font-bold text-base text-slate-700 dark:text-slate-300 flex items-center gap-2">
                <span class="material-symbols-outlined text-primary">schedule</span> Horário de Funcionamento
              </h3>
              <p class="text-xs text-slate-400 mt-0.5">Campo: <code>horario_funcionamento</code> (jsonb)</p>
            </div>
            <button onclick="copyWeekdays()" class="text-sm text-primary font-semibold hover:underline flex items-center gap-1">
              <span class="material-symbols-outlined text-base">content_copy</span> Copiar Seg–Sex
            </button>
          </div>
          <div class="divide-y divide-slate-100 dark:divide-slate-800" id="scheduleRows">
          </div>
        </div>

        <div class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm p-6 mt-6 space-y-4">
          <h3 class="font-bold text-base text-slate-700 dark:text-slate-300 flex items-center gap-2">
            <span class="material-symbols-outlined text-primary">delivery_dining</span> Tempo Médio de Entrega
          </h3>
          <div class="flex items-center gap-4">
            <div class="flex-1">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300 block mb-1.5">Tempo médio (min)</label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="number" value="40" min="10" max="180"/>
              <p class="text-xs text-slate-400 mt-1">Campo: <code>tempo_medio_entrega_min</code></p>
            </div>
            <div class="flex-1">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300 block mb-1.5">Tempo médio de preparo (min)</label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="number" value="30" min="5" max="120"/>
              <p class="text-xs text-slate-400 mt-1">Campo: <code>config_entrega.tempo_medio_preparo_min</code></p>
            </div>
          </div>
        </div>
      </div>

      <!-- ===== TAB: ENTREGA ===== -->
      <div id="tab-delivery" class="section-card space-y-6 hidden">
        <div class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm p-6 space-y-5">
          <h3 class="font-bold text-base text-slate-700 dark:text-slate-300 flex items-center gap-2">
            <span class="material-symbols-outlined text-primary">local_shipping</span> Configurações de Entrega
          </h3>
          <p class="text-sm text-slate-500">Campo: <code class="text-xs bg-slate-100 dark:bg-slate-800 px-1 py-0.5 rounded">config_entrega</code> (jsonb)</p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Taxa de Entrega Fixa (R$)</label>
              <div class="flex items-center bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl overflow-hidden focus-within:ring-2 focus-within:ring-primary/30 focus-within:border-primary">
                <span class="px-3 text-slate-500 text-sm border-r border-slate-200 dark:border-slate-700 py-3 bg-slate-100 dark:bg-slate-700 font-bold">R$</span>
                <input class="flex-1 bg-transparent px-3 py-3 text-sm outline-none" type="number" value="5.00" step="0.50" min="0"/>
              </div>
              <p class="text-xs text-slate-400"><code>taxa_entrega_fixa</code></p>
            </div>
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Taxa por KM (R$)</label>
              <div class="flex items-center bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl overflow-hidden focus-within:ring-2 focus-within:ring-primary/30 focus-within:border-primary">
                <span class="px-3 text-slate-500 text-sm border-r border-slate-200 dark:border-slate-700 py-3 bg-slate-100 dark:bg-slate-700 font-bold">R$</span>
                <input class="flex-1 bg-transparent px-3 py-3 text-sm outline-none" type="number" value="2.00" step="0.10" min="0"/>
              </div>
              <p class="text-xs text-slate-400"><code>taxa_por_km</code></p>
            </div>
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Pedido Mínimo (R$)</label>
              <div class="flex items-center bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl overflow-hidden focus-within:ring-2 focus-within:ring-primary/30 focus-within:border-primary">
                <span class="px-3 text-slate-500 text-sm border-r border-slate-200 dark:border-slate-700 py-3 bg-slate-100 dark:bg-slate-700 font-bold">R$</span>
                <input class="flex-1 bg-transparent px-3 py-3 text-sm outline-none" type="number" value="15.00" step="1" min="0"/>
              </div>
              <p class="text-xs text-slate-400"><code>pedido_minimo</code></p>
            </div>
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Frete Grátis Acima de (R$)</label>
              <div class="flex items-center bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl overflow-hidden focus-within:ring-2 focus-within:ring-primary/30 focus-within:border-primary">
                <span class="px-3 text-slate-500 text-sm border-r border-slate-200 dark:border-slate-700 py-3 bg-slate-100 dark:bg-slate-700 font-bold">R$</span>
                <input class="flex-1 bg-transparent px-3 py-3 text-sm outline-none" type="number" value="50.00" step="5" min="0"/>
              </div>
              <p class="text-xs text-slate-400"><code>gratis_acima_de</code> — deixe 0 para desativar</p>
            </div>
            <div class="space-y-1.5 md:col-span-2">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Raio Máximo de Entrega (km)</label>
              <div class="flex items-center gap-4">
                <input type="range" class="flex-1 accent-primary h-2" min="1" max="30" value="8" id="raioSlider" oninput="document.getElementById('raioVal').textContent=this.value"/>
                <span class="bg-primary text-white text-sm font-bold px-3 py-1.5 rounded-lg min-w-[60px] text-center" id="raioVal">8 km</span>
              </div>
              <p class="text-xs text-slate-400"><code>raio_maximo_km</code></p>
            </div>
          </div>
        </div>

        <!-- Visual summary card -->
        <div class="bg-primary/5 border border-primary/20 rounded-2xl p-5">
          <h4 class="font-bold text-sm text-primary mb-3 flex items-center gap-2">
            <span class="material-symbols-outlined text-base">info</span> Resumo das Taxas de Entrega
          </h4>
          <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 text-center">
            <div class="bg-white dark:bg-slate-900 rounded-xl p-3 border border-slate-200 dark:border-slate-800">
              <p class="text-xs text-slate-500 font-medium">Taxa Fixa</p>
              <p class="text-lg font-bold text-slate-800 dark:text-slate-100">R$ 5,00</p>
            </div>
            <div class="bg-white dark:bg-slate-900 rounded-xl p-3 border border-slate-200 dark:border-slate-800">
              <p class="text-xs text-slate-500 font-medium">Por KM</p>
              <p class="text-lg font-bold text-slate-800 dark:text-slate-100">R$ 2,00</p>
            </div>
            <div class="bg-white dark:bg-slate-900 rounded-xl p-3 border border-slate-200 dark:border-slate-800">
              <p class="text-xs text-slate-500 font-medium">Grátis Acima</p>
              <p class="text-lg font-bold text-slate-800 dark:text-slate-100">R$ 50,00</p>
            </div>
            <div class="bg-white dark:bg-slate-900 rounded-xl p-3 border border-slate-200 dark:border-slate-800">
              <p class="text-xs text-slate-500 font-medium">Raio Máximo</p>
              <p class="text-lg font-bold text-slate-800 dark:text-slate-100">8 km</p>
            </div>
          </div>
        </div>
      </div>

      <!-- ===== TAB: AVANÇADO ===== -->
      <div id="tab-advanced" class="section-card space-y-6 hidden">
        <div class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm p-6 space-y-5">
          <h3 class="font-bold text-base text-slate-700 dark:text-slate-300 flex items-center gap-2">
            <span class="material-symbols-outlined text-primary">tune</span> Configurações Avançadas
          </h3>
          <p class="text-sm text-slate-500">Campo: <code class="text-xs bg-slate-100 dark:bg-slate-800 px-1 py-0.5 rounded">config_avancada</code> (jsonb)</p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Tempo Mínimo de Entrega (min)</label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="number" value="15" min="5"/>
              <p class="text-xs text-slate-400"><code>tempo_minimo_entrega_min</code></p>
            </div>
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Tempo Máximo de Entrega (min)</label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="number" value="60" min="10"/>
              <p class="text-xs text-slate-400"><code>tempo_maximo_entrega_min</code></p>
            </div>
            <div class="space-y-1.5 md:col-span-2">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Intervalo de Atualização de Estoque (min)</label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="number" value="5" min="1"/>
              <p class="text-xs text-slate-400"><code>intervalo_atualizacao_estoque_min</code></p>
            </div>
          </div>

          <!-- Toggles section -->
          <div class="pt-2 space-y-4">
            <div class="flex items-center justify-between p-4 bg-slate-50 dark:bg-slate-800 rounded-xl">
              <div>
                <p class="font-bold text-sm">Aceita Agendamento</p>
                <p class="text-xs text-slate-500 mt-0.5">Permite que clientes façam pedidos agendados. Campo: <code>aceita_agendamento</code></p>
              </div>
              <label class="relative inline-flex items-center cursor-pointer">
                <input type="checkbox" class="sr-only peer" id="toggleAgendamento"/>
                <div class="w-11 h-6 bg-slate-200 rounded-full peer peer-checked:bg-primary after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-5"></div>
              </label>
            </div>

            <div id="agendamentoConfig" class="hidden p-4 bg-primary/5 border border-primary/20 rounded-xl space-y-3">
              <div class="space-y-1.5">
                <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Antecedência Mínima para Agendamento (min)</label>
                <input class="w-full bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="number" value="60" min="30"/>
                <p class="text-xs text-slate-400"><code>tempo_antecedencia_agendamento_min</code></p>
              </div>
            </div>
          </div>
        </div>

        <!-- Danger Zone -->
        <div class="bg-red-50 dark:bg-red-900/10 rounded-2xl border border-red-100 dark:border-red-900/30 p-6">
          <h3 class="text-red-700 dark:text-red-400 font-bold text-base mb-1 flex items-center gap-2">
            <span class="material-symbols-outlined text-base">warning</span> Zona de Atenção
          </h3>
          <div class="space-y-4 mt-4">
            <div class="flex items-center justify-between gap-4 flex-wrap">
              <div>
                <p class="font-bold text-sm text-red-700 dark:text-red-400">Desativar Loja Temporariamente</p>
                <p class="text-xs text-red-600/70 dark:text-red-400/60">Sua loja ficará invisível no marketplace enquanto desativada. Campo: <code>status_aberto</code></p>
              </div>
              <button class="border border-red-500 text-red-600 dark:border-red-400 dark:text-red-400 px-5 py-2.5 rounded-xl font-bold text-sm hover:bg-red-500 hover:text-white transition-all">
                Desativar Loja
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- ===== TAB: RESPONSÁVEL ===== -->
      <div id="tab-responsible" class="section-card hidden">
        <div class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm p-6 space-y-5">
          <div class="flex items-start justify-between gap-3">
            <div>
              <h3 class="font-bold text-base text-slate-700 dark:text-slate-300 flex items-center gap-2">
                <span class="material-symbols-outlined text-primary">person</span> Dados do Responsável Legal
              </h3>
              <p class="text-sm text-slate-500 mt-1">Informações do responsável pela conta. Esses dados são confidenciais.</p>
            </div>
            <span class="bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400 text-xs font-bold px-3 py-1 rounded-full flex items-center gap-1 whitespace-nowrap">
              <span class="material-symbols-outlined text-sm">lock</span> Dados sensíveis
            </span>
          </div>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Nome Completo <span class="text-primary">*</span></label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="text" placeholder="Nome completo do responsável"/>
              <p class="text-xs text-slate-400">Campo: <code>responsavel_nome</code></p>
            </div>
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">CPF <span class="text-primary">*</span></label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm font-mono" type="text" placeholder="000.000.000-00"/>
              <p class="text-xs text-slate-400">Campo: <code>responsavel_cpf</code></p>
            </div>
          </div>
          <div class="bg-blue-50 dark:bg-blue-900/10 border border-blue-100 dark:border-blue-900/30 rounded-xl p-4 flex items-start gap-3">
            <span class="material-symbols-outlined text-blue-500 text-base mt-0.5">info</span>
            <p class="text-xs text-blue-700 dark:text-blue-400">Alterações nos dados do responsável podem requerer revalidação dos documentos. Em caso de dúvida, entre em contato com o suporte.</p>
          </div>
        </div>
      </div>

      <!-- ===== TAB: DADOS BANCÁRIOS ===== -->
      <div id="tab-banking" class="section-card hidden">
        <div class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm p-6 space-y-5">
          <div class="flex items-start justify-between gap-3">
            <div>
              <h3 class="font-bold text-base text-slate-700 dark:text-slate-300 flex items-center gap-2">
                <span class="material-symbols-outlined text-primary">account_balance</span> Dados Bancários
              </h3>
              <p class="text-sm text-slate-500 mt-1">Conta para recebimento dos pagamentos. Campo: <code class="text-xs bg-slate-100 dark:bg-slate-800 px-1 py-0.5 rounded">dados_bancarios</code> (jsonb)</p>
            </div>
            <span class="bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400 text-xs font-bold px-3 py-1 rounded-full flex items-center gap-1 whitespace-nowrap">
              <span class="material-symbols-outlined text-sm">security</span> Dados protegidos
            </span>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div class="space-y-1.5 md:col-span-2">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Tipo de Conta</label>
              <div class="flex gap-3">
                <label class="flex-1 flex items-center gap-3 bg-slate-50 dark:bg-slate-800 border-2 border-slate-200 dark:border-slate-700 rounded-xl p-4 cursor-pointer hover:border-primary transition-colors has-[:checked]:border-primary has-[:checked]:bg-primary/5">
                  <input type="radio" name="tipoConta" value="corrente" class="accent-primary" checked/>
                  <div>
                    <p class="font-bold text-sm">Conta Corrente</p>
                    <p class="text-xs text-slate-400">Pessoa Jurídica ou Física</p>
                  </div>
                </label>
                <label class="flex-1 flex items-center gap-3 bg-slate-50 dark:bg-slate-800 border-2 border-slate-200 dark:border-slate-700 rounded-xl p-4 cursor-pointer hover:border-primary transition-colors has-[:checked]:border-primary has-[:checked]:bg-primary/5">
                  <input type="radio" name="tipoConta" value="poupanca" class="accent-primary"/>
                  <div>
                    <p class="font-bold text-sm">Conta Poupança</p>
                    <p class="text-xs text-slate-400">Pessoa Física</p>
                  </div>
                </label>
              </div>
              <p class="text-xs text-slate-400"><code>tipo_conta</code></p>
            </div>

            <div class="space-y-1.5 md:col-span-2">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Banco <span class="text-primary">*</span></label>
              <select class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm">
                <option value="">Selecione o banco</option>
                <option value="001">001 - Banco do Brasil</option>
                <option value="033">033 - Santander</option>
                <option value="104">104 - Caixa Econômica Federal</option>
                <option value="237">237 - Bradesco</option>
                <option value="341">341 - Itaú</option>
                <option value="260">260 - Nu Pagamentos (Nubank)</option>
                <option value="336">336 - C6 Bank</option>
                <option value="077">077 - Banco Inter</option>
                <option value="212">212 - Banco Original</option>
              </select>
              <p class="text-xs text-slate-400"><code>banco</code></p>
            </div>

            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Agência <span class="text-primary">*</span></label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm font-mono" type="text" placeholder="0000"/>
              <p class="text-xs text-slate-400"><code>agencia</code></p>
            </div>
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Conta <span class="text-primary">*</span></label>
              <div class="flex gap-2">
                <input class="flex-1 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm font-mono" type="text" placeholder="00000000"/>
                <input class="w-16 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-3 py-3 text-sm font-mono text-center" type="text" placeholder="0" maxlength="1"/>
              </div>
              <p class="text-xs text-slate-400"><code>conta</code> + <code>conta_digito</code></p>
            </div>

            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">Nome do Titular <span class="text-primary">*</span></label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm" type="text" placeholder="Nome completo como no banco"/>
              <p class="text-xs text-slate-400"><code>titular</code></p>
            </div>
            <div class="space-y-1.5">
              <label class="text-sm font-bold text-slate-700 dark:text-slate-300">CPF/CNPJ do Titular <span class="text-primary">*</span></label>
              <input class="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-primary/30 focus:border-primary px-4 py-3 text-sm font-mono" type="text" placeholder="000.000.000-00 ou 00.000.000/0001-00"/>
              <p class="text-xs text-slate-400"><code>cpf_cnpj_titular</code></p>
            </div>
          </div>

          <div class="bg-amber-50 dark:bg-amber-900/10 border border-amber-100 dark:border-amber-900/30 rounded-xl p-4 flex items-start gap-3">
            <span class="material-symbols-outlined text-amber-500 text-base mt-0.5">warning</span>
            <p class="text-xs text-amber-700 dark:text-amber-400">
              Os dados bancários são criptografados e usados exclusivamente para repasse dos valores das vendas via Asaas. Alterações podem levar até 2 dias úteis para ser validadas.
            </p>
          </div>
        </div>
      </div>

    </div>
  </main>
</div>

<!-- Toast notification -->
<div id="toast" class="fixed bottom-6 right-6 bg-slate-900 text-white px-5 py-3.5 rounded-2xl shadow-2xl flex items-center gap-3 translate-y-24 opacity-0 transition-all duration-300 z-50">
  <span class="material-symbols-outlined text-green-400">check_circle</span>
  <span class="font-semibold text-sm">Alterações salvas com sucesso!</span>
</div>

<script>
  // Tab switching
  function showTab(tabId) {
    document.querySelectorAll('[id^="tab-"]').forEach(el => el.classList.add('hidden'));
    document.getElementById('tab-' + tabId).classList.remove('hidden');
    document.querySelectorAll('.tab-btn').forEach(btn => {
      btn.classList.remove('active');
      if (btn.dataset.tab === tabId) btn.classList.add('active');
    });
  }

  // Schedule rows
  const days = [
    { key: 'seg', label: 'Segunda-feira',  start: '06:00', end: '20:00', open: true },
    { key: 'ter', label: 'Terça-feira',    start: '06:00', end: '20:00', open: true },
    { key: 'qua', label: 'Quarta-feira',   start: '06:00', end: '20:00', open: true },
    { key: 'qui', label: 'Quinta-feira',   start: '06:00', end: '20:00', open: true },
    { key: 'sex', label: 'Sexta-feira',    start: '06:00', end: '20:00', open: true },
    { key: 'sab', label: 'Sábado',         start: '07:00', end: '19:00', open: true },
    { key: 'dom', label: 'Domingo',        start: '08:00', end: '14:00', open: false },
  ];

  const container = document.getElementById('scheduleRows');
  days.forEach(day => {
    const row = document.createElement('div');
    row.id = 'row-' + day.key;
    row.className = 'p-5 flex flex-col md:flex-row md:items-center justify-between gap-4' + (!day.open ? ' bg-slate-50/60 dark:bg-slate-800/20' : '');
    row.innerHTML = `
      <div class="flex items-center gap-4 min-w-[180px]">
        <label class="relative inline-flex items-center cursor-pointer">
          <input type="checkbox" class="sr-only peer" ${day.open ? 'checked' : ''} onchange="toggleDay('${day.key}', this.checked)"/>
          <div class="w-11 h-6 bg-slate-200 rounded-full peer dark:bg-slate-700 peer-checked:bg-primary after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-5"></div>
        </label>
        <span class="font-bold ${!day.open ? 'text-slate-400' : ''}" id="label-${day.key}">${day.label}</span>
      </div>
      <div class="flex items-center gap-3 ${!day.open ? 'opacity-40 pointer-events-none' : ''}" id="times-${day.key}">
        <input class="bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3 py-2.5 text-sm focus:ring-2 focus:ring-primary/30 focus:border-primary" type="time" value="${day.start}"/>
        <span class="text-slate-400 font-medium">até</span>
        <input class="bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-3 py-2.5 text-sm focus:ring-2 focus:ring-primary/30 focus:border-primary" type="time" value="${day.end}"/>
      </div>
      ${!day.open ? '<span class="text-sm font-semibold text-slate-400" id="closed-label-'+day.key+'">Fechado</span>' : '<span class="text-xs text-slate-400 hidden" id="closed-label-'+day.key+'">Fechado</span>'}
    `;
    container.appendChild(row);
    if (day.key !== days[days.length - 1].key) {
      const divider = document.createElement('div');
      divider.className = 'border-t border-slate-100 dark:border-slate-800';
      container.appendChild(divider);
    }
  });

  function toggleDay(key, isOpen) {
    const timesEl = document.getElementById('times-' + key);
    const labelEl = document.getElementById('label-' + key);
    const closedLabel = document.getElementById('closed-label-' + key);
    const rowEl = document.getElementById('row-' + key);
    if (isOpen) {
      timesEl.classList.remove('opacity-40', 'pointer-events-none');
      labelEl.classList.remove('text-slate-400');
      closedLabel.classList.add('hidden');
      rowEl.classList.remove('bg-slate-50/60', 'dark:bg-slate-800/20');
    } else {
      timesEl.classList.add('opacity-40', 'pointer-events-none');
      labelEl.classList.add('text-slate-400');
      closedLabel.classList.remove('hidden');
      rowEl.classList.add('bg-slate-50/60', 'dark:bg-slate-800/20');
    }
  }

  function copyWeekdays() {
    const segStart = document.querySelector('#times-seg input[type=time]:first-child')?.value;
    const segEnd = document.querySelector('#times-seg input[type=time]:last-child')?.value;
    ['ter', 'qua', 'qui', 'sex'].forEach(key => {
      const inputs = document.querySelectorAll(`#times-${key} input[type=time]`);
      if (inputs[0]) inputs[0].value = segStart;
      if (inputs[1]) inputs[1].value = segEnd;
    });
  }

  // Agendamento toggle
  document.getElementById('toggleAgendamento').addEventListener('change', function() {
    document.getElementById('agendamentoConfig').classList.toggle('hidden', !this.checked);
  });

  // Save toast
  function saveChanges() {
    const toast = document.getElementById('toast');
    toast.classList.remove('translate-y-24', 'opacity-0');
    setTimeout(() => toast.classList.add('translate-y-24', 'opacity-0'), 3000);
  }

  // Slider display
  document.getElementById('raioSlider').addEventListener('input', function() {
    document.getElementById('raioVal').textContent = this.value + ' km';
  });
</script>
</body>
</html>