class Utente {
  final String id;
  final String email;
  String? nomeCompleto;
  final String? fotoProfiloUrl;
  String? dataNascita;
  String? telefono;

  Utente({
    required this.id,
    required this.email,
    this.nomeCompleto,
    this.fotoProfiloUrl,
    this.dataNascita,
    this.telefono,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'nomeCompleto': nomeCompleto,
      'fotoProfiloUrl': fotoProfiloUrl,
      'dataNascita': dataNascita,
      'telefono': telefono,
    };
  }

  factory Utente.fromJson(String id, Map<String, dynamic> json) {
    return Utente(
      id: id,
      email: json['email'] as String,
      nomeCompleto: json['nomeCompleto'] as String?,
      fotoProfiloUrl: json['fotoProfiloUrl'] as String?,
      dataNascita: json['dataNascita'],
      telefono: json['telefono'],
    );
  }
}
