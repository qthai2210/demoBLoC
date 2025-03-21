import 'package:equatable/equatable.dart';
import 'package:demobloc/models/todo.dart';

abstract class TodosState extends Equatable {
  const TodosState();

  @override
  List<Object> get props => [];
}

class TodosInitial extends TodosState {}

class TodosLoading extends TodosState {}

class TodosLoaded extends TodosState {
  final List<Todo> todos;
  final String searchTerm;

  // Computed property to get filtered todos based on search term
  List<Todo> get filteredTodos =>
      searchTerm.isEmpty
          ? todos
          : todos
              .where(
                (todo) =>
                    todo.title.toLowerCase().contains(
                      searchTerm.toLowerCase(),
                    ) ||
                    todo.description.toLowerCase().contains(
                      searchTerm.toLowerCase(),
                    ),
              )
              .toList();

  const TodosLoaded(this.todos, {this.searchTerm = ''});

  @override
  List<Object> get props => [todos, searchTerm];
}

class TodosError extends TodosState {
  final String message;

  const TodosError(this.message);

  @override
  List<Object> get props => [message];
}
