import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';

class SignupViewModel extends BaseViewModel {
  final NavigationService _navService = locator<NavigationService>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  DateTime? dob;

  bool isBusySignup = false;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  void toggleObscure() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  String get dobFormatted {
    if (dob == null) return 'Select date of birth';
    return DateFormat.yMMMMd().format(dob!);
  }

  bool get isValidName => nameController.text.trim().isNotEmpty;
  bool get isValidPhone => phoneController.text.trim().length >= 10;
  bool get isValidEmail {
    final text = emailController.text.trim();
    if (text.isEmpty) return false;
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(text);
  }

  bool get isValidPassword => passwordController.text.length >= 6;
  bool get isValidDob => dob != null;

  bool get canSubmit =>
      isValidName && isValidPhone && isValidEmail && isValidPassword && isValidDob && !isBusySignup;

  Future<void> pickDob(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 20, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: dob ?? initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      dob = picked;
      notifyListeners();
    }
  }

  Future<void> signup() async {
    if (!canSubmit) return;
    isBusySignup = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await _navService.navigateToHomepageView();
    isBusySignup = false;
    notifyListeners();
  }

  Future<void> ssoGoogle() async {
    if (isBusySignup) return;
    isBusySignup = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await _navService.navigateToHomepageView();
    isBusySignup = false;
    notifyListeners();
  }

  Future<void> ssoApple() async {
    if (isBusySignup) return;
    isBusySignup = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await _navService.navigateToHomepageView();
    isBusySignup = false;
    notifyListeners();
  }

  Future<void> navigateToLogin() async {
    if (_navService.back()) return;
    await _navService.navigateToLoginView();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
