/// Holds the current token in memory so any service can attach it.
class AuthSession {
  static String? token;

  /// Set by AuthProvider; called when the server answers 401.
  static void Function()? onUnauthorized;
}
