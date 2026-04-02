class Attivita{
  final String id;   //id univoco dell'attività
  final String viaggioId;   //collega l'attività al viaggio a cui appartiene
  final String titolo;   //titolo dell'attività
  bool completata;   //indica se l'attività è stata completata o meno

  Attivita({
    required this.id,
    required this.viaggioId,
    required this.titolo,
    this.completata = false,
  });
}