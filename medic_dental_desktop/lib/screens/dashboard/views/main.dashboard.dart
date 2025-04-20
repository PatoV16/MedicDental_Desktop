import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medic_dental_desktop/database/helper.database.dart';
import 'package:medic_dental_desktop/screens/appoinments/views/CalendarAppointmentsScreen.dart';
import 'package:medic_dental_desktop/screens/dashboard/widgets/navbar/DrawerItemTile.widget.dart';
import 'package:medic_dental_desktop/screens/info/views/InformationScreen.dart';

class DentalDashboard extends StatefulWidget {
  @override
  _DentalDashboardState createState() => _DentalDashboardState();
}

class _DentalDashboardState extends State<DentalDashboard> {
  Widget _currentPage = InformacionClinicaScreen();
  Map<String, dynamic>? configuracion;
  int _notificationCount = 0; // Contador de notificaciones
  List<Map<String, dynamic>> _upcomingAppointments = [];
  final GlobalKey _notificationButtonKey = GlobalKey();

  final List<Widget> _pages = [
    Center(child: Text("Citas")),
    Center(child: Text("Pacientes")),
    Center(child: Text("Odontogramas")),
    Center(child: Text("Inventario")),
    Center(child: Text("Cuentas")),
    Center(child: Text("Configuración")),
  ];

  @override
  void initState() {
    super.initState();
    cargarConfiguracion();
    _loadUpcomingAppointments();
  }

  Future<void> cargarConfiguracion() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> resultado = await db.query('configuracion', limit: 1);
    if (resultado.isNotEmpty) {
      setState(() {
        configuracion = resultado.first;
      });
    }
  }

  // Método para cargar las próximas citas
Future<void> _loadUpcomingAppointments() async {
  final now = DateTime.now();
  final today = DateFormat('yyyy-MM-dd').format(now);
  final currentTime = DateFormat('HH:mm').format(now);
  final db = await DatabaseHelper();

  List<Map<String, dynamic>> all = [];

  // Citas de hoy
  final todayAppointments = await db.getAppointmentsByDate(today);
  all.addAll(todayAppointments.where((a) => a['time'].compareTo(currentTime) >= 0));

  // Citas de los próximos 3 días
  for (int i = 1; i <= 3; i++) {
    final futureDate = DateFormat('yyyy-MM-dd').format(now.add(Duration(days: i)));
    final upcoming = await db.getAppointmentsByDate(futureDate);
    all.addAll(upcoming);
  }

  // Ordenar por fecha y hora
  all.sort((a, b) {
    final dtA = '${a['date']} ${a['time']}';
    final dtB = '${b['date']} ${b['time']}';
    return dtA.compareTo(dtB);
  });

  // Limitar a 10
  final upcomingLimited = all.take(10).toList();

  print("Citas próximas encontradas: $upcomingLimited");

  setState(() {
    _upcomingAppointments = upcomingLimited;
    _notificationCount = upcomingLimited.length;
  });
}


  void _onPageSelected(Widget page) {
    setState(() {
      _currentPage = page;
    });
  }

  // Método para mostrar el popup de notificaciones
  void _showNotificationsPopup(Function(Widget) onNavigate) {
    final RenderBox renderBox = _notificationButtonKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              right: 20,
              top: position.dy + renderBox.size.height + 5,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 320,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 18, 120, 108),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.notifications, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Próximas Citas',
                              style: GoogleFonts.montserrat(
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_upcomingAppointments.length} citas',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _upcomingAppointments.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.event_available,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No hay citas programadas próximamente',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Flexible(
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: _upcomingAppointments.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final appointment = _upcomingAppointments[index];
                                  final isToday = appointment['date'] == DateFormat('yyyy-MM-dd').format(DateTime.now());
                                  
                                  // Formatear fecha para mostrar
                                  final appointmentDate = DateFormat('yyyy-MM-dd').parse(appointment['date']);
                                  final formattedDate = isToday
                                      ? 'Hoy'
                                      : DateFormat('E, d MMM', 'es').format(appointmentDate);
                                  
                                  // Formatear hora
                                  final timeFormat = DateFormat('HH:mm');
                                  final appointmentTime = timeFormat.parse(appointment['time']);
                                  final formattedTime = DateFormat('h:mm a').format(appointmentTime);
                                  
                                  // Determinar color de estado
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
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(255, 18, 120, 108).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            formattedTime,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                              color: const Color.fromARGB(255, 18, 120, 108),
                                            ),
                                          ),
                                          Text(
                                            formattedDate,
                                            style: TextStyle(
                                              fontSize: 8,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ],
                                      ),
                                   
                                    ),
                                    title: Text(
                                      appointment['patient_name'] ?? 'Paciente sin nombre',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          appointment['treatment'] ?? 'Consulta general',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                appointment['status'] ?? 'pendiente',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: statusColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${appointment['duration']} min',
                                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () {
                                        // Acción para ver detalles o editar la cita
                                        _showAppointmentOptionsDialog(context, appointment);
                                      },
                                    ),
                                    onTap: () {
                                      // Navegar a la vista detallada de la cita
                                      Navigator.pop(context); // Cerrar el popup
                                      // Aquí añadirías código para navegar a la vista detallada
                                    },
                                  );
                                },
                              ),
                            ),
                     
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.grey[200]!)),
                        ),
                        child: Center(
                          child: TextButton.icon(
                            icon: const Icon(Icons.calendar_month),
                            label: const Text('Ver todas las citas'),
                           onPressed: () {
  Navigator.pop(context); // Cierra el popup
  onNavigate(CalendarAppointmentsScreen()); // Navega usando la barra lateral
},
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
      },
    );
  }
