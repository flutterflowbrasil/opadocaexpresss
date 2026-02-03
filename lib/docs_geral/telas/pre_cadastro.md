<!DOCTYPE html>
<html lang="pt-br"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Padoca Express - Seleção de Perfil</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,typography,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com" rel="preconnect"/>
<link crossorigin="" href="https://fonts.gstatic.com" rel="preconnect"/>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;700&amp;display=swap" rel="stylesheet"/>
<script>
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        primary: "#FF7034", // Orange
                        burgundy: "#7D2D35", // Main Text Color
                        "background-light": "#F9F5F0",
                        "background-dark": "#1C1917", 
                        "card-light": "#FFFFFF",
                        "card-dark": "#292524", 
                    },
                    fontFamily: {
                        display: ["Outfit", "sans-serif"],
                        body: ["Outfit", "sans-serif"],
                    },
                    borderRadius: {
                        DEFAULT: "1.5rem",
                        "button": "1rem",
                    },
                },
            },
        };
    </script>
<style type="text/tailwindcss">
        body {
            font-family: 'Outfit', sans-serif;
            -webkit-tap-highlight-color: transparent;
            min-height: 100dvh;
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
<body class="bg-background-light dark:bg-background-dark min-h-screen transition-colors duration-300">
<div class="max-w-md mx-auto min-h-screen flex flex-col px-6 pt-10 pb-8">
<div class="flex flex-col items-center mb-8">
<div class="w-24 h-24 rounded-full bg-white dark:bg-card-dark shadow-xl overflow-hidden flex items-center justify-center p-2 mb-6 border border-orange-50 dark:border-stone-800">
<img alt="Padoca Express Logo" class="w-full h-full object-contain" src="https://lh3.googleusercontent.com/aida-public/AB6AXuBRvFlYc8HYmRehdeNm576mIpuRKs3io23fe5Z9OeudbBUplOWgVIsbeJLNk62860-IgLuO1HbAZG-jcy6S6YpktvQAcMBuoU6ndn_hzCpDfnOkfGNQiXwIbCJN1kbiM3wIBwTvDcCZxxbFc7btv95s4RVSeU7B2oSIicJPR-ngYejealLrQhv58MbkdlS5fX7DPdBxs9o644lJgBOyVfLneJs4bACBV7Bv_2noUZQQsTvMD17RIdZqn1A7TVU6DxrB-x9V6pvW"/>
</div>
<h1 class="text-burgundy dark:text-orange-100 text-2xl font-bold text-center leading-tight mb-2">
                Como você deseja usar o Padoca Express?
            </h1>
<p class="text-gray-500 dark:text-stone-400 text-center text-sm font-medium leading-relaxed max-w-[280px]">
                Escolha a opção que melhor se adequa ao seu perfil
            </p>
</div>
<div class="space-y-4 flex-grow">
<div class="bg-card-light dark:bg-card-dark p-5 rounded-[2rem] shadow-[0_8px_30px_rgb(0,0,0,0.04)] dark:shadow-[0_8px_30px_rgb(0,0,0,0.2)] border border-transparent dark:border-stone-700">
<div class="flex items-center justify-center gap-3 mb-1">
<div class="w-10 h-10 bg-orange-50 dark:bg-stone-700/50 rounded-full flex items-center justify-center shrink-0">
<span class="material-symbols-outlined text-burgundy dark:text-primary text-2xl">person</span>
</div>
<h2 class="text-burgundy dark:text-stone-100 text-xl font-bold">Cliente</h2>
</div>
<p class="text-gray-500 dark:text-stone-400 text-sm text-center mb-4">Quero pedir rapidinho!</p>
<button class="w-full bg-primary hover:bg-orange-600 text-white font-bold py-3.5 px-6 rounded-button shadow-lg shadow-orange-500/30 transition-all active:scale-[0.98]">
                    Cadastrar como Cliente
                </button>
</div>
<div class="bg-card-light dark:bg-card-dark p-5 rounded-[2rem] shadow-[0_8px_30px_rgb(0,0,0,0.04)] dark:shadow-[0_8px_30px_rgb(0,0,0,0.2)] border border-transparent dark:border-stone-700">
<div class="flex items-center justify-center gap-3 mb-1">
<div class="w-10 h-10 bg-orange-50 dark:bg-stone-700/50 rounded-full flex items-center justify-center shrink-0">
<span class="material-symbols-outlined text-burgundy dark:text-primary text-2xl">storefront</span>
</div>
<h2 class="text-burgundy dark:text-stone-100 text-xl font-bold">Estabelecimento</h2>
</div>
<p class="text-gray-500 dark:text-stone-400 text-sm text-center mb-4">Sou parceiro, quero me cadastrar.</p>
<button class="w-full bg-primary hover:bg-orange-600 text-white font-bold py-3.5 px-6 rounded-button shadow-lg shadow-orange-500/30 transition-all active:scale-[0.98]">
                    Cadastrar Estabelecimento
                </button>
</div>
<div class="bg-card-light dark:bg-card-dark p-5 rounded-[2rem] shadow-[0_8px_30px_rgb(0,0,0,0.04)] dark:shadow-[0_8px_30px_rgb(0,0,0,0.2)] border border-transparent dark:border-stone-700">
<div class="flex items-center justify-center gap-3 mb-1">
<div class="w-10 h-10 bg-orange-50 dark:bg-stone-700/50 rounded-full flex items-center justify-center shrink-0">
<span class="material-symbols-outlined text-burgundy dark:text-primary text-2xl">motorcycle</span>
</div>
<h2 class="text-burgundy dark:text-stone-100 text-xl font-bold">Entregador</h2>
</div>
<p class="text-gray-500 dark:text-stone-400 text-sm text-center mb-4">Quero fazer entregas!</p>
<button class="w-full bg-primary hover:bg-orange-600 text-white font-bold py-3.5 px-6 rounded-button shadow-lg shadow-orange-500/30 transition-all active:scale-[0.98]">
                    Cadastrar como Entregador
                </button>
</div>
</div>
<div class="mt-8 flex justify-center">
<button class="p-3 rounded-full bg-white dark:bg-card-dark text-burgundy dark:text-primary shadow-sm border border-stone-200 dark:border-stone-700 transition-colors" onclick="document.documentElement.classList.toggle('dark')">
<span class="material-symbols-outlined block dark:hidden">dark_mode</span>
<span class="material-symbols-outlined hidden dark:block">light_mode</span>
</button>
</div>
<div class="h-6"></div>
</div>

</body></html>