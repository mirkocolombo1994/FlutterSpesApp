import 'package:flutter_test/flutter_test.dart';
import 'package:task_master_app/spes_app/models/product.dart';

void main() {
  group('Product Model Tests', () {
    test('Should create a Product from Map correctly', () {
      final map = {
        'barcode': '123456',
        'name': 'Pasta Barilla',
        'brand': 'Barilla',
        'weight': 0.5,
        'weightUnit': 'kg',
        'category': 'Pasta',
        'imageUrl': 'path/to/image.png',
      };

      final product = Product.fromMap(map);

      expect(product.barcode, '123456');
      expect(product.name, 'Pasta Barilla');
      expect(product.weight, 0.5);
      expect(product.category, 'Pasta');
    });

    test('Should convert Product to Map correctly', () {
      const product = Product(
        barcode: '123456',
        name: 'Pasta Barilla',
        brand: 'Barilla',
        weight: 0.5,
        weightUnit: 'kg',
        category: 'Pasta',
      );

      final map = product.toMap();

      expect(map['barcode'], '123456');
      expect(map['name'], 'Pasta Barilla');
      expect(map['weight'], 0.5);
    });
  });
}
