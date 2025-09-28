import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:stacked/stacked.dart';

import 'login_viewmodel.dart';
import '../../common/app_theme.dart';

class LoginView extends StackedView<LoginViewModel> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    LoginViewModel viewModel,
    Widget? child,
  ) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient bg
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  cs.primaryContainer.withOpacity(.18),
                  cs.surface,
                ],
              ),
            ),
          ),
          Positioned(
            top: -70,
            left: -50,
            child: _Halo(color: cs.primary.withOpacity(.25), size: 220),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: _Halo(color: cs.secondary.withOpacity(.18), size: 180),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Welcome back",
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: .2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Sign in to continue",
                        style: textTheme.bodyLarge
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 24),
                      _Card(
                        child: AutofillGroup(
                          child: Column(
                            children: [
                              TextField(
                                controller: viewModel.emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  hintText: "you@example.com",
                                  prefixIcon: const Icon(Icons.mail_outline),
                                  suffixIcon: viewModel.isValidEmail
                                      ? const Icon(Icons.verified_rounded)
                                      : null,
                                ),
                                onChanged: (_) => viewModel.notifyListeners(),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: viewModel.passwordController,
                                obscureText: viewModel.obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  hintText: "Enter your password",
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: viewModel.obscurePassword
                                        ? "Show"
                                        : "Hide",
                                    onPressed: viewModel.toggleObscure,
                                    icon: Icon(
                                      viewModel.obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                                onSubmitted: (_) => viewModel.canSubmit
                                    ? viewModel.login()
                                    : null,
                                onChanged: (_) => viewModel.notifyListeners(),
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: null,
                                  child: const Text("Forgot password?"),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: viewModel.canSubmit &&
                                          !viewModel.isBusyLogin
                                      ? viewModel.login
                                      : null,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    child: viewModel.isBusyLogin
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2.6),
                                          )
                                        : const Text("Sign in"),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                      child: Divider(color: cs.outlineVariant)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text("or sign in with",
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        )),
                                  ),
                                  Expanded(
                                      child: Divider(color: cs.outlineVariant)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: viewModel.ssoGoogle,
                                      icon: const FaIcon(
                                          FontAwesomeIcons.google,
                                          size: 18),
                                      label: const Text("Google"),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: viewModel.ssoApple,
                                      icon: const FaIcon(FontAwesomeIcons.apple,
                                          size: 20),
                                      label: const Text("Apple"),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("New here? ",
                              style: textTheme.bodyMedium
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                          TextButton(
                            onPressed: viewModel.navigateToSignup,
                            child: const Text("Create account"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  LoginViewModel viewModelBuilder(BuildContext context) => LoginViewModel();
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(.70),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }
}

class _Halo extends StatelessWidget {
  final Color color;
  final double size;
  const _Halo({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(.35), blurRadius: 50, spreadRadius: 8)
        ],
      ),
    );
  }
}
