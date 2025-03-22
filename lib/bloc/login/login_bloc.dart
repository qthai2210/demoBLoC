import 'package:bloc/bloc.dart';
import 'package:demobloc/bloc/login/login_event.dart';
import 'package:demobloc/bloc/login/login_state.dart';
import 'package:demobloc/repositories/authentication_repository.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required AuthenticationRepository authenticationRepository})
    : _authenticationRepository = authenticationRepository,
      super(const LoginState()) {
    on<LoginUsernameChanged>(_onUsernameChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginSubmitted>(_onSubmitted);
  }

  final AuthenticationRepository _authenticationRepository;

  void _onUsernameChanged(
    LoginUsernameChanged event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(username: event.username));
  }

  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(password: event.password));
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (state.username.isEmpty || state.password.isEmpty) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: 'Username and password cannot be empty',
        ),
      );
      return;
    }

    // Reset any previous error and set loading state
    emit(
      state.copyWith(
        status: LoginStatus.loading,
        errorMessage: '', // Clear previous error message
      ),
    );

    try {
      await _authenticationRepository.logIn(
        username: state.username,
        password: state.password,
      );
      emit(state.copyWith(status: LoginStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
