import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_master_app/spes_app/providers/cart_provider.dart';
import '../mocks/mocks.dart';

void main() {
  setUpAll(() {
    registerTestMocks();
  });

  group('CartNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Should add item to cart correctly', () {
      final item = CartItem(id: '1', barcode: '111', name: 'Test Product', price: 2.50);
      
      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(item);

      final state = container.read(cartProvider);
      expect(state.length, 1);
      expect(state[0].name, 'Test Product');
      expect(state[0].price, 2.50);
    });

    test('Should remove item from cart', () {
      final item = CartItem(id: '1', barcode: '111', name: 'Test Product', price: 2.50);
      final notifier = container.read(cartProvider.notifier);
      
      notifier.addItem(item);
      expect(container.read(cartProvider).length, 1);

      notifier.removeItem('1');
      expect(container.read(cartProvider), isEmpty);
    });

    test('Should clear cart and reset current store', () {
      final item = CartItem(id: '1', barcode: '111', name: 'Test Product', price: 2.50);
      final notifier = container.read(cartProvider.notifier);
      
      notifier.addItem(item);
      notifier.clear();
      
      expect(container.read(cartProvider), isEmpty);
    });
  });
}
