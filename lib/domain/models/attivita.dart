class Attivita {
  final String id;
  final String nome;
  final String? nota;
  final bool isCompletata;

  const Attivita({
    required this.id,
    required this.nome,
    this.nota,
    this.isCompletata = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'nota': nota,
      'isCompletata': isCompletata,
    };
  }

  factory Attivita.fromJson(Map<String, dynamic> json) {
    return Attivita(
      id: json['id'] as String,
      nome: json['nome'] as String,
      nota: json['nota'] as String?,
      isCompletata: json['isCompletata'] as bool? ?? false,
    );
  }

  Attivita copyWith({String? nome, String? nota, bool? isCompletata}) {
    return Attivita(
      id: id,
      nome: nome ?? this.nome,
      nota: nota ?? this.nota,
      isCompletata: isCompletata ?? this.isCompletata,
    );
  }
}