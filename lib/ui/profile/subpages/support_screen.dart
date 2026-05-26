import 'package:flutter/material.dart';

enum SupportSection { faq, about }

class SupportScreen extends StatelessWidget {
  const SupportScreen({
    super.key,
    required this.section,
  });

  final SupportSection section;

  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFF757575);
  static const Color errorColor = Color(0xFFF44336);

  bool get isFaq => section == SupportSection.faq;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          isFaq ? 'FAQ' : 'About App',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: Colors.black87,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: isFaq ? const _FaqContent() : const _AboutContent(),
    );
  }
}

class _FaqContent extends StatelessWidget {
  const _FaqContent();

  static const List<Map<String, String>> faqs = [
    {
      'q': 'Come creo un nuovo viaggio?',
      'a':
          'Dalla Home puoi toccare il pulsante "Nuovo viaggio", inserire nome, destinazione e date, quindi salvare il contenuto.',
    },
    {
      'q': 'Come aggiungo una spesa?',
      'a':
          'Apri il dettaglio di un viaggio e accedi alla sezione spese. Da lì puoi inserire manualmente una nuova spesa o usare la scansione dello scontrino se disponibile.',
    },
    {
      'q': 'Posso modificare il mio profilo?',
      'a':
          'Sì. Nella sezione Profilo puoi aprire "My Profile", attivare la modalità modifica e aggiornare i dati personali.',
    },
    {
      'q': 'Come funzionano le notifiche?',
      'a':
          'Nella pagina Notifiche puoi attivare o disattivare i promemoria viaggio, gli aggiornamenti spese e le comunicazioni relative all’app.',
    },
    {
      'q': 'Posso esportare un report delle spese?',
      'a':
          'Sì. Dallo storico o dal dettaglio del viaggio puoi aprire il report PDF e condividerlo o salvarlo.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        const Text(
          'Domande frequenti',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: SupportScreen.primaryColor,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        ...faqs.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                iconColor: SupportScreen.primaryColor,
                collapsedIconColor: Colors.black54,
                title: Text(
                  item['q']!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item['a']!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: SupportScreen.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AboutContent extends StatelessWidget {
  const _AboutContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        const Text(
          'Informazioni',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: SupportScreen.primaryColor,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MyTravel',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'MyTravel ti aiuta a gestire trasferte, viaggi e spese in modo semplice, veloce e ordinato.',
                style: TextStyle(
                  fontSize: 14,
                  color: SupportScreen.textSecondary,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Versione 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: SupportScreen.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
