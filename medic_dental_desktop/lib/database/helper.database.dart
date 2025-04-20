import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Singleton pattern
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'dental_clinic.db');
    
    return await openDatabase(
      path,
      version: 2,  // Incrementamos la versión para manejar la actualización
      onCreate: _onCreate,
    );
  }

  // Método para manejar actualizaciones de base de datos
  

  Future _onCreate(Database db, int version) async {
    // Create Patients table
    await db.execute('''
      CREATE TABLE patients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT,
        birthdate TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    
    // Create Appointments table
    await db.execute('''
      CREATE TABLE appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        patient_name TEXT,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        duration INTEGER NOT NULL,
        treatment TEXT,
        notes TEXT,
        status TEXT NOT NULL,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE SET NULL
      )
    ''');
    //odontograms table
    await db.execute('''
        CREATE TABLE IF NOT EXISTS odontogramas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          cliente_id TEXT NOT NULL,
          fecha_registro TEXT NOT NULL,
          doctor_id TEXT,
          especificaciones TEXT,
          observaciones TEXT,
          dientes_estado TEXT NOT NULL,
          FOREIGN KEY(cliente_id) REFERENCES patients(id)
        )
      ''');
    // Create Treatments table
  await db.execute('''
  CREATE TABLE IF NOT EXISTS IngresosEgresos (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    Fecha TEXT NOT NULL,
    Concepto TEXT NOT NULL,
    Ingresos REAL DEFAULT 0,
    Egresos REAL DEFAULT 0,
    Saldo REAL
  )
''');

    
    // Create Inventory table
   await db.execute('''
      CREATE TABLE tratamientos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100),
    descripcion TEXT,
    precio DECIMAL(10,2),
    duracion_minutos INT
)
'''  );
 
await db.execute('''
  CREATE TABLE IF NOT EXISTS CuentasPorCobrar (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    Paciente TEXT NOT NULL,
    Articulo TEXT NOT NULL,
    ValorCredito REAL NOT NULL,
    FechaInicial TEXT NOT NULL,
    SaldoCuenta REAL NOT NULL,
    FechaFinal TEXT,
    Estado TEXT
  )
''');
await db.execute('''
  CREATE TABLE IF NOT EXISTS RecaudosDiarios (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    RecaudoDiario REAL NOT NULL,
    FechaCobro TEXT NOT NULL,
    NombreCliente TEXT NOT NULL,
    Concepto TEXT NOT NULL,
    Contador INTEGER DEFAULT 0
  )
''');


await db.execute('''
  CREATE TABLE  productos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    descripcion TEXT,
    stock INTEGER NOT NULL,
    precio_unitario REAL NOT NULL
  )
''');

await db.execute('''
  CREATE TABLE entradas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    producto_id INTEGER NOT NULL,
    cantidad INTEGER NOT NULL,
    fecha TEXT NOT NULL,
    observaciones TEXT,
    FOREIGN KEY(producto_id) REFERENCES productos(id)
  )
''');

await db.execute('''
  CREATE TABLE  salidas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    producto_id INTEGER NOT NULL,
    cantidad INTEGER NOT NULL,
    fecha TEXT NOT NULL,
    observaciones TEXT,
    FOREIGN KEY(producto_id) REFERENCES productos(id)
  )
''');

await db.execute('''CREATE TABLE configuracion (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ruc TEXT NOT NULL,
  iva REAL NOT NULL,
  nombre_empresa TEXT NOT NULL,
  direccion TEXT,
  telefono TEXT,
  logo TEXT,  
  email TEXT,
  website TEXT,
  fecha_creacion TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
''');
    
    await db.execute('''
  CREATE TABLE patient_photos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id INTEGER NOT NULL,
    image_path TEXT NOT NULL,
    description TEXT,
    date TEXT NOT NULL,
    FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE
  )
