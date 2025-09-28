import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginViewModel extends BaseViewModel {
  final NavigationService _navigationService = NavigationService();
  final DialogService _dialogService = DialogService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  bool get isPasswordVisible => _isPasswordVisible;
  bool get isLoading => _isLoading;

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    if (!_isValidEmail(emailController.text)) {
      _showSnackBar('Please enter a valid email address');
      return;
    }

    setLoading(true);

    try {
      // TODO: Implement actual login logic with your backend
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      // Navigate to home page after successful login
      _navigationService.clearStackAndShow('/home');
    } catch (e) {
      _showSnackBar('Login failed. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    setLoading(true);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        // TODO: Implement Google sign-in logic with your backend
        await Future.delayed(const Duration(seconds: 1)); // Simulate API call

        // Navigate to home page after successful login
        _navigationService.clearStackAndShow('/home');
      }
    } catch (e) {
      _showSnackBar('Google sign-in failed. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  Future<void> signInWithApple() async {
    setLoading(true);

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.userIdentifier!.isNotEmpty) {
        // TODO: Implement Apple sign-in logic with your backend
        await Future.delayed(const Duration(seconds: 1)); // Simulate API call

        // Navigate to home page after successful login
        _navigationService.clearStackAndShow('/home');
      }
    } catch (e) {
      _showSnackBar('Apple sign-in failed. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  void forgotPassword() {
    // TODO: Implement forgot password functionality
    _showSnackBar('Forgot password functionality coming soon!');
  }

  void navigateToSignUp() {
    _navigationService.navigateTo('/sign-up');
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showSnackBar(String message) {
    // _dialogService.showSnackbar(
    //   message: message,
    //   duration: const Duration(seconds: 3),
    // );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
