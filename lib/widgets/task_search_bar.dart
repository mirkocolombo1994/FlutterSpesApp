import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_master_app/task_provider.dart';

class TaskSearchBar extends StatefulWidget implements PreferredSizeWidget {
  const TaskSearchBar({super.key});

  @override
  State<TaskSearchBar> createState() => _TaskSearchBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TaskSearchBarState extends State<TaskSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: _isSearching
          ? TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                hintText: "Search Task",
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (text) {
                Provider.of<TaskProvider>(context, listen: false).filterTasks(text);
              },
            )
          : const Text("Tasks List"),
      actions: _isSearching
          ? [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _isSearching = false;
                    Provider.of<TaskProvider>(context, listen: false).filterTasks('');
                  });
                },
              ),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                  _focusNode.requestFocus();
                },
              )
            ],
    );
  }
}