void _onNotificationPressed(Function(Widget) onNavigate) async {
  await _loadUpcomingAppointments();
  _showNotificationsPopup(onNavigate);
}
  // Diálogo de opciones para cada cita
  void _showAppointmentOptionsDialog(BuildContext context, Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Opciones de cita',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Color.fromARGB(255, 18, 120, 108)),
                title: const Text('Editar cita'),
                onTap: () {
                  Navigator.pop(context); // Cerrar el diálogo
                  Navigator.pop(context); // Cerrar el popup
                  // Aquí irías a la pantalla de edición de cita
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Marcar como confirmada'),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateAppointmentStatus(appointment['id'], 'confirmada');
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Cancelar cita'),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateAppointmentStatus(appointment['id'], 'cancelada');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Método para actualizar el estado de una cita
  Future<void> _updateAppointmentStatus(int id, String status) async {
    final db = await DatabaseHelper();
    await db.updateAppointment(id, {'status': status});
    
    // Recargar las citas y cerrar el popup
    await _loadUpcomingAppointments();
    Navigator.pop(context); // Cerrar el popup de notificaciones
  }

  @override
  Widget build(BuildContext context) {
    final String nombreClinica = configuracion?['nombre_empresa'] ?? 'Clínica Dental';
    final String? logoBase64 = configuracion?['logo'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 18, 120, 108),
        elevation: 4,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            if (logoBase64 != null && logoBase64.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.memory(
                      base64Decode(logoBase64),
                      height: 42,
                      width: 42,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [Colors.white, Colors.white.withOpacity(0.9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds);
              },
              child: Text(
                nombreClinica,
                style: GoogleFonts.montserrat(
                  textStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 2.0,
                        color: Colors.black26,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            Text(
              _getCurrentDate(),
              style: GoogleFonts.lato(
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Botón de notificaciones con badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                key: _notificationButtonKey,
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                tooltip: "Notificaciones",
                onPressed: () => _onNotificationPressed(_onPageSelected),
              ),
              if (_notificationCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          ExpandableSidebar(onItemSelected: _onPageSelected),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: _currentPage,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Función para obtener la fecha actual en formato elegante
  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
      "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
    ];
    return "${now.day} de ${months[now.month - 1]}, ${now.year}";
  }
}