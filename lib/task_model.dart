enum TaskStatus {todo, doing, done}

class Task {

  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  TaskStatus status;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.status = TaskStatus.todo
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'status': status.index,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: DateTime.parse(map['dueDate']),
      status: TaskStatus.values[map['status']],
    );
  }


}



