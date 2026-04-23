import 'package:cloud_firestore/cloud_firestore.dart';

class Viaggio {
  final String id;
  final String userId; // chi ha creato il viaggio
  final String nome;
  final String destinazione;
  final DateTime dataInizio;
  final DateTime dataFine;
  final bool isCompletato;
  final String? immagineCopertinaUrl; // opzionale, per le card

  const Viaggio({
    required this.id,
    required this.userId,
    required this.nome,
    required this.destinazione,
    required this.dataInizio,
    required this.dataFine,
    this.isCompletato = false,
    this.immagineCopertinaUrl,
  });

  // Quanti giorni mancano alla partenza (negativo = già partito)
  int get giorniAllaPartenza {
    final oggi = DateTime.now();
    final partenza =
        DateTime(dataInizio.year, dataInizio.month, dataInizio.day);
    final todayNorm = DateTime(oggi.year, oggi.month, oggi.day);
    return partenza.difference(todayNorm).inDays;
  }

  // Il viaggio è attualmente in corso?
  bool get isInCorso {
    final oggi = DateTime.now();
    return oggi.isAfter(dataInizio) && oggi.isBefore(dataFine);
  }

  // Serializzazione verso Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nome': nome,
      'destinazione': destinazione,
      'dataInizio': Timestamp.fromDate(dataInizio),
      'dataFine': Timestamp.fromDate(dataFine),
      'isCompletato': isCompletato,
      'immagineCopertinaUrl': immagineCopertinaUrl,
    };
  }

  // Deserializzazione da Firestore
  factory Viaggio.fromJson(String id, Map<String, dynamic> json) {
    return Viaggio(
      id: id,
      userId: json['userId'] as String,
      nome: json['nome'] as String,
      destinazione: json['destinazione'] as String,
      dataInizio: (json['dataInizio'] as Timestamp).toDate(),
      dataFine: (json['dataFine'] as Timestamp).toDate(),
      isCompletato: json['isCompletato'] as bool? ?? false,
      immagineCopertinaUrl: json['immagineCopertinaUrl'] as String?,
    );
  }

  // Crea una copia modificata (utile per update parziali)
  Viaggio copyWith({
    String? nome,
    String? destinazione,
    DateTime? dataInizio,
    DateTime? dataFine,
    bool? isCompletato,
    String? immagineCopertinaUrl,
  }) {
    return Viaggio(
      id: id,
      userId: userId,
      nome: nome ?? this.nome,
      destinazione: destinazione ?? this.destinazione,
      dataInizio: dataInizio ?? this.dataInizio,
      dataFine: dataFine ?? this.dataFine,
      isCompletato: isCompletato ?? this.isCompletato,
      immagineCopertinaUrl: immagineCopertinaUrl ?? this.immagineCopertinaUrl,
    );
  }
}
