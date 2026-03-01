import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_master_app/task_provider.dart';
import 'package:task_master_app/tasks_list.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => TaskProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Master',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo.shade100),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo.shade100,
        ),
      ),
      home: const TasksList(),
    );
  }
}
