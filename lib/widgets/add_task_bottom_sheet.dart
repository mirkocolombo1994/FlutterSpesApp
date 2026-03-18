import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_master_app/task_model.dart';
import 'package:task_master_app/task_provider.dart';
import 'package:uuid/uuid.dart';

class AddTaskBottomSheet extends StatefulWidget {
  const AddTaskBottomSheet({super.key});

  @override
  State<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  void _clearController() {
    _titleController.clear();
    _descriptionController.clear();
    _dueDateController.clear();
  }

  void _addNewTask() {
    if (_titleController.text.isEmpty || _dueDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Title and due date is mandatory"),
        ),
      );
      return;
    }
    final provider = Provider.of<TaskProvider>(context, listen: false);
    var uuid = const Uuid();
    String uniqueId = uuid.v4();
    provider.addTask(Task(
      id: uniqueId,
      title: _titleController.text,
      description: _descriptionController.text,
      dueDate: _selectedDate,
      status: TaskStatus.todo,
    ));
    setState(() {
      _selectedDate = DateTime.now();
    });
    _clearController();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Add new task", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              labelText: "title",
            ),
            controller: _titleController,
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              labelText: "description",
            ),
            controller: _descriptionController,
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              labelText: "due date",
            ),
            controller: _dueDateController,
            readOnly: true,
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2099),
              );
              if (pickedDate != null) {
                setState(() {
                  _selectedDate = pickedDate;
                  _dueDateController.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                });
              }
            }
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _addNewTask,
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
