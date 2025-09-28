import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:stacked/stacked.dart';

import 'signup_viewmodel.dart';
import '../../common/app_theme.dart';

class SignupView extends StackedView<SignupViewModel> {
  const SignupView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    SignupViewModel viewModel,
    Widget? child,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: gradientBackground(context),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Hero(
                                tag: 'auth-title',
                                child: Text(
                                  'Create account',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 6),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 3,
                                width: 160,
                                decoration: BoxDecoration(
                                  color: scheme.primary.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: viewModel.nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        onChanged: (_) => viewModel.notifyListeners(),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => viewModel.pickDob(context),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date of birth',
                            prefixIcon: Icon(Icons.cake_outlined),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              viewModel.dobFormatted,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: viewModel.phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        onChanged: (_) => viewModel.notifyListeners(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: viewModel.emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          errorText: (viewModel.emailController.text.isEmpty || viewModel.isValidEmail)
                              ? null
                              : 'Enter a valid email',
                        ),
                        onChanged: (_) => viewModel.notifyListeners(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: viewModel.passwordController,
                        obscureText: viewModel.obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          helperText: 'At least 6 characters',
                          suffixIcon: IconButton(
                            icon: Icon(viewModel.obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: viewModel.toggleObscure,
                          ),
                        ),
                        onChanged: (_) => viewModel.notifyListeners(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: viewModel.canSubmit ? viewModel.signup : null,
                          child: viewModel.isBusySignup
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Create account'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: viewModel.isBusySignup ? null : viewModel.ssoGoogle,
                            icon: const FaIcon(FontAwesomeIcons.google),
                            tooltip: 'Continue with Google',
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: viewModel.isBusySignup ? null : viewModel.ssoApple,
                            icon: const FaIcon(FontAwesomeIcons.apple),
                            tooltip: 'Continue with Apple',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: GestureDetector(
                          onTap: viewModel.navigateToLogin,
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: [
                                const TextSpan(text: 'Already have an account? '),
                                TextSpan(
                                  text: 'Log in',
                                  style: TextStyle(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  SignupViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      SignupViewModel();
}
