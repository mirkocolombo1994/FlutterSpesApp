import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_master_app/task_provider.dart';
import 'package:task_master_app/widgets/task_item.dart';
import 'package:task_master_app/task_detail_screen.dart';

class TaskListView extends StatelessWidget {
  const TaskListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        return ListView.builder(
          itemCount: provider.filteredTasks.length,
          itemBuilder: (context, index) {
            final task = provider.filteredTasks[index];
            return Dismissible(
              direction: DismissDirection.startToEnd,
              key: Key(task.id),
              onDismissed: (direction) {
                final deletedTask = task;
                provider.removeTask(task.id);
                // Pulisce gli snackbar in coda in modo che mostri subito quello attuale
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 5),
                    content: Text("Task ${deletedTask.title} deleted"),
                    action: SnackBarAction(
                      label: "Undo",
                      onPressed: () {
                        provider.addTask(deletedTask);
                      },
                      textColor: Colors.white,
                    ),
                  ),
                );
              },
              background: Container(
                color: Colors.red.shade300,
                alignment: Alignment.centerLeft,
                child: const Icon(Icons.delete),
              ),
              child: TaskItem(
                task: task,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TaskDetailScreen(task: task)),
                  );
                },
                onStatusChanged: () {
                  provider.toggleStatus(task.id);
                },
              ),
            );
          },
        );
      },
    );
  }
}
