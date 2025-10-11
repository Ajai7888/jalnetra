enum UserRole { fieldOfficer, supervisor, analyst }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  User({required this.id, required this.name, required this.email, required this.role});
}