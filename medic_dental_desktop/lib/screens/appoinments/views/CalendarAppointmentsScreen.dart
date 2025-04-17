import 'package:flutter/material.dart';
import 'package:medic_dental_desktop/database/helper.database.dart';
import 'package:medic_dental_desktop/screens/appoinments/views/AppointmentFormScreen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarAppointmentsScreen extends StatefulWidget {
  @override
  _CalendarAppointmentsScreenState createState() =>
      _CalendarAppointmentsScreenState();
}

class _CalendarAppointmentsScreenState
    extends State<CalendarAppointmentsScreen> {
  late Map<DateTime, List<Map<String, dynamic>>> _appointments;
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  List<Map<String, dynamic>> _todayAppointments = [];
  List<Map<String, dynamic>> _upcomingAppointments = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _appointments = {};
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    List<Map<String, dynamic>> appointments =
        await DatabaseHelper().getAllAppointments();

    Map<DateTime, List<Map<String, dynamic>>> appointmentsMap = {};
    DateTime today = DateTime.now();
    DateTime todayOnly = DateTime(today.year, today.month, today.day);
    List<Map<String, dynamic>> todayList = [];
    List<Map<String, dynamic>> upcomingList = [];

    for (var appointment in appointments) {
      DateTime date = DateTime.parse(appointment['date']);
      DateTime justDate = DateTime(date.year, date.month, date.day);

      if (!appointmentsMap.containsKey(justDate)) {
        appointmentsMap[justDate] = [];
      }
      appointmentsMap[justDate]!.add(appointment);

      if (justDate == todayOnly) {
        todayList.add(appointment);
      } else if (justDate.isAfter(todayOnly)) {
        upcomingList.add(appointment);
      }
    }

    setState(() {
      _appointments = appointmentsMap;
      _todayAppointments = todayList;
      _upcomingAppointments = upcomingList;
    });
  }

  Future<void> _updateAppointmentStatus(int id, String newStatus) async {
    await DatabaseHelper().updateAppointmentStatus(id, newStatus);
    await _loadAppointments(); // refrescar datos
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    final appointments = _appointments[DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    )] ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(DateFormat('EEEE, dd MMMM yyyy', 'es').format(selectedDay)),
          content: appointments.isEmpty
              ? Text("No hay citas para este día.")
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      var appointment = appointments[index];

                      // Determinar color del estado
                      Color statusColor;
                      switch (appointment['status']) {
                        case 'confirmada':
                          statusColor = Colors.green;
                          break;
                        case 'pendiente':
                          statusColor = Colors.orange;
                          break;
                        case 'cancelada':
                          statusColor = Colors.red;
                          break;
                        default:
                          statusColor = Colors.blue;
                      }

                      return ListTile(
                        title: Text('${appointment['patient_name']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Hora: ${appointment['time']} - Tratamiento: ${appointment['treatment']}'),
                            const SizedBox(height: 4),
                            Text(
                              'Estado: ${appointment['status']}',
                              style: TextStyle(color: statusColor),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          onSelected: (String newStatus) async {
                            await _updateAppointmentStatus(appointment['id'], newStatus);
                            Navigator.pop(context); // cerrar el diálogo
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem(value: 'confirmada', child: Text('Confirmar')),
                            PopupMenuItem(value: 'pendiente', child: Text('Pendiente')),
                            PopupMenuItem(value: 'cancelada', child: Text('Cancelar')),
                          ],
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              child: Text("Cerrar"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> list) {
    return ExpansionTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      children: list.isEmpty
          ? [ListTile(title: Text('Sin citas'))]
          : list.map((appointment) {
              return ListTile(
                title: Text('${appointment['patient_name']}'),
                subtitle: Text(
                    'Fecha: ${appointment['date']} - Hora: ${appointment['time']}'),
              );
            }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Citas Programadas")),
      body: Column(
        children: [
          _buildSection("📅 Citas para Hoy", _todayAppointments),
          _buildSection("📆 Próximas Citas", _upcomingAppointments),
          Divider(),
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime(2020),
            lastDay: DateTime(2050),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final normalizedDate = DateTime(date.year, date.month, date.day);
                if (_appointments.containsKey(normalizedDate)) {
                  return Positioned(
                    bottom: 1,
                    right: 1,
                    child: CircleAvatar(
                      backgroundColor: Colors.blue,
                      radius: 8,
                      child: Text(
                        _appointments[normalizedDate]!.length.toString(),
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddAppointmentScreen()),
          ).then((_) => _loadAppointments());
        },
        child: Icon(Icons.add),
        tooltip: 'Agregar Cita',
      ),
    );
  }
}
