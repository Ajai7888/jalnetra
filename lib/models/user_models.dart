// lib/models/user_models.dart
enum UserRole { fieldOfficer, supervisor, admin, analyst, publicUser }

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  // Fields for registration details
  final String? phone;
  final String? employeeId;
  final String? department;
  final String? designation;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.employeeId,
    this.department,
    this.designation,
  });

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      id: data['id'] ?? '',
      name: data['name'] ?? 'N/A',
      email: data['email'] ?? 'N/A',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == data['role'],
        orElse: () => UserRole.fieldOfficer,
      ),
      phone: data['phone'],
      employeeId: data['employeeId'],
      department: data['department'],
      designation: data['designation'],
    );
  }

  // Converts the user object to a map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role
          .toString()
          .split('.')
          .last, // Stored as a string (e.g., "fieldOfficer")
      'phone': phone,
      'employeeId': employeeId,
      'department': department,
      'designation': designation,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
