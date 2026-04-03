import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/open_food_facts_service.dart';

final openFoodFactsProvider = Provider<OpenFoodFactsService>((ref) {
  final service = OpenFoodFactsService();
  service.init();
  return service;
});
