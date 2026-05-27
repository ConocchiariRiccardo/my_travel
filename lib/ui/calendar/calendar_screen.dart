import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderColor = Color(0xFFE0E0E0);

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

  DateTime get _oggi {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isPastDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return normalized.isBefore(_oggi);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Calendario Trasferte',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          final eventi = _viewModel.eventiPerGiorno;
          final viaggiOggi = _viewModel.viaggiDelGiornoSelezionato;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: _buildSectionLabel('Panoramica mese'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
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
                      final normalizzato =
                          DateTime(day.year, day.month, day.day);
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left_rounded,
                        color: primaryColor,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right_rounded,
                        color: primaryColor,
                      ),
                      headerPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                      weekendStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      defaultTextStyle: const TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                      ),
                      weekendTextStyle: const TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                      ),
                      todayDecoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders<Viaggio>(
                      defaultBuilder: (context, day, focusedDay) {
                        final normalizzato =
                            DateTime(day.year, day.month, day.day);
                        final viaggiDelGiorno = eventi[normalizzato] ?? [];
                        final isPast = _isPastDay(day);

                        if (viaggiDelGiorno.isEmpty) {
                          return Container(
                            margin: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: isPast
                                  ? Colors.grey.shade100
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: isPast
                                      ? Colors.grey.shade400
                                      : Colors.black87,
                                  fontWeight: isPast
                                      ? FontWeight.w500
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }

                        final colore =
                            _viewModel.coloreViaggio(viaggiDelGiorno.first);

                        return Container(
                          margin: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: isPast
                                ? colore.withOpacity(0.06)
                                : colore.withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isPast
                                  ? colore.withOpacity(0.18)
                                  : colore.withOpacity(0.30),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color:
                                    isPast ? colore.withOpacity(0.45) : colore,
                                fontWeight: FontWeight.w700,
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
                            : primaryColor;

                        return Container(
                          margin: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: colore,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      },
                      todayBuilder: (context, day, focusedDay) {
                        final isSelected =
                            isSameDay(day, _viewModel.giornoSelezionato);

                        if (isSelected) return null;

                        return Container(
                          margin: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.10),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor.withOpacity(0.25),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (_viewModel.eventiPerGiorno.isNotEmpty) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildLegenda(),
                ),
              ],
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSectionLabel(
                  'Trasferte del ${_dateFormat.format(_viewModel.giornoSelezionato ?? DateTime.now())}',
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: viaggiOggi.isEmpty
                    ? _buildGiornoVuoto()
                    : _buildListaViaggiDelGiorno(viaggiOggi),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: primaryColor,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildLegenda() {
    final Set<String> ids = {};
    final List<Viaggio> viaggiUnici = [];

    for (final lista in _viewModel.eventiPerGiorno.values) {
      for (final v in lista) {
        if (ids.add(v.id)) viaggiUnici.add(v);
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 10,
        children: viaggiUnici.map((v) {
          final colore = _viewModel.coloreViaggio(v);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colore.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colore,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  v.nome,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGiornoVuoto() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: Icon(
                Icons.event_available_outlined,
                size: 34,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nessuna trasferta in questa data',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Seleziona un altro giorno del calendario per vedere i viaggi pianificati.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaViaggiDelGiorno(List<Viaggio> viaggi) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: viaggi.length,
      itemBuilder: (context, index) {
        final viaggio = viaggi[index];
        final colore = _viewModel.coloreViaggio(viaggio);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () =>
                  Navigator.pushNamed(context, '/trip', arguments: viaggio.id),
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: colore.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.flight_rounded,
                          color: colore,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              viaggio.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    viaggio.destinazione,
                                    style: const TextStyle(
                                      color: textSecondary,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${_dateFormat.format(viaggio.dataInizio)} → ${_dateFormat.format(viaggio.dataFine)}',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
