import 'package:flutter/material.dart';

class SpesAppScreen extends StatelessWidget {
  const SpesAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SpesApp'),
      ),
      body: const Center(
        child: Text(
          'Benvenuto in SpesApp',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
