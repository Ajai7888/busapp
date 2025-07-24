class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final bool isApproved;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.isApproved,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'isApproved': isApproved,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'faculty',
      isApproved: map['isApproved'] ?? false,
    );
  }
}
