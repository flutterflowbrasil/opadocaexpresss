import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MeusEnderecosModal extends ConsumerStatefulWidget {
  const MeusEnderecosModal({super.key});

  @override
  ConsumerState<MeusEnderecosModal> createState() => _MeusEnderecosModalState();
}

class _MeusEnderecosModalState extends ConsumerState<MeusEnderecosModal> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _enderecos = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEnderecos();
  }

  Future<void> _fetchEnderecos() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Usuário não autenticado';
          _isLoading = false;
        });
        return;
      }

      // Primeiro busca o Id do Cliente na tabela clientes
      final clienteData = await _supabase
          .from('clientes')
          .select('id')
          .eq('usuario_id', user.id)
          .maybeSingle();

      if (clienteData == null) {
        setState(() {
          _errorMessage = 'Dados de cliente não encontrados.';
          _isLoading = false;
        });
        return;
      }

      final clienteId = clienteData['id'];

      // Agora busca os endereços usando o id do cliente
      final response = await _supabase
          .from('enderecos_clientes')
          .select()
          .eq('cliente_id', clienteId)
          .order('is_padrao', ascending: false) // Padroes primeiro
          .order('created_at', ascending: false);

      setState(() {
        _enderecos = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar endereços: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Define icones de acordo com o apelido/texto
  IconData _getIconForAddress(String? apelido) {
    if (apelido == null) return Icons.location_on_outlined;
    final lower = apelido.toLowerCase();
    if (lower.contains('casa')) return Icons.home_outlined;
    if (lower.contains('trabalho') || lower.contains('empresa')) {
      return Icons.work_outline;
    }
    return Icons.location_on_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFFFF7034);
    const secondaryColor = Color(0xFF7D2D35);
    final backgroundColor =
        isDark ? const Color(0xFF23150F) : const Color(0xFFF9F5F0);
    final cardColor =
        isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: backgroundColor,
            ),
            child: Column(
              children: [
                // Header Flutuante
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: backgroundColor.withValues(alpha: 0.9),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: isDark ? Colors.white : secondaryColor,
                          size: 28,
                        ),
                        tooltip: 'Fechar',
                        hoverColor: (isDark ? Colors.white : secondaryColor)
                            .withOpacity(0.1),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              right: 48), // Offset for center aligning title
                          child: Text(
                            'Meus Endereços',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : secondaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content Area
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: primaryColor))
                      : _errorMessage != null
                          ? Center(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                    color:
                                        isDark ? Colors.red[300] : Colors.red),
                              ),
                            )
                          : _enderecos.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.location_off_outlined,
                                        size: 64,
                                        color: isDark
                                            ? Colors.grey[600]
                                            : Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Nenhum endereço salvo',
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: _enderecos.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final ender = _enderecos[index];
                                    final apelido =
                                        ender['apelido'] ?? 'Endereço';
                                    final isPadrao = ender['is_padrao'] == true;

                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isPadrao
                                              ? primaryColor.withValues(
                                                  alpha: 0.5)
                                              : (isDark
                                                  ? Colors.white
                                                      .withValues(alpha: 0.1)
                                                  : Colors.orange
                                                      .withValues(alpha: 0.1)),
                                          width: isPadrao ? 2 : 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.03),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: primaryColor.withValues(
                                                  alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              _getIconForAddress(apelido),
                                              color: primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                            apelido,
                                                            style: GoogleFonts
                                                                .outfit(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: isDark
                                                                  ? Colors.white
                                                                  : secondaryColor,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          if (isPadrao) ...[
                                                            const SizedBox(
                                                                width: 8),
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          6,
                                                                      vertical:
                                                                          2),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: primaryColor
                                                                    .withValues(
                                                                        alpha:
                                                                            0.1),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            4),
                                                              ),
                                                              child: Text(
                                                                'PADRÃO',
                                                                style:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      primaryColor,
                                                                ),
                                                              ),
                                                            ),
                                                          ]
                                                        ],
                                                      ),
                                                    ),
                                                    IconButton(
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(),
                                                      icon: Icon(
                                                        Icons.edit_outlined,
                                                        color: isDark
                                                            ? Colors.grey[400]
                                                            : Colors.grey[500],
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        // Editar endereço (A implementar depois)
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '${ender['logradouro']}, ${ender['numero']}${ender['complemento'] != null && ender['complemento'].toString().isNotEmpty ? ' - ${ender['complemento']}' : ''}\n'
                                                  '${ender['bairro']}, ${ender['cidade']} - ${ender['estado']}\n'
                                                  'CEP: ${ender['cep']}',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 14,
                                                    color: isDark
                                                        ? Colors.grey[400]
                                                        : secondaryColor
                                                            .withValues(
                                                                alpha: 0.7),
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                ),

                // Botão Adicionar Fixo Rodapé
                Container(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 24,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Adicionar endereço (A implementar)
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      'Adicionar Novo Endereço',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: primaryColor.withValues(alpha: 0.5),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
