class AppUser {
  final String uid;
  final String email;
  final String name;
  final String role; // 'owner', 'manager', 'kasir'
  final String storeId;
  final String storeName;
  final String subscriptionStatus;
  final DateTime? trialExpiresAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.storeId,
    required this.storeName,
    this.subscriptionStatus = 'active',
    this.trialExpiresAt,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String documentId) {
    return AppUser(
      uid: documentId,
      email: data['email'] ?? '',
      name: data['name'] ?? 'Kasir',
      role: data['role'] ?? 'kasir',
      storeId: data['store_id'] ?? 'bhayangkari_pusat',
      storeName: data['store_name'] ?? 'Bhayangkari Pusat',
      subscriptionStatus: data['subscription_status'] ?? 'active',
      trialExpiresAt: data['trial_expires_at'] != null ? DateTime.parse(data['trial_expires_at']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'store_id': storeId,
      'store_name': storeName,
      'subscription_status': subscriptionStatus,
      'trial_expires_at': trialExpiresAt?.toIso8601String(),
    };
  }

  bool get isOwner => role == 'owner';
  bool get isManager => role == 'manager';
  bool get isKasir => role == 'kasir';

  bool get isTrial => subscriptionStatus == 'trial';
  bool get isTrialExpired => isTrial && trialExpiresAt != null && DateTime.now().isAfter(trialExpiresAt!);
  bool get isLocked => isTrialExpired;
}
