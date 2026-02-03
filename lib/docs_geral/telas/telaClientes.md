<!DOCTYPE html>
<html lang="pt-br"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Cadastro de Cliente - Padoca Express</title>
<link href="https://fonts.googleapis.com" rel="preconnect"/>
<link crossorigin="" href="https://fonts.gstatic.com" rel="preconnect"/>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/icon?family=Material+Icons+Outlined" rel="stylesheet"/>
<script src="https://cdn.tailwindcss.com?plugins=forms,typography"></script>
<script>
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        primary: "#FF7034", // Orange
                        burgundy: "#8B2635", // Dark burgundy seen in logo/text
                        "background-light": "#F9F5F0", // Cream
                        "background-dark": "#121212",
                        "card-light": "#FFFFFF",
                        "card-dark": "#1E1E1E",
                    },
                    fontFamily: {
                        display: ["Inter", "sans-serif"],
                    },
                    borderRadius: {
                        DEFAULT: "12px",
                    },
                },
            },
        };
    </script>
<style>
        body {
            font-family: 'Inter', sans-serif;
            -webkit-tap-highlight-color: transparent;
        }input[type="checkbox"]:checked {
            background-color: #FF7034;
            border-color: #FF7034;
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-light dark:bg-background-dark min-h-screen">
<div class="max-w-md mx-auto min-h-screen flex flex-col">
<header class="flex items-center justify-between px-4 py-4 sticky top-0 bg-background-light/80 dark:bg-background-dark/80 backdrop-blur-md z-10">
<button class="w-10 h-10 flex items-center justify-center rounded-full border border-gray-200 dark:border-gray-700 bg-white dark:bg-card-dark shadow-sm">
<span class="material-icons-outlined text-gray-700 dark:text-gray-200">arrow_back</span>
</button>
<div class="flex items-center gap-2">
<span class="material-icons-outlined text-burgundy dark:text-primary">bakery_dining</span>
<h1 class="font-bold text-burgundy dark:text-gray-100 uppercase tracking-wide text-sm">ÔPADOCA EXPRESS</h1>
</div>
<div class="w-10"></div> 
</header>
<main class="px-6 pb-10 flex-1 overflow-y-auto">
<div class="flex justify-center mb-6">
<div class="w-24 h-24 bg-white dark:bg-card-dark rounded-2xl shadow-sm flex items-center justify-center p-2">
<img alt="Opadoca Express Logo" class="rounded-lg object-contain" src="https://lh3.googleusercontent.com/aida-public/AB6AXuAr9i59tSNMlyejfjkpjoFxP9Vtfpyu43-4hXuuPymD4YkEtBZyUN5Q7n9rKgY6mFH4In0iV9h5jvbRRuedBSk_gTMIJMZsZbMMEy1LsksvboCJyzgn8d00_Q2o63S5iHCIDSiqbj-QbIvuXN4VpuJTIOK5P0DI0BaW1pgilvQ5vP_jBI1_eG_wvYxWaAfGskDb89sqPO1FtDftTOHYFkokz9_Sb52V6mAjHwTq6hwfgKBnT1Q9Bq5mwwtttRNEfdu6fYJvPOht"/>
</div>
</div>
<div class="mb-8">
<div class="flex items-center gap-2 text-burgundy dark:text-primary mb-1">
<span class="material-icons-outlined text-2xl font-bold">person_add</span>
<h2 class="text-2xl font-bold">Cadastro de Cliente</h2>
</div>
<p class="text-gray-500 dark:text-gray-400 text-sm">Crie sua conta e faça seus pedidos com facilidade.</p>
</div>
<form class="space-y-5" onsubmit="event.preventDefault();">
<div class="space-y-1.5">
<label class="block text-sm font-semibold text-burgundy dark:text-gray-300">Nome Completo</label>
<div class="relative">
<span class="material-icons-outlined absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-xl">person</span>
<input class="w-full pl-11 pr-4 py-3.5 bg-white dark:bg-card-dark border-gray-100 dark:border-gray-800 rounded-xl focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all text-gray-800 dark:text-gray-100" placeholder="Digite seu nome completo" type="text"/>
</div>
</div>
<div class="space-y-1.5">
<label class="block text-sm font-semibold text-burgundy dark:text-gray-300">Telefone/WhatsApp</label>
<div class="relative">
<span class="material-icons-outlined absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-xl">phone</span>
<input class="w-full pl-11 pr-4 py-3.5 bg-white dark:bg-card-dark border-gray-100 dark:border-gray-800 rounded-xl focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all text-gray-800 dark:text-gray-100" placeholder="(11) 99999-9999" type="tel"/>
</div>
</div>
<div class="space-y-1.5">
<label class="block text-sm font-semibold text-burgundy dark:text-gray-300">E-mail</label>
<div class="relative">
<span class="material-icons-outlined absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-xl">mail_outline</span>
<input class="w-full pl-11 pr-4 py-3.5 bg-white dark:bg-card-dark border-gray-100 dark:border-gray-800 rounded-xl focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all text-gray-800 dark:text-gray-100" placeholder="seu@email.com" type="email"/>
</div>
</div>
<div class="space-y-1.5">
<label class="block text-sm font-semibold text-burgundy dark:text-gray-300">Senha</label>
<div class="relative">
<span class="material-icons-outlined absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-xl">lock_outline</span>
<input class="w-full pl-11 pr-12 py-3.5 bg-white dark:bg-card-dark border-gray-100 dark:border-gray-800 rounded-xl focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all text-gray-800 dark:text-gray-100" placeholder="Mínimo 6 caracteres" type="password"/>
<button class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400" type="button">
<span class="material-icons-outlined text-xl">visibility_off</span>
</button>
</div>
</div>
<div class="space-y-1.5">
<label class="block text-sm font-semibold text-burgundy dark:text-gray-300">Confirmar Senha</label>
<div class="relative">
<span class="material-icons-outlined absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-xl">lock_outline</span>
<input class="w-full pl-11 pr-12 py-3.5 bg-white dark:bg-card-dark border-gray-100 dark:border-gray-800 rounded-xl focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all text-gray-800 dark:text-gray-100" placeholder="Digite a senha novamente" type="password"/>
<button class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400" type="button">
<span class="material-icons-outlined text-xl">visibility_off</span>
</button>
</div>
</div>
<div class="flex items-start gap-3 mt-4">
<div class="flex items-center h-5">
<input class="w-5 h-5 rounded border-gray-300 dark:border-gray-700 text-primary focus:ring-primary" id="terms" type="checkbox"/>
</div>
<label class="text-sm text-gray-500 dark:text-gray-400" for="terms">
                        Eu aceito os <span class="text-primary font-medium cursor-pointer">termos de serviço e política de privacidade</span>
</label>
</div>
<div class="bg-white/50 dark:bg-card-dark/40 border border-gray-100 dark:border-gray-800 p-4 rounded-2xl flex items-start gap-4">
<div class="bg-primary/10 p-2 rounded-xl">
<span class="material-icons-outlined text-primary">shopping_cart</span>
</div>
<div>
<h4 class="text-burgundy dark:text-primary font-bold text-sm">Pronto para fazer seus pedidos!</h4>
<p class="text-xs text-gray-500 dark:text-gray-400 leading-tight mt-1">Pães frescos, doces e muito mais direto na sua casa.</p>
</div>
</div>
<button class="w-full bg-primary hover:bg-orange-600 text-white font-bold py-4 rounded-2xl shadow-lg shadow-primary/20 transition-all flex items-center justify-center gap-2 mt-2" type="submit">
<span class="material-icons-outlined">person_add_alt_1</span>
                    Cadastrar
                </button>
</form>
<div class="mt-8 text-center pb-8">
<p class="text-gray-500 dark:text-gray-400 text-sm">
                    Já tem uma conta? 
                    <a class="text-burgundy dark:text-primary font-bold ml-1" href="#">Fazer Login</a>
</p>
</div>
</main>
<div class="h-6 flex justify-center items-end pb-2">
<div class="w-32 h-1.5 bg-gray-300 dark:bg-gray-700 rounded-full"></div>
</div>
</div>

</body></html>