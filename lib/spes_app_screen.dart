import 'package:flutter/material.dart';
import 'spes_app/screens/shopping_lists_screen.dart';
import 'spes_app/screens/products_screen.dart';
import 'spes_app/screens/stores_screen.dart';
import 'spes_app/screens/price_history_screen.dart';

class SpesAppScreen extends StatefulWidget {
  const SpesAppScreen({super.key});

  @override
  State<SpesAppScreen> createState() => _SpesAppScreenState();
}

class _SpesAppScreenState extends State<SpesAppScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = const [
    ShoppingListsScreen(),
    ProductsScreen(),
    StoresScreen(),
    PriceHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Liste',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Prodotti',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'Punti Vendita',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Storico',
          ),
        ],
      ),
    );
  }
}
