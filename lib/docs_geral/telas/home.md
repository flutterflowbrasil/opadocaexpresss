<!DOCTYPE html>
<html lang="pt-BR"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Padoca Express - Home</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,typography"></script>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/icon?family=Material+Icons+Outlined" rel="stylesheet"/>
<script>
      tailwind.config = {
        darkMode: "class",
        theme: {
          extend: {
            colors: {
              primary: "#FF7034",
              secondary: "#7D2D35",
              "background-light": "#F9F5F0",
              "background-dark": "#1C1917",
            },
            fontFamily: {
              display: ["Outfit", "sans-serif"],
            },
            borderRadius: {
              DEFAULT: "1rem",
            },
          },
        },
      };
    </script>
<style>
        body { font-family: 'Outfit', sans-serif; }
        .hide-scrollbar::-webkit-scrollbar { display: none; }
        .hide-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-light dark:bg-background-dark text-secondary dark:text-stone-200 min-h-screen pb-24">
<header class="px-5 pt-6 pb-2 sticky top-0 bg-background-light/95 dark:bg-background-dark/95 backdrop-blur-md z-50">
<div class="flex items-center justify-between">
<div class="flex items-center gap-2">
<span class="material-icons-outlined text-primary">location_on</span>
<div>
<p class="text-[10px] uppercase tracking-wider text-stone-500 font-bold">Entregar em</p>
<div class="flex items-center gap-1">
<span class="text-sm font-semibold truncate max-w-[180px]">Rua das Flores, 123</span>
<span class="material-icons-outlined text-xs">expand_more</span>
</div>
</div>
</div>
<div class="flex items-center gap-4">
<button class="relative p-2 rounded-full bg-white dark:bg-stone-800 shadow-sm">
<span class="material-icons-outlined text-xl">notifications</span>
<span class="absolute top-2 right-2 w-2 h-2 bg-primary rounded-full border-2 border-white dark:border-stone-800"></span>
</button>
<button class="p-2 rounded-full bg-white dark:bg-stone-800 shadow-sm">
<span class="material-icons-outlined text-xl">shopping_bag</span>
</button>
</div>
</div>
<div class="mt-4">
<div class="relative flex items-center">
<span class="material-icons-outlined absolute left-4 text-stone-400">search</span>
<input class="w-full bg-white dark:bg-stone-800 border-none rounded-2xl py-3.5 pl-12 pr-4 text-sm placeholder:text-stone-400 focus:ring-2 focus:ring-primary shadow-sm" placeholder="Buscar padarias, doces, salgados..." type="text"/>
</div>
</div>
</header>
<main class="px-5 space-y-8 mt-4">
<section class="relative h-48 rounded-3xl overflow-hidden shadow-lg">
<img alt="Bakery Interior" class="w-full h-full object-cover" src="https://lh3.googleusercontent.com/aida-public/AB6AXuCQzi6FvdVl_U9nntl9LO9AlHWPqrBeua7UiVsIlTtXcPLLDoYcIg-cMd50qaExmuoohRIgKdmGxjOwVK3vplRHVh6ezct2feyGwnm_SqLHVMg9vuvQ8N531TnLgUxxv5gbkXDtsoQV8JpfqAZlWh7HAobrMpDTeF8biHKOb9TnUJk-wo1WVCdBNa2ISCKnbgISEHiA5oNamWF5AMWiMsyCLQEKpLjJCk_qVBb87JnYILGmSbOPwuPBMLM-pSYWyWgDLY17o21N"/>
<div class="absolute inset-0 bg-gradient-to-r from-black/80 to-transparent flex flex-col justify-center px-6">
<h2 class="text-white text-3xl font-bold leading-tight drop-shadow-md">Ôpadoca Express</h2>
<p class="text-white/90 text-sm mt-1 max-w-[200px]">Suas padarias favoritas na palma da mão</p>
<button class="mt-4 w-fit px-6 py-2 bg-white text-secondary font-bold text-sm rounded-full shadow-lg active:scale-95 transition-transform">
                    Peça agora
                </button>
