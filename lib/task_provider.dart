import 'package:flutter/material.dart';
import 'package:task_master_app/database_helper.dart';
import 'task_model.dart';

class TaskProvider extends ChangeNotifier {
  // 1. Usa una lista vera, non un getter che ne crea una nuova ogni volta
  /*final List<Task> _myTasks = [
    Task(id: '1', title: 'Figma design', description: 'Try and use figma', dueDate: DateTime.now()),
    Task(id: '2', title: 'Flutter design', description: 'Try and use flutter', dueDate: DateTime.now()),
    Task(id: '3', title: 'React design', description: 'Try and use react', dueDate: DateTime.now()),
  ];*/
  List<Task> _myTasks = [];
  List<Task> get myTasks => _myTasks;

  String _searchText = '';

  // Aggiungiamo un costruttore che avvia subito il caricamento
  TaskProvider() {
    inizializzaDB();
  }

  List<Task> get filteredTasks => _searchText.isNotEmpty ? _myTasks.where((task) => task.title.toLowerCase().contains(_searchText.toLowerCase())).toList() : _myTasks;

  Future<void> inizializzaDB() async {
    _myTasks = await DatabaseHelper.instance.readAllTasks();
    notifyListeners();
  }

  Future<void> addTask(Task newTask) async {
    await DatabaseHelper.instance.insertTask(newTask);
    _myTasks.add(newTask);
    notifyListeners();
  }

  Future<void> toggleStatus(String id) async {
    // Cerchiamo l'indice del task nella lista
    int index = _myTasks.indexWhere((t) => t.id == id);

    if (index != -1) {
      Task oldTask = _myTasks[index];
      _myTasks[index] = Task(
        id: oldTask.id,
        title: oldTask.title,
        description: oldTask.description,
        dueDate: oldTask.dueDate,
        // Logica di switch: se è todo diventa complete, altrimenti todo
        status: oldTask.status == TaskStatus.todo ? TaskStatus.done : TaskStatus.todo,
      );

      await DatabaseHelper.instance.updateTask(_myTasks[index]);
      // In Dart, per attivare il refresh, spesso è meglio sostituire l'oggetto


      // QUESTO avvisa l'interfaccia di ridisegnarsi
      notifyListeners();
    }
  }

  Future<void> removeTask(String id) async {
    await DatabaseHelper.instance.deleteTask(id);
    _myTasks.removeWhere((task) => task.id == id);
    notifyListeners();
  }

  Future<void> filterTasks(String text) async {
    _searchText = text;
    notifyListeners();
  }
}