import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:furqan/core/di/get_it_service.dart';
import 'package:furqan/core/services/prefs.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  final supabase = sl<SupabaseClient>();
  final prefs = sl<Prefs>();

  Future<void> googleSignIn() async {
    try {
      emit(GoogleAuthLoading());

      final googleSignIn = kIsWeb
          ? GoogleSignIn(
              clientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
            )
          : GoogleSignIn(
              // Android client ID from Google Cloud Console
              serverClientId: const String.fromEnvironment(
                'GOOGLE_ANDROID_CLIENT_ID',
              ),
            );

      log('Starting Google Sign In...');
      final googleUser = await googleSignIn.signIn().catchError((error) {
        log('Google Sign In Error: $error');
        throw Exception('Failed to start Google Sign In: $error');
      });

      if (googleUser == null) {
        log('Google Sign In cancelled by user');
        emit(const GoogleAuthError("Sign in cancelled by user"));
        return;
      }

      log('Getting Google Auth tokens...');
      final googleAuth = await googleUser.authentication.catchError((error) {
        log('Google Auth Error: $error');
        throw Exception('Failed to get Google authentication: $error');
      });

      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        log('Missing access token');
        emit(const GoogleAuthError("Missing access token"));
        return;
      }

      log('Signing in to Supabase with Google token...');
      final authResponse = await supabase.auth
          .signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken!,
            accessToken: accessToken,
          )
          .catchError((error) {
            log('Supabase Auth Error: $error');
            throw Exception('Failed to sign in to Supabase: $error');
          });

      final user = authResponse.user;
      if (user != null) {
        log('Successfully signed in user: ${user.email}');
        await prefs.saveUser(
          name: user.userMetadata?['name'] ?? '',
          email: user.email ?? '',
          photo: user.userMetadata?['picture'] ?? '',
          userId: user.id,
        );
        // await addDefaultChallengesAndAchievements();
      }

      emit(GoogleAuthSuccess(authResponse: authResponse));
    } catch (e, stackTrace) {
      log('Google Sign In Failed', error: e, stackTrace: stackTrace);
      emit(
        GoogleAuthError(
          'Sign in failed: ${e.toString().replaceAll('Exception:', '')}',
        ),
      );
    }
  }

  Future<void> signInWithFacebook() async {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: kIsWeb ? null : 'io.supabase.flutter://callback',
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  Future<void> signInWithGithub() async {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.github,
      redirectTo: kIsWeb ? null : 'my.scheme://my-host',
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  Future<void> signUpNewUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      emit(SignUpLoading());
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {"name": name},
        emailRedirectTo: "io.supabase.flutter://login-callback",
      );
      log(res.toString());
      final user = res.user;
      if (user != null) {
        log('New user signed up: ${user.email}');
        try {
          await supabase.from('users').insert({
            'id': user.id,
            'email': user.email,
            'name': name,
            'profile_image': null,
          });

          log("Saved");
        } on Exception catch (e) {
          log('Error inserting user into database: ${e.toString()}');
        }
        // await addDefaultChallengesAndAchievements();
      }
      emit(SignUpSuccess(authResponse: res));
    } on AuthApiException catch (e) {
      log(e.toString());
      emit(SignUpError(e.message));
    } catch (e) {
      final message = "error while signing up ${e.toString()}";
      log(message);
      emit(SignUpError(message));
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      emit(SignInLoading());
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user != null) {
        await prefs.saveUser(
          name: res.user!.userMetadata?['name'] ?? '',
          email: res.user!.email ?? '',
          photo: res.user!.userMetadata?['photo'] ?? '',
          userId: res.user!.id,
        );
        emit(SignInSuccess(authResponse: res));
      }
    } on AuthApiException catch (e) {
      log(e.toString());
      emit(SignInError(e.message));
    }
  }

  Future<void> signInWithEmailOtp({required String email}) async {
    try {
      emit(SignInOtpLoading());
      await supabase.auth.signInWithOtp(email: email);
      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(const SnackBar(content: Text("OTP sent!")));
      emit(SignInOtpSuccess());
    } on Exception catch (e) {
      emit(SignInOtpError(e.toString()));
    }
  }

  // Future<void> verifyOtp(String email, String otp) async {
  //   try {
  //     await supabase.auth.verifyOTP(
  //       email: email,
  //       token: otp,
  //       type: OtpType.email,
  //     );
  //     emit(SignInSuccess(authResponse: AuthResponse()));
  //   } on Exception catch (e) {
  //     emit(SignInError(e.toString()));
  //   }
  // }

  Future<void> resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutter://reset-password',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent to your email!'),
          backgroundColor: Colors.green,
        ),
      );
    } on AuthApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    await prefs.clear();
  }

  Future<bool> checkSession() async {
    final session = supabase.auth.currentSession;
    final isLoggedIn = await prefs.isLoggedIn();
    return session != null && isLoggedIn;
  }
}
