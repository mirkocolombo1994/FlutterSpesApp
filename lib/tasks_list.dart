import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_master_app/task_detail_screen.dart';
import 'package:task_master_app/task_item.dart';
import 'package:task_master_app/task_model.dart';
import 'package:task_master_app/task_provider.dart';
import 'package:uuid/uuid.dart';

class TasksList extends StatefulWidget {
  const TasksList({super.key});

  @override
  State<TasksList> createState() => _TasksListState();
}

class _TasksListState extends State<TasksList> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final FocusNode _focusNode = FocusNode();

  DateTime _selectedDate = DateTime.now();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          title: _isSearching ?
          TextField(
            controller: _searchController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: "Search Task",
              prefixIcon: const Icon(Icons.search),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (text) {
              Provider.of<TaskProvider>(context, listen: false).filterTasks(text);
            },
          ):
          Text("Tasks List"),
          actions: _isSearching ?
          [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _isSearching = false;
                  Provider.of<TaskProvider>(context, listen: false).filterTasks('');
                });
              }
            ),
          ]:
          [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                  });
                _focusNode.requestFocus();
              }
            )
          ],
        ),
        body: Consumer<TaskProvider>(
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
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
                      // Chiami il metodo del provider, non modifichi il task qui!
                      provider.toggleStatus(task.id);
                    },
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddTaskSheet();
            /*final provider = Provider.of<TaskProvider>(context, listen: false);
            var uuid = const Uuid();
            String uniqueId = uuid.v4(); // Genera qualcosa come: "f47ac10b-58cc-4372-a567-0e02b2c3d479"
            provider.addTask(Task(
              id: uniqueId,
              title: 'New task created on ${DateTime.now().second}',
              description: 'Try add task to db',
              dueDate: DateTime.now(),
              status: TaskStatus.todo,
            ));*/
          },
          child: const Icon(Icons.add),
        )
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    _dueDateController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void clearController() {
    _titleController.clear();
    _descriptionController.clear();
    _dueDateController.clear();
    _searchController.clear();
    _focusNode.unfocus();
  }

  void _showAddTaskSheet() {

    showModalBottomSheet(
        context: context,
        isScrollControlled: true, // Fondamentale per la tastiera!
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20)
          ),
        ),
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20, // Alza il pannello
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Add new task", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: "title",
                ),
                controller: _titleController,
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: "description",
                ),
                controller: _descriptionController,
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
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
                child: Text("Save"),
              ),
            ],
          ),

        ),

    );
  }

  void _addNewTask() {
    if (_titleController.text.isEmpty || _dueDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
    _selectedDate = DateTime.now();
    clearController();
    Navigator.pop(context);
  }

}
