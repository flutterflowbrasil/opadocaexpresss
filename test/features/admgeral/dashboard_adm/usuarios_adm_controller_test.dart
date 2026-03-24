import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:padoca_express/features/admgeral/dashboard_adm/usuarios/controllers/usuarios_adm_controller.dart';
import 'package:padoca_express/features/admgeral/dashboard_adm/usuarios/controllers/usuarios_adm_state.dart';
import 'package:padoca_express/features/admgeral/dashboard_adm/usuarios/data/usuarios_adm_repository.dart';
import 'package:padoca_express/features/admgeral/dashboard_adm/usuarios/models/usuario_adm_model.dart';

// ── Mock ──────────────────────────────────────────────────────────────────────

class MockUsuariosAdmRepository extends Mock implements UsuariosAdmRepository {}

// ── Fixture helper ────────────────────────────────────────────────────────────

UsuarioAdmModel _u({
  String id = 'u1',
  String nome = 'Joao Silva',
  String email = 'joao@test.com',
  String tipo = 'cliente',
  String status = 'ativo',
  bool emailVerificado = true,
  bool telefoneVerificado = false,
}) {
  return UsuarioAdmModel(
    id: id,
    nome: nome,
    email: email,
    tipoUsuario: tipo,
    status: status,
    emailVerificado: emailVerificado,
    telefoneVerificado: telefoneVerificado,
    createdAt: DateTime(2024, 1, 1),
  );
}

// ── Setup helper ──────────────────────────────────────────────────────────────

/// Cria container, adiciona listener (para evitar autoDispose) e aguarda o fetch.
Future<({ProviderContainer container, void Function() dispose})> _setup(
  MockUsuariosAdmRepository mockRepo,
) async {
  final container = ProviderContainer(
    overrides: [
      usuariosAdmRepositoryProvider.overrideWithValue(mockRepo),
    ],
  );

  // Listener para evitar que autoDispose remova o provider antes do teste terminar
  final sub = container.listen(
    usuariosAdmControllerProvider,
    (_, __) {},
    fireImmediately: true,
  );

  // Esvazia a fila de microtasks e timers para o fetch do construtor completar
  await pumpEventQueue(times: 200);

  return (
    container: container,
    dispose: () {
      sub.close();
      container.dispose();
    },
  );
}

// ── Testes ────────────────────────────────────────────────────────────────────

