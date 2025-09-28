import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SignUpViewModel extends BaseViewModel {
  final NavigationService _navigationService = NavigationService();
  final DialogService _dialogService = DialogService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;
  DateTime? _selectedDate;

  bool get isPasswordVisible => _isPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;
  bool get isLoading => _isLoading;
  bool get acceptTerms => _acceptTerms;

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    notifyListeners();
  }

  void toggleAcceptTerms(bool? value) {
    _acceptTerms = value ?? false;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> selectDateOfBirth() async {
    final context = null;
    if (context == null) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate:
          DateTime.now().subtract(const Duration(days: 4380)), // 12 years ago
    );

    if (picked != null && picked != _selectedDate) {
      _selectedDate = picked;
      dobController.text =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      notifyListeners();
    }
  }

  Future<void> signUp() async {
    if (!_validateForm()) {
      return;
    }

    setLoading(true);

    try {
      // TODO: Implement actual signup logic with your backend
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      // Navigate to home page after successful signup
      _navigationService.clearStackAndShow('/home');
    } catch (e) {
      _showSnackBar('Signup failed. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  Future<void> signUpWithGoogle() async {
    setLoading(true);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        // TODO: Implement Google signup logic with your backend
        await Future.delayed(const Duration(seconds: 1)); // Simulate API call

        // Navigate to home page after successful signup
        _navigationService.clearStackAndShow('/home');
      }
    } catch (e) {
      _showSnackBar('Google signup failed. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  Future<void> signUpWithApple() async {
    setLoading(true);

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.userIdentifier!.isNotEmpty) {
        // TODO: Implement Apple signup logic with your backend
        await Future.delayed(const Duration(seconds: 1)); // Simulate API call

        // Navigate to home page after successful signup
        _navigationService.clearStackAndShow('/home');
      }
    } catch (e) {
      _showSnackBar('Apple signup failed. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  void navigateToLogin() {
    _navigationService.navigateTo('/login');
  }

  bool _validateForm() {
    if (nameController.text.trim().isEmpty) {
      _showSnackBar('Please enter your full name');
      return false;
    }

    if (_selectedDate == null) {
      _showSnackBar('Please select your date of birth');
      return false;
    }

    if (emailController.text.trim().isEmpty) {
      _showSnackBar('Please enter your email address');
      return false;
    }

    if (!_isValidEmail(emailController.text.trim())) {
      _showSnackBar('Please enter a valid email address');
      return false;
    }

    if (phoneController.text.trim().isEmpty) {
      _showSnackBar('Please enter your phone number');
      return false;
    }

    if (!_isValidPhone(phoneController.text.trim())) {
      _showSnackBar('Please enter a valid phone number');
      return false;
    }

    if (passwordController.text.isEmpty) {
      _showSnackBar('Please enter a password');
      return false;
    }

    if (passwordController.text.length < 6) {
      _showSnackBar('Password must be at least 6 characters long');
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showSnackBar('Passwords do not match');
      return false;
    }

    if (!_acceptTerms) {
      _showSnackBar('Please accept the terms and conditions');
      return false;
    }

    return true;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    // Basic phone validation - you can enhance this based on your requirements
    return RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phone);
  }

  void _showSnackBar(String message) {
    // _dialogService.showSnackbar(
    //   message: message,
    //   duration: const Duration(seconds: 3),
    // );
  }

  @override
  void dispose() {
    nameController.dispose();
    dobController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
