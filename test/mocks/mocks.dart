import 'package:mocktail/mocktail.dart';
import 'package:task_master_app/spes_app/models/product.dart';
import 'package:task_master_app/spes_app/models/store.dart';
import 'package:task_master_app/spes_app/models/price_history.dart';

// Fake classes per Mocktail (necessarie per argomenti tipizzati)
class FakeProduct extends Fake implements Product {}
class FakeStore extends Fake implements Store {}
class FakePriceHistory extends Fake implements PriceHistory {}

void registerTestMocks() {
  registerFallbackValue(FakeProduct());
  registerFallbackValue(FakeStore());
  registerFallbackValue(FakePriceHistory());
}
