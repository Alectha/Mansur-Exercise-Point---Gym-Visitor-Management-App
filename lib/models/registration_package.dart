class RegistrationPackage {
  final int? id;
  final String name;
  final int price;

  RegistrationPackage({
    this.id,
    required this.name,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
    };
  }

  factory RegistrationPackage.fromMap(Map<String, dynamic> map) {
    return RegistrationPackage(
      id: map['id'],
      name: map['name'],
      price: map['price'],
    );
  }
}
