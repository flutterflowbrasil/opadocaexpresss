import 'package:flutter/material.dart';
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

    final List<Widget> screens = [
      const HomeContent(),
      const Center(child: Text('Pedidos')), // Placeholder
      const PerfilUserScreen(),
    ];

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      appBar: ClienteAppBar(isDark: isDark),
      body: screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
