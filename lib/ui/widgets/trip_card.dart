import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/viaggio.dart';

class TripCard extends StatelessWidget {
  final Viaggio viaggio;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TripCard({
    super.key,
    required this.viaggio,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'it_IT');
    final giorni = viaggio.giorniAllaPartenza;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // --- Sfondo colorato ---
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _gradientPerStato(giorni),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

              // --- Contenuto ---
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Riga superiore: destinazione + badge stato
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Icona + Destinazione
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              viaggio.destinazione,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        // Badge stato
                        _BadgeStato(
                            giorni: giorni, isInCorso: viaggio.isInCorso),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Nome viaggio
                    Text(
                      viaggio.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Riga inferiore: date + countdown + delete
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Date
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${dateFormat.format(viaggio.dataInizio)} → ${dateFormat.format(viaggio.dataFine)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        // Countdown o "In corso"
                        _CountdownBadge(
                          giorni: giorni,
                          isInCorso: viaggio.isInCorso,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- Bottone elimina (in alto a destra) ---
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Colori diversi in base allo stato del viaggio
  List<Color> _gradientPerStato(int giorni) {
    if (viaggio.isInCorso) {
      return [const Color(0xFF059669), const Color(0xFF047857)]; // verde
    }
    if (giorni <= 3 && giorni >= 0) {
      return [const Color(0xFFD97706), const Color(0xFFB45309)]; // arancione
    }
    return [const Color(0xFF1E3A8A), const Color(0xFF1E40AF)]; // blu default
  }
}

// Badge testuale che mostra lo stato
class _BadgeStato extends StatelessWidget {
  final int giorni;
  final bool isInCorso;

  const _BadgeStato({required this.giorni, required this.isInCorso});

  @override
  Widget build(BuildContext context) {
    String testo;
    if (isInCorso) {
      testo = '● In corso';
    } else if (giorni == 0) {
      testo = '● Oggi!';
    } else if (giorni < 0) {
      testo = 'Concluso';
    } else {
      testo = 'Programmato';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        testo,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Badge con il countdown numerico
class _CountdownBadge extends StatelessWidget {
  final int giorni;
  final bool isInCorso;

  const _CountdownBadge({required this.giorni, required this.isInCorso});

  @override
  Widget build(BuildContext context) {
    if (isInCorso) return const SizedBox.shrink();

    String testo;
    if (giorni == 0) {
      testo = 'Oggi!';
    } else if (giorni < 0) {
      testo = '${giorni.abs()}gg fa';
    } else {
      testo = 'tra $giorni gg';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        testo,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
