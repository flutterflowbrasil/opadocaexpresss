import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/cliente/componentes/custom_bottom_navigation_bar.dart';
import 'package:padoca_express/features/cliente/componentes/home_header.dart';
import 'package:padoca_express/features/cliente/home/home_content.dart';
import 'package:padoca_express/features/cliente/perfil/perfil_user_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgLight = const Color(0xFFF9F5F0);
    final bgDark = const Color(0xFF1C1917);
    final _secondaryColor = const Color(0xFF7D2D35);

    final List<Widget> screens = [
      const HomeContent(),
      const Center(child: Text('Pedidos')), // Placeholder
      const PerfilUserScreen(),
    ];

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      appBar: _currentIndex == 2
          ? AppBar(
              backgroundColor: isDark ? bgDark : bgLight,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    color: isDark ? Colors.white : _secondaryColor, size: 20),
                onPressed: () {
                  setState(() => _currentIndex = 0);
                },
              ),
              title: Text(
                'Perfil',
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white : _secondaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            )
          : ClienteAppBar(isDark: isDark),
      body: screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
