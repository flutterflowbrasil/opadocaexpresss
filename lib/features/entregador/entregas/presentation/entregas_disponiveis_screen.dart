import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Tela legado de lista broadcast. O despacho agora é 1-a-1 via
/// `despacho_pedidos` no dashboard.
class EntregasDisponiveisScreen extends StatelessWidget {
  const EntregasDisponiveisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go('/dashboard_entregador');
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
