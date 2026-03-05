import 'package:flutter/material.dart';
import '../componentes_dash/sidebar_menu.dart';
import '../componentes_dash/dashboard_header.dart';
import '../componentes_dash/dashboard_colors.dart';
import 'componentes_kanban/kanban_board.dart';
import 'componentes_kanban/kanban_footer.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: isDark
          ? DashboardColors.backgroundDark
          : DashboardColors.backgroundLight,
      drawer: isWideScreen
          ? null
          : Drawer(
              child: SidebarMenu(
                activeId: 'orders',
                onItemSelected: (id) {
                  Navigator.pop(context);
                },
              ),
            ),
      body: Row(
        children: [
          if (isWideScreen)
            SidebarMenu(
              activeId: 'orders',
              onItemSelected: (_) {},
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DashboardHeader(
                    estabelecimentoNome:
                        'Padoca Express'), // Later bind to state
                const Expanded(
                  child: KanbanBoard(),
                ),
                const KanbanFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