''');


  }

  // PATIENT CRUD OPERATIONS
  
  Future<int> insertPatient(Map<String, dynamic> patient) async {
    Database db = await database;
    return await db.insert('patients', patient);
  }

  Future<List<Map<String, dynamic>>> getAllPatients() async {
    Database db = await database;
    return await db.query('patients', orderBy: 'name');
  }

  Future<Map<String, dynamic>?> getPatient(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updatePatient(int id, Map<String, dynamic> patient) async {
    Database db = await database;
    return await db.update(
      'patients',
      patient,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePatient(int id) async {
    Database db = await database;
    return await db.delete(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  Future<int> getTotalPacientes() async {
  final db = await database;
  final result = await db.rawQuery('SELECT COUNT(*) as total FROM patients');
  return Sqflite.firstIntValue(result) ?? 0;
}

  // APPOINTMENT CRUD OPERATIONS
  
  Future<int> insertAppointment(Map<String, dynamic> appointment) async {
    Database db = await database;
    return await db.insert('appointments', appointment);
  }

  Future<List<Map<String, dynamic>>> getAllAppointments() async {
    Database db = await database;
    return await db.query('appointments', orderBy: 'date, time');
  }

  Future<List<Map<String, dynamic>>> getAppointmentsByDate(String date) async {
    Database db = await database;
    return await db.query(
      'appointments',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'time',
    );
  }

  Future<List<Map<String, dynamic>>> getPatientAppointments(int patientId) async {
    Database db = await database;
    return await db.query(
      'appointments',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'date DESC, time DESC',
    );
  }

  Future<int> updateAppointment(int id, Map<String, dynamic> appointment) async {
    Database db = await database;
    return await db.update(
      'appointments',
      appointment,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAppointment(int id) async {
    Database db = await database;
    return await db.delete(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  Future<void> updateAppointmentStatus(int id, String status) async {
  final db = await database;
  await db.update(
    'appointments',
    {'status': status},
    where: 'id = ?',
    whereArgs: [id],
  );
}


 
  // ODONTOGRAMA CRUD OPERATIONS
  
  Future<int> insertOdontograma(Map<String, dynamic> odontograma) async {
    Database db = await database;
    return await db.insert('odontogramas', odontograma);
  }

  Future<List<Map<String, dynamic>>> getAllOdontogramas() async {
    Database db = await database;
    return await db.query('odontogramas', orderBy: 'fecha_registro DESC');
  }

  Future<List<Map<String, dynamic>>> getPatientOdontogramas(String clienteId) async {
    Database db = await database;
    return await db.query(
      'odontogramas',
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      orderBy: 'fecha_registro DESC',
    );
  }

  Future<Map<String, dynamic>?> getOdontograma(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'odontogramas',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateOdontograma(int id, Map<String, dynamic> odontograma) async {
    Database db = await database;
    return await db.update(
      'odontogramas',
      odontograma,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteOdontograma(int id) async {
    Database db = await database;
    return await db.delete(
      'odontogramas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Additional methods for complex queries
  
  // Get appointments with patient information
  Future<List<Map<String, dynamic>>> getAppointmentsWithPatients() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT a.*, p.name as patient_name, p.phone as patient_phone 
      FROM appointments a
      LEFT JOIN patients p ON a.patient_id = p.id
      ORDER BY a.date, a.time
    ''');
  }
  
  // Get the latest odontograma for a patient
  Future<Map<String, dynamic>?> getLatestPatientOdontograma(String clienteId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'odontogramas',
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      orderBy: 'fecha_registro DESC',
      limit: 1
    );
    
    return result.isNotEmpty ? result.first : null;
  }

  // INGRESOS EGRESOS
  Future<int> insertMovimiento(Map<String, dynamic> data) async {
  final db = await database;
  return await db.insert('IngresosEgresos', data);
}
Future<List<Map<String, dynamic>>> getMovimientos() async {
  final db = await database;
  return await db.query('IngresosEgresos', orderBy: 'Fecha DESC');
}
Future<int> updateMovimiento(int id, Map<String, dynamic> data) async {
  final db = await database;
  return await db.update(
    'IngresosEgresos',
    data,
    where: 'Id = ?',
    whereArgs: [id],
  );
}
Future<int> deleteMovimiento(int id) async {
  final db = await database;
  return await db.delete('IngresosEgresos', where: 'Id = ?', whereArgs: [id]);
}
// CUENTAS POR COBRAR

Future<int> insertCuentaPorCobrar(Map<String, dynamic> data) async {
  final db = await database;
  return await db.insert('CuentasPorCobrar', data);
}

Future<List<Map<String, dynamic>>> getCuentasPorCobrar() async {
  final db = await database;
  return await db.query('CuentasPorCobrar', orderBy: 'FechaInicial DESC');
}

Future<int> updateCuentaPorCobrar(int id, Map<String, dynamic> data) async {
  final db = await database;
  return await db.update(
    'CuentasPorCobrar',
    data,
    where: 'Id = ?',
    whereArgs: [id],
  );
}

Future<int> deleteCuentaPorCobrar(int id) async {
  final db = await database;
  return await db.delete(
    'CuentasPorCobrar',
    where: 'Id = ?',
    whereArgs: [id],
  );
}
//RECUADOS DIARIOS
// Insertar un nuevo recaudo diario
Future<int> insertRecaudoDiario(Map<String, dynamic> data) async {
  final db = await database;
  final result = await db.rawQuery('SELECT MAX(Contador) as maxContador FROM RecaudosDiarios');
  final maxContador = result.first['maxContador'] as int? ?? 0;

  // Asignar el nuevo contador
  data['Contador'] = maxContador + 1;
  return await db.insert('RecaudosDiarios', data);
}

