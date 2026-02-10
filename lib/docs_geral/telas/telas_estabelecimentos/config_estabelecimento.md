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
                        "bakery-burgundy": "#7D2D35",
                        "bakery-cream": "#F9F5F0",
                        "background-light": "#F9F5F0",
                        "background-dark": "#23150f",
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
        body {
            font-family: 'Plus Jakarta Sans', sans-serif;
        }
        .form-input:focus {
            border-color: #ff7033 !important;
            @apply ring-0;
        }.toggle-checkbox:checked {
            right: 0;
            background-color: #ff7033;
        }
        .toggle-checkbox:checked + .toggle-label {
            background-color: #ff7033;
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
<body class="bg-background-light dark:bg-background-dark min-h-screen flex justify-center">
<div class="relative flex h-auto min-h-screen w-full max-w-[480px] flex-col bg-background-light dark:bg-background-dark overflow-x-hidden pb-24">
<div class="flex items-center bg-background-light dark:bg-background-dark p-4 pb-2 sticky top-0 z-10">
<div class="text-bakery-burgundy dark:text-white flex size-12 shrink-0 items-center justify-start">
<span class="material-symbols-outlined cursor-pointer">arrow_back_ios</span>
</div>
<h1 class="text-bakery-burgundy dark:text-white text-lg font-bold leading-tight tracking-tight flex-1 text-center pr-12">Padoca Express</h1>
</div>
<div class="px-4 py-2">
<div class="flex items-center justify-between mb-2">
<span class="text-bakery-burgundy/60 dark:text-white/60 text-xs font-bold uppercase tracking-wider">Passo 2 de 3</span>
<span class="text-bakery-burgundy/60 dark:text-white/60 text-xs font-bold">66%</span>
</div>
<div class="w-full bg-bakery-burgundy/10 dark:bg-white/10 h-1.5 rounded-full overflow-hidden">
<div class="bg-primary h-full rounded-full transition-all duration-500" style="width: 66.6%"></div>
</div>
</div>
<div class="px-4 py-4">
<h2 class="text-bakery-burgundy dark:text-white text-2xl font-bold leading-tight">Configurações</h2>
<p class="text-bakery-burgundy/70 dark:text-white/70 text-sm mt-1">Configure o endereço e os horários da sua padaria.</p>
</div>
<section class="space-y-4 px-4 pb-8">
<div class="flex items-center gap-2 pt-2 border-b border-bakery-burgundy/10 pb-2 mb-4">
<span class="material-symbols-outlined text-primary">location_on</span>
<h3 class="text-bakery-burgundy dark:text-white text-lg font-bold">Endereço</h3>
</div>
<div class="flex flex-col gap-4">
<label class="flex flex-col flex-1">
<p class="text-bakery-burgundy dark:text-white text-sm font-semibold pb-1.5 ml-1">CEP</p>
<input class="form-input flex w-full rounded-xl border-none bg-white dark:bg-white/10 text-bakery-burgundy dark:text-white h-14 placeholder:text-bakery-burgundy/40 p-4 text-base shadow-sm" placeholder="00000-000" type="text"/>
</label>
<label class="flex flex-col flex-1">
<p class="text-bakery-burgundy dark:text-white text-sm font-semibold pb-1.5 ml-1">Logradouro</p>
<input class="form-input flex w-full rounded-xl border-none bg-white dark:bg-white/10 text-bakery-burgundy dark:text-white h-14 placeholder:text-bakery-burgundy/40 p-4 text-base shadow-sm" placeholder="Ex: Rua das Flores" type="text"/>
</label>
<div class="flex gap-4">
<label class="flex flex-col w-1/3">
<p class="text-bakery-burgundy dark:text-white text-sm font-semibold pb-1.5 ml-1">Número</p>
<input class="form-input flex w-full rounded-xl border-none bg-white dark:bg-white/10 text-bakery-burgundy dark:text-white h-14 placeholder:text-bakery-burgundy/40 p-4 text-base shadow-sm" placeholder="123" type="text"/>
</label>
<label class="flex flex-col flex-1">
<p class="text-bakery-burgundy dark:text-white text-sm font-semibold pb-1.5 ml-1">Bairro</p>
<input class="form-input flex w-full rounded-xl border-none bg-white dark:bg-white/10 text-bakery-burgundy dark:text-white h-14 placeholder:text-bakery-burgundy/40 p-4 text-base shadow-sm" placeholder="Centro" type="text"/>
</label>
</div>
<div class="flex gap-4">
<label class="flex flex-col flex-1">
<p class="text-bakery-burgundy dark:text-white text-sm font-semibold pb-1.5 ml-1">Cidade</p>
<input class="form-input flex w-full rounded-xl border-none bg-white dark:bg-white/10 text-bakery-burgundy dark:text-white h-14 placeholder:text-bakery-burgundy/40 p-4 text-base shadow-sm" placeholder="São Paulo" type="text"/>
</label>
<label class="flex flex-col w-1/4">
<p class="text-bakery-burgundy dark:text-white text-sm font-semibold pb-1.5 ml-1">UF</p>
<input class="form-input flex w-full rounded-xl border-none bg-white dark:bg-white/10 text-bakery-burgundy dark:text-white h-14 placeholder:text-bakery-burgundy/40 p-4 text-base shadow-sm" maxlength="2" placeholder="SP" type="text"/>
</label>
</div>
</div>
</section>
<section class="space-y-4 px-4 pb-8">
<div class="flex items-center gap-2 pt-2 border-b border-bakery-burgundy/10 pb-2 mb-4">
<span class="material-symbols-outlined text-primary">schedule</span>
<h3 class="text-bakery-burgundy dark:text-white text-lg font-bold">Horário de Funcionamento</h3>
</div>
<div class="space-y-3">
<div class="bg-white dark:bg-white/5 rounded-xl p-4 shadow-sm border border-bakery-burgundy/5">
<div class="flex items-center justify-between mb-3">
<span class="text-bakery-burgundy dark:text-white font-semibold">Segunda-feira</span>
<div class="relative inline-block w-12 h-6 align-middle select-none transition duration-200 ease-in">
<input checked="" class="toggle-checkbox absolute block w-6 h-6 rounded-full bg-white border-4 appearance-none cursor-pointer checked:right-0 checked:border-primary border-gray-300 right-6 transition-all duration-300" id="toggle-seg" name="toggle" type="checkbox"/>
<label class="toggle-label block overflow-hidden h-6 rounded-full bg-gray-300 cursor-pointer" for="toggle-seg"></label>
</div>
</div>
<div class="flex gap-4 items-center">
<div class="flex-1">
<p class="text-[10px] uppercase text-bakery-burgundy/60 font-bold mb-1">Início</p>
<input class="w-full bg-bakery-cream/50 dark:bg-black/20 border-none rounded-lg text-bakery-burgundy dark:text-white p-2 text-sm" type="time" value="07:00"/>
</div>
<div class="flex-1">
<p class="text-[10px] uppercase text-bakery-burgundy/60 font-bold mb-1">Fim</p>
<input class="w-full bg-bakery-cream/50 dark:bg-black/20 border-none rounded-lg text-bakery-burgundy dark:text-white p-2 text-sm" type="time" value="20:00"/>
</div>
</div>
</div>
<div class="bg-white dark:bg-white/5 rounded-xl p-4 shadow-sm border border-bakery-burgundy/5 opacity-60">
<div class="flex items-center justify-between">
<span class="text-bakery-burgundy dark:text-white font-semibold">Terça a Sexta</span>
<div class="relative inline-block w-12 h-6 align-middle select-none transition duration-200 ease-in">
<input checked="" class="toggle-checkbox absolute block w-6 h-6 rounded-full bg-white border-4 appearance-none cursor-pointer checked:right-0 checked:border-primary border-gray-300 right-6 transition-all duration-300" id="toggle-week" name="toggle" type="checkbox"/>
<label class="toggle-label block overflow-hidden h-6 rounded-full bg-gray-300 cursor-pointer" for="toggle-week"></label>
</div>
</div>
</div>
<div class="bg-white dark:bg-white/5 rounded-xl p-4 shadow-sm border border-bakery-burgundy/5">
<div class="flex items-center justify-between mb-3">
<span class="text-bakery-burgundy dark:text-white font-semibold">Sábado</span>
<div class="relative inline-block w-12 h-6 align-middle select-none transition duration-200 ease-in">
<input checked="" class="toggle-checkbox absolute block w-6 h-6 rounded-full bg-white border-4 appearance-none cursor-pointer checked:right-0 checked:border-primary border-gray-300 right-6 transition-all duration-300" id="toggle-sab" name="toggle" type="checkbox"/>
<label class="toggle-label block overflow-hidden h-6 rounded-full bg-gray-300 cursor-pointer" for="toggle-sab"></label>
</div>
</div>
<div class="flex gap-4 items-center">
<div class="flex-1">
<p class="text-[10px] uppercase text-bakery-burgundy/60 font-bold mb-1">Início</p>
<input class="w-full bg-bakery-cream/50 dark:bg-black/20 border-none rounded-lg text-bakery-burgundy dark:text-white p-2 text-sm" type="time" value="08:00"/>
</div>
<div class="flex-1">
<p class="text-[10px] uppercase text-bakery-burgundy/60 font-bold mb-1">Fim</p>
<input class="w-full bg-bakery-cream/50 dark:bg-black/20 border-none rounded-lg text-bakery-burgundy dark:text-white p-2 text-sm" type="time" value="18:00"/>
</div>
</div>
</div>
<div class="bg-white dark:bg-white/5 rounded-xl p-4 shadow-sm border border-bakery-burgundy/5">
<div class="flex items-center justify-between">
<span class="text-bakery-burgundy dark:text-white font-semibold">Domingo</span>
<div class="relative inline-block w-12 h-6 align-middle select-none transition duration-200 ease-in">
<input class="toggle-checkbox absolute block w-6 h-6 rounded-full bg-white border-4 appearance-none cursor-pointer border-gray-300 right-6 transition-all duration-300" id="toggle-dom" name="toggle" type="checkbox"/>
<label class="toggle-label block overflow-hidden h-6 rounded-full bg-gray-300 cursor-pointer" for="toggle-dom"></label>
</div>
</div>
<p class="text-xs text-bakery-burgundy/50 mt-1 italic">Fechado</p>
</div>
</div>
</section>
<div class="fixed bottom-0 left-0 right-0 flex justify-center px-4 pb-8 pt-4 bg-gradient-to-t from-bakery-cream via-bakery-cream to-transparent dark:from-background-dark dark:via-background-dark pointer-events-none">
<button class="pointer-events-auto w-full max-w-[448px] h-14 bg-primary text-white font-bold text-lg rounded-xl shadow-lg shadow-primary/20 hover:bg-primary/90 transition-all flex items-center justify-center gap-2">
<span>Continuar</span>
<span class="material-symbols-outlined">arrow_forward</span>
</button>
</div>
</div>

</body></html>