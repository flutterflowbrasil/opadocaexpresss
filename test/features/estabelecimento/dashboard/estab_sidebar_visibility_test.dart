import 'package:flutter_test/flutter_test.dart';
import 'package:padoca_express/core/config/plataforma_runtime_config.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/componentes_dash/estab_sidebar_visibility.dart';

void main() {
  group('EstabSidebarVisibility', () {
    test('oculta coupons quando cuponsAtivos é false', () {
      const cfg = PlataformaRuntimeConfig(cuponsAtivos: false);
      expect(EstabSidebarVisibility.isItemVisible('coupons', cfg), isFalse);
    });

    test('mostra coupons quando cuponsAtivos é true', () {
      const cfg = PlataformaRuntimeConfig(cuponsAtivos: true);
      expect(EstabSidebarVisibility.isItemVisible('coupons', cfg), isTrue);
    });

    test('demais itens permanecem visíveis', () {
      const cfg = PlataformaRuntimeConfig(cuponsAtivos: false);
      for (final id in [
        'dashboard',
        'orders',
        'products',
        'reviews',
        'finance',
        'reports',
        'settings',
      ]) {
        expect(EstabSidebarVisibility.isItemVisible(id, cfg), isTrue, reason: id);
      }
    });

    test('filterItems remove coupons desativados e mantém os demais', () {
      const cfg = PlataformaRuntimeConfig(cuponsAtivos: false);
      final filtered = EstabSidebarVisibility.filterItems(
        const ['products', 'coupons', 'orders'],
        (id) => id,
        cfg,
      );
      expect(filtered, ['products', 'orders']);
    });
  });
}
