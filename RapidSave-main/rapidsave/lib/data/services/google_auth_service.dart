import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';

class GoogleAuthService {
  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final _dio = DioClient().dio;

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) return null;

      final res = await _dio.post(
        '/auth/google',
        data: {
          'id_token': idToken,
          'name': account.displayName ?? '',
          'email': account.email,
        },
      );

      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? Exception('Google sign in failed');
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
