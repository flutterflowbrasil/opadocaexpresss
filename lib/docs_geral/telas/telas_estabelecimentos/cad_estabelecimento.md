<!DOCTYPE html>
<html class="light" lang="pt-BR"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#ff7033",
                        "background-light": "#f9f5f0",
                        "background-dark": "#23150f",
                        "burgundy": "#7d2d35",
                    },
                    fontFamily: {
                        "display": ["Plus Jakarta Sans", "sans-serif"]
                    },
                    borderRadius: {
                        "DEFAULT": "0.5rem",
                        "lg": "1rem",
                        "xl": "1.5rem",
                        "full": "9999px"
                    },
                },
            },
        }
    </script>
<style>
        body {
            font-family: 'Plus Jakarta Sans', sans-serif;
            min-height: max(884px, 100dvh);
        }
        .material-symbols-outlined {
            font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-light dark:bg-background-dark text-burgundy dark:text-gray-100 min-h-screen flex flex-col">
<header class="sticky top-0 z-50 bg-background-light/95 dark:bg-background-dark/95 backdrop-blur-sm px-4 py-3 border-b border-burgundy/10 flex items-center justify-between">
<button class="flex items-center justify-center size-10 rounded-full hover:bg-primary/10 transition-colors">
<span class="material-symbols-outlined text-burgundy dark:text-gray-100">arrow_back_ios_new</span>
</button>
<div class="flex flex-col items-center">
<div class="flex items-center gap-2">
<div class="size-6 bg-primary rounded-full flex items-center justify-center">
<span class="material-symbols-outlined text-white text-[16px]">bakery_dining</span>
</div>
<h2 class="text-burgundy dark:text-gray-100 text-sm font-bold tracking-tight">ÔPADOCA EXPRESS</h2>
</div>
</div>
<div class="size-10"></div>
</header>
<main class="flex-1 overflow-y-auto px-4 pb-10">
<div class="pt-8 pb-6 text-center">
<h1 class="text-2xl font-bold text-burgundy dark:text-gray-100 leading-tight">Cadastro de Estabelecimento</h1>
<p class="text-burgundy/70 dark:text-gray-400 text-sm mt-2">Seja um parceiro e comece a vender suas delícias.</p>
</div>
<form class="space-y-8">
<div class="flex flex-col items-center gap-4">
<label class="w-full flex flex-col items-center gap-3 rounded-xl border-2 border-dashed border-primary/30 bg-primary/5 px-6 py-10 cursor-pointer hover:bg-primary/10 transition-all">
<div class="size-16 bg-primary rounded-full flex items-center justify-center shadow-lg shadow-primary/20">
<span class="material-symbols-outlined text-white text-3xl">photo_camera</span>
</div>
<div class="text-center">
<p class="text-burgundy dark:text-gray-100 font-bold">Foto da Padaria</p>
<p class="text-burgundy/60 dark:text-gray-400 text-xs mt-1">Banner ou logo da loja (PNG, JPG)</p>
</div>
<input accept="image/*" class="hidden" type="file"/>
</label>
</div>
<div class="space-y-4">
<div class="flex items-center gap-2 mb-2">
<span class="material-symbols-outlined text-primary">storefront</span>
<h3 class="text-lg font-bold text-burgundy dark:text-gray-100">Informações da Loja</h3>
</div>
<div class="space-y-3">
<div class="relative">
<span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-burgundy/40 dark:text-gray-500 text-xl">store</span>
<input class="w-full pl-11 pr-4 py-3 rounded-lg border border-burgundy/20 bg-white dark:bg-gray-800 dark:border-gray-700 focus:border-primary focus:ring-1 focus:ring-primary outline-none text-sm transition-all" placeholder="Nome da Padaria/Loja" type="text"/>
</div>
<div class="grid grid-cols-1 md:grid-cols-2 gap-3">
<div class="relative">
<span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-burgundy/40 dark:text-gray-500 text-xl">badge</span>
<input class="w-full pl-11 pr-4 py-3 rounded-lg border border-burgundy/20 bg-white dark:bg-gray-800 dark:border-gray-700 focus:border-primary focus:ring-1 focus:ring-primary outline-none text-sm transition-all" placeholder="CNPJ: 00.000.000/0001-00" type="text"/>
</div>
<div class="relative">
<span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-burgundy/40 dark:text-gray-500 text-xl">call</span>
<input class="w-full pl-11 pr-4 py-3 rounded-lg border border-burgundy/20 bg-white dark:bg-gray-800 dark:border-gray-700 focus:border-primary focus:ring-1 focus:ring-primary outline-none text-sm transition-all" placeholder="Telefone Comercial" type="tel"/>
</div>
</div>
<div class="relative">
<span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-burgundy/40 dark:text-gray-500 text-xl">location_on</span>
<input class="w-full pl-11 pr-4 py-3 rounded-lg border border-burgundy/20 bg-white dark:bg-gray-800 dark:border-gray-700 focus:border-primary focus:ring-1 focus:ring-primary outline-none text-sm transition-all" placeholder="Endereço Completo" type="text"/>
</div>
</div>
</div>
<div class="space-y-4">
<div class="flex items-center gap-2 mb-2">
<span class="material-symbols-outlined text-primary">person</span>
<h3 class="text-lg font-bold text-burgundy dark:text-gray-100">Responsável</h3>
</div>
<div class="space-y-3">
<div class="relative">
<span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-burgundy/40 dark:text-gray-500 text-xl">account_circle</span>
<input class="w-full pl-11 pr-4 py-3 rounded-lg border border-burgundy/20 bg-white dark:bg-gray-800 dark:border-gray-700 focus:border-primary focus:ring-1 focus:ring-primary outline-none text-sm transition-all" placeholder="Nome do Responsável" type="text"/>
</div>
<div class="relative">
<span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-burgundy/40 dark:text-gray-500 text-xl">id_card</span>
<input class="w-full pl-11 pr-4 py-3 rounded-lg border border-burgundy/20 bg-white dark:bg-gray-800 dark:border-gray-700 focus:border-primary focus:ring-1 focus:ring-primary outline-none text-sm transition-all" placeholder="CPF: 000.000.000-00" type="text"/>
</div>
</div>
</div>
<div class="space-y-4">
<div class="flex items-center gap-2 mb-2">
<span class="material-symbols-outlined text-primary">lock</span>
<h3 class="text-lg font-bold text-burgundy dark:text-gray-100">Credenciais de Acesso</h3>
</div>
<div class="space-y-3">
<div class="relative">
<span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-burgundy/40 dark:text-gray-500 text-xl">mail</span>
<input class="w-full pl-11 pr-4 py-3 rounded-lg border border-burgundy/20 bg-white dark:bg-gray-800 dark:border-gray-700 focus:border-primary focus:ring-1 focus:ring-primary outline-none text-sm transition-all" placeholder="E-mail" type="email"/>
</div>
<div class="relative">
<span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-burgundy/40 dark:text-gray-500 text-xl">key</span>
<input class="w-full pl-11 pr-12 py-3 rounded-lg border border-burgundy/20 bg-white dark:bg-gray-800 dark:border-gray-700 focus:border-primary focus:ring-1 focus:ring-primary outline-none text-sm transition-all" placeholder="Senha" type="password"/>
<span class="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-burgundy/40 dark:text-gray-500 cursor-pointer">visibility</span>
</div>
<div class="relative">
<span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-burgundy/40 dark:text-gray-500 text-xl">verified_user</span>
<input class="w-full pl-11 pr-12 py-3 rounded-lg border border-burgundy/20 bg-white dark:bg-gray-800 dark:border-gray-700 focus:border-primary focus:ring-1 focus:ring-primary outline-none text-sm transition-all" placeholder="Confirmar Senha" type="password"/>
</div>
</div>
</div>
<div class="space-y-4">
<div class="flex items-center gap-2 mb-2">
<span class="material-symbols-outlined text-primary">account_balance</span>
<h3 class="text-lg font-bold text-burgundy dark:text-gray-100">Informações de Repasse (ASAAS)</h3>
</div>
<div class="bg-primary/5 rounded-xl p-4 border border-primary/10">
<p class="text-xs text-burgundy/70 dark:text-gray-400 mb-4 leading-relaxed">
                        Os pagamentos serão processados via ASAAS. Certifique-se de que os dados bancários coincidem com o CNPJ informado.
                    </p>
<div class="space-y-3">
<div class="relative">
<span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-burgundy/40 dark:text-gray-500 text-xl">person_pin</span>
<input class="w-full pl-11 pr-4 py-3 rounded-lg border border-burgundy/20 bg-white dark:bg-gray-800 dark:border-gray-700 focus:border-primary focus:ring-1 focus:ring-primary outline-none text-sm transition-all" placeholder="Titular da Conta (Nome ou Razão Social)" type="text"/>
</div>
<div class="relative">
<span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-burgundy/40 dark:text-gray-500 text-xl">account_balance_wallet</span>
<select class="w-full pl-11 pr-10 py-3 rounded-lg border border-burgundy/20 bg-white dark:bg-gray-800 dark:border-gray-700 focus:border-primary focus:ring-1 focus:ring-primary outline-none text-sm transition-all appearance-none">
<option disabled="" selected="" value="">Tipo de Conta</option>
<option value="corrente">Conta Corrente</option>
<option value="poupanca">Conta Poupança</option>
</select>
<span class="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-burgundy/40 dark:text-gray-500 pointer-events-none">expand_more</span>
</div>
<div class="relative">
<span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-burgundy/40 dark:text-gray-500 text-xl">account_balance</span>
<input class="w-full pl-11 pr-4 py-3 rounded-lg border border-burgundy/20 bg-white dark:bg-gray-800 dark:border-gray-700 focus:border-primary focus:ring-1 focus:ring-primary outline-none text-sm transition-all" placeholder="Banco (Ex: Itaú, NuBank)" type="text"/>
</div>
<div class="grid grid-cols-2 gap-3">
<input class="w-full px-4 py-3 rounded-lg border border-burgundy/20 bg-white dark:bg-gray-800 dark:border-gray-700 focus:border-primary focus:ring-1 focus:ring-primary outline-none text-sm transition-all" placeholder="Agência" type="text"/>
<input class="w-full px-4 py-3 rounded-lg border border-burgundy/20 bg-white dark:bg-gray-800 dark:border-gray-700 focus:border-primary focus:ring-1 focus:ring-primary outline-none text-sm transition-all" placeholder="Conta com Dígito" type="text"/>
</div>
</div>
</div>
</div>
<div class="flex items-start gap-3 pt-2">
<input class="mt-1 size-5 rounded border-burgundy/20 text-primary focus:ring-primary cursor-pointer" id="terms" type="checkbox"/>
<label class="text-xs text-burgundy/70 dark:text-gray-400 leading-normal" for="terms">
                    Li e concordo com os <a class="text-primary font-bold underline" href="#">Termos de Serviço</a> e as <a class="text-primary font-bold underline" href="#">Políticas de Privacidade</a> da Padoca Express.
                </label>
</div>
<div class="pt-4">
<button class="w-full bg-primary hover:bg-primary/90 text-white font-bold py-4 rounded-xl shadow-lg shadow-primary/30 flex items-center justify-center gap-2 transition-all transform active:scale-[0.98]" type="submit">
<span class="material-symbols-outlined">storefront</span>
                    Cadastrar Estabelecimento
                </button>
<p class="text-center text-[10px] text-burgundy/40 dark:text-gray-500 mt-4 uppercase tracking-widest font-medium">
                    Plataforma Segura SSL/TLS
                </p>
</div>
</form>
</main>
<div class="hidden">
<img data-alt="Mapa decorativo mostrando localização de padarias" data-location="São Paulo" src="https://lh3.googleusercontent.com/aida-public/AB6AXuBMUFnFScUM8BBM6nCtLFXZoMy2DTIPZ1_45sB-QwpNz1JFCjVxgmuISPhG9bqhlJLuZlUY_fy2NA9BVlRe1N2HvxJjKc5H9WLlNPkK9RlVm__InlwUcEWgA2N-zYZ0InooPs1h6o_QZMZiaFr14dHfit47ID8RsQ7CnlAKDoSywGtOhO3nwD6Zx0d-a1IuD39bvtocYIUv1_nJfrTdeuIVj6CUKspzq4sY0-aIpBKG1Blu-qlcxP-IG08pEDVN722mFATp2a3_"/>
</div>

</body></html>