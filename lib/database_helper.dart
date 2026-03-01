import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'task_model.dart';

class DatabaseHelper {
  // Singleton: un'unica istanza in tutta l'app
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Chiediamo il database: se esiste lo diamo, se no lo creiamo
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Troviamo la cartella sicura sul telefono
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Apriamo il DB (creandolo se è la prima volta)
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Qui scriviamo il linguaggio del database: l'SQL
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        dueDate TEXT,
        status INTEGER
      )
    ''');
  }

  // Funzione per salvare un task
  Future<void> insertTask(Task task) async {
    final db = await instance.database;
    await db.insert('tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Funzione per leggere tutti i task
  Future<List<Task>> readAllTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks');
    return result.map((json) => Task.fromMap(json)).toList();
  }

  // Funzione per aggiornare un task (es. cambio colore/stato)
  Future<int> updateTask(Task task) async {
    final db = await instance.database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await instance.database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

}