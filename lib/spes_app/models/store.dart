class Store {
  final String id;
  final String name;
  final String? chain;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final bool isClosed;

  Store({
    required this.id,
    required this.name,
    this.chain,
    this.phone,
    this.latitude,
    this.longitude,
    this.isClosed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'chain': chain,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'is_closed': isClosed ? 1 : 0,
    };
  }

  factory Store.fromMap(Map<String, dynamic> map) {
    bool parsedIsClosed = false;
    if (map['is_closed'] != null) {
      if (map['is_closed'] is int) {
        parsedIsClosed = map['is_closed'] == 1;
      } else if (map['is_closed'] is bool) {
        parsedIsClosed = map['is_closed'] as bool;
      }
    }

    return Store(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Sconosciuto',
      chain: map['chain']?.toString(),
      phone: map['phone']?.toString(),
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      isClosed: parsedIsClosed,
    );
  }
}

