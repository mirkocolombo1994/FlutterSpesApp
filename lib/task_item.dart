import 'package:flutter/material.dart';
import 'task_model.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback? onStatusChanged; //per gestire cambio colore
  final VoidCallback? onTap; //per gestire click

  const TaskItem({super.key, required this.task, this.onStatusChanged, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Determiniamo il colore in base allo stato
    final Color statusColor = task.status == TaskStatus.done
        ? Colors.teal      // Il tuo Verde Smeraldo
        : Colors.indigo;   // Il tuo Blu Istituzionale

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: IconButton(
          icon: Icon(
            task.status == TaskStatus.done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: statusColor,
          ),
          onPressed: onStatusChanged,
        ),
        title: Text(
          task.title,
          style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
        ),
        subtitle: Text(task.description, maxLines: 1, overflow: TextOverflow.ellipsis),
        //trailing: const Icon(Icons.more_vert), // I tre puntini che volevi
        trailing: IconButton(
            onPressed: onTap,
            icon: Icon(
              Icons.more_vert,
            ),
        ), // I tre puntini che volevi
      ),
    );
  }
}