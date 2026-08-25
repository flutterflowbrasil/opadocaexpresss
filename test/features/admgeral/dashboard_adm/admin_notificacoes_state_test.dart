import 'package:flutter_test/flutter_test.dart';
import 'package:padoca_express/features/admgeral/dashboard_adm/notificacoes/controllers/admin_notificacoes_controller.dart';
import 'package:padoca_express/features/admgeral/dashboard_adm/notificacoes/models/admin_notificacao_model.dart';

void main() {
  group('AdminNotificacoesState', () {
    AdminNotificacaoModel alerta({
      required String id,
      AdminNotificacaoPrioridade prioridade =
          AdminNotificacaoPrioridade.urgente,
    }) {
      return AdminNotificacaoModel(
        id: id,
        tipo: AdminNotificacaoTipo.cadastroPendente,
        prioridade: prioridade,
        titulo: 'Teste',
        descricao: 'Desc',
        criadoEm: DateTime(2026, 1, 1),
      );
    }

    test('totalCriticos ignora alertas dismissados', () {
      final state = AdminNotificacoesState(
        alertas: [
          alerta(id: 'a1'),
          alerta(id: 'a2', prioridade: AdminNotificacaoPrioridade.atencao),
          alerta(id: 'a3', prioridade: AdminNotificacaoPrioridade.info),
        ],
        dismissedIds: {'a1'},
      );

      expect(state.totalCriticos, 1);
      expect(state.alertasVisiveis.length, 2);
      expect(state.urgentes.length, 0);
    });

    test('alertasVisiveis filtra todos os dismissados', () {
      final state = AdminNotificacoesState(
        alertas: [alerta(id: 'x'), alerta(id: 'y')],
        dismissedIds: {'x', 'y'},
      );

      expect(state.alertasVisiveis, isEmpty);
      expect(state.totalCriticos, 0);
    });
  });
}
