import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wallet/core/services/service_providers.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthController(this._ref) : super(AuthState());

  bool login(String pin, bool enableAutoLogin) {
    state = state.copyWith(isLoading: true);
    
    final storageService = _ref.read(storageServiceProvider);
    final isValid = storageService.verifyPin(pin);

    if (isValid) {
      storageService.setAutoLoginEnabled(enableAutoLogin);
      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: 'wrong_pin',
      );
      return false;
    }
  }

  void logout() {
    final storageService = _ref.read(storageServiceProvider);
    storageService.setAutoLoginEnabled(false);
    state = AuthState();
  }

  bool isUserAutoLoggedIn() {
    final storageService = _ref.read(storageServiceProvider);
    return storageService.isAutoLoginEnabled();
  }

  Future<void> changePassword(String newPin) async {
    final storageService = _ref.read(storageServiceProvider);
    await storageService.setPin(newPin);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});
