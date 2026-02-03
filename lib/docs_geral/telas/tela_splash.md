<!DOCTYPE html>
<html class="light" lang="pt-br"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Padoca Express - Splash Screen</title>
<link href="https://fonts.googleapis.com" rel="preconnect"/>
<link crossorigin="" href="https://fonts.gstatic.com" rel="preconnect"/>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;700&amp;display=swap" rel="stylesheet"/>
<script src="https://cdn.tailwindcss.com?plugins=forms,typography"></script>
<script>
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        primary: "#F59E0B", // Vibrant orange based on reference
                        "background-light": "#FDBA74",
                        "background-dark": "#7C2D12",
                    },
                    fontFamily: {
                        display: ["Inter", "sans-serif"],
                    },
                    borderRadius: {
                        DEFAULT: "1rem",
                    },
                },
            },
        };
    </script>
<style>.bg-splash-gradient {
            background: linear-gradient(180deg, #FFB74D 0%, #FF8F00 100%);
        }
        .dark .bg-splash-gradient {
            background: linear-gradient(180deg, #7C2D12 0%, #431407 100%);
        }@keyframes float {
            0% { transform: translateY(0px); }
            50% { transform: translateY(-10px); }
            100% { transform: translateY(0px); }
        }
        .animate-float {
            animation: float 3s ease-in-out infinite;
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="font-display antialiased">
<div class="fixed top-0 w-full h-12 flex items-center justify-between px-8 z-50 text-white">
<span class="text-sm font-semibold">9:41</span>
<div class="flex items-center space-x-1.5">
<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path d="M2 11a1 1 0 011-1h2a1 1 0 011 1v5a1 1 0 01-1 1H3a1 1 0 01-1-1v-5zM8 7a1 1 0 011-1h2a1 1 0 011 1v9a1 1 0 01-1 1H9a1 1 0 01-1-1V7zM14 4a1 1 0 011-1h2a1 1 0 011 1v12a1 1 0 01-1 1h-2a1 1 0 01-1-1V4z"></path></svg>
<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path clip-rule="evenodd" d="M17.707 9.293a1 1 0 010 1.414l-7 7a1 1 0 01-1.414 0l-7-7a1 1 0 011.414-1.414L10 14.586l6.293-6.293a1 1 0 011.414 0z" fill-rule="evenodd"></path></svg>
<div class="w-6 h-3 border border-white rounded-sm relative">
<div class="absolute inset-y-0.5 left-0.5 right-1.5 bg-white rounded-sm"></div>
</div>
</div>
</div>
<main class="relative h-screen w-full flex flex-col items-center justify-center bg-splash-gradient overflow-hidden">
<div class="flex flex-col items-center justify-center px-6">
<div class="w-64 h-64 md:w-80 md:h-80 bg-white rounded-3xl shadow-2xl flex items-center justify-center p-6 transform rotate-[-2deg] animate-float">
<img alt="Ôpadoca Logo with Scooter and Bakery Items" class="w-full h-auto object-contain" src="https://lh3.googleusercontent.com/aida-public/AB6AXuAcAhLGVWSCREyn_fxd9kRFyEc17GsEaFYdSWkau6m-jAjU0c5ORmbmau30RVSRi8y84TVRuZvBKaz1EFHGBkS-wvuqH6yeogey_bynxWe3P_uJPwAv36iSE3j1Qw5S26wTw-inBrn3avpxQMEa6jFEH0-8cWPY547nnE6LCfRj5YutZ6isPHC3d4CSTP8saCXMaX8R4Wz50jyU-HCnEHNqSMFKy0rFADFdVjN9xekPeFLNumeD9s2TvS4VQzjdNBPEEvRf5_ur"/>
</div>
<div class="mt-12 text-center">
<h1 class="text-white text-3xl md:text-4xl font-bold tracking-tight drop-shadow-md">
                    Ôpadoca entrega rapidinho!
                </h1>
<div class="mt-4 flex justify-center">
<div class="h-1 w-20 bg-white rounded-full opacity-90 shadow-sm"></div>
</div>
</div>
</div>
<div class="absolute bottom-12 w-full text-center">
<p class="text-white/80 text-sm font-medium tracking-widest uppercase">
                Padoca Express
            </p>
</div>
<div class="absolute bottom-2 left-1/2 -translate-x-1/2 w-32 h-1.5 bg-white/40 rounded-full"></div>
</main>
<script>
        // Check for dark mode preference
        if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
            document.documentElement.classList.add('dark');
        }
        // Listen for changes
        window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', event => {
            if (event.matches) {
                document.documentElement.classList.add('dark');
            } else {
                document.documentElement.classList.remove('dark');
            }
        });
    </script>

</body></html>