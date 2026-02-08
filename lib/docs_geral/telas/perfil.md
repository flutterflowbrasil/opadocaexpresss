<!DOCTYPE html>
<html class="light" lang="pt-br"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Perfil - Padoca Express</title>
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
        body {
            min-height: max(884px, 100dvh);
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-light dark:bg-background-dark font-display text-burgundy dark:text-white antialiased">
<div class="relative flex h-auto min-h-screen w-full flex-col overflow-x-hidden max-w-md mx-auto shadow-2xl bg-background-light dark:bg-background-dark pb-24">
<div class="flex items-center px-4 pt-6 pb-2 justify-between sticky top-0 bg-background-light/80 dark:bg-background-dark/80 backdrop-blur-md z-10">
<div class="text-burgundy dark:text-white flex size-10 shrink-0 items-center justify-center cursor-pointer">
<span class="material-symbols-outlined text-[28px]">arrow_back</span>
</div>
<h1 class="text-burgundy dark:text-white text-xl font-bold leading-tight tracking-tight flex-1 text-center pr-10">Perfil</h1>
</div>
<div class="flex flex-col items-center py-6 gap-4">
<div class="relative">
<div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full border-4 border-white dark:border-zinc-800 shadow-lg min-h-32 w-32 bg-zinc-200" data-alt="User profile avatar showing a smiling person" style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuB3TYB3nqJUiQDEvsnYTSQOCp1namm9a65lATM2cc8ubuael3Nr1Ul4AderRK6Edi-lO38d_HYIgstd9X06jK5zhkX3UaY-NDqa0g2uvEDwJ_0Zt_d1Y1kQztqZB0i82DV8IqZza4C4CCQGKdNx5WnPxOd00pyXSeucasIFrszm7nGWWJqh3O35jXiY6ApwsJ8eBWVhuZeYp61CkRJp_-KF1GWrx3Rp3vD0wXCCoZybsaWzoX1paLPYt9eIyHP8x8Cvy5TPEkKq");'>
</div>
</div>
<div class="flex flex-col items-center justify-center">
<p class="text-burgundy dark:text-white text-2xl font-extrabold tracking-tight">Nome do Usuário</p>
<p class="text-primary font-medium text-sm">e-mail@exemplo.com</p>
</div>
</div>
<div class="px-4 space-y-6">
<div>
<h3 class="text-burgundy/60 dark:text-white/60 text-xs font-bold uppercase tracking-widest px-1 pb-3">Minha Conta</h3>
<div class="bg-cream-card dark:bg-zinc-900/50 rounded-2xl shadow-sm border border-orange-100 dark:border-zinc-800 overflow-hidden">
<div class="flex items-center gap-4 px-4 py-4 hover:bg-orange-50 dark:hover:bg-zinc-800 cursor-pointer transition-colors border-b border-orange-50 dark:border-zinc-800">
<div class="text-primary flex items-center justify-center rounded-xl bg-primary/10 shrink-0 size-10">
<span class="material-symbols-outlined">person</span>
</div>
<p class="text-burgundy dark:text-white text-base font-semibold flex-1">Editar Informações</p>
<span class="material-symbols-outlined text-zinc-400">chevron_right</span>
</div>
<div class="flex items-center gap-4 px-4 py-4 hover:bg-orange-50 dark:hover:bg-zinc-800 cursor-pointer transition-colors border-b border-orange-50 dark:border-zinc-800">
<div class="text-primary flex items-center justify-center rounded-xl bg-primary/10 shrink-0 size-10">
<span class="material-symbols-outlined">location_on</span>
</div>
<p class="text-burgundy dark:text-white text-base font-semibold flex-1">Endereços Salvos</p>
<span class="material-symbols-outlined text-zinc-400">chevron_right</span>
</div>
<div class="flex items-center gap-4 px-4 py-4 hover:bg-orange-50 dark:hover:bg-zinc-800 cursor-pointer transition-colors">
<div class="text-primary flex items-center justify-center rounded-xl bg-primary/10 shrink-0 size-10">
<span class="material-symbols-outlined">payments</span>
</div>
<p class="text-burgundy dark:text-white text-base font-semibold flex-1">Formas de Pagamento</p>
<span class="material-symbols-outlined text-zinc-400">chevron_right</span>
</div>
</div>
</div>
<div>
<h3 class="text-burgundy/60 dark:text-white/60 text-xs font-bold uppercase tracking-widest px-1 pb-3">Configurações</h3>
<div class="bg-cream-card dark:bg-zinc-900/50 rounded-2xl shadow-sm border border-orange-100 dark:border-zinc-800 overflow-hidden">
<div class="flex items-center justify-between px-4 py-4">
<div class="flex items-center gap-4">
<div class="text-primary flex items-center justify-center rounded-xl bg-primary/10 shrink-0 size-10">
<span class="material-symbols-outlined">dark_mode</span>
</div>
<p class="text-burgundy dark:text-white text-base font-semibold">Modo Escuro</p>
</div>
<label class="relative inline-flex items-center cursor-pointer">
<input class="sr-only peer" type="checkbox" value=""/>
<div class="w-11 h-6 bg-zinc-200 peer-focus:outline-none rounded-full peer dark:bg-zinc-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-primary"></div>
</label>
</div>
</div>
</div>
<div class="pt-4">
<button class="w-full flex items-center justify-center gap-3 py-4 rounded-xl border-2 border-primary/30 text-primary font-bold hover:bg-primary/5 transition-colors">
<span class="material-symbols-outlined">logout</span>
                    Sair do App
                </button>
</div>
</div>
<div class="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-md bg-white/90 dark:bg-zinc-900/90 backdrop-blur-lg border-t border-orange-100 dark:border-zinc-800 px-6 py-3 flex justify-around items-center z-50 rounded-t-3xl">
<div class="flex flex-col items-center gap-1 cursor-pointer opacity-40 dark:opacity-50">
<span class="material-symbols-outlined text-[26px]">home</span>
<span class="text-[10px] font-bold">Início</span>
</div>
<div class="flex flex-col items-center gap-1 cursor-pointer opacity-40 dark:opacity-50">
<span class="material-symbols-outlined text-[26px]">receipt_long</span>
<span class="text-[10px] font-bold">Pedidos</span>
</div>
<div class="flex flex-col items-center gap-1 cursor-pointer active-tab">
<span class="material-symbols-outlined text-[26px] fill-[1]">person</span>
<span class="text-[10px] font-bold">Perfil</span>
</div>
</div>
<div class="h-6 w-full bg-white dark:bg-zinc-900 fixed bottom-0 max-w-md left-1/2 -translate-x-1/2"></div>
</div>

</body></html>