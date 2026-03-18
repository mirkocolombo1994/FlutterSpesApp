import 'package:flutter/material.dart';
import 'package:task_master_app/tasks_list.dart';
import 'package:task_master_app/spes_app_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scegli Funzione'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 4,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              leading: const Icon(Icons.list_alt, size: 40, color: Colors.indigo),
              title: const Text(
                'Lista Task',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Gestisci i tuoi task giornalieri'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TasksList()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              leading: const Icon(Icons.shopping_cart, size: 40, color: Colors.indigo),
              title: const Text(
                'SpesApp',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Gestione della spesa'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SpesAppScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
