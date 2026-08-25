import 'package:padoca_express/core/config/plataforma_runtime_config.dart';

/// Visibilidade dos itens do sidebar do estabelecimento.
/// Novos itens: adicionar case em [isItemVisible] + chave em plataforma_config.
class EstabSidebarVisibility {
  EstabSidebarVisibility._();

  static bool isItemVisible(String itemId, PlataformaRuntimeConfig cfg) {
    switch (itemId) {
      case 'coupons':
        return cfg.cuponsAtivos;
      default:
        return true;
    }
  }

  static List<T> filterItems<T>(
    Iterable<T> items,
    String Function(T item) idOf,
    PlataformaRuntimeConfig cfg,
  ) {
    return items
        .where((item) => isItemVisible(idOf(item), cfg))
        .toList(growable: false);
  }
}
