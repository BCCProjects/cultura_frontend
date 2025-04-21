class User {
  final int id;
  final String username;
  final String? email;

  User({required this.id, required this.username, this.email});

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'],
    username: j['username'],
    email: j['email'],
  );
}
