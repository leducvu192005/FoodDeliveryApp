class AuthSession {
  final String accessToken;
  final String role;
  final String userId;

  AuthSession({
    required this.accessToken,
    required this.role,
    required this.userId,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
    );
  }
}
