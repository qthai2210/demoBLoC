import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:demobloc/bloc/todos/todos_event.dart';
import 'package:demobloc/bloc/todos/todos_state.dart';
import 'package:demobloc/repositories/todo_repository.dart';
import 'package:demobloc/models/todo.dart';

class TodosBloc extends Bloc<TodosEvent, TodosState> {
  final TodoRepository _todoRepository;
  late StreamSubscription<List<Todo>> _todosSubscription;

  TodosBloc({required TodoRepository todoRepository})
    : _todoRepository = todoRepository,
      super(TodosInitial()) {
    on<LoadTodos>(_onLoadTodos);
    on<AddTodo>(_onAddTodo);
    on<UpdateTodo>(_onUpdateTodo);
    on<DeleteTodo>(_onDeleteTodo);
    on<ToggleTodoCompletion>(_onToggleTodoCompletion);
    on<SearchTodos>(_onSearchTodos); // Add handling for search

    // Initialize with current todos
    add(LoadTodos());

    // Listen for repository changes
    _todosSubscription = _todoRepository.todos.listen((todos) {
      // Only update if we're not in the middle of an operation
      if (state is! TodosLoading) {
        emit(TodosLoaded(todos));
      }
    });
  }

  @override
  Future<void> close() {
    _todosSubscription.cancel();
    _todoRepository.dispose();
    return super.close();
  }

  void _onLoadTodos(LoadTodos event, Emitter<TodosState> emit) async {
    emit(TodosLoading());
    try {
      // Reduced loading time to improve user experience
      await Future.delayed(const Duration(milliseconds: 100));
      final todos = await _todoRepository.todos.first;
      emit(TodosLoaded(todos));
    } catch (e) {
      emit(TodosError(e.toString()));
    }
  }

  void _onAddTodo(AddTodo event, Emitter<TodosState> emit) async {
    try {
      // Get current todos if available
      final currentTodos =
          state is TodosLoaded ? (state as TodosLoaded).todos : <Todo>[];

      // Optimistically update state with new todo
      emit(TodosLoaded([...currentTodos, event.todo]));

      // Actually save
      await _todoRepository.addTodo(event.todo);
    } catch (e) {
      emit(TodosError(e.toString()));
      // Reload todos on error to ensure consistency
      add(LoadTodos());
    }
  }

  void _onUpdateTodo(UpdateTodo event, Emitter<TodosState> emit) async {
    final state = this.state;
    if (state is TodosLoaded) {
      try {
        await _todoRepository.updateTodo(event.todo);
      } catch (e) {
        emit(TodosError(e.toString()));
      }
    }
  }

  void _onDeleteTodo(DeleteTodo event, Emitter<TodosState> emit) async {
    final state = this.state;
    if (state is TodosLoaded) {
      try {
        await _todoRepository.deleteTodo(event.id);
      } catch (e) {
        emit(TodosError(e.toString()));
      }
    }
  }

  void _onToggleTodoCompletion(
    ToggleTodoCompletion event,
    Emitter<TodosState> emit,
  ) async {
    final state = this.state;
    if (state is TodosLoaded) {
      try {
        // Optimistically update UI state first
        final List<Todo> updatedTodos =
            state.todos.map((todo) {
              if (todo.id == event.id) {
                return todo.copyWith(isCompleted: !todo.isCompleted);
              }
              return todo;
            }).toList();

        // Emit immediately with updated todos
        emit(TodosLoaded(updatedTodos));

        // Then update the repository
        await _todoRepository.toggleTodoCompletion(event.id);
      } catch (e) {
        emit(TodosError(e.toString()));
        // Reload todos on error to ensure consistency
        add(LoadTodos());
      }
    }
  }

  void _onSearchTodos(SearchTodos event, Emitter<TodosState> emit) {
    final state = this.state;
    if (state is TodosLoaded) {
      emit(TodosLoaded(state.todos, searchTerm: event.searchTerm));
    }
  }
}
