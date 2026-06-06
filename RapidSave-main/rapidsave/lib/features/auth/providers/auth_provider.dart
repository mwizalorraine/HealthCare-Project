import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/local/cache_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/fcm_service.dart';
import '../../../data/services/google_auth_service.dart';
import '../../../data/services/socket_service.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) => AuthState(
    user: clearUser ? null : user ?? this.user,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
  );
}

// ── Auth notifier ─────────────────────────────────────────────────────────────
class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;
  late final GoogleAuthService _googleAuthService;
  late final CacheService _cache;
  late final DioClient _dioClient;

  @override
  AuthState build() {
    _authService = AuthService();
    _googleAuthService = GoogleAuthService();
    _cache = CacheService();
    _dioClient = DioClient();

    // Automatically log out when any API call receives a 401.
    final sub = _dioClient.onUnauthorized.listen((_) => _handleUnauthorized());
    ref.onDispose(sub.cancel);

    _loadCachedUser();
    return const AuthState();
  }

  Future<void> _handleUnauthorized() async {
    if (!state.isAuthenticated) return;
    await logout();
  }

  Future<void> _loadCachedUser() async {
    try {
      final userJson = await _cache.get('settings_box', 'current_user');
      final token = await _dioClient.getToken();
      if (userJson != null && token != null) {
        final user = UserModel.fromJson(
          jsonDecode(userJson as String) as Map<String, dynamic>,
        );
        state = state.copyWith(user: user);
        unawaited(_initPostAuthServices());
      }
    } catch (_) {}
  }

  // Called after any successful authentication to start FCM and socket.
  // Fire-and-forget: callers don't await this so the UI is never blocked.
  Future<void> _initPostAuthServices({bool freshLogin = false}) async {
    await FcmService().init();
    // On a fresh login the old token may have been deleted on logout; force
    // a new token to be generated and sent to the backend.
    if (freshLogin) {
      await FcmService().refreshAndRegisterToken();
    }
    await SocketService().connect();
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.register(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
      );
      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return e.toString();
    }
  }

  Future<String?> verifyEmail({
    required String email,
    required String code,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _authService.verifyEmail(email: email, code: code);
      final data = res['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _dioClient.setToken(token);
      await _cache.put(
        'settings_box',
        'current_user',
        jsonEncode(user.toJson()),
      );
      state = state.copyWith(isLoading: false, user: user);
      unawaited(_initPostAuthServices(freshLogin: true));
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return e.toString();
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _authService.login(email: email, password: password);
      final data = res['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _dioClient.setToken(token);
      await _cache.put(
        'settings_box',
        'current_user',
        jsonEncode(user.toJson()),
      );
      state = state.copyWith(isLoading: false, user: user);
      unawaited(_initPostAuthServices(freshLogin: true));
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return e.toString();
    }
  }

  Future<String?> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _googleAuthService.signInWithGoogle();
      if (res == null) {
        state = state.copyWith(isLoading: false);
        return null;
      }
      final data = res['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _dioClient.setToken(token);
      await _cache.put(
        'settings_box',
        'current_user',
        jsonEncode(user.toJson()),
      );
      state = state.copyWith(isLoading: false, user: user);
      unawaited(_initPostAuthServices(freshLogin: true));
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return e.toString();
    }
  }

  Future<void> resendVerificationCode(String email) async {
    try {
      await _authService.resendVerificationCode(email);
    } catch (_) {}
  }

  Future<String?> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.forgotPassword(email);
      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return e.toString();
    }
  }

  Future<String?> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.resetPassword(token: token, newPassword: newPassword);
      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return e.toString();
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return e.toString();
    }
  }

  Future<String?> updateProfile({String? name, String? phone}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _authService.updateProfile(name: name, phone: phone);
      await _cache.put('settings_box', 'current_user', jsonEncode(updated.toJson()));
      state = state.copyWith(isLoading: false, user: updated);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return e.toString();
    }
  }

  Future<void> logout() async {
    await FcmService().deleteToken();
    SocketService().disconnect();
    await _dioClient.clearToken();
    await _cache.clearBox('settings_box');
    await _googleAuthService.signOut();
    state = const AuthState();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
