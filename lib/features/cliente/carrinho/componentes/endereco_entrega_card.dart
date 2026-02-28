import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/cliente/carrinho/models/endereco_model.dart';

class EnderecoEntregaCard extends StatelessWidget {
  final bool isDark;
  final Color bgSecColor;
  final EnderecoClienteModel? endereco;
  final VoidCallback onAdicionar;
  final VoidCallback onTrocar;

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  const EnderecoEntregaCard({
    super.key,
    required this.isDark,
    required this.bgSecColor,
    this.endereco,
    required this.onAdicionar,
    required this.onTrocar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgSecColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _secondaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: endereco == null
                ? Text(
                    'Nenhum endereço selecionado',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : _secondaryColor,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${endereco!.logradouro}, ${endereco!.numero}',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : _secondaryColor,
                        ),
                      ),
                      Text(
                        '${endereco!.bairro}, ${endereco!.cidade} - ${endereco!.estado}',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: isDark
                              ? Colors.grey[400]
                              : _secondaryColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
          ),
          TextButton(
            onPressed: endereco == null ? onAdicionar : onTrocar,
            child: Text(
              endereco == null ? 'Adicionar' : 'Trocar',
              style: GoogleFonts.outfit(
                color: _primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
