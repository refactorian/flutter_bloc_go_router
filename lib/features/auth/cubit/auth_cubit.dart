import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/storage/local_storage_service.dart';

enum AuthStatus { authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? username;
  final String? token;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.username,
    this.token,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({AuthStatus? status, String? username, String? token}) {
    return AuthState(
      status: status ?? this.status,
      username: username ?? this.username,
      token: token ?? this.token,
    );
  }

  @override
  List<Object?> get props => [status, username, token];
}

/// Cubit managing persistent authentication state and route protection.
class AuthCubit extends Cubit<AuthState> {
  final LocalStorageService? storageService;

  AuthCubit({this.storageService}) : super(const AuthState()) {
    _loadPersistedSession();
  }

  void _loadPersistedSession() {
    if (storageService == null) return;
    final username = storageService!.getAuthUsername();
    final token = storageService!.getAuthToken();
    if (username != null && username.isNotEmpty) {
      emit(
        AuthState(
          status: AuthStatus.authenticated,
          username: username,
          token: token,
        ),
      );
    }
  }

  Future<void> login(
    String username, {
    String? token = 'mock_jwt_token_123',
  }) async {
    await storageService?.saveAuthSession(username: username, token: token);
    if (!isClosed) {
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          username: username,
          token: token,
        ),
      );
    }
  }

  Future<void> logout() async {
    await storageService?.clearAuthSession();
    if (!isClosed) {
      emit(
        const AuthState(
          status: AuthStatus.unauthenticated,
          username: null,
          token: null,
        ),
      );
    }
  }
}
