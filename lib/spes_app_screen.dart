import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'spes_app/providers/cart_provider.dart';
import 'spes_app/screens/shopping_lists_screen.dart';
import 'spes_app/screens/products_screen.dart';
import 'spes_app/screens/stores_screen.dart';
import 'spes_app/screens/price_history_screen.dart';
import 'spes_app/screens/current_shopping_screen.dart';
import 'spes_app/screens/categories_screen.dart';
import 'spes_app/screens/settings_screen.dart';
import 'spes_app/constants/app_strings.dart';

/// Schermata principale dell'applicazione SpesApp.
/// Gestisce la navigazione tramite BottomNavigationBar per le sezioni principali
/// e un Drawer laterale per le sezioni di gestione secondarie.
class SpesAppScreen extends StatefulWidget {
  const SpesAppScreen({super.key});

  @override
  State<SpesAppScreen> createState() => _SpesAppScreenState();
}

class _SpesAppScreenState extends State<SpesAppScreen> {
  int _currentIndex = 0;
  
  // Lista delle pagine accessibili dalla barra di navigazione inferiore
  final List<Widget> _pages = const [
    CurrentShoppingScreen(), // La "Cassa" per la spesa in corso
    ShoppingListsScreen(),   // Le liste della spesa create dall'utente
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final cartItems = ref.watch(cartProvider);
        
        return Scaffold(
          // AppBar che mostra il titolo in base alla pagina selezionata
          appBar: AppBar(
            automaticallyImplyLeading: false, // Nasconde la freccia indietro automatica
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: Text(_currentIndex == 0 ? AppStrings.currentShopping : AppStrings.shoppingLists),
            actions: [
              if (_currentIndex == 0 && cartItems.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () {
                    ref.read(cartProvider.notifier).clear();
                  },
                  tooltip: AppStrings.clearCartTooltip,
                )
            ],
          ),
          // Menu laterale a scomparsa per le opzioni di gestione
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
                          AppStrings.drawerMenuTitle,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.inventory_2,
                  title: AppStrings.navProdotti,
                  onTap: () => _navigateTo(const ProductsScreen()),
                ),
                _buildDrawerItem(
                  icon: Icons.storefront,
                  title: AppStrings.navPuntiVendita,
                  onTap: () => _navigateTo(const StoresScreen()),
                ),
                _buildDrawerItem(
                  icon: Icons.history,
                  title: AppStrings.navStorico,
                  onTap: () => _navigateTo(const PriceHistoryScreen()),
                ),
                _buildDrawerItem(
                  icon: Icons.category,
                  title: AppStrings.navCategorie,
                  onTap: () => _navigateTo(const CategoriesScreen()),
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: AppStrings.navImpostazioni,
                  onTap: () => _navigateTo(const SettingsScreen()),
                ),
                _buildDrawerItem(
                  icon: Icons.home,
                  title: AppStrings.navHomePrincipale,
                  onTap: () {
                    Navigator.pop(context); // Chiude drawer
                    Navigator.pop(context); // Torna alla HomeScreen principale
                  },
                ),
              ],
            ),
          ),
          body: _pages[_currentIndex],
          // Barra di navigazione inferiore semplificata con solo 2 icone
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
                label: AppStrings.navCassa,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long),
                label: AppStrings.navListe,
              ),
            ],
          ),
        );
      }
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
