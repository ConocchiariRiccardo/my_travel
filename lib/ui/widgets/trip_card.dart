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
    final giorni = viaggio.giorniAllaPartenza;
    final dateFormat = DateFormat('dd MMM yyyy', 'it_IT');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _getGradientColors(viaggio.destinazione),
                  ),
                ),
              ),

              // --- Overlay scuro in basso per leggibilità ---
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 90,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // --- Badge stato in alto a sinistra ---
              Positioned(
                top: 12,
                left: 12,
                child: _buildStateBadge(giorni),
              ),

              // --- Bottone elimina in alto a destra ---
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: () => _confirmDelete(context),
                ),
              ),

              // --- Testo in basso ---
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viaggio.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          viaggio.destinazione,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.white70,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${dateFormat.format(viaggio.dataInizio)} → ${dateFormat.format(viaggio.dataFine)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateBadge(int giorni) {
    String testo;
    Color colore;

    if (viaggio.isInCorso) {
      testo = '● In corso';
      colore = Colors.green.shade600;
    } else if (giorni == 0) {
      testo = '🚀 Oggi!';
      colore = Colors.orange.shade700;
    } else if (giorni > 0) {
      testo = 'Tra $giorni ${giorni == 1 ? "giorno" : "giorni"}';
      colore = const Color(0xFF1E3A8A);
    } else {
      testo = 'Concluso';
      colore = Colors.grey.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colore,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        testo,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Genera un gradiente diverso in base alla destinazione
  // (deterministico: stessa città = stesso colore)
  List<Color> _getGradientColors(String destinazione) {
    final palettes = [
      [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
      [const Color(0xFF065F46), const Color(0xFF34D399)],
      [const Color(0xFF7C3AED), const Color(0xFFA78BFA)],
      [const Color(0xFF92400E), const Color(0xFFFBBF24)],
      [const Color(0xFF9D174D), const Color(0xFFF472B6)],
      [const Color(0xFF1E40AF), const Color(0xFF60A5FA)],
    ];
    final index = destinazione.length % palettes.length;
    return palettes[index];
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina viaggio'),
        content: Text(
          'Vuoi eliminare "${viaggio.nome}"? L\'operazione è irreversibile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (conferma == true) onDelete();
  }
}
