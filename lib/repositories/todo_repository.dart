import 'dart:async';
import 'package:demobloc/models/todo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TodoRepository {
  final List<Todo> _todos = [];
  final _controller = StreamController<List<Todo>>.broadcast();
  bool _isInitialized = false;

  Stream<List<Todo>> get todos async* {
    // Make sure we're initialized
    if (!_isInitialized) {
      await _loadTodos();
      _isInitialized = true;
    }
    // Return current todos immediately
    yield _todos;
    // Then listen for future updates
    yield* _controller.stream;
  }

  Future<void> _loadTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todosJson = prefs.getStringList('todos') ?? [];

      _todos.clear();
      for (final todoJson in todosJson) {
        final todoMap = jsonDecode(todoJson);
        _todos.add(
          Todo(
            id: todoMap['id'],
            title: todoMap['title'],
            description: todoMap['description'],
            isCompleted: todoMap['isCompleted'],
          ),
        );
      }
      _controller.add(_todos);
      print('Loaded ${_todos.length} todos from storage');
    } catch (e) {
      print('Error loading todos: $e');
      // Don't throw, just add an empty list
      _controller.add([]);
    }
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todosJson =
        _todos
            .map(
              (todo) => jsonEncode({
                'id': todo.id,
                'title': todo.title,
                'description': todo.description,
                'isCompleted': todo.isCompleted,
              }),
            )
            .toList();

    await prefs.setStringList('todos', todosJson);
    _controller.add(_todos);
  }

  Future<void> addTodo(Todo todo) async {
    _todos.add(todo);
    await _saveTodos();
  }

  Future<void> updateTodo(Todo todo) async {
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      _todos[index] = todo;
      await _saveTodos();
    }
  }

  Future<void> deleteTodo(String id) async {
    _todos.removeWhere((todo) => todo.id == id);
    await _saveTodos();
  }

  Future<void> toggleTodoCompletion(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = _todos[index];
      _todos[index] = todo.copyWith(isCompleted: !todo.isCompleted);
      await _saveTodos();
    }
  }

  Future<List<Todo>> getTodos() async {
    if (!_isInitialized) {
      await _loadTodos();
      _isInitialized = true;
    }
    return List.from(_todos);
  }

  void dispose() {
    _controller.close();
  }
}
