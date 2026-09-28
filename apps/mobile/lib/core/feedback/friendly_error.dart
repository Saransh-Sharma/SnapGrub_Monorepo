import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:snapgrub/core/network/snapgrub_api_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A human explanation of an error.
class FriendlyError {
  const FriendlyError({
    required this.title,
    required this.message,
    this.retryable = true,
    this.offline = false,
  });

  final String title;
  final String message;
  final bool retryable;
  final bool offline;
}

/// Maps any thrown object to short, specific copy (see docs/09-design/voice.md). Never surfaces stack traces,
/// class names or raw backend codes.
FriendlyError friendlyError(Object error) {
  if (error is SnapGrubApiException) {
    if (error.status == 401 || error.status == 403) {
      return const FriendlyError(
        title: 'Sign in again',
        message: 'Your session expired.',
        retryable: false,
      );
    }
    return FriendlyError(
      title: error.retryable ? 'That didn’t work' : 'Can’t do that right now',
      message: error.userMessage.trim().isEmpty
          ? 'Something went wrong on our end. Your data is safe.'
          : error.userMessage,
      retryable: error.retryable,
    );
  }
  if (error is SocketException ||
      error is http.ClientException ||
      error is TimeoutException ||
      _looksOffline(error)) {
    return const FriendlyError(
      title: 'You’re offline',
      message: 'Anything you log is saved and will sync later.',
      offline: true,
    );
  }
  if (error is AuthException) {
    return FriendlyError(
      title: 'Couldn’t sign in',
      message: authErrorMessage(error),
      retryable: false,
    );
  }
  if (error is PostgrestException || error is StorageException) {
    return const FriendlyError(
      title: 'Didn’t sync',
      message: 'Saved on your phone. We’ll retry soon.',
    );
  }
  if (error is PlatformException) {
    final code = error.code.toLowerCase();
    if (code.contains('permission') || code.contains('denied')) {
      return const FriendlyError(
        title: 'Access needed',
        message: 'Turn it on in Settings.',
        retryable: false,
      );
    }
    return const FriendlyError(
      title: 'Not available',
      message: 'This isn’t working right now. Try again.',
    );
  }
  if (error is ArgumentError) {
    // Validation errors are already written for people.
    final message = error.message?.toString() ?? '';
    return FriendlyError(
      title: 'Check your entry',
      message: message.isEmpty ? 'Some details need fixing.' : message,
      retryable: false,
    );
  }
  if (error is StateError && error.message.contains('not configured')) {
    return const FriendlyError(
      title: 'Not connected',
      message: 'This build can’t reach SnapGrub.',
      retryable: false,
    );
  }
  return const FriendlyError(
    title: 'Something went wrong',
    message: 'Nothing was lost. Try again.',
  );
}

/// Short, specific auth copy. Distinguishes the common cases so users know
/// what to fix instead of a single generic failure.
String authErrorMessage(Object error) {
  final text = (error is AuthException ? '${error.code} ${error.message}' : '$error')
      .toLowerCase();
  if (text.contains('invalid_credentials') ||
      text.contains('invalid login') ||
      text.contains('invalid credentials')) {
    return 'Wrong email or password. Try again or use a code.';
  }
  if (text.contains('otp_expired') ||
      text.contains('expired') ||
      text.contains('token has expired')) {
    return 'Code expired. Get a new one.';
  }
  if (text.contains('otp') || text.contains('token') && text.contains('invalid')) {
    return 'Wrong code. Check your latest email.';
  }
  if (text.contains('user_already_exists') || text.contains('already registered')) {
    return 'You already have an account. Sign in instead.';
  }
  if (text.contains('weak_password') || text.contains('password should')) {
    return 'Use at least 8 characters.';
  }
  if (text.contains('rate') || text.contains('too many') || text.contains('429')) {
    return 'Too many tries. Wait a minute and try again.';
  }
  if (text.contains('email_not_confirmed') || text.contains('not confirmed')) {
    return 'Confirm your email first. Check your inbox.';
  }
  if (_looksOffline(error)) {
    return 'You’re offline. Connect and try again.';
  }
  return 'Couldn’t sign in. Check your details and try again.';
}

bool _looksOffline(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('socketexception') ||
      text.contains('failed host lookup') ||
      text.contains('network is unreachable') ||
      text.contains('connection refused') ||
      text.contains('connection closed') ||
      text.contains('offline');
}
