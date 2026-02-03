<!DOCTYPE html>
<html class="light" lang="pt-br"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Padoca Express - Login</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,typography,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/icon?family=Material+Icons+Round" rel="stylesheet"/>
<script>
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        primary: "#FF7034",
                        "background-light": "#F9F5F0",
                        "background-dark": "#1A1614",
                        burgundy: "#7D2D35",
                    },
                    fontFamily: {
                        display: ["Outfit", "sans-serif"],
                    },
                    borderRadius: {
                        DEFAULT: "16px",
                    },
                },
            },
        };
    </script>
<style type="text/tailwindcss">
        body {
            font-family: 'Outfit', sans-serif;
            -webkit-tap-highlight-color: transparent;
        }
        .ios-shadow {
            box-shadow: 0 4px 20px -2px rgba(0, 0, 0, 0.05);
        }
        .btn-shadow {
            box-shadow: 0 4px 12px rgba(255, 112, 52, 0.3);
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
<body class="bg-background-light dark:bg-background-dark min-h-screen flex items-center justify-center p-6 transition-colors duration-300">
<div class="w-full max-w-md space-y-8 flex flex-col items-center">
<div class="relative w-40 h-40 rounded-full bg-white dark:bg-zinc-800 p-4 shadow-lg flex items-center justify-center overflow-hidden">
<img alt="Padoca Express Logo" class="w-full h-full object-contain" src="https://lh3.googleusercontent.com/aida-public/AB6AXuA-Vud0AmmUksrJBZrlqKumO7Dq0QrxA7MvESYYBIdPsj1lErxEE1IVAW5ur0pJC1V0wP5eTrEeZHHOO2jOk7-97Zvop4xJ79wraD77AbKYZ81RWzm-fHKkkzU5y7x2rplcEQNqTI31dq87MV3TPjRWBMaLW2t0CLlhzJB9R-nk9P4USNCDshnC3ZBxANbjN17ULq3LJQoDZmkte_lMtTiEAZI2lFI1MFr_L1ppRZf48GXECg2_1r_ttEvjz1uthl3CZPenjqbc"/>
</div>
<div class="text-center space-y-2">
<h1 class="text-3xl font-bold text-burgundy dark:text-orange-100">Login</h1>
<p class="text-zinc-500 dark:text-zinc-400 text-sm">Bem-vindo de volta ao Padoca Express!</p>
</div>
<div class="w-full space-y-5">
<div class="space-y-1.5">
<label class="text-sm font-semibold text-burgundy dark:text-zinc-300 ml-1">E-mail</label>
<div class="relative group">
<span class="material-icons-round absolute left-4 top-1/2 -translate-y-1/2 text-burgundy/40 dark:text-zinc-500 group-focus-within:text-primary transition-colors">email</span>
<input class="w-full pl-12 pr-4 py-4 bg-white dark:bg-zinc-900 border-none rounded-2xl ring-1 ring-zinc-200 dark:ring-zinc-800 focus:ring-2 focus:ring-primary transition-all ios-shadow outline-none text-burgundy dark:text-white placeholder:text-zinc-400" placeholder="exemplo@dominio.com" type="email"/>
</div>
</div>
<div class="space-y-1.5">
<div class="flex justify-between items-center px-1">
<label class="text-sm font-semibold text-burgundy dark:text-zinc-300">Senha</label>
<a class="text-xs font-medium text-primary hover:opacity-80 transition-opacity" href="#">Esqueceu a senha?</a>
</div>
<div class="relative group">
<span class="material-icons-round absolute left-4 top-1/2 -translate-y-1/2 text-burgundy/40 dark:text-zinc-500 group-focus-within:text-primary transition-colors">lock</span>
<input class="w-full pl-12 pr-12 py-4 bg-white dark:bg-zinc-900 border-none rounded-2xl ring-1 ring-zinc-200 dark:ring-zinc-800 focus:ring-2 focus:ring-primary transition-all ios-shadow outline-none text-burgundy dark:text-white placeholder:text-zinc-400" placeholder="••••••••" type="password"/>
<button class="absolute right-4 top-1/2 -translate-y-1/2 text-zinc-400 hover:text-primary transition-colors" type="button">
<span class="material-icons-round text-xl">visibility_off</span>
</button>
</div>
</div>
<div class="flex items-center gap-3 px-1 pt-1">
<input class="w-5 h-5 rounded border-zinc-300 text-primary focus:ring-primary bg-white dark:bg-zinc-900 dark:border-zinc-700 transition-all cursor-pointer" id="terms" type="checkbox"/>
<label class="text-sm font-medium text-burgundy dark:text-zinc-300 cursor-pointer select-none" for="terms">
                    Aceito os <a class="text-primary hover:underline" href="#">termos e condições</a>
</label>
</div>
<button class="w-full py-4 bg-primary text-white font-bold rounded-2xl btn-shadow hover:scale-[0.98] active:scale-95 transition-all flex items-center justify-center gap-2 mt-4 text-lg">
                Entrar
            </button>
</div>
<div class="w-full flex items-center gap-4 py-2">
<div class="h-px flex-1 bg-zinc-200 dark:bg-zinc-800"></div>
<span class="text-xs font-medium text-zinc-400 uppercase tracking-widest">ou continuar com</span>
<div class="h-px flex-1 bg-zinc-200 dark:bg-zinc-800"></div>
</div>
<div class="w-full">
<button class="w-full py-4 bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 rounded-2xl ios-shadow hover:bg-zinc-50 dark:hover:bg-zinc-800 flex items-center justify-center gap-3 transition-colors active:scale-[0.98]">
<svg fill="none" height="24" viewBox="0 0 24 24" width="24" xmlns="http://www.w3.org/2000/svg">
<path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"></path>
<path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"></path>
<path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z" fill="#FBBC05"></path>
<path d="M12 5.38c1.62 0 3.06.56 4.21 1.66l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"></path>
</svg>
<span class="font-semibold text-zinc-700 dark:text-zinc-300">Continuar com Google</span>
</button>
</div>
<p class="text-sm text-zinc-500 dark:text-zinc-400">
            Ainda não tem conta? 
            <a class="text-primary font-bold hover:underline" href="#">Cadastre-se</a>
</p>
</div>
<button class="fixed bottom-6 right-6 w-12 h-12 rounded-full bg-burgundy text-white flex items-center justify-center shadow-lg active:scale-90 transition-transform" onclick="document.documentElement.classList.toggle('dark')">
<span class="material-icons-round">dark_mode</span>
</button>

</body></html>