</div>
</section>
<section>
<div class="flex items-center justify-between mb-4">
<h3 class="text-lg font-bold">Categorias</h3>
</div>
<div class="flex gap-4 overflow-x-auto hide-scrollbar pb-2">
<div class="flex flex-col items-center gap-2 flex-shrink-0">
<div class="w-20 h-20 rounded-2xl overflow-hidden shadow-md">
<img alt="Padarias" class="w-full h-full object-cover" src="https://lh3.googleusercontent.com/aida-public/AB6AXuDjtt2qwFaLUYEfmchTvz39KIAFEoyJUnrCJilxLSJS3NTx0KgIU4pp_2MMy0Zz4b2Avf_6wfx0qTBiaCaTf3H1Cj__tt3KPMKCXgs6SABvORidCc_PDdDRSBsunNbkHrT751eox3f9meyDuRpMZ9cZ_Cfk-Y0ubu1vEeRVfO4ciEVFZ7UYRrUad1k7M9ymeAC8RSU05QcndrLNO1IpeLqA_FgooOmX_bfldZm8hqSkYYYppIvHAV5e-Kv6h8q1Izjr1l32tVph"/>
</div>
<span class="text-xs font-semibold">Padarias</span>
</div>
<div class="flex flex-col items-center gap-2 flex-shrink-0">
<div class="w-20 h-20 rounded-2xl overflow-hidden shadow-md">
<img alt="Doces" class="w-full h-full object-cover" src="https://lh3.googleusercontent.com/aida-public/AB6AXuC4v9rSpUpQ6T31Sz0GMm_83pd7MC_xwrEgVfD1tWeiqe0zceuMMv4HdX_Zv4EaqwK-VAdB2lK9UQpqQTKHDPWlq7Qwj8id9ub5GhXAJUGFWhY62DrDZ-pnRcQYK2upBnfftcy01vI8_IDR18llkUeX90jd5C3VHwd6E3-Bisr_HMvnoo9WLVLlc6fYOyQduIvNLRheBVhCCEFem3Pd5zVedx9hM_rwLKmXEQpwwyz4h5drwClszzx8whMcpbwMiwqY_2-5yenU"/>
</div>
<span class="text-xs font-semibold">Doces</span>
</div>
<div class="flex flex-col items-center gap-2 flex-shrink-0">
<div class="w-20 h-20 rounded-2xl overflow-hidden shadow-md">
<img alt="Salgados" class="w-full h-full object-cover" src="https://lh3.googleusercontent.com/aida-public/AB6AXuCzxBlT15a4JOMztOu31625DtXRaueeQHmAiIBoS8EnPkrKGTrn78eNk8TJIYEibFfh7QFzOkYSMr6u-JBh9J7Lfj420QrHhVtmTReP2zE_Yz5RHR21zSCcqwVBy2yI3DUgX3RWT1qa2guagw5g0511ptLumZhl740RuAomC5F3zUYgzZe3ealm2PBbMuZqpXJH39oACUV-0cA85fJDbG-_WBiDlmtubup9QI1HBQm9NCZHxdgg4lasnrLa2gvBwSEuOoMbl3wb"/>
</div>
<span class="text-xs font-semibold">Salgados</span>
</div>
<div class="flex flex-col items-center gap-2 flex-shrink-0">
<div class="w-20 h-20 rounded-2xl overflow-hidden shadow-md">
<img alt="Lanches" class="w-full h-full object-cover" src="https://lh3.googleusercontent.com/aida-public/AB6AXuAbxe2MZFtuE28MdZSt6FGc6fJXL9k5BtNBMjCCMlLZdpd6TZPX6rHVc-8fdvM6BLbA8N6EPEKFuXFuMLpglMGet3xOAZMAiB47YIRtc_YY8J31I4lLEMCJLs-DQSajJQVD8EpCZXqgEE2ceSoFXcBINhDrolgiidaoMBq1uFStGvNKu6A0nOa7sHLyLyQGjdc-v2EuPiJwysQ9y8GaK4knoa8CmbLnSvG0YBoKz3-ytwxXbqEZytlr695XPzKW3Q7G5nd0zsSK"/>
</div>
<span class="text-xs font-semibold">Lanches</span>
</div>
<div class="flex flex-col items-center gap-2 flex-shrink-0">
<div class="w-20 h-20 rounded-2xl overflow-hidden shadow-md">
<img alt="Bolos" class="w-full h-full object-cover" src="https://lh3.googleusercontent.com/aida-public/AB6AXuC_ccsew0LHKbHPRbG4Jt9ps-abWTKAA9p5msprnRdy_TG16yHH1pd7nJuoifY_vJ8en-KXdraevk2DJoIByyE4W8NwkkG078jKrj4UO8Y6X05yJRx8RGm6PWYxwWxfqOsru9Kl395IlTLxT_JPFHp82IFRRer6qEK6pY0C9TocWZmHDpYFIBEZvWbSySKvU1lm0MHMmwYUQO7gHEoZt15DlYHFKX1aYza8-2XDGZWIH2x0MBLzMtmlS_GNbtc8FIvLdLQpYzK-"/>
</div>
<span class="text-xs font-semibold">Bolos</span>
</div>
</div>
</section>
<section class="pb-8">
<div class="flex items-center justify-between mb-4">
<h3 class="text-lg font-bold">Padarias próximas</h3>
<button class="text-primary font-bold text-sm">Ver todas</button>
</div>
<div class="space-y-4">
<div class="bg-white dark:bg-stone-800 p-4 rounded-3xl flex gap-4 shadow-sm border border-stone-100 dark:border-stone-700">
<div class="w-24 h-24 rounded-2xl overflow-hidden flex-shrink-0">
<img alt="Padaria do João" class="w-full h-full object-cover" src="https://lh3.googleusercontent.com/aida-public/AB6AXuBIAJFQpRQccuw6kIO7ILI1W0VnQwn88c0Thxrlik-oHE4xiGop6G7k3hAKan6LdiLCxZL1gP2jdhFcN2gOiekXOr-ZuKg7Vr1pxMvOeBEUo4w-3JxQnHlnPV95Eh4XGoTILppoPbPVqjNNh85F7o_JHccU0f5IMNkui01it90JF2HZg7Ua4Rgjy-OuBKxdjFZEFCprd8RdmwQgic85jHDpIJ8RG5OQ3J-6yzpLnb1tApzoLqsnK5EcdssTCRXgaUfvMYXqa9MF"/>
</div>
<div class="flex flex-col justify-center py-1">
<h4 class="font-bold text-base">Padaria do João</h4>
<p class="text-xs text-stone-500 dark:text-stone-400 mt-0.5">Pães, doces e salgados fresquinhos</p>
<div class="flex items-center gap-3 mt-2">
<div class="flex items-center gap-1">
<span class="material-icons-outlined text-sm text-yellow-500">star</span>
<span class="text-xs font-bold text-yellow-600">4.8</span>
</div>
<div class="flex items-center gap-1 text-stone-500 dark:text-stone-400">
<span class="material-icons-outlined text-sm">schedule</span>
<span class="text-xs">25-35 min</span>
</div>
<div class="flex items-center gap-1 text-stone-500 dark:text-stone-400">
<span class="material-icons-outlined text-sm">delivery_dining</span>
<span class="text-xs">R$ 3,99</span>
</div>
</div>
</div>
</div>
<div class="bg-white dark:bg-stone-800 p-4 rounded-3xl flex gap-4 shadow-sm border border-stone-100 dark:border-stone-700">
<div class="w-24 h-24 rounded-2xl overflow-hidden flex-shrink-0">
<img alt="Central do Trigo" class="w-full h-full object-cover" src="https://lh3.googleusercontent.com/aida-public/AB6AXuC_82VztcAbUqnSx11UGKx5KKkpLtIaSqxHz_SjGoOP-CxVG3AQQ8Q98SbIuyhwoHaehz8nyOb-Wo3oiEp3WTcWuDqsbh3UytlXFQYSA3mw7rm-ZYCuXK76ZD-VMeryKG3NhxTGaoWyw8Ns_aJQ3c6ffJt-N4kdLdAaNvL_vFPCb_eP203Bt1tTPlu5imk9u3L7yzmjuqJOb39-cqUyc7pQkmnwrks8jVUkZrzSYuCDScXgAfirHAOmc8cCg50oJCnMWADvGx9_"/>
</div>
<div class="flex flex-col justify-center py-1">
<h4 class="font-bold text-base">Central do Trigo</h4>
<p class="text-xs text-stone-500 dark:text-stone-400 mt-0.5">O melhor pão de queijo da região</p>
<div class="flex items-center gap-3 mt-2">
<div class="flex items-center gap-1">
<span class="material-icons-outlined text-sm text-yellow-500">star</span>
<span class="text-xs font-bold text-yellow-600">4.9</span>
</div>
<div class="flex items-center gap-1 text-stone-500 dark:text-stone-400">
<span class="material-icons-outlined text-sm">schedule</span>
<span class="text-xs">15-25 min</span>
</div>
<div class="flex items-center gap-1 text-stone-500 dark:text-stone-400">
<span class="material-icons-outlined text-sm">delivery_dining</span>
<span class="text-xs">Grátis</span>
</div>
</div>
</div>
</div>
<div class="bg-white dark:bg-stone-800 p-4 rounded-3xl flex gap-4 shadow-sm border border-stone-100 dark:border-stone-700 opacity-80">
<div class="w-24 h-24 rounded-2xl overflow-hidden flex-shrink-0 grayscale">
<img alt="Pão de Açúcar" class="w-full h-full object-cover" src="https://lh3.googleusercontent.com/aida-public/AB6AXuDEElaS7MvXl55YpMWEUzN6rzVF1XrwDUKkFzj7QEsE7vTwccUxbgulx-2s9SFF-Xd2AO_mBkiwrJtpeYnwfoUsKlhmlx-7AAl1Oo3j4EMyf8rOw05q4IZjy1IrnGDWotClv1u5LsNk0rFusflR4HVg10q-kIbxi0jh_DptNWUQBjaa9Fn3Oc2u6kbjrdkV79-mzySIknFN0R0Mza95A9XzSspPkyfCOsujMsaP8rkDSc2qPct_EeNBfvbaDy63o6uBV-EJKlNI"/>
</div>
<div class="flex flex-col justify-center py-1">
<h4 class="font-bold text-base text-stone-400">Bella Massa</h4>
<p class="text-xs text-stone-400 mt-0.5">Tortas, quiches e cafés gourmets</p>
<div class="flex items-center gap-3 mt-2">
<div class="flex items-center gap-1">
<span class="material-icons-outlined text-sm text-stone-300">star</span>
<span class="text-xs font-bold text-stone-300">4.5</span>
</div>
<div class="flex items-center gap-1 text-stone-300">
<span class="material-icons-outlined text-sm">schedule</span>
<span class="text-xs">Fechado</span>
</div>
</div>
</div>
</div>
</div>
</section>
</main>
<nav class="fixed bottom-0 left-0 right-0 bg-white/95 dark:bg-stone-900/95 backdrop-blur-md border-t border-stone-100 dark:border-stone-800 px-6 py-4 z-50">
<div class="flex items-center justify-between max-w-md mx-auto">
<button class="flex flex-col items-center gap-1 group">
<span class="material-icons-outlined text-primary">home</span>
<span class="text-[10px] font-bold text-primary">Início</span>
</button>
<button class="flex flex-col items-center gap-1 text-stone-400 dark:text-stone-500 group">
<span class="material-icons-outlined">receipt_long</span>
<span class="text-[10px] font-bold">Pedidos</span>
</button>
<button class="flex flex-col items-center gap-1 text-stone-400 dark:text-stone-500 group">
<span class="material-icons-outlined">search</span>
<span class="text-[10px] font-bold">Busca</span>
</button>
<button class="flex flex-col items-center gap-1 text-stone-400 dark:text-stone-500 group">
<span class="material-icons-outlined">person_outline</span>
<span class="text-[10px] font-bold">Perfil</span>
</button>
</div>
</nav>
<button class="fixed bottom-24 right-5 w-12 h-12 bg-secondary text-white rounded-full flex items-center justify-center shadow-xl z-50" onclick="document.documentElement.classList.toggle('dark')">
<span class="material-icons-outlined">dark_mode</span>
</button>

</body></html>