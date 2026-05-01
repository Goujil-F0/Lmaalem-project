class UserModel {
  final String uid;
  final String nom;
  final String email;
  final String role; // 'client' ou 'artisan'
  final String? photoUrl;
  final String? cinUrl;

  UserModel({
    required this.uid,
    required this.nom,
    required this.email,
    required this.role,
    this.photoUrl,
    this.cinUrl,
  });

  // Convertir en Map pour envoyer à Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nom': nom,
      'email': email,
      'role': role,
      'photoUrl': photoUrl,
      'cinUrl': cinUrl,
    };
  }

  // Créer un UserModel depuis une réponse JSON
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      nom: map['nom'],
      email: map['email'],
      role: map['role'],
      photoUrl: map['photoUrl'],
      cinUrl: map['cinUrl'],
    );
  }
}