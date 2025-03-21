import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:demobloc/bloc/todos/todos_event.dart';
import 'package:demobloc/bloc/todos/todos_state.dart';
import 'package:demobloc/repositories/todo_repository.dart';
import 'package:demobloc/models/todo.dart';
import 'package:rxdart/rxdart.dart';

class TodosBloc extends Bloc<TodosEvent, TodosState> {
  final TodoRepository _todoRepository;
  final _searchTerms = BehaviorSubject<String>();

  TodosBloc({required TodoRepository todoRepository})
    : _todoRepository = todoRepository,
      super(TodosLoading()) {
    // Start with loading state

    on<LoadTodos>(_onLoadTodos);
    on<AddTodo>(_onAddTodo);
    on<UpdateTodo>(_onUpdateTodo);
    on<DeleteTodo>(_onDeleteTodo);
    on<ToggleTodoCompletion>(_onToggleTodoCompletion);
    on<SearchTodos>(_onSearchTodos);

    // Set up debounced search
    _searchTerms
        .debounceTime(const Duration(milliseconds: 300))
        .distinct()
        .listen((term) => add(SearchTodos(term)));

    // Load todos immediately
    _loadTodos();
  }

  // Private method to load todos without event
  Future<void> _loadTodos() async {
    try {
      final todos = await _todoRepository.getTodos();
      emit(TodosLoaded(todos));
    } catch (e) {
      print('Error in _loadTodos: $e');
      emit(TodosError('Failed to load todos: $e'));
    }
  }

  void _onLoadTodos(LoadTodos event, Emitter<TodosState> emit) async {
    emit(TodosLoading());
    try {
      final todos = await _todoRepository.getTodos();
      emit(TodosLoaded(todos));
    } catch (e) {
      print('Error in _onLoadTodos: $e');
      emit(TodosError('Failed to load todos: $e'));
    }
  }

  // Add search term to the BehaviorSubject
  void addSearchTerm(String term) {
    _searchTerms.add(term);
  }

  @override
  Future<void> close() {
    _searchTerms.close();
    return super.close();
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
