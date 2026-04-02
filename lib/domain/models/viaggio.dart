class Viaggio{
    final String id;
    final String nome;   // Nome del viaggio
    final String destinazione;   // Destinazione del viaggio
    final DateTime dataPartenza;   // Data di partenza del viaggio
    final DateTime dataRitorno;   // Data di ritorno del viaggio
    final String? descrizione;   // Descrizione del viaggio
    final String? immagineUrl;   // URL dell'immagine rappresentativa del viaggio
    final bool completato;   // Indica se il viaggio è stato completato o meno

    Viaggio({
        required this.id,
        required this.nome,
        required this.destinazione,
        required this.dataPartenza,
        required this.dataRitorno,
        this.descrizione,
        this.immagineUrl,
        this.completato = false,
    });
}