// Obtener todos los recaudos diarios
Future<List<Map<String, dynamic>>> getRecaudosDiarios() async {
  final db = await database;
  return await db.query('RecaudosDiarios', orderBy: 'FechaCobro DESC');
}

// Actualizar un recaudo diario por ID
Future<int> updateRecaudoDiario(int id, Map<String, dynamic> data) async {
  final db = await database;
  return await db.update(
    'RecaudosDiarios',
    data,
    where: 'Id = ?',
    whereArgs: [id],
  );
}

// Eliminar un recaudo diario por ID
Future<int> deleteRecaudoDiario(int id) async {
  final db = await database;
  return await db.delete(
    'RecaudosDiarios',
    where: 'Id = ?',
    whereArgs: [id],
  );
}
//CRUD  
//productos
Future<int> insertProducto(Map<String, dynamic> producto) async {
  final db = await database;
  return await db.insert('productos', producto);
}

Future<List<Map<String, dynamic>>> getAllProductos() async {
  final db = await database;
  return await db.query('productos');
}

Future<int> updateProducto(int id, Map<String, dynamic> producto) async {
  final db = await database;
  return await db.update('productos', producto, where: 'id = ?', whereArgs: [id]);
}

Future<int> deleteProducto(int id) async {
  final db = await database;
  return await db.delete('productos', where: 'id = ?', whereArgs: [id]);
}
//CRUD ENTRADAS
Future<int> insertEntrada(Map<String, dynamic> entrada) async {
  final db = await database;
  return await db.insert('entradas', entrada);
}

Future<List<Map<String, dynamic>>> getAllEntradas() async {
  final db = await database;
  return await db.query('entradas');
}

Future<int> deleteEntrada(int id) async {
  final db = await database;
  return await db.delete('entradas', where: 'id = ?', whereArgs: [id]);
}
Future<int> getTotalEntradas() async {
  final db = await database;
  final result = await db.rawQuery('SELECT SUM(cantidad) as total FROM entradas');
  return Sqflite.firstIntValue(result) ?? 0;
}

//CRUD SALIDAS
Future<int> insertSalida(Map<String, dynamic> salida) async {
  final db = await database;
  return await db.insert('salidas', salida);
}

Future<List<Map<String, dynamic>>> getAllSalidas() async {
  final db = await database;
  return await db.query('salidas');
}

Future<int> deleteSalida(int id) async {
  final db = await database;
  return await db.delete('salidas', where: 'id = ?', whereArgs: [id]);
}

Future<int> getTotalSalidas() async {
  final db = await database;
  final result = await db.rawQuery('SELECT SUM(cantidad) as total FROM salidas');
  return Sqflite.firstIntValue(result) ?? 0;
}
Future<List<Map<String, dynamic>>> getEntradasByProducto(int productoId) async {
  final db = await database;
  return await db.query('entradas', where: 'producto_id = ?', whereArgs: [productoId]);
}

Future<List<Map<String, dynamic>>> getSalidasByProducto(int productoId) async {
  final db = await database;
  return await db.query('salidas', where: 'producto_id = ?', whereArgs: [productoId]);
}

//CRUR CONFIGURACION
 Future<void> insertConfiguracion(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'configuracion',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace, // Para reemplazar en caso de duplicados
    );
  }

  Future<Map<String, dynamic>> getConfiguracion() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('configuracion');
    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return {}; // Retorna un mapa vacío si no hay configuración
    }
  }
Future<int> updateConfiguracion(int id, Map<String, dynamic> data) async {
  final db = await database;
  return await db.update(
    'configuracion',
    data,
    where: 'id = ?',
    whereArgs: [id],
  );
}
Future<int> deleteConfiguracion(int id) async {
  final db = await database;
  return await db.delete(
    'configuracion',
    where: 'id = ?',
    whereArgs: [id],
  );
}
//Fotos
Future<void> insertPhoto(Map<String, dynamic> photo) async {
  final db = await database;
  await db.insert('patient_photos', photo);
}

Future<List<Map<String, dynamic>>> getPhotosByPatient(int patientId) async {
  final db = await database;
  return await db.query(
    'patient_photos',
    where: 'patient_id = ?',
    whereArgs: [patientId],
    orderBy: 'date DESC',
  );
}

Future<void> deletePhoto(int id) async {
  final db = await database;
  await db.delete('patient_photos', where: 'id = ?', whereArgs: [id]);
}

Future<void> updatePhotoDescription(int id, String description) async {
  final db = await database;
  await db.update(
    'patient_photos',
    {'description': description},
    where: 'id = ?',
    whereArgs: [id],
  );
}


}