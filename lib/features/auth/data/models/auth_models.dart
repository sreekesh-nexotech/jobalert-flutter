/// Lightweight DTOs the auth feature exchanges with the API. We keep them
/// hand-written (no codegen) since the auth surface is small and the
/// backend's `{access, refresh, user}` envelope is stable.

class AppUser {
  AppUser({
    required this.uid,
    required this.email,
    this.firstName = '',
    this.lastName = '',
    this.username = '',
    this.countryCode = '',
    this.mobileNumber = '',
  });

  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String username;
  final String countryCode;
  final String mobileNumber;

  String get displayName {
    final f = firstName.trim();
    final l = lastName.trim();
    if (f.isEmpty && l.isEmpty) return username.isNotEmpty ? username : email;
    return [f, l].where((s) => s.isNotEmpty).join(' ');
  }

  String get initials {
    final src = displayName.trim().isEmpty ? email : displayName;
    final parts = src.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        uid: json['uid'] as String? ?? '',
        email: json['email'] as String? ?? '',
        firstName: (json['first_name'] as String?) ?? '',
        lastName: (json['last_name'] as String?) ?? '',
        username: (json['username'] as String?) ?? '',
        countryCode: (json['country_code'] as String?) ?? '',
        mobileNumber: (json['mobile_number'] as String?) ?? '',
      );
}

/// Purpose constants matching the backend `OTPCode.Purpose` enum.
enum OtpPurpose {
  signupVerify('signup_verify'),
  passwordReset('password_reset');

  const OtpPurpose(this.wire);
  final String wire;
}

/// Backend gender enum values.
enum Gender {
  male('male', 'Male'),
  female('female', 'Female'),
  other('other', 'Non-binary'),
  preferNot('prefer_not_to_say', 'Prefer not to say');

  const Gender(this.wire, this.label);
  final String wire;
  final String label;

  static Gender fromLabel(String label) =>
      Gender.values.firstWhere((g) => g.label == label, orElse: () => Gender.preferNot);
}
