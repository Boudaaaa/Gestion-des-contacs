class Contact {
  int? id;
  String name;
  String phone;

  Contact({this.id, required this.name, required this.phone});

  factory Contact.fromMap(Map<String, dynamic> map) => Contact(
        id: map['id'] as int?,
        name: map['name'] as String,
        phone: map['phone'] as String,
      );

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'phone': phone,
    };
    if (id != null) map['id'] = id;
    return map;
  }
}
