import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:demobloc/bloc/todos/todos_bloc.dart';
import 'package:demobloc/bloc/todos/todos_event.dart';
import 'package:demobloc/bloc/todos/todos_state.dart';
import 'package:demobloc/models/todo.dart';
import 'package:demobloc/screens/add_edit_todo_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:demobloc/bloc/authentication/authentication_bloc.dart';
import 'package:demobloc/bloc/authentication/authentication_event.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const TodosScreen());
  }

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  @override
  void initState() {
    super.initState();
    // Explicitly load todos when the screen appears
    Future.microtask(() => context.read<TodosBloc>().add(LoadTodos()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
        backgroundColor: const Color(0xFF009688),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              context.read<AuthenticationBloc>().add(
                AuthenticationLogoutRequested(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(),
          Expanded(
            child: BlocBuilder<TodosBloc, TodosState>(
              builder: (context, state) {
                // Add more debug output
                print('Current todos state: $state');

                if (state is TodosLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF009688),
                      ),
                    ),
                  );
                } else if (state is TodosLoaded) {
                  final todos = state.filteredTodos;
                  print('Loaded ${todos.length} todos'); // Debug output
                  return todos.isEmpty
                      ? _buildEmptyState(state.searchTerm.isNotEmpty)
                      : _buildTodosList(context, todos);
                } else if (state is TodosError) {
                  // Show error but also add a retry button
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${state.message}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<TodosBloc>().add(LoadTodos());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Always try to load if we're in an unknown state
                  Future.microtask(
                    () => context.read<TodosBloc>().add(LoadTodos()),
                  );
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF009688),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF009688),
        onPressed: () {
          Navigator.of(context).push(
            AddEditTodoScreen.route(
              onSave: (title, description) {
                context.read<TodosBloc>().add(
                  AddTodo(
                    Todo(
                      id: const Uuid().v4(),
                      title: title,
                      description: description,
                    ),
                  ),
                );
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.note_alt_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          Text(
            isSearching ? 'No matching todos found' : 'No todos yet',
            style: const TextStyle(fontSize: 20, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Text(
            isSearching
                ? 'Try a different search term'
                : 'Add your first todo by tapping the + button',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTodosList(BuildContext context, List<Todo> todos) {
    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return Dismissible(
          key: Key('todo_${todo.id}'),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            context.read<TodosBloc>().add(DeleteTodo(todo.id));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Todo deleted')));
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                todo.title,
                style: TextStyle(
                  decoration:
                      todo.isCompleted ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                todo.description,
                style: TextStyle(
                  decoration:
                      todo.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              leading: Checkbox(
                value: todo.isCompleted,
                activeColor: const Color(0xFF009688),
                onChanged: (_) {
                  // Dispatch the event to toggle completion
                  context.read<TodosBloc>().add(ToggleTodoCompletion(todo.id));
                },
              ),
              onTap: () {
                Navigator.of(context).push(
                  AddEditTodoScreen.route(
                    todo: todo,
                    onSave: (title, description) {
                      context.read<TodosBloc>().add(
                        UpdateTodo(
                          todo.copyWith(title: title, description: description),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _SearchBar extends StatefulWidget {
  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _textController,
        decoration: InputDecoration(
          hintText: 'Search todos...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _textController.clear();
              // Use the direct add method for clear to make it immediate
              context.read<TodosBloc>().add(const SearchTodos(''));
            },
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) {
          // Use the debounced method for user typing
          context.read<TodosBloc>().addSearchTerm(value);
        },
      ),
    );
  }
}
