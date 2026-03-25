import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'adicionar_endereco_modal.dart';
import 'endereco_model.dart';

/// Modal de seleção de endereço de entrega.
/// - Lista os endereços salvos do cliente.
/// - Permite adicionar um novo endereço (reutiliza AdicionarEnderecoModal).
/// - Retorna o [EnderecoCliente] selecionado ou null.
class SelecionarEnderecoModal extends ConsumerStatefulWidget {
  const SelecionarEnderecoModal({super.key});

  static Future<EnderecoCliente?> show(BuildContext context) {
    return showModalBottomSheet<EnderecoCliente>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SelecionarEnderecoModal(),
    );
  }

  @override
  ConsumerState<SelecionarEnderecoModal> createState() =>
      _SelecionarEnderecoModalState();
}

class _SelecionarEnderecoModalState
    extends ConsumerState<SelecionarEnderecoModal> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<EnderecoCliente> _enderecos = [];

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  @override
  void initState() {
    super.initState();
    _fetchEnderecos();
  }

  Future<void> _fetchEnderecos() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final clienteData = await _supabase
          .from('clientes')
          .select('id')
          .eq('usuario_id', user.id)
          .maybeSingle();

      if (clienteData == null) {
        setState(() => _isLoading = false);
        return;
      }

      final data = await _supabase
          .from('enderecos_clientes')
          .select()
          .eq('cliente_id', clienteData['id'])
          .order('is_padrao', ascending: false)
          .order('created_at', ascending: false);

      setState(() {
        _enderecos = [for (final e in data) EnderecoCliente.fromJson(e)];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  IconData _getIcon(String? apelido) {
    if (apelido == null) return Icons.location_on_outlined;
    final l = apelido.toLowerCase();
    if (l.contains('casa')) return Icons.home_outlined;
    if (l.contains('trabalho') || l.contains('empresa')) {
      return Icons.work_outline;
    }
    return Icons.location_on_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1917) : const Color(0xFFF9F5F0);
    final cardColor =
        isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            color: bgColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Selecionar Endereço',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : _secondaryColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: isDark ? Colors.white70 : _secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                    height: 1,
                    color: _primaryColor.withValues(alpha: 0.1)),

                // Lista
                Flexible(
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child:
                              CircularProgressIndicator(color: _primaryColor),
                        )
                      : _enderecos.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_off_outlined,
                                      size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Nenhum endereço salvo',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              itemCount: _enderecos.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final e = _enderecos[index];
                                return InkWell(
                                  onTap: () => Navigator.pop(context, e),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: e.isPadrao
                                            ? _primaryColor.withValues(
                                                alpha: 0.5)
                                            : (isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.08)
                                                : _primaryColor
                                                    .withValues(alpha: 0.1)),
                                        width: e.isPadrao ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: _primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            _getIcon(e.apelido),
                                            color: _primaryColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      e.apelido ?? 'Endereço',
                                                      style: GoogleFonts.outfit(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 15,
                                                        color: isDark
                                                            ? Colors.white
                                                            : _secondaryColor,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (e.isPadrao) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            _primaryColor.withValues(
                                                                alpha: 0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                4),
                                                      ),
                                                      child: Text(
                                                        'PADRÃO',
                                                        style:
                                                            GoogleFonts.outfit(
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: _primaryColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ]
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${e.logradouro}, ${e.numero} — ${e.bairro}, ${e.cidade}',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 13,
                                                  color: isDark
                                                      ? Colors.grey[400]
                                                      : _secondaryColor
                                                          .withValues(
                                                              alpha: 0.6),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.chevron_right,
                                            color: Colors.grey[400]),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),

                // Botão adicionar novo
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    MediaQuery.of(context).padding.bottom + 20,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final novo = await AdicionarEnderecoModal.show(context);
                      if (novo != null && context.mounted) {
                        Navigator.pop(context, novo);
                      }
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      'Adicionar Novo Endereço',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size(double.infinity, 52),
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
