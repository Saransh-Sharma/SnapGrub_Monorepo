enum AuthStatus {
  checking,
  configurationMissing,
  signedOut,
  passwordRecovery,
  signedIn,
}

class AuthState {
  const AuthState({
    required this.status,
    this.userId,
    this.message,
  });

  const AuthState.checking() : this(status: AuthStatus.checking);

  const AuthState.configurationMissing()
      : this(
          status: AuthStatus.configurationMissing,
          message: 'Supabase URL and anon key are required for auth.',
        );

  const AuthState.signedOut() : this(status: AuthStatus.signedOut);

  const AuthState.passwordRecovery(String userId)
      : this(status: AuthStatus.passwordRecovery, userId: userId);

  const AuthState.signedIn(String userId)
      : this(status: AuthStatus.signedIn, userId: userId);

  final AuthStatus status;
  final String? userId;
  final String? message;

  bool get isSignedIn => status == AuthStatus.signedIn && userId != null;
}
