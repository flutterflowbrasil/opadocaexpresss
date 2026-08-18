import 'package:flutter/material.dart';

/// Stub web: `google_maps_flutter` nao pode ser importado no Chrome sem a
/// JS API carregada (MapTypeId crash). Entregador ja e redirecionado para
/// `/baixar_app_entregador`.
class EntregaAndamentoScreen extends StatelessWidget {
  final String pedidoId;

  const EntregaAndamentoScreen({super.key, required this.pedidoId});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
