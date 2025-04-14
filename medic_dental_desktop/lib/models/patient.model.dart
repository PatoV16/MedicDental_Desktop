class Patient {
  final int? id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? birthdate;
  final String? notes;
  final String createdAt;

  Patient({
    this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.birthdate,
    this.notes,
    required this.createdAt,
  });

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
      birthdate: map['birthdate'],
      notes: map['notes'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'birthdate': birthdate,
      'notes': notes,
      'created_at': createdAt,
    };
  }
}