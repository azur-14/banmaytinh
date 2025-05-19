class EmailCheckResult {
  final bool exists;
  final bool isEmailVerified;

  EmailCheckResult({
    required this.exists,
    required this.isEmailVerified,
  });

  factory EmailCheckResult.fromJson(Map<String, dynamic> json) {
    return EmailCheckResult(
      exists: json['exists'] as bool,
      isEmailVerified: json['isEmailVerified'] as bool,
    );
  }
}
