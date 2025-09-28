import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';

class LoginViewModel extends BaseViewModel {
  final NavigationService _navService = locator<NavigationService>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isBusyLogin = false;
  String? _error;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  String? getError() {
    return _error;
  }

  void toggleObscure() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  bool get isValidEmail {
    final text = emailController.text.trim();
    if (text.isEmpty) return false;
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(text);
  }

  bool get isValidPassword => passwordController.text.isNotEmpty;

  bool get canSubmit => isValidEmail && isValidPassword && !isBusyLogin;

  Future<void> login() async {
    if (!canSubmit) return;
    _error = null;
    isBusyLogin = true;
    notifyListeners();
    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await _navService.navigateToHomepageView();
    } catch (e) {
      _error = 'Login failed. Please try again.';
    } finally {
      isBusyLogin = false;
      notifyListeners();
    }
  }

  Future<void> ssoGoogle() async {
    if (isBusyLogin) return;
    isBusyLogin = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await _navService.navigateToHomepageView();
    isBusyLogin = false;
    notifyListeners();
  }

  Future<void> ssoApple() async {
    if (isBusyLogin) return;
    isBusyLogin = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await _navService.navigateToHomepageView();
    isBusyLogin = false;
    notifyListeners();
  }

  Future<void> navigateToSignup() async {
    await _navService.navigateToSignupView();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
