import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_travel/domain/models/viaggio.dart';
import 'package:my_travel/domain/models/spesa.dart';
import 'package:my_travel/domain/models/attivita.dart';

// ════════════════════════════════════════════════════════════
//  Viaggio
// ════════════════════════════════════════════════════════════
void _viaggioTests() {
  final oggi = DateTime.now();

  Viaggio make({
    int giorniAlPartenza = 5,
    bool inCorso = false,
    bool concluso = false,
  }) {
    late DateTime inizio;
    late DateTime fine;
    if (inCorso) {
      inizio = oggi.subtract(const Duration(days: 1));
      fine = oggi.add(const Duration(days: 2));
    } else if (concluso) {
      inizio = oggi.subtract(const Duration(days: 10));
      fine = oggi.subtract(const Duration(days: 7));
    } else {
      inizio = oggi.add(Duration(days: giorniAlPartenza));
      fine = inizio.add(const Duration(days: 3));
    }
    return Viaggio(
      id: 'v1',
      userId: 'u1',
      nome: 'Test',
      destinazione: 'Roma',
      dataInizio: inizio,
      dataFine: fine,
    );
  }

  group('Viaggio.giorniAllaPartenza', () {
    test('ritorna il numero corretto di giorni rimanenti', () {
      expect(make(giorniAlPartenza: 7).giorniAllaPartenza, 7);
    });

    test('ritorna 0 il giorno stesso della partenza', () {
      final v = Viaggio(
        id: 'x', userId: 'u', nome: 'N', destinazione: 'D',
        dataInizio: DateTime(oggi.year, oggi.month, oggi.day),
        dataFine: DateTime(oggi.year, oggi.month, oggi.day + 2),
      );
      expect(v.giorniAllaPartenza, 0);
    });

    test('ritorna negativo per viaggio nel passato', () {
      expect(make(concluso: true).giorniAllaPartenza, isNegative);
    });
  });

  group('Viaggio.isInCorso', () {
    test('true se la data attuale è tra inizio e fine', () {
      expect(make(inCorso: true).isInCorso, isTrue);
    });

    test('false se il viaggio è nel futuro', () {
      expect(make(giorniAlPartenza: 3).isInCorso, isFalse);
    });

    test('false se il viaggio è concluso', () {
      expect(make(concluso: true).isInCorso, isFalse);
    });
  });

  group('Viaggio.toJson / fromJson', () {
    test('round-trip serializzazione', () {
      final v = make(giorniAlPartenza: 3);
      final json = v.toJson();
      // Simula la lettura da Firestore: Timestamp → Date
      final jsonConTimestamp = {
        ...json,
        'dataInizio': Timestamp.fromDate(v.dataInizio),
        'dataFine': Timestamp.fromDate(v.dataFine),
      };
      final v2 = Viaggio.fromJson('v1', jsonConTimestamp);
      expect(v2.nome, v.nome);
      expect(v2.destinazione, v.destinazione);
      expect(v2.isCompletato, v.isCompletato);
    });

    test('isCompletato default è false', () {
      final v = make();
      expect(v.toJson()['isCompletato'], isFalse);
    });
  });

  group('Viaggio.copyWith', () {
    test('sovrascrive solo i campi specificati', () {
      final v = make();
      final v2 = v.copyWith(nome: 'Nuovo nome', isCompletato: true);
      expect(v2.nome, 'Nuovo nome');
      expect(v2.isCompletato, isTrue);
      expect(v2.destinazione, v.destinazione); // invariato
    });
  });
}

// ════════════════════════════════════════════════════════════
//  Spesa
// ════════════════════════════════════════════════════════════
void _spesaTests() {
  Spesa makeSpesa({double importo = 25.50, String cat = 'Pasto'}) => Spesa(
        id: 's1',
        viaggioId: 'v1',
        descrizione: 'Pranzo',
        importo: importo,
        categoria: cat,
        data: DateTime(2024, 6, 15),
      );

  group('Spesa.importoFormattato', () {
    test('formatta correttamente con virgola', () {
      expect(makeSpesa(importo: 25.50).importoFormattato, '€ 25,50');
    });

    test('importo intero mostra due decimali', () {
      expect(makeSpesa(importo: 100.0).importoFormattato, '€ 100,00');
    });

    test('importo con un decimale mostra due cifre', () {
      expect(makeSpesa(importo: 9.5).importoFormattato, '€ 9,50');
    });
  });

  group('Spesa.toJson / fromJson', () {
    test('round-trip serializzazione', () {
      final s = makeSpesa();
      final json = {
        ...s.toJson(),
        'data': Timestamp.fromDate(s.data),
      };
      final s2 = Spesa.fromJson('s1', json);
      expect(s2.descrizione, s.descrizione);
      expect(s2.importo, s.importo);
      expect(s2.categoria, s.categoria);
    });

    test('immagineScontrinoUrl è nullable', () {
      final s = makeSpesa();
      expect(s.toJson()['immagineScontrinoUrl'], isNull);
    });
  });

  group('Spesa.copyWith', () {
    test('aggiorna solo l/importo', () {
      final s = makeSpesa();
      final s2 = s.copyWith(importo: 99.99);
      expect(s2.importo, 99.99);
      expect(s2.descrizione, s.descrizione);
    });

    test('aggiorna categoria', () {
      final s = makeSpesa();
      final s2 = s.copyWith(categoria: 'Alloggio');
      expect(s2.categoria, 'Alloggio');
    });
  });
}

// ════════════════════════════════════════════════════════════
//  Attivita
// ════════════════════════════════════════════════════════════
void _attivitaTests() {
  const a = Attivita(id: 'a1', nome: 'Riunione', isCompletata: false);

  group('Attivita costruzione', () {
    test('isCompletata di default è false', () {
      const a2 = Attivita(id: 'x', nome: 'Test');
      expect(a2.isCompletata, isFalse);
    });

    test('nota è nullable', () {
      expect(a.nota, isNull);
    });
  });

  group('Attivita.toJson / fromJson', () {
    test('round-trip serializzazione', () {
      final json = a.toJson();
      final a2 = Attivita.fromJson(json);
      expect(a2.id, a.id);
      expect(a2.nome, a.nome);
      expect(a2.isCompletata, a.isCompletata);
    });

    test('nota viene serializzata e deserializzata', () {
      const withNote = Attivita(id: 'b1', nome: 'Task', nota: 'Portare documenti');
      final json = withNote.toJson();
      final back = Attivita.fromJson(json);
      expect(back.nota, 'Portare documenti');
    });

    test('isCompletata default false se mancante nel JSON', () {
      final json = {'id': 'c1', 'nome': 'Task senza flag'};
      final a2 = Attivita.fromJson(json);
      expect(a2.isCompletata, isFalse);
    });
  });

  group('Attivita.copyWith', () {
    test('toggle isCompletata', () {
      final completata = a.copyWith(isCompletata: true);
      expect(completata.isCompletata, isTrue);
      expect(completata.id, a.id); // invariato
    });

    test('aggiorna nome mantenendo il resto', () {
      final renamed = a.copyWith(nome: 'Nuova riunione');
      expect(renamed.nome, 'Nuova riunione');
      expect(renamed.isCompletata, a.isCompletata);
    });
  });
}

// ════════════════════════════════════════════════════════════
//  Entrypoint
// ════════════════════════════════════════════════════════════
void main() {
  group('Viaggio', _viaggioTests);
  group('Spesa', _spesaTests);
  group('Attivita', _attivitaTests);
}
