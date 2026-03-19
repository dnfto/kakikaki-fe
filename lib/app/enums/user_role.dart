enum UserRole {
  free,
  premium,
  admin;

  static UserRole fromDatabase(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase();
    switch (normalized) {
      case 'premium':
        return UserRole.premium;
      case 'admin':
        return UserRole.admin;
      case 'free':
      default:
        return UserRole.free;
    }
  }

  bool get isPremium => this == UserRole.premium || this == UserRole.admin;
}
