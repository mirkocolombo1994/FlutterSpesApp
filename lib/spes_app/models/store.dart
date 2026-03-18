class Store {
  final String id;
  final String name;
  final String? chain;
  final String? phone;
  final double? latitude;
  final double? longitude;

  Store({
    required this.id,
    required this.name,
    this.chain,
    this.phone,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'chain': chain,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Store.fromMap(Map<String, dynamic> map) {
    return Store(
      id: map['id'],
      name: map['name'],
      chain: map['chain'],
      phone: map['phone'],
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }
}
