<!DOCTYPE html>

<html class="light" lang="pt-br"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Editar Dados - Padoca Express</title>
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
<style type="text/tailwindcss">
        @layer base {
            .material-symbols-outlined {
                font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
            }
        }
        .form-input-custom {
            @apply w-full bg-white dark:bg-zinc-900 border-orange-100 dark:border-zinc-800 rounded-xl px-4 py-3.5 text-burgundy dark:text-white focus:border-primary focus:ring-primary placeholder:text-zinc-400;
        }
    </style>
<style>
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
<body class="bg-background-light dark:bg-background-dark font-display text-burgundy dark:text-white antialiased overflow-x-hidden">
<div class="relative flex h-auto min-h-screen w-full flex-col overflow-x-hidden max-w-md mx-auto shadow-2xl bg-background-light dark:bg-background-dark pb-24 sm:pb-32">
<div class="flex items-center px-4 pt-6 pb-2 sticky top-0 bg-background-light/80 dark:bg-background-dark/80 backdrop-blur-md z-10">
<div class="text-burgundy dark:text-white flex size-10 shrink-0 items-center justify-center cursor-pointer">
<span class="material-symbols-outlined text-[28px]">arrow_back</span>
</div>
<h1 class="text-burgundy dark:text-white font-bold leading-tight tracking-tight flex-1 text-center pr-10 text-lg">Editar Informações</h1>
</div>
<div class="flex flex-col items-center py-8">
<div class="relative group">
<div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full border-4 border-white dark:border-zinc-800 shadow-lg min-h-32 w-32 bg-zinc-200 overflow-hidden" style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuB3TYB3nqJUiQDEvsnYTSQOCp1namm9a65lATM2cc8ubuael3Nr1Ul4AderRK6Edi-lO38d_HYIgstd9X06jK5zhkX3UaY-NDqa0g2uvEDwJ_0Zt_d1Y1kQztqZB0i82DV8IqZza4C4CCQGKdNx5WnPxOd00pyXSeucasIFrszm7nGWWJqh3O35jXiY6ApwsJ8eBWVhuZeYp61CkRJp_-KF1GWrx3Rp3vD0wXCCoZybsaWzoX1paLPYt9eIyHP8x8Cvy5TPEkKq");'>
</div>
<button class="absolute -bottom-2 left-1/2 -translate-x-1/2 bg-primary text-white px-4 py-1.5 rounded-full shadow-md text-xs font-bold uppercase tracking-wider flex items-center gap-1">
<span class="material-symbols-outlined text-[16px]">edit</span>
                    Alterar
                </button>
</div>
</div>
<div class="space-y-5 px-4">
<!-- Informações Pessoais Section -->
<div class="space-y-4">
<h2 class="text-sm font-extrabold uppercase tracking-widest text-burgundy dark:text-white mb-4">Informações Pessoais</h2>
<div class="space-y-1.5">
<label class="text-xs font-bold uppercase tracking-widest text-burgundy/60 dark:text-white/60 ml-1">Nome</label>
<input class="form-input-custom text-sm sm:text-base" placeholder="Seu nome completo" type="text" value="Nome do Usuário"/>
</div>
<div class="space-y-1.5">
<label class="text-xs font-bold uppercase tracking-widest text-burgundy/60 dark:text-white/60 ml-1">Data de Nascimento</label>
<input class="form-input-custom text-sm sm:text-base" placeholder="DD/MM/AAAA" type="text" value=""/>
</div>
<div class="space-y-1.5">
<label class="text-xs font-bold uppercase tracking-widest text-burgundy/60 dark:text-white/60 ml-1">CPF</label>
<input class="form-input-custom text-sm sm:text-base" placeholder="000.000.000-00" type="text" value="123.456.789-00"/>
</div>
<div class="space-y-1.5">
<label class="text-xs font-bold uppercase tracking-widest text-burgundy/60 dark:text-white/60 ml-1">Telefone</label>
<input class="form-input-custom text-sm sm:text-base" placeholder="(00) 00000-0000" type="text" value="(11) 99999-9999"/>
</div>
</div>
<!-- Segurança Section -->
<div class="space-y-4 pt-4">
<h2 class="text-sm font-extrabold uppercase tracking-widest text-burgundy dark:text-white mb-4">Segurança</h2>
<div class="space-y-1.5">
<label class="text-xs font-bold uppercase tracking-widest text-burgundy/60 dark:text-white/60 ml-1">Alterar E-mail</label>
<div class="relative">
<input class="form-input-custom text-sm sm:text-base" placeholder="seu@email.com" type="email" value="e-mail@exemplo.com"/>
<span class="material-symbols-outlined absolute right-4 top-1/2 -translate-y-1/2 text-burgundy/40 text-[20px]">edit</span>
</div>
</div>
</div>
<div class="pt-8 pb-10">
<button class="w-full bg-primary text-white py-4 rounded-xl font-bold text-lg shadow-lg shadow-primary/20 active:scale-[0.98] transition-all">
        Salvar Alterações
    </button>
</div>
</div>
<div class="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-md bg-white/90 dark:bg-zinc-900/90 backdrop-blur-lg border-t border-orange-100 dark:border-zinc-800 px-6 py-3 flex justify-between items-center z-50 rounded-t-3xl">
<div class="flex flex-col items-center gap-1 cursor-pointer opacity-40 dark:opacity-50">
<span class="material-symbols-outlined text-[26px]">home</span>
<span class="text-[10px] font-bold">Início</span>
</div>
<div class="flex flex-col items-center gap-1 cursor-pointer opacity-40 dark:opacity-50">
<span class="material-symbols-outlined text-[26px]">search</span>
<span class="text-[10px] font-bold">Busca</span>
</div>
<div class="flex flex-col items-center gap-1 cursor-pointer opacity-40 dark:opacity-50">
<span class="material-symbols-outlined text-[26px]">receipt_long</span>
<span class="text-[10px] font-bold">Pedidos</span>
</div>
<div class="flex flex-col items-center gap-1 cursor-pointer text-primary">
<span class="material-symbols-outlined text-[26px] fill-[1]">person</span>
<span class="text-[10px] font-bold">Perfil</span>
</div>
</div>
<div class="h-6 w-full bg-white dark:bg-zinc-900 fixed bottom-0 max-w-md left-1/2 -translate-x-1/2"></div>
</div>
</body></html>