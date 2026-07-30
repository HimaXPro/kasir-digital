class AppUser {
  final String uid;
  final String email;
  final String name;
  final String role; // 'owner', 'manager', 'kasir'
  final String provinceId;
  final String cityId;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.provinceId,
    required this.cityId,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String documentId) {
    return AppUser(
      uid: documentId,
      email: data['email'] ?? '',
      name: data['name'] ?? 'Kasir',
      role: data['role'] ?? 'kasir',
      provinceId: data['province_id'] ?? 'jatim',
      cityId: data['city_id'] ?? 'malang',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'province_id': provinceId,
      'city_id': cityId,
    };
  }

  bool get isOwner => role == 'owner';
  bool get isManager => role == 'manager';
  bool get isKasir => role == 'kasir';
}
