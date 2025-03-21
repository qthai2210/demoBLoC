import 'package:equatable/equatable.dart';
import 'package:demobloc/models/todo.dart';

abstract class TodosEvent extends Equatable {
  const TodosEvent();

  @override
  List<Object> get props => [];
}

class LoadTodos extends TodosEvent {}

class AddTodo extends TodosEvent {
  final Todo todo;

  const AddTodo(this.todo);

  @override
  List<Object> get props => [todo];
}

class UpdateTodo extends TodosEvent {
  final Todo todo;

  const UpdateTodo(this.todo);

  @override
  List<Object> get props => [todo];
}

class DeleteTodo extends TodosEvent {
  final String id;

  const DeleteTodo(this.id);

  @override
  List<Object> get props => [id];
}

class ToggleTodoCompletion extends TodosEvent {
  final String id;

  const ToggleTodoCompletion(this.id);

  @override
  List<Object> get props => [id];
}

class SearchTodos extends TodosEvent {
  final String searchTerm;

  const SearchTodos(this.searchTerm);

  @override
  List<Object> get props => [searchTerm];
}
