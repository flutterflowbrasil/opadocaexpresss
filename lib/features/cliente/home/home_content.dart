import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/cliente/componentes/bakery_card.dart';
import 'package:padoca_express/features/cliente/componentes/category_item.dart';
import 'package:padoca_express/features/cliente/componentes/home_header.dart';
import 'package:padoca_express/features/cliente/componentes/promo_banner.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFFFF7034);
    const secondaryColor = Color(0xFF7D2D35);
    final cardColor = isDark ? const Color(0xFF27272A) : Colors.white;

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: HomeHeader(
            isDark: isDark,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            cardColor: cardColor,
          ),
        ),

        // Banner Section
        SliverToBoxAdapter(child: PromoBanner(secondaryColor: secondaryColor)),

        // Categories
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            child: Text(
              'Categorias',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : secondaryColor,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                CategoryItem(
                  title: 'Padarias',
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDjtt2qwFaLUYEfmchTvz39KIAFEoyJUnrCJilxLSJS3NTx0KgIU4pp_2MMy0Zz4b2Avf_6wfx0qTBiaCaTf3H1Cj__tt3KPMKCXgs6SABvORidCc_PDdDRSBsunNbkHrT751eox3f9meyDuRpMZ9cZ_Cfk-Y0ubu1vEeRVfO4ciEVFZ7UYRrUad1k7M9ymeAC8RSU05QcndrLNO1IpeLqA_FgooOmX_bfldZm8hqSkYYYppIvHAV5e-Kv6h8q1Izjr1l32tVph',
                  isDark: isDark,
                ),
                CategoryItem(
                  title: 'Doces',
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuC4v9rSpUpQ6T31Sz0GMm_83pd7MC_xwrEgVfD1tWeiqe0zceuMMv4HdX_Zv4EaqwK-VAdB2lK9UQpqQTKHDPWlq7Qwj8id9ub5GhXAJUGFWhY62DrDZ-pnRcQYK2upBnfftcy01vI8_IDR18llkUeX90jd5C3VHwd6E3-Bisr_HMvnoo9WLVLlc6fYOyQduIvNLRheBVhCCEFem3Pd5zVedx9hM_rwLKmXEQpwwyz4h5drwClszzx8whMcpbwMiwqY_2-5yenU',
                  isDark: isDark,
                ),
                CategoryItem(
                  title: 'Salgados',
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCzxBlT15a4JOMztOu31625DtXRaueeQHmAiIBoS8EnPkrKGTrn78eNk8TJIYEibFfh7QFzOkYSMr6u-JBh9J7Lfj420QrHhVtmTReP2zE_Yz5RHR21zSCcqwVBy2yI3DUgX3RWT1qa2guagw5g0511ptLumZhl740RuAomC5F3zUYgzZe3ealm2PBbMuZqpXJH39oACUV-0cA85fJDbG-_WBiDlmtubup9QI1HBQm9NCZHxdgg4lasnrLa2gvBwSEuOoMbl3wb',
                  isDark: isDark,
                ),
                CategoryItem(
                  title: 'Lanches',
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuAbxe2MZFtuE28MdZSt6FGc6fJXL9k5BtNBMjCCMlLZdpd6TZPX6rHVc-8fdvM6BLbA8N6EPEKFuXFuMLpglMGet3xOAZMAiB47YIRtc_YY8J31I4lLEMCJLs-DQSajJQVD8EpCZXqgEE2ceSoFXcBINhDrolgiidaoMBq1uFStGvNKu6A0nOa7sHLyLyQGjdc-v2EuPiJwysQ9y8GaK4knoa8CmbLnSvG0YBoKz3-ytwxXbqEZytlr695XPzKW3Q7G5nd0zsSK',
                  isDark: isDark,
                ),
                CategoryItem(
                  title: 'Bolos',
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuC_ccsew0LHKbHPRbG4Jt9ps-abWTKAA9p5msprnRdy_TG16yHH1pd7nJuoifY_vJ8en-KXdraevk2DJoIByyE4W8NwkkG078jKrj4UO8Y6X05yJRx8RGm6PWYxwWxfqOsru9Kl395IlTLxT_JPFHp82IFRRer6qEK6pY0C9TocWZmHDpYFIBEZvWbSySKvU1lm0MHMmwYUQO7gHEoZt15DlYHFKX1aYza8-2XDGZWIH2x0MBLzMtmlS_GNbtc8FIvLdLQpYzK-',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),

        // Nearby Bakeries
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Padarias próximas',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : secondaryColor,
                  ),
                ),
                Text(
                  'Ver todas',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              BakeryCard(
                name: 'Padaria do João',
                description: 'Pães, doces e salgados fresquinhos',
                rating: '4.8',
                time: '25-35 min',
                fee: 'R\$ 3,99',
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBIAJFQpRQccuw6kIO7ILI1W0VnQwn88c0Thxrlik-oHE4xiGop6G7k3hAKan6LdiLCxZL1gP2jdhFcN2gOiekXOr-ZuKg7Vr1pxMvOeBEUo4w-3JxQnHlnPV95Eh4XGoTILppoPbPVqjNNh85F7o_JHccU0f5IMNkui01it90JF2HZg7Ua4Rgjy-OuBKxdjFZEFCprd8RdmwQgic85jHDpIJ8RG5OQ3J-6yzpLnb1tApzoLqsnK5EcdssTCRXgaUfvMYXqa9MF',
                isDark: isDark,
                cardColor: cardColor,
              ),
              const SizedBox(height: 16),
              BakeryCard(
                name: 'Central do Trigo',
                description: 'O melhor pão de queijo da região',
                rating: '4.9',
                time: '15-25 min',
                fee: 'Grátis',
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuC_82VztcAbUqnSx11UGKx5KKkpLtIaSqxHz_SjGoOP-CxVG3AQQ8Q98SbIuyhwoHaehz8nyOb-Wo3oiEp3WTcWuDqsbh3UytlXFQYSA3mw7rm-ZYCuXK76ZD-VMeryKG3NhxTGaoWyw8Ns_aJQ3c6ffJt-N4kdLdAaNvL_vFPCb_eP203Bt1tTPlu5imk9u3L7yzmjuqJOb39-cqUyc7pQkmnwrks8jVUkZrzSYuCDScXgAfirHAOmc8cCg50oJCnMWADvGx9_',
                isDark: isDark,
                cardColor: cardColor,
              ),
              const SizedBox(height: 16),
              BakeryCard(
                name: 'Bella Massa',
                description: 'Tortas, quiches e cafés gourmets',
                rating: '4.5',
                time: 'Fechado',
                fee: '',
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDEElaS7MvXl55YpMWEUzN6rzVF1XrwDUKkFzj7QEsE7vTwccUxbgulx-2s9SFF-Xd2AO_mBkiwrJtpeYnwfoUsKlhmlx-7AAl1Oo3j4EMyf8rOw05q4IZjy1IrnGDWotClv1u5LsNk0rFusflR4HVg10q-kIbxi0jh_DptNWUQBjaa9Fn3Oc2u6kbjrdkV79-mzySIknFN0R0Mza95A9XzSspPkyfCOsujMsaP8rkDSc2qPct_EeNBfvbaDy63o6uBV-EJKlNI',
                isDark: isDark,
                cardColor: cardColor,
                isClosed: true,
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }
}
