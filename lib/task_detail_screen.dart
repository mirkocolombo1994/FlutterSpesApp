import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_master_app/task_provider.dart';
import 'task_model.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(task.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Description", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(task.description),
            const SizedBox(height: 20),
            Text("Due Date: ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}"),
            const Spacer(),
            // Tasto Elimina in fondo per sicurezza (come discusso)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50),
                onPressed: () {
                  final provider = Provider.of<TaskProvider>(context, listen: false);
                  provider.removeTask(task.id);
                  Navigator.pop(context);
                },
                child: Text("Delete Task", style: const TextStyle(color: Colors.red)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
