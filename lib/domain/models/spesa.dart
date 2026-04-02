class Spesa{
  final String id;   //id univoco della spesa
  final String viaggioId;   //collega la spesa al viaggio a cui appartiene
  final String titolo;   //titolo della spesa
  final double importo;   //importo che verrà estratto da un'AI
  final DateTime data;   //data estratta da un'AI
  final String? immagineScontrino;   //per la foto dello scontrino
  final bool esportata;   //diventa true dopo aver generato il report PDF

  Spesa({
    required this.id,
    required this.viaggioId,
    required this.titolo,
    required this.importo,
    required this.data,
    this.immagineScontrino,
    this.esportata = false,
  });
}