<!DOCTYPE html>
<html class="light" lang="pt-br"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Meus Endereços - Padoca Express</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#ff7033",
                        "background-light": "#F9F5F0",
                        "background-dark": "#23150f",
                        "burgundy": "#7D2D35",
                        "cream-card": "#FFFFFF",
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
        .material-symbols-outlined {
            font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
        }
        .active-tab {
            color: #ff7033 !important;
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-light dark:bg-background-dark font-display text-burgundy dark:text-white antialiased">
<div class="relative flex min-h-screen w-full flex-col overflow-x-hidden max-w-md mx-auto shadow-2xl bg-background-light dark:bg-background-dark">
<div class="flex items-center px-4 pt-6 pb-2 sticky top-0 bg-background-light/90 dark:bg-background-dark/90 backdrop-blur-md z-10">
<div class="text-burgundy dark:text-white flex size-10 shrink-0 items-center justify-center cursor-pointer">
<span class="material-symbols-outlined text-[28px]">arrow_back</span>
</div>
<h1 class="text-burgundy dark:text-white text-xl font-bold leading-tight tracking-tight flex-1 text-center pr-10">Meus Endereços</h1>
</div>
<div class="px-4 py-6 space-y-4 flex-1">
<div class="bg-cream-card dark:bg-zinc-900/50 rounded-2xl p-4 shadow-sm border border-orange-100 dark:border-zinc-800 flex items-start gap-4 transition-transform active:scale-[0.98]">
<div class="text-primary flex items-center justify-center rounded-xl bg-primary/10 shrink-0 size-12">
<span class="material-symbols-outlined text-[24px]">home</span>
</div>
<div class="flex-1">
<div class="flex items-center justify-between mb-1">
<h3 class="text-burgundy dark:text-white font-bold text-lg">Casa</h3>
<button class="text-zinc-400 hover:text-primary transition-colors">
<span class="material-symbols-outlined">edit</span>
</button>
</div>
<p class="text-burgundy/70 dark:text-zinc-400 text-sm leading-relaxed">
                        Rua das Padarias, 123 - Apto 42<br/>
                        Vila Madalena, São Paulo - SP<br/>
                        CEP: 05432-000
                    </p>
</div>
</div>
<div class="bg-cream-card dark:bg-zinc-900/50 rounded-2xl p-4 shadow-sm border border-orange-100 dark:border-zinc-800 flex items-start gap-4 transition-transform active:scale-[0.98]">
<div class="text-primary flex items-center justify-center rounded-xl bg-primary/10 shrink-0 size-12">
<span class="material-symbols-outlined text-[24px]">work</span>
</div>
<div class="flex-1">
<div class="flex items-center justify-between mb-1">
<h3 class="text-burgundy dark:text-white font-bold text-lg">Trabalho</h3>
<button class="text-zinc-400 hover:text-primary transition-colors">
<span class="material-symbols-outlined">edit</span>
</button>
</div>
<p class="text-burgundy/70 dark:text-zinc-400 text-sm leading-relaxed">
                        Av. Paulista, 1000 - 15º Andar<br/>
                        Bela Vista, São Paulo - SP<br/>
                        CEP: 01310-100
                    </p>
</div>
</div>
<div class="bg-cream-card dark:bg-zinc-900/50 rounded-2xl p-4 shadow-sm border border-orange-100 dark:border-zinc-800 flex items-start gap-4 transition-transform active:scale-[0.98]">
<div class="text-primary flex items-center justify-center rounded-xl bg-primary/10 shrink-0 size-12">
<span class="material-symbols-outlined text-[24px]">location_on</span>
</div>
<div class="flex-1">
<div class="flex items-center justify-between mb-1">
<h3 class="text-burgundy dark:text-white font-bold text-lg">Casa da Avó</h3>
<button class="text-zinc-400 hover:text-primary transition-colors">
<span class="material-symbols-outlined">edit</span>
</button>
</div>
<p class="text-burgundy/70 dark:text-zinc-400 text-sm leading-relaxed">
                        Alameda dos Anjos, 450<br/>
                        Jardim Europa, São Paulo - SP<br/>
                        CEP: 01449-001
                    </p>
</div>
</div>
</div>
<div class="sticky bottom-0 bg-background-light dark:bg-background-dark px-4 pb-10 pt-4 border-t border-orange-100 dark:border-zinc-800">
<button class="w-full bg-primary text-white py-4 rounded-xl font-bold text-lg shadow-lg shadow-primary/20 hover:bg-primary/90 transition-all flex items-center justify-center gap-2">
<span class="material-symbols-outlined">add</span>
                Adicionar Novo Endereço
            </button>
</div>
<div class="h-6 w-full bg-background-light dark:bg-background-dark"></div>
</div>

</body></html>