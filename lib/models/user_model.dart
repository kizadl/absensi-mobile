/// Mirrors the User JSON contract:
/// {id, role, name, nim, username, email, phone, photo}
class UserModel {
  const UserModel({
    required this.id,
    required this.role,
    required this.name,
    required this.username,
    required this.email,
    this.nim,
    this.phone,
    this.photo,
  });

  final int id;
  final String role;
  final String name;
  final String username;
  final String email;
  final String? nim;
  final String? phone;
  final String? photo;

  bool get isMahasiswa => role == 'mahasiswa';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      role: json['role'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      nim: json['nim'] as String?,
      phone: json['phone'] as String?,
      photo: json['photo'] as String?,
    );
  }
}
