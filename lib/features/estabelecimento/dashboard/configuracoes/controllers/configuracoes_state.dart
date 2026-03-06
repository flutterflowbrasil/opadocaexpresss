import 'package:flutter/foundation.dart';
import '../models/estabelecimento_model.dart';

@immutable
class ConfiguracoesState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final EstabelecimentoModel? originalEstab;
  final EstabelecimentoModel? editedEstab;
  final Uint8List? newLogoBytes;
  final Uint8List? newBannerBytes;

  const ConfiguracoesState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.originalEstab,
    this.editedEstab,
    this.newLogoBytes,
    this.newBannerBytes,
  });

  bool get hasChanges {
    if (newLogoBytes != null || newBannerBytes != null) return true;
    if (originalEstab == null || editedEstab == null) return false;
    return originalEstab != editedEstab;
  }

  ConfiguracoesState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    EstabelecimentoModel? originalEstab,
    EstabelecimentoModel? editedEstab,
    Uint8List? newLogoBytes,
    Uint8List? newBannerBytes,
    bool clearLogoBytes = false,
    bool clearBannerBytes = false,
  }) {
    return ConfiguracoesState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error, // Se não for passado, limpa o erro
      originalEstab: originalEstab ?? this.originalEstab,
      editedEstab: editedEstab ?? this.editedEstab,
      newLogoBytes: clearLogoBytes ? null : (newLogoBytes ?? this.newLogoBytes),
      newBannerBytes:
          clearBannerBytes ? null : (newBannerBytes ?? this.newBannerBytes),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfiguracoesState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          isSaving == other.isSaving &&
          error == other.error &&
          originalEstab == other.originalEstab &&
          editedEstab == other.editedEstab &&
          newLogoBytes == other.newLogoBytes &&
          newBannerBytes == other.newBannerBytes;

  @override
  int get hashCode =>
      isLoading.hashCode ^
      isSaving.hashCode ^
      error.hashCode ^
      originalEstab.hashCode ^
      editedEstab.hashCode ^
      newLogoBytes.hashCode ^
      newBannerBytes.hashCode;
}
