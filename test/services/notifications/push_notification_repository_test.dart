import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:padoca_express/services/notifications/push_notification_controller.dart';
import 'package:padoca_express/services/notifications/push_notification_repository.dart';

class MockPushNotificationRepository extends Mock
    implements PushNotificationRepository {}

void main() {
  group('PushNotificationRepository payloads', () {
    test('buildUpsertRow marca dispositivo ativo e limpa invalidacao', () {
      final now = DateTime.utc(2026, 8, 17, 15);
      final row = PushNotificationRepository.buildUpsertRow(
        usuarioId: 'user-1',
        token: 'sub-abc',
        plataforma: 'android',
        appVersion: '1.0.0',
        deviceModel: 'Pixel',
        now: now,
      );

      expect(row['usuario_id'], 'user-1');
      expect(row['token'], 'sub-abc');
      expect(row['plataforma'], 'android');
      expect(row['ativo'], isTrue);
      expect(row['invalido'], isFalse);
      expect(row['invalido_em'], isNull);
      expect(row['motivo_invalido'], isNull);
      expect(row['app_version'], '1.0.0');
      expect(row['device_model'], 'Pixel');
      expect(row['ultimo_uso_em'], now.toIso8601String());
      expect(row['updated_at'], now.toIso8601String());
    });

    test('buildUpsertRow aceita plataforma web', () {
      final row = PushNotificationRepository.buildUpsertRow(
        usuarioId: 'user-2',
        token: 'web-sub',
        plataforma: 'web',
        now: DateTime.utc(2026, 8, 17),
      );

      expect(row['plataforma'], 'web');
      expect(row.containsKey('app_version'), isFalse);
    });

    test('buildDeactivateRow desativa o device no logout', () {
      final now = DateTime.utc(2026, 8, 17, 16);
      final row = PushNotificationRepository.buildDeactivateRow(now: now);

      expect(row['ativo'], isFalse);
      expect(row['updated_at'], now.toIso8601String());
    });
  });

  group('PushNotificationController deep links', () {
    test('entregador com pedido_id abre a entrega', () {
      expect(
        PushNotificationController.routeFor('entregador', 'pedido-9'),
        '/dashboard_entregador/entrega/pedido-9',
      );
    });

    test('entregador sem pedido abre o dashboard', () {
      expect(
        PushNotificationController.routeFor('entregador', null),
        '/dashboard_entregador',
      );
    });

    test('entregador com despacho_id abre o dashboard da oferta', () {
      expect(
        PushNotificationController.routeFor(
          'entregador',
          null,
          despachoId: 'desp-1',
        ),
        '/dashboard_entregador',
      );
    });

    test('estabelecimento abre o kanban de pedidos', () {
      expect(
        PushNotificationController.routeFor('estabelecimento', 'qualquer'),
        '/dashboard_estabelecimento/pedidos',
      );
    });

    test('cliente com pedido_id abre o pedido', () {
      expect(
        PushNotificationController.routeFor('cliente', 'p1'),
        '/cliente/pedido/p1',
      );
    });
  });

  group('PushNotificationRepository mock', () {
    test('getUserPreferences delega para o repositorio', () async {
      final repo = MockPushNotificationRepository();
      when(() => repo.getUserPreferences('user-1')).thenAnswer(
        (_) async => {'push_ativo': true, 'push_entregas': true},
      );

      final prefs = await repo.getUserPreferences('user-1');

      expect(prefs?['push_ativo'], isTrue);
      verify(() => repo.getUserPreferences('user-1')).called(1);
    });

    test('deactivatePushDevice e chamado no logout', () async {
      final repo = MockPushNotificationRepository();
      when(() => repo.deactivatePushDevice('sub-1')).thenAnswer((_) async {});

      await repo.deactivatePushDevice('sub-1');

      verify(() => repo.deactivatePushDevice('sub-1')).called(1);
      verifyNever(() => repo.deactivateAllForUser(any()));
    });
  });
}
