import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:demobloc/bloc/authentication/authentication_bloc.dart';
import 'package:demobloc/bloc/authentication/authentication_state.dart';
import 'package:demobloc/repositories/authentication_repository.dart';
import 'package:demobloc/screens/home_screen.dart';
import 'package:demobloc/screens/login_screen.dart';
import 'package:demobloc/repositories/todo_repository.dart';
import 'package:demobloc/bloc/todos/todos_bloc.dart';
import 'package:demobloc/screens/todos_screen.dart';

void main() async {
  // Ensure Flutter binding is initialized before accessing platform services
  WidgetsFlutterBinding.ensureInitialized();

  final authenticationRepository = AuthenticationRepository();
  final todoRepository = TodoRepository();

  runApp(
    MyApp(
      authenticationRepository: authenticationRepository,
      todoRepository: todoRepository,
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.authenticationRepository,
    required this.todoRepository,
  });

  final AuthenticationRepository authenticationRepository;
  final TodoRepository todoRepository;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthenticationBloc _authenticationBloc;
  late final TodosBloc _todosBloc;

  @override
  void initState() {
    super.initState();
    _authenticationBloc = AuthenticationBloc(
      authenticationRepository: widget.authenticationRepository,
    );
    _todosBloc = TodosBloc(todoRepository: widget.todoRepository);
  }

  @override
  void dispose() {
    _authenticationBloc.close();
    _todosBloc.close();
    widget.authenticationRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.authenticationRepository),
        RepositoryProvider.value(value: widget.todoRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authenticationBloc),
          BlocProvider.value(value: _todosBloc),
        ],
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState get _navigator => _navigatorKey.currentState!;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'BLoC Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6A1B9A)),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return BlocListener<AuthenticationBloc, AuthenticationState>(
          listener: (context, state) {
            switch (state.status) {
              case AuthenticationStatus.authenticated:
                // Navigate directly to TodosScreen instead of HomeScreen
                _navigator.pushAndRemoveUntil<void>(
                  TodosScreen.route(),
                  (route) => false,
                );
                break;
              case AuthenticationStatus.unauthenticated:
                _navigator.pushAndRemoveUntil<void>(
                  LoginScreen.route(),
                  (route) => false,
                );
                break;
              case AuthenticationStatus.unknown:
                break;
            }
          },
          child: child,
        );
      },
      home: const SplashScreen(),
      onGenerateRoute: (_) => SplashScreen.route(),
    );
  }
}

// Add a simple splash screen
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const SplashScreen());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
