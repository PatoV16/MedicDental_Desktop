class RecaudoDiario {
  int? id;
  double recaudoDiario;
  String fechaCobro;
  String nombreCliente;
  String concepto;

  RecaudoDiario({
    this.id,
    required this.recaudoDiario,
    required this.fechaCobro,
    required this.nombreCliente,
    required this.concepto,
  });

  // Convertir desde un Map (registro de la base de datos)
  factory RecaudoDiario.fromMap(Map<String, dynamic> map) {
    return RecaudoDiario(
      id: map['Id'],
      recaudoDiario: map['RecaudoDiario'],
      fechaCobro: map['FechaCobro'],
      nombreCliente: map['NombreCliente'],
      concepto: map['Concepto'],
    );
  }

  // Convertir a Map (para insertar o actualizar)
  Map<String, dynamic> toMap() {
    return {
      'Id': id,
      'RecaudoDiario': recaudoDiario,
      'FechaCobro': fechaCobro,
      'NombreCliente': nombreCliente,
      'Concepto': concepto,
    };
  }
}
