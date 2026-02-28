import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:padoca_express/features/auth/data/auth_repository.dart';
import 'package:padoca_express/features/cliente/perfil/profile_controller.dart';
import 'package:padoca_express/core/theme/theme_provider.dart';
import 'package:padoca_express/features/cliente/perfil/comp/editar_informacoes.dart';
import 'package:padoca_express/features/cliente/perfil/comp/meus_enderecos.dart';

class PerfilUserScreen extends ConsumerStatefulWidget {
  const PerfilUserScreen({super.key});

  @override
  ConsumerState<PerfilUserScreen> createState() => _PerfilUserScreenState();
}

class _PerfilUserScreenState extends ConsumerState<PerfilUserScreen> {
  @override
  void initState() {
    super.initState();
    // Carrega o perfil ao iniciar a tela
    Future.microtask(
      () => ref.read(profileControllerProvider.notifier).loadProfile(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFFFF7034);
    const secondaryColor = Color(0xFF7D2D35);
    final cardColor = isDark ? const Color(0xFF27272A) : Colors.white;

    final profileState = ref.watch(profileControllerProvider);
    final themeMode = ref.watch(themeProvider);
    final isThemeDark = themeMode == ThemeMode.dark;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Avatar & Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: DecorationImage(
                      image: NetworkImage(
                        profileState.fotoPerfilUrl ??
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuB3TYB3nqJUiQDEvsnYTSQOCp1namm9a65lATM2cc8ubuael3Nr1Ul4AderRK6Edi-lO38d_HYIgstd9X06jK5zhkX3UaY-NDqa0g2uvEDwJ_0Zt_d1Y1kQztqZB0i82DV8IqZza4C4CCQGKdNx5WnPxOd00pyXSeucasIFrszm7nGWWJqh3O35jXiY6ApwsJ8eBWVhuZeYp61CkRJp_-KF1GWrx3Rp3vD0wXCCoZybsaWzoX1paLPYt9eIyHP8x8Cvy5TPEkKq',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (profileState.isLoading)
                  const CircularProgressIndicator(color: primaryColor)
                else
                  Column(
                    children: [
                      Text(
                        profileState.name ?? 'Usuário',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : secondaryColor,
                        ),
                      ),
                      Text(
                        profileState.email ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Minha Conta
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    'MINHA CONTA',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark
                          ? Colors.grey[400]
                          : secondaryColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.orange[50]!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        title: 'Editar Informações',
                        isDark: isDark,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) =>
                                const EditarInformacoesModal(),
                          ).then((updated) {
                            if (updated == true) {
                              // Recarregar os dados do perfil na tela principal
                              ref
                                  .read(profileControllerProvider.notifier)
                                  .loadProfile();
                            }
                          });
                        },
                      ),
                      Divider(
                        height: 1,
                        color: isDark ? Colors.grey[800] : Colors.orange[50],
                      ),
                      _buildMenuItem(
                        icon: Icons.location_on_outlined,
                        title: 'Endereços Salvos',
                        isDark: isDark,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(32)),
                            ),
                            builder: (context) => const MeusEnderecosModal(),
                          );
                        },
                      ),
                      Divider(
                        height: 1,
                        color: isDark ? Colors.grey[800] : Colors.orange[50],
                      ),
                      _buildMenuItem(
                        icon: Icons.payments_outlined,
                        title: 'Formas de Pagamento',
                        isDark: isDark,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Configurações
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    'CONFIGURAÇÕES',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark
                          ? Colors.grey[400]
                          : secondaryColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.orange[50]!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.dark_mode_outlined,
                                color: primaryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Modo Escuro',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : secondaryColor,
                                ),
                              ),
                            ),
                            Switch(
                              value: isThemeDark,
                              onChanged: (val) {
                                ref
                                    .read(themeProvider.notifier)
                                    .toggleTheme(val);
                              },
                              activeThumbColor: primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Botão Sair
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  foregroundColor: primaryColor,
                ),
                icon: const Icon(Icons.logout),
                label: Text(
                  'Sair do App',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isDark,
    required Color primaryColor,
    required Color secondaryColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : secondaryColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