void main() {
  late MockUsuariosAdmRepository mockRepo;

  setUp(() {
    mockRepo = MockUsuariosAdmRepository();
  });

  group('UsuariosAdmState — isEmpty (unit puro)', () {
    test('isEmpty = true quando sem loading, sem erro e sem usuarios', () {
      const s = UsuariosAdmState(isLoading: false, usuarios: [], errorMessage: null);
      expect(s.isEmpty, isTrue);
    });

    test('isEmpty = false quando esta carregando', () {
      const s = UsuariosAdmState(isLoading: true, usuarios: []);
      expect(s.isEmpty, isFalse);
    });

    test('isEmpty = false quando ha mensagem de erro', () {
      const s = UsuariosAdmState(isLoading: false, usuarios: [], errorMessage: 'erro');
      expect(s.isEmpty, isFalse);
    });
  });

  group('UsuariosAdmController — fetch', () {
    test('deve atualizar estado com usuarios ao fetch bem sucedido', () async {
      final usuarios = [
        _u(id: 'u1', nome: 'Joao'),
        _u(id: 'u2', nome: 'Maria', tipo: 'entregador'),
      ];
      when(() => mockRepo.fetchUsuarios()).thenAnswer((_) async => usuarios);

      final s = await _setup(mockRepo);
      addTearDown(s.dispose);

      final state = s.container.read(usuariosAdmControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.usuarios.length, 2);
      expect(state.errorMessage, isNull);
    });

    test('deve registrar errorMessage quando fetchUsuarios lanca excecao', () async {
      when(() => mockRepo.fetchUsuarios()).thenThrow(Exception('Falha de rede'));

      final s = await _setup(mockRepo);
      addTearDown(s.dispose);

      final state = s.container.read(usuariosAdmControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
    });
  });

  group('UsuariosAdmController — filtros', () {
    test('deve filtrar por tipo', () async {
      final usuarios = [
        _u(id: 'u1', tipo: 'cliente'),
        _u(id: 'u2', tipo: 'entregador'),
        _u(id: 'u3', tipo: 'cliente'),
      ];
      when(() => mockRepo.fetchUsuarios()).thenAnswer((_) async => usuarios);

      final s = await _setup(mockRepo);
      addTearDown(s.dispose);

      s.container.read(usuariosAdmControllerProvider.notifier).setFiltroTipo('cliente');
      final state = s.container.read(usuariosAdmControllerProvider);
      expect(state.filtered.length, 2);
      expect(state.filtered.every((u) => u.tipoUsuario == 'cliente'), isTrue);
    });

    test('deve filtrar por status', () async {
      final usuarios = [
        _u(id: 'u1', status: 'ativo'),
        _u(id: 'u2', status: 'suspenso'),
        _u(id: 'u3', status: 'ativo'),
      ];
      when(() => mockRepo.fetchUsuarios()).thenAnswer((_) async => usuarios);

      final s = await _setup(mockRepo);
      addTearDown(s.dispose);

      s.container.read(usuariosAdmControllerProvider.notifier).setFiltroStatus('suspenso');
      final state = s.container.read(usuariosAdmControllerProvider);
      expect(state.filtered.length, 1);
      expect(state.filtered.first.status, 'suspenso');
    });

    test('deve filtrar por busca de nome', () async {
      final usuarios = [
        _u(id: 'u1', nome: 'Ana Costa'),
        _u(id: 'u2', nome: 'Bruno Lima'),
      ];
      when(() => mockRepo.fetchUsuarios()).thenAnswer((_) async => usuarios);

      final s = await _setup(mockRepo);
      addTearDown(s.dispose);

      s.container.read(usuariosAdmControllerProvider.notifier).setBusca('ana');
      final state = s.container.read(usuariosAdmControllerProvider);
      expect(state.filtered.length, 1);
      expect(state.filtered.first.nome, 'Ana Costa');
    });

    test('deve retornar lista vazia quando busca nao encontra resultados', () async {
      final usuarios = [_u(id: 'u1', nome: 'Joao')];
      when(() => mockRepo.fetchUsuarios()).thenAnswer((_) async => usuarios);

      final s = await _setup(mockRepo);
      addTearDown(s.dispose);

      s.container.read(usuariosAdmControllerProvider.notifier).setBusca('xyzxyz');
      final state = s.container.read(usuariosAdmControllerProvider);
      expect(state.filtered, isEmpty);
    });
  });

  group('UsuariosAdmController — KPIs', () {
    test('deve calcular KPIs corretamente', () async {
      final usuarios = [
        _u(id: 'u1', tipo: 'cliente',         status: 'ativo'),
        _u(id: 'u2', tipo: 'cliente',         status: 'suspenso'),
        _u(id: 'u3', tipo: 'entregador',      status: 'ativo'),
        _u(id: 'u4', tipo: 'estabelecimento', status: 'ativo'),
        _u(id: 'u5', tipo: 'admin',            status: 'ativo'),
      ];
      when(() => mockRepo.fetchUsuarios()).thenAnswer((_) async => usuarios);

      final s = await _setup(mockRepo);
      addTearDown(s.dispose);

      final state = s.container.read(usuariosAdmControllerProvider);
      expect(state.total,            5);
      expect(state.clientes,         2);
      expect(state.entregadores,     1);
      expect(state.estabelecimentos, 1);
      expect(state.admins,           1);
      expect(state.ativos,           4);
    });

    test('deve contar nao verificados corretamente', () async {
      final usuarios = [
        _u(id: 'u1', emailVerificado: true),
        _u(id: 'u2', emailVerificado: false),
        _u(id: 'u3', emailVerificado: false),
      ];
      when(() => mockRepo.fetchUsuarios()).thenAnswer((_) async => usuarios);

      final s = await _setup(mockRepo);
      addTearDown(s.dispose);

      final state = s.container.read(usuariosAdmControllerProvider);
      expect(state.naoVerificados, 2);
    });
  });

  group('UsuariosAdmController — executarAcao', () {
    test('deve atualizar status ao suspender com sucesso', () async {
      final usuarios = [_u(id: 'u1', status: 'ativo')];
      when(() => mockRepo.fetchUsuarios()).thenAnswer((_) async => usuarios);
      when(() => mockRepo.atualizarStatus('u1', 'suspenso')).thenAnswer((_) async {});

      final s = await _setup(mockRepo);
      addTearDown(s.dispose);

      await s.container.read(usuariosAdmControllerProvider.notifier).executarAcao('suspender', 'u1');
      await pumpEventQueue();

      final state = s.container.read(usuariosAdmControllerProvider);
      expect(state.usuarios.first.status, 'suspenso');
      expect(state.errorMessage, isNull);
    });

    test('deve reverter status se atualizarStatus lancar excecao', () async {
      final usuarios = [_u(id: 'u1', status: 'ativo')];
      when(() => mockRepo.fetchUsuarios()).thenAnswer((_) async => usuarios);
      when(() => mockRepo.atualizarStatus('u1', 'suspenso')).thenThrow(Exception('Erro'));

      final s = await _setup(mockRepo);
      addTearDown(s.dispose);

      await s.container.read(usuariosAdmControllerProvider.notifier).executarAcao('suspender', 'u1');
      await pumpEventQueue();

      final state = s.container.read(usuariosAdmControllerProvider);
      expect(state.usuarios.first.status, 'ativo'); // rollback
      expect(state.errorMessage, isNotNull);
    });

    test('nao deve suspender usuario admin', () async {
      final usuarios = [_u(id: 'admin1', tipo: 'admin', status: 'ativo')];
      when(() => mockRepo.fetchUsuarios()).thenAnswer((_) async => usuarios);

      final s = await _setup(mockRepo);
      addTearDown(s.dispose);

      await s.container.read(usuariosAdmControllerProvider.notifier).executarAcao('suspender', 'admin1');

      verifyNever(() => mockRepo.atualizarStatus(any(), any()));
      final state = s.container.read(usuariosAdmControllerProvider);
      expect(state.usuarios.first.status, 'ativo');
    });
  });
}
