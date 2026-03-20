import 'package:flutter/material.dart';
import 'spes_app/screens/shopping_lists_screen.dart';
import 'spes_app/screens/products_screen.dart';
import 'spes_app/screens/stores_screen.dart';
import 'spes_app/screens/price_history_screen.dart';
import 'spes_app/screens/current_shopping_screen.dart';
import 'spes_app/screens/categories_screen.dart';

class SpesAppScreen extends StatefulWidget {
  const SpesAppScreen({super.key});

  @override
  State<SpesAppScreen> createState() => _SpesAppScreenState();
}

class _SpesAppScreenState extends State<SpesAppScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = const [
    CurrentShoppingScreen(),
    ShoppingListsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Spesa in Corso' : 'Liste Spesa'),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.indigo.shade100,
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_basket, size: 50, color: Colors.indigo),
                    SizedBox(height: 10),
                    Text(
                      'SpesApp Menu',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                  ],
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.inventory_2,
              title: 'Prodotti',
              onTap: () => _navigateTo(const ProductsScreen()),
            ),
            _buildDrawerItem(
              icon: Icons.storefront,
              title: 'Punti Vendita',
              onTap: () => _navigateTo(const StoresScreen()),
            ),
            _buildDrawerItem(
              icon: Icons.history,
              title: 'Storico Prezzi',
              onTap: () => _navigateTo(const PriceHistoryScreen()),
            ),
            _buildDrawerItem(
              icon: Icons.category,
              title: 'Categorie',
              onTap: () => _navigateTo(const CategoriesScreen()),
            ),
          ],
        ),
      ),
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
            icon: Icon(Icons.shopping_cart),
            label: 'Cassa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Liste',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.pop(context); // Chiude il drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}
