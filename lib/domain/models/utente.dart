class Utente {
  final String id;
  final String email;
  final String? nomeCompleto;
  final String? fotoProfiloUrl;

  const Utente({
    required this.id,
    required this.email,
    this.nomeCompleto,
    this.fotoProfiloUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'nomeCompleto': nomeCompleto,
      'fotoProfiloUrl': fotoProfiloUrl,
    };
  }

  factory Utente.fromJson(String id, Map<String, dynamic> json) {
    return Utente(
      id: id,
      email: json['email'] as String,
      nomeCompleto: json['nomeCompleto'] as String?,
      fotoProfiloUrl: json['fotoProfiloUrl'] as String?,
    );
  }
}