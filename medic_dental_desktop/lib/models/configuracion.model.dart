class Configuracion {
  int? id;
  String ruc;
  String nombre_Empresa;
  String? direccion;
  String? telefono;
  String? logo;
  String? email;
  String? website;
  String? fechaCreacion;

  Configuracion({
    this.id,
    required this.ruc,
    required this.nombre_Empresa,
    this.direccion,
    this.telefono,
    this.logo,
    this.email,
    this.website,
    this.fechaCreacion,
  });

  // Convertir de Map (de la base de datos) a objeto
  factory Configuracion.fromMap(Map<String, dynamic> map) {
    return Configuracion(
      id: map['id'],
      ruc: map['ruc'],
      nombre_Empresa: map['nombre_empresa'],
      direccion: map['direccion'],
      telefono: map['telefono'],
      logo: map['logo'],
      email: map['email'],
      website: map['website'],
      fechaCreacion: map['fecha_creacion'],
    );
  }

  // Convertir de objeto a Map (para insertar o actualizar en la base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ruc': ruc,
      'nombre_empresa': nombre_Empresa,
      'direccion': direccion,
      'telefono': telefono,
      'logo': logo,
      'email': email,
      'website': website,
      'fecha_creacion': fechaCreacion,
    };
  }
}
