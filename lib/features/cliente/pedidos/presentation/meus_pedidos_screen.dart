import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/cliente/pedidos/controllers/pedidos_cliente_controller.dart';
import 'package:padoca_express/features/cliente/pedidos/presentation/componentes/pedido_card.dart';
import 'package:padoca_express/features/cliente/pedidos/presentation/componentes/empty_state_pedidos.dart';

class MeusPedidosScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const MeusPedidosScreen({super.key, this.onBack});

  @override
  ConsumerState<MeusPedidosScreen> createState() => _MeusPedidosScreenState();
}

class _MeusPedidosScreenState extends ConsumerState<MeusPedidosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _primaryColor = Color(0xFFEC5B13);
  static const _burgundy = Color(0xFF4A1010);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pedidosClienteControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Tailwind: bg-background-light or bg-background-dark
    final bgColor = isDark ? const Color(0xFF221610) : const Color(0xFFF8F6F6);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: widget.onBack != null
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    color: isDark ? Colors.white : _burgundy, size: 20),
                onPressed: widget.onBack,
              )
            : null,
        title: Text(
          'Meus Pedidos',
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white : _burgundy,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            color: isDark
                ? const Color(0xFF0F172A).withOpacity(0.5)
                : Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: _primaryColor,
              indicatorWeight: 2,
              labelColor: _primaryColor,
              unselectedLabelColor:
                  isDark ? Colors.grey[400] : Colors.grey[500],
              labelStyle:
                  GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle:
                  GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
              tabs: const [
                Tab(text: 'Ativos'),
                Tab(text: 'Anteriores'),
              ],
            ),
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : state.error != null
              ? Center(child: Text('Erro: \${state.error}'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Aba Ativos
                    RefreshIndicator(
                      onRefresh: () => ref
                          .read(pedidosClienteControllerProvider.notifier)
                          .carregarPedidos(),
                      color: _primaryColor,
                      child: state.pedidosAtivos.isEmpty
                          ? ListView(children: const [
                              SizedBox(height: 100),
                              EmptyStatePedidos(isAtivos: true)
                            ])
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.pedidosAtivos.length,
                              itemBuilder: (ctx, i) =>
                                  PedidoCard(pedido: state.pedidosAtivos[i]),
                            ),
                    ),
                    // Aba Anteriores
                    RefreshIndicator(
                      onRefresh: () => ref
                          .read(pedidosClienteControllerProvider.notifier)
                          .carregarPedidos(),
                      color: _primaryColor,
                      child: state.pedidosAnteriores.isEmpty
                          ? ListView(children: const [
                              SizedBox(height: 100),
                              EmptyStatePedidos(isAtivos: false)
                            ])
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.pedidosAnteriores.length,
                              itemBuilder: (ctx, i) => PedidoCard(
                                  pedido: state.pedidosAnteriores[i]),
                            ),
                    ),
                  ],
                ),
    );
  }
}
