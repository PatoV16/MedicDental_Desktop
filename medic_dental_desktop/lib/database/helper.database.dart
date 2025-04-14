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
      onUpgrade: _onUpgrade,
    );
  }

  // Método para manejar actualizaciones de base de datos
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Añadir la tabla odontogramas si estamos actualizando de la versión 1 a la 2
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
    }
  }

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
    
    // Create Treatments table
    await db.execute('''
      CREATE TABLE treatments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        treatment_date TEXT NOT NULL,
        diagnosis TEXT,
        treatment TEXT,
        cost REAL,
        paid REAL,
        notes TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');
    
    // Create Inventory table
    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        quantity INTEGER NOT NULL,
        unit TEXT,
        cost REAL,
        supplier TEXT,
        reorder_level INTEGER,
        expiration_date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inventory_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        reason TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (inventory_id) REFERENCES inventory (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact TEXT,
        email TEXT,
        phone TEXT
      )
    ''');
    
    // Create Payments table
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        treatment_id INTEGER,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_method TEXT,
        notes TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE,
        FOREIGN KEY (treatment_id) REFERENCES treatments (id) ON DELETE CASCADE
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

  // INVENTORY CRUD OPERATIONS
  
  Future<int> insertInventoryItem(Map<String, dynamic> item) async {
    Database db = await database;
    return await db.insert('inventory', item);
  }

  Future<List<Map<String, dynamic>>> getAllInventory() async {
    Database db = await database;
    return await db.query('inventory', orderBy: 'name');
  }

  

  Future<int> updateInventoryItem(int id, Map<String, dynamic> item) async {
    Database db = await database;
    return await db.update(
      'inventory',
      item,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteInventoryItem(int id) async {
    Database db = await database;
    return await db.delete(
      'inventory',
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
  
  // Get total amount paid by a patient
  Future<double> getTotalPaidByPatient(int patientId) async {
    Database db = await database;
    var result = await db.rawQuery('''
      SELECT SUM(amount) as total_paid
      FROM payments
      WHERE patient_id = ?
    ''', [patientId]);
    
    return result.first['total_paid'] == null ? 0.0 : result.first['total_paid'] as double;
  }
  
  // Get patient balance (total treatment costs - payments)
  Future<double> getPatientBalance(int patientId) async {
    Database db = await database;
    
    var treatmentResult = await db.rawQuery('''
      SELECT SUM(cost) as total_cost
      FROM treatments
      WHERE patient_id = ?
    ''', [patientId]);
    
    var paymentResult = await db.rawQuery('''
      SELECT SUM(amount) as total_paid
      FROM payments
      WHERE patient_id = ?
    ''', [patientId]);
    
    double totalCost = treatmentResult.first['total_cost'] == null ? 
                        0.0 : treatmentResult.first['total_cost'] as double;
    double totalPaid = paymentResult.first['total_paid'] == null ? 
                       0.0 : paymentResult.first['total_paid'] as double;
    
    return totalCost - totalPaid;
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
//INVENTORY 
// Create
   Future<int> createInventoryItem(Map<String, dynamic> itemData) async {
    Database db = await database;
    return await db.insert('inventory', itemData);
  }

  // Read (single item)
  
  Future<Map<String, dynamic>?> getInventoryItem(int id) async {
    final db = await database;
    final result = await db.query(
      'inventory',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Read (all items)
  Future<List<Map<String, dynamic>>> getAllInventoryItems() async {
   Database db = await database;
    return await db.query('inventory');
  }

  // Read (items with low stock)
 
  // Update quantity (with movement record)
   Future<void> updateInventoryQuantity(
    int itemId, 
    int quantityChange, 
    String movementType, 
    String? reason,
  ) async {
    Database db = await database;
    
    await db.transaction((txn) async {
      // Update inventory quantity
      await txn.rawUpdate('''
        UPDATE inventory 
        SET quantity = quantity + ? 
        WHERE id = ?
      ''', [quantityChange, itemId]);

      // Record movement
      await txn.insert('inventory_movements', {
        'inventory_id': itemId,
        'type': movementType,
        'quantity': quantityChange.abs(),
        'reason': reason,
        'date': DateTime.now().toIso8601String(),
      });
    });
  }


  // INVENTORY MOVEMENTS
  Future<int> insertInventoryMovement(Map<String, dynamic> movement) async {
    Database db = await database;
    return await db.insert('inventory_movements', movement);
  }

  Future<List<Map<String, dynamic>>> getInventoryMovements(int inventoryId) async {
    Database db = await database;
    return await db.query(
      'inventory_movements',
      where: 'inventory_id = ?',
      whereArgs: [inventoryId],
      orderBy: 'date DESC',
    );
  }

  Future<void> registerInventoryMovement({
    required int inventoryId,
    required String type,
    required int quantity,
    required String reason,
  }) async {
    Database db = await database;

    await db.transaction((txn) async {
      var item = await txn.query(
        'inventory',
        where: 'id = ?',
        whereArgs: [inventoryId],
        limit: 1,
      );

      if (item.isEmpty) return;

      int currentQty = item.first['quantity'] as int;
      int newQty = type == 'entrada' ? currentQty + quantity : currentQty - quantity;

      await txn.update(
        'inventory',
        {'quantity': newQty},
        where: 'id = ?',
        whereArgs: [inventoryId],
      );

      await txn.insert('inventory_movements', {
        'inventory_id': inventoryId,
        'type': type,
        'quantity': quantity,
        'reason': reason,
        'date': DateTime.now().toIso8601String(),
      });
    });
  }
}