import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../auth/auth_view_model.dart';
import '../../domain/models/viaggio.dart';
import 'calendar_view_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final CalendarViewModel _viewModel;
  final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'it_IT');

  @override
  void initState() {
    super.initState();
    _viewModel = CalendarViewModel();
    final userId = context.read<AuthViewModel>().currentUser!.uid;
    _viewModel.inizializza(userId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Calendario Trasferte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final eventi = _viewModel.eventiPerGiorno;
          final viaggiOggi = _viewModel.viaggiDelGiornoSelezionato;

          return Column(
            children: [
              // --- Calendario ---
              Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TableCalendar<Viaggio>(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2030),
                  focusedDay: _viewModel.meseVisualizzato,
                  selectedDayPredicate: (day) =>
                      isSameDay(day, _viewModel.giornoSelezionato),
                  eventLoader: (day) {
                    final normalizzato = DateTime(day.year, day.month, day.day);
                    return eventi[normalizzato] ?? [];
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    _viewModel.selezionaGiorno(selectedDay);
                    _viewModel.cambioMese(focusedDay);
                  },
                  onPageChanged: (focusedDay) {
                    _viewModel.cambioMese(focusedDay);
                  },
                  locale: 'it_IT',
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: Color(0xFF1E3A8A),
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFF1E3A8A),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    // Stile per i giorni con eventi (sovrascriviamo il builder)
                    outsideDaysVisible: false,
                  ),
                  // Builder custom per colorare i giorni di trasferta
                  calendarBuilders: CalendarBuilders<Viaggio>(
                    defaultBuilder: (context, day, focusedDay) {
                      final normalizzato =
                          DateTime(day.year, day.month, day.day);
                      final viaggiDelGiorno = eventi[normalizzato] ?? [];

                      if (viaggiDelGiorno.isEmpty) return null;

                      // Usa il colore del primo viaggio del giorno
                      final colore =
                          _viewModel.coloreViaggio(viaggiDelGiorno.first);

                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colore.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colore.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: colore,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      final normalizzato =
                          DateTime(day.year, day.month, day.day);
                      final viaggiDelGiorno = eventi[normalizzato] ?? [];
                      final colore = viaggiDelGiorno.isNotEmpty
                          ? _viewModel.coloreViaggio(viaggiDelGiorno.first)
                          : const Color(0xFF1E3A8A);

                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colore,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // --- Legenda colori viaggi ---
              if (_viewModel.eventiPerGiorno.isNotEmpty) _buildLegenda(),

              // --- Pannello giorno selezionato ---
              Expanded(
                child: viaggiOggi.isEmpty
                    ? _buildGiornoVuoto()
                    : _buildListaViaggDelGiorno(viaggiOggi),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegenda() {
    // Raccoglie tutti i viaggi unici presenti nel calendario
    final Set<String> ids = {};
    final List<Viaggio> viaggiUnici = [];
    for (final lista in _viewModel.eventiPerGiorno.values) {
      for (final v in lista) {
        if (ids.add(v.id)) viaggiUnici.add(v);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: viaggiUnici.map((v) {
          final colore = _viewModel.coloreViaggio(v);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colore,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                v.nome,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGiornoVuoto() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 52,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'Nessuna trasferta in questa data',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildListaViaggDelGiorno(List<Viaggio> viaggi) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: viaggi.length,
      itemBuilder: (context, index) {
        final viaggio = viaggi[index];
        final colore = _viewModel.coloreViaggio(viaggio);

        return GestureDetector(
          onTap: () => context.push('/trip/${viaggio.id}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(color: colore, width: 4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viaggio.nome,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            viaggio.destinazione,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_dateFormat.format(viaggio.dataInizio)} → ${_dateFormat.format(viaggio.dataFine)}',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: colore,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
