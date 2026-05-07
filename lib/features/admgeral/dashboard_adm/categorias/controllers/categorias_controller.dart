import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/categoria_model.dart';
import '../repositories/categorias_repository.dart';

class CategoriasState {
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final List<CategoriaModel> categorias;

  const CategoriasState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.categorias = const [],
  });

  CategoriasState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    List<CategoriaModel>? categorias,
  }) {
    return CategoriasState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error, // Se for null no copyWith, remove o erro, a menos que passado algo ou precise de um ValueWrapper
      categorias: categorias ?? this.categorias,
    );
  }
}

final categoriasRepositoryProvider = Provider<CategoriasRepository>((ref) {
  return CategoriasRepository(Supabase.instance.client);
});

final categoriasControllerProvider =
    StateNotifierProvider.autoDispose<CategoriasController, CategoriasState>((ref) {
  final repository = ref.watch(categoriasRepositoryProvider);
  return CategoriasController(repository);
});

class CategoriasController extends StateNotifier<CategoriasState> {
  final CategoriasRepository _repository;

  CategoriasController(this._repository) : super(const CategoriasState()) {
    carregarCategorias();
  }

  Future<void> carregarCategorias() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final lista = await _repository.getCategorias();
      state = state.copyWith(isLoading: false, categorias: lista);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erro ao carregar categorias: \$e');
    }
  }

  String gerarSlug(String nome) {
    var s = nome.toLowerCase();
    s = s.replaceAll(RegExp(r'[áàâãä]'), 'a');
    s = s.replaceAll(RegExp(r'[éèêë]'), 'e');
    s = s.replaceAll(RegExp(r'[íìîï]'), 'i');
    s = s.replaceAll(RegExp(r'[óòôõö]'), 'o');
    s = s.replaceAll(RegExp(r'[úùûü]'), 'u');
    s = s.replaceAll(RegExp(r'[ç]'), 'c');
    s = s.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    s = s.replaceAll(RegExp(r'\s+'), '-');
    return s;
  }

  Future<bool> salvarCategoria({
    String? id,
    required String nome,
    required String slug,
    required int ordemExibicao,
    required bool ativa,
    File? imagemFile,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      // Validar se a ordem já existe em outra categoria
      final ordemEmUso = state.categorias.any(
        (c) => c.ordemExibicao == ordemExibicao && c.id != id,
      );
      if (ordemEmUso) {
        state = state.copyWith(
          isSubmitting: false,
          error: 'A ordem de exibição $ordemExibicao já está em uso.',
        );
        return false;
      }

      String? imagemUrl;
      
      // Processar e subir imagem se houver
      if (imagemFile != null) {
        // Redimensionar para 512x512 no modo contain com fundo branco
        final bytes = await imagemFile.readAsBytes();
        final image = img.decodeImage(bytes);
        
        if (image != null) {
          // Criar canvas branco 512x512
          final canvas = img.Image(width: 512, height: 512);
          img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
          
          // Calcular escala para manter proporção
          final double ratioX = 512 / image.width;
          final double ratioY = 512 / image.height;
          final double ratio = ratioX < ratioY ? ratioX : ratioY;
          
          final int newW = (image.width * ratio).round();
          final int newH = (image.height * ratio).round();
          
          final resized = img.copyResize(image, width: newW, height: newH);
          
          // Centralizar
          final dstX = (512 - newW) ~/ 2;
          final dstY = (512 - newH) ~/ 2;
          
          img.compositeImage(canvas, resized, dstX: dstX, dstY: dstY);
          
          final finalBytes = img.encodeJpg(canvas, quality: 85);
          
          // Salvar temporariamente para upload
          final tempDir = Directory.systemTemp;
          final tempFile = File('\${tempDir.path}/cat_temp_\${DateTime.now().millisecondsSinceEpoch}.jpg');
          await tempFile.writeAsBytes(finalBytes);
          
          // ID fictício para upload novo. Se tiver ID, usa ele. Se não, gera um temporario.
          // Como o ID é gerado no DB, precisaremos criar primeiro e subir depois, ou subir com um UUID gerado.
          // Ajuste: vamos gerar UUID no app se for novo, ou subir depois.
          // Aqui, geramos a imagemFile tratada e passamos para a próxima etapa.
          imagemFile = tempFile;
        }
      }

      CategoriaModel categoria;

      if (id == null) {
        // Create
        final data = {
          'nome': nome,
          'slug': slug,
          'ordem_exibicao': ordemExibicao,
          'ativa': ativa,
        };
        categoria = await _repository.createCategoria(data);
        
        // Se tem imagem, faz upload agora que temos o ID
        if (imagemFile != null) {
          imagemUrl = await _repository.uploadImagem(categoria.id, imagemFile);
          categoria = await _repository.updateCategoria(categoria.id, {'imagem_url': imagemUrl});
        }
      } else {
        // Update
        if (imagemFile != null) {
          imagemUrl = await _repository.uploadImagem(id, imagemFile);
        }
        
        final data = {
          'nome': nome,
          'slug': slug,
          'ordem_exibicao': ordemExibicao,
          'ativa': ativa,
          if (imagemUrl != null) 'imagem_url': imagemUrl,
        };
        categoria = await _repository.updateCategoria(id, data);
      }

      await carregarCategorias(); // Recarrega para obter lista atualizada
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: 'Erro ao salvar categoria: \$e');
      return false;
    }
  }

  Future<void> toggleAtiva(CategoriaModel categoria) async {
    try {
      await _repository.updateCategoria(categoria.id, {'ativa': !categoria.ativa});
      await carregarCategorias();
    } catch (e) {
      state = state.copyWith(error: 'Erro ao alterar status: \$e');
    }
  }

  void limparErro() {
    state = state.copyWith(error: null);
  }
}
