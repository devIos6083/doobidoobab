class Contact {
  final int? id;
  final String name;
  final String phoneNumber;
  final String position;
  final String department;
  final String? email;
  final String? profileImagePath;

  Contact({
    this.id,
    required this.name,
    required this.phoneNumber,
    required this.position,
    required this.department,
    this.email,
    this.profileImagePath,
  });

  // Convert a Contact into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'position': position,
      'department': department,
      'email': email,
      'profileImagePath': profileImagePath,
    };
  }

  // Create a Contact from a Map
  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'],
      name: map['name'],
      phoneNumber: map['phoneNumber'],
      position: map['position'],
      department: map['department'],
      email: map['email'],
      profileImagePath: map['profileImagePath'],
    );
  }

  // Create a copy of this Contact with the given fields replaced
  Contact copyWith({
    int? id,
    String? name,
    String? phoneNumber,
    String? position,
    String? department,
    String? email,
    String? profileImagePath,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      position: position ?? this.position,
      department: department ?? this.department,
      email: email ?? this.email,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}
