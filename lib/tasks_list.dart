import 'package:flutter/material.dart';
import 'package:task_master_app/widgets/add_task_bottom_sheet.dart';
import 'package:task_master_app/widgets/task_search_bar.dart';
import 'package:task_master_app/widgets/task_list_view.dart';

class TasksList extends StatelessWidget {
  const TasksList({super.key});

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AddTaskBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TaskSearchBar(),
      body: const TaskListView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
