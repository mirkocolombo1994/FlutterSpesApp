import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_master_app/spes_app/screens/current_shopping_screen.dart';
import 'package:task_master_app/spes_app/providers/cart_provider.dart';
import 'package:task_master_app/spes_app/providers/store_provider.dart';
import 'package:task_master_app/spes_app/providers/product_provider.dart';
import 'package:task_master_app/spes_app/models/store.dart';
import 'package:task_master_app/spes_app/models/product.dart';
import 'package:task_master_app/spes_app/constants/app_strings.dart';
import '../mocks/mocks.dart';


// Notifiers per i test
class TestCartNotifier extends CartNotifier {
  final List<CartItem> initialState;
  TestCartNotifier(this.initialState);
  @override
  List<CartItem> build() => initialState;
}

class TestStoreNotifier extends StoreNotifier {
  @override
  List<Store> build() => [];
}

class TestProductNotifier extends ProductNotifier {
  @override
  List<Product> build() => [];
}

class TestActiveStoreNotifier extends ActiveStoreNotifier {
  final String? initialId;
  TestActiveStoreNotifier(this.initialId);
  @override
  String? build() => initialId;
}

void main() {
  setUpAll(() {
    registerTestMocks();
  });

  Widget createTestableWidget({List<CartItem> items = const []}) {
    return ProviderScope(
      overrides: [
        activeStoreIdProvider.overrideWith(() => TestActiveStoreNotifier('1')),
        storeProvider.overrideWith(TestStoreNotifier.new),
        productProvider.overrideWith(TestProductNotifier.new),
        cartProvider.overrideWith(() => TestCartNotifier(items)),
      ],
      child: const MaterialApp(
        home: Scaffold(body: CurrentShoppingScreen()),
      ),
    );
  }

  testWidgets('CurrentShoppingScreen should show empty message when cart is empty', (tester) async {
    await tester.pumpWidget(createTestableWidget(items: []));


    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.emptyCart), findsOneWidget);
  });

  testWidgets('CurrentShoppingScreen should show product if cart not empty', (tester) async {
    final items = [
      CartItem(id: '1', barcode: '123', name: 'Pasta', price: 1.50)
    ];

    await tester.pumpWidget(createTestableWidget(items: items));


    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verifichiamo la presenza del testo 'Pasta'
    expect(find.text('Pasta'), findsOneWidget);
  });
}
