enum ShoppingListType { classic, superisparmio, mix }

class ShoppingList {
  final String id;
  final String name;
  final ShoppingListType type;
  final String? storeId; // Nullable: used for CLASSIC to lock the store
  final DateTime createdAt;

  ShoppingList({
    required this.id,
    required this.name,
    required this.type,
    this.storeId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'store_id': storeId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    return ShoppingList(
      id: map['id'],
      name: map['name'],
      type: ShoppingListType.values.byName(map['type']),
      storeId: map['store_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
