class Utente{
  final String id;   //id univoco dell'utente
  final String nome;   //nome visualizzato dell'utente
  final String email;   //email per l'autenticazione dell'utente
  final String password;   //password per l'autenticazione dell'utente
  final String? immagineProfilo;   //per la foto profilo personalizzata

  Utente({
    required this.id,
    required this.nome,
    required this.email,
    required this.password,
    this.immagineProfilo,
  });
}