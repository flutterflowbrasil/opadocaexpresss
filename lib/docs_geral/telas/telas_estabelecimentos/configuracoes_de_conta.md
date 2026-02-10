<!DOCTYPE html>
<html class="light" lang="pt-BR"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Padoca Express - Configuração de Conta</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#FF7034", 
                        "burgundy": "#7D2D35", 
                        "background-light": "#F9F5F0", 
                        "background-dark": "#23150f",
                    },
                    fontFamily: {
                        "display": ["Plus Jakarta Sans", "sans-serif"]
                    },
                    borderRadius: {"DEFAULT": "0.5rem", "lg": "1rem", "xl": "1.5rem", "full": "9999px"},
                },
            },
        }
    </script>
<style type="text/tailwindcss">body {
    font-family: "Plus Jakarta Sans", sans-serif;
    min-height: max(884px, 100dvh)
    }
.custom-select-arrow {
    background-image: url(https://lh3.googleusercontent.com/aida-public/AB6AXuAd_rQVCSw_F3DMVArJPFuxtcNRx4pS9F4GYT1YJ9TUX33MVvLI9bwX0I3G6kghPeD3R2TmcQLtcOhL3x_MySwJcRElD-j0K9lQ-b9xzUi5YUjAX7dcrRsVJwyr-IaKr3dXW42PywcRsxvIWfQ77AnbPccqZWFnKyt4Dh_uw6dD7tYlAkANHLjx0L3tl43GubetescTLWrro2Ep6zVuoZWy4Y29rk6s_QWOBSbhlCSSs6sbQCB6JKUhLqjlnyHxgwN6qL9_3Jsk);
    background-repeat: no-repeat;
    background-position: right 1rem center;
    background-size: 1.5rem;
    appearance: none
    }
.dark .custom-select-arrow {
    background-image: url(https://lh3.googleusercontent.com/aida-public/AB6AXuBzIjVGKZZh_mBVcvQbIo3_kg6xZnuGlhthuql_lrJdEOOkmnf2Drkti0NC6vd9KJF8rSzRACyOO8faD_4p77g3r5WkzZXEO-hynY0QTXUsO0-H6W8NAMMPmlZ1qXGw2YTysSo0D966R7QBZjekmilsd4ZQo9HgdzXcapK9270KQ2xIvQ950FoeLsyXf-A6Lzz45HAIm7LYqFYGDSz8EVPsx_IjYp9IsuCfSFvozC5RJ8UTmabrcWTy9ZGiQ8bQC1Mdf3862S2g)
    }</style>
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
<body class="bg-background-light dark:bg-background-dark min-h-screen font-display">
<div class="relative flex min-h-screen w-full max-w-[430px] mx-auto flex-col bg-background-light dark:bg-background-dark shadow-xl">
<header class="flex items-center p-4 pt-6 pb-2 justify-between">
<button class="text-burgundy dark:text-white flex size-12 shrink-0 items-center justify-center hover:bg-burgundy/5 rounded-full transition-colors">
<span class="material-symbols-outlined">chevron_left</span>
</button>
<h1 class="text-burgundy dark:text-white text-lg font-bold leading-tight tracking-tight flex-1 text-center pr-12">Configuração da Conta</h1>
</header>
<div class="flex flex-col gap-2 px-8 pt-2 pb-6">
<div class="flex justify-between items-center mb-1">
<span class="text-burgundy dark:text-burgundy text-[11px] font-bold tracking-[0.1em] uppercase">PASSO 3 DE 3</span>
<span class="text-burgundy dark:text-burgundy text-[11px] font-bold tracking-[0.05em]">100%</span>
</div>
<div class="w-full h-1.5 rounded-full bg-burgundy/10 dark:bg-white/10 overflow-hidden">
<div class="h-full rounded-full bg-primary" style="width: 100%;"></div>
</div>
</div>
<main class="flex-1 overflow-y-auto px-6 pb-24">
<div class="py-4">
<h2 class="text-burgundy dark:text-white text-2xl font-extrabold leading-tight">Dados para Recebimento</h2>
<p class="text-burgundy/70 dark:text-gray-400 text-sm mt-1">Informe a conta onde deseja receber suas vendas do Padoca Express.</p>
</div>
<form class="space-y-5 mt-4">
<div class="flex flex-col gap-2">
<label class="text-burgundy dark:text-gray-200 text-sm font-bold flex items-center gap-2">
<span class="material-symbols-outlined text-[20px]">account_balance</span>
                        Nome do Banco
                    </label>
<select class="custom-select-arrow form-select w-full h-14 rounded-xl border-burgundy/20 dark:border-white/20 bg-white dark:bg-white/5 text-burgundy dark:text-white px-4 focus:ring-2 focus:ring-primary focus:border-primary transition-all">
<option value="">Selecione seu banco</option>
<option value="001">001 - Banco do Brasil</option>
<option value="033">033 - Santander</option>
<option value="104">104 - Caixa Econômica</option>
<option value="237">237 - Bradesco</option>
<option value="341">341 - Itaú</option>
<option value="260">260 - Nubank</option>
</select>
</div>
<div class="grid grid-cols-2 gap-4">
<div class="flex flex-col gap-2">
<label class="text-burgundy dark:text-gray-200 text-sm font-bold flex items-center gap-2">
<span class="material-symbols-outlined text-[20px]">apartment</span>
                            Agência
                        </label>
<input class="form-input w-full h-14 rounded-xl border-burgundy/20 dark:border-white/20 bg-white dark:bg-white/5 text-burgundy dark:text-white px-4 focus:ring-2 focus:ring-primary focus:border-primary transition-all placeholder:text-burgundy/30" inputmode="numeric" placeholder="0000" type="text"/>
</div>
<div class="flex flex-col gap-2">
<label class="text-burgundy dark:text-gray-200 text-sm font-bold flex items-center gap-2">
<span class="material-symbols-outlined text-[20px]">tag</span>
                            Conta + Dígito
                        </label>
<input class="form-input w-full h-14 rounded-xl border-burgundy/20 dark:border-white/20 bg-white dark:bg-white/5 text-burgundy dark:text-white px-4 focus:ring-2 focus:ring-primary focus:border-primary transition-all placeholder:text-burgundy/30" inputmode="numeric" placeholder="00000-0" type="text"/>
</div>
</div>
<div class="flex flex-col gap-3">
<label class="text-burgundy dark:text-gray-200 text-sm font-bold">Tipo de Conta</label>
<div class="grid grid-cols-2 gap-3 p-1 bg-burgundy/5 dark:bg-white/5 rounded-xl border border-burgundy/10 dark:border-white/10">
<label class="relative cursor-pointer">
<input checked="" class="peer sr-only" name="account_type" type="radio" value="corrente"/>
<div class="flex items-center justify-center py-3 px-2 rounded-lg text-sm font-semibold transition-all peer-checked:bg-white peer-checked:text-primary peer-checked:shadow-sm text-burgundy/60 dark:text-white/60">
                                Corrente
                            </div>
</label>
<label class="relative cursor-pointer">
<input class="peer sr-only" name="account_type" type="radio" value="poupanca"/>
<div class="flex items-center justify-center py-3 px-2 rounded-lg text-sm font-semibold transition-all peer-checked:bg-white peer-checked:text-primary peer-checked:shadow-sm text-burgundy/60 dark:text-white/60">
                                Poupança
                            </div>
</label>
</div>
</div>
<div class="flex flex-col gap-2">
<label class="text-burgundy dark:text-gray-200 text-sm font-bold flex items-center gap-2">
<span class="material-symbols-outlined text-[20px]">person</span>
                        Nome do Titular
                    </label>
<input class="form-input w-full h-14 rounded-xl border-burgundy/20 dark:border-white/20 bg-white dark:bg-white/5 text-burgundy dark:text-white px-4 focus:ring-2 focus:ring-primary focus:border-primary transition-all placeholder:text-burgundy/30" placeholder="Digite o nome do titular da conta" type="text"/>
</div>
<div class="flex flex-col gap-2">
<label class="text-burgundy dark:text-gray-200 text-sm font-bold flex items-center gap-2">
<span class="material-symbols-outlined text-[20px]">badge</span>
                        CPF/CNPJ do Titular
                    </label>
<div class="relative">
<input class="form-input w-full h-14 rounded-xl border-burgundy/20 dark:border-white/20 bg-white dark:bg-white/5 text-burgundy dark:text-white px-4 focus:ring-2 focus:ring-primary focus:border-primary transition-all placeholder:text-burgundy/30" placeholder="00.000.000/0001-00" type="text"/>
</div>
<p class="text-[11px] text-burgundy/60 dark:text-gray-400 pl-1">Deve coincidir com os dados de cadastro da empresa.</p>
</div>
<div class="bg-primary/10 dark:bg-primary/5 border border-primary/20 rounded-xl p-4 flex gap-3 mt-4">
<span class="material-symbols-outlined text-primary shrink-0">info</span>
<div class="flex flex-col gap-1">
<p class="text-burgundy dark:text-gray-200 text-xs font-bold leading-tight">Pagamentos Seguros via ASAAS</p>
<p class="text-burgundy/70 dark:text-gray-400 text-[11px] leading-relaxed">
                            Seus repasses serão processados com segurança através da tecnologia ASAAS. Certifique-se de que a conta bancária informada pertence ao mesmo titular do cadastro para evitar atrasos nos pagamentos.
                        </p>
</div>
</div>
</form>
</main>
<div class="absolute bottom-0 left-0 right-0 p-6 bg-gradient-to-t from-background-light dark:from-background-dark via-background-light/95 dark:via-background-dark/95 to-transparent pt-10">
<button class="w-full bg-primary hover:bg-orange-600 text-white font-extrabold text-base h-16 rounded-2xl shadow-lg shadow-primary/25 transition-all active:scale-95 flex items-center justify-center gap-2">
                Salvar e Iniciar
                <span class="material-symbols-outlined">rocket_launch</span>
</button>
</div>
</div>

</body></html>