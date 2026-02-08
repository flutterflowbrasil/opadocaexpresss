import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileState {
  final bool isLoading;
  final String? name;
  final String? email;
  final String? error;

  ProfileState({this.isLoading = true, this.name, this.email, this.error});

  ProfileState copyWith({
    bool? isLoading,
    String? name,
    String? email,
    String? error,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      name: name ?? this.name,
      email: email ?? this.email,
      error: error,
    );
  }
}

class ProfileController extends StateNotifier<ProfileState> {
  final AuthRepository _authRepository;
  final SupabaseClient _supabase;

  ProfileController(this._authRepository, this._supabase)
    : super(ProfileState()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(isLoading: false, error: 'Usuário não logado');
        return;
      }

      final data = await _authRepository.getProfile(userId);
      if (data != null) {
        state = state.copyWith(
          isLoading: false,
          name: data['nome'],
          email: data['email'],
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Erro ao carregar perfil',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
      final authRepository = ref.watch(authRepositoryProvider);
      final supabase = Supabase.instance.client;
      return ProfileController(authRepository, supabase);
    });
