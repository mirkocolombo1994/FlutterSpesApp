/// Rappresenta una categoria di prodotti (es. "Pasta", "Detersivi")
class Category {
  final String id;
  final String name;

  Category({
    required this.id,
    required this.name,
  });

  /// Converte l'oggetto in una mappa per il salvataggio nel database SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  /// Crea un oggetto Category a partire da una mappa letta dal database
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
    );
  }
}
