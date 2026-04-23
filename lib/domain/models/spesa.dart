import 'package:cloud_firestore/cloud_firestore.dart';

class Spesa {
  final String id;
  final String viaggioId;
  final String descrizione;
  final double importo;
  final String categoria;   // es. "Trasporto", "Pasto", "Alloggio"
  final DateTime data;
  final String? immagineScontrinoUrl;

  const Spesa({
    required this.id,
    required this.viaggioId,
    required this.descrizione,
    required this.importo,
    required this.categoria,
    required this.data,
    this.immagineScontrinoUrl,
  });

  // Importo formattato in euro, es. "€ 12,50"
  String get importoFormattato {
    return '€ ${importo.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'viaggioId': viaggioId,
      'descrizione': descrizione,
      'importo': importo,
      'categoria': categoria,
      'data': Timestamp.fromDate(data),
      'immagineScontrinoUrl': immagineScontrinoUrl,
    };
  }

  factory Spesa.fromJson(String id, Map<String, dynamic> json) {
    return Spesa(
      id: id,
      viaggioId: json['viaggioId'] as String,
      descrizione: json['descrizione'] as String,
      importo: (json['importo'] as num).toDouble(),
      categoria: json['categoria'] as String,
      data: (json['data'] as Timestamp).toDate(),
      immagineScontrinoUrl: json['immagineScontrinoUrl'] as String?,
    );
  }

  Spesa copyWith({
    String? descrizione,
    double? importo,
    String? categoria,
    DateTime? data,
    String? immagineScontrinoUrl,
  }) {
    return Spesa(
      id: id,
      viaggioId: viaggioId,
      descrizione: descrizione ?? this.descrizione,
      importo: importo ?? this.importo,
      categoria: categoria ?? this.categoria,
      data: data ?? this.data,
      immagineScontrinoUrl: immagineScontrinoUrl ?? this.immagineScontrinoUrl,
    );
  }
}