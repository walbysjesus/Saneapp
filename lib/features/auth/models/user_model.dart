// Modelo de usuario profesional para SaneApp/// ─────────────────────────────
// ✔ Centraliza la información del usuario
// ✔ Listo para integración con Firebase y lógica avanzada

class UserModel {
  final String uid;
  final String email;
  final String? fullName;
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.email,
    this.fullName,
    this.photoUrl,
  });

  // Factory para crear desde un mapa (útil para Firebase)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'],
      photoUrl: map['photoUrl'],
    );
  }

  // Convertir a mapa (útil para guardar en Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'photoUrl': photoUrl,
    };
  }

  // Copia segura para updates
  UserModel copyWith({String? email, String? fullName, String? photoUrl}) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
