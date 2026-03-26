import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/entregas_disponiveis_controller.dart';
import '../models/pedido_disponivel_model.dart';
// No AppBarPadrao import

class EntregasDisponiveisScreen extends ConsumerWidget {
  const EntregasDisponiveisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(entregasDisponiveisControllerProvider);
    final controller = ref.read(entregasDisponiveisControllerProvider.notifier);

    // Error listening
    ref.listen(entregasDisponiveisControllerProvider, (prev, next) {
      if (next.error != null && (prev?.error != next.error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(
          'Entregas Disponíveis',
          style: GoogleFonts.publicSans(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.carregarDisponiveis();
        },
        child: _buildBody(state, controller),
      ),
    );
  }

  Widget _buildBody(state, EntregasDisponiveisController controller) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEA580C)),
        ),
      );
    }

    if (state.pedidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_outlined,
                size: 64, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text(
              'Nenhuma entrega\ndisponível no momento',
              textAlign: TextAlign.center,
              style: GoogleFonts.publicSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.pedidos.length,
      itemBuilder: (context, index) {
        final p = state.pedidos[index];
        return _PedidoCard(
            pedido: p,
            isAceitando: state.isAceitando,
            onAceitar: () => controller.aceitarEntrega(p.id));
      },
    );
  }
}

class _PedidoCard extends StatelessWidget {
  final PedidoDisponivelModel pedido;
  final bool isAceitando;
  final VoidCallback onAceitar;

  const _PedidoCard({
    required this.pedido,
    required this.isAceitando,
    required this.onAceitar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          const BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pedido #${pedido.numero}',
                      style: GoogleFonts.publicSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1F2937)),
                    ),
                    Text(
                      'R\$ ${(pedido.taxaEntrega + pedido.total).toStringAsFixed(2)}',
                      style: GoogleFonts.publicSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFEA580C)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.storefront_outlined,
                        size: 20, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pedido.nomeEstabelecimento,
                            style: GoogleFonts.publicSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF374151)),
                          ),
                          Text(
                            pedido.enderecoEstabelecimento,
                            style: GoogleFonts.publicSans(
                                fontSize: 12,
                                color: const Color(0xFF6B7280)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 20, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pedido.clienteNome,
                            style: GoogleFonts.publicSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF374151)),
                          ),
                          Text(
                            pedido.enderecoCliente,
                            style: GoogleFonts.publicSans(
                                fontSize: 12,
                                color: const Color(0xFF6B7280)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: isAceitando ? null : onAceitar,
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFEA580C),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16)),
              ),
              alignment: Alignment.center,
              child: isAceitando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : Text(
                      'Aceitar Entrega',
                      style: GoogleFonts.publicSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          )
        ],
      ),
    );
  }
}
