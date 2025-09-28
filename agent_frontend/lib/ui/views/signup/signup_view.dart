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
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary.withOpacity(.12),
                  cs.tertiaryContainer.withOpacity(.10),
                  cs.secondary.withOpacity(.08),
                ],
              ),
            ),
          ),
          // Subtle blobs
          Positioned(
            top: -80,
            right: -60,
            child: _Blob(color: cs.primaryContainer.withOpacity(.35), size: 240),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: _Blob(color: cs.secondaryContainer.withOpacity(.35), size: 200),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Text(
                        "Create your account",
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: .2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Join us and start your journey.",
                        style: textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 24),
                      // Card
                      _GlassCard(
                        child: AutofillGroup(
                          child: Column(
                            children: [
                              _LabeledField(
                                label: "Full name",
                                child: TextField(
                                  controller: viewModel.nameController,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.name],
                                  decoration: const InputDecoration(
                                    hintText: "John Doe",
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  onChanged: (_) => viewModel.notifyListeners(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _LabeledField(
                                label: "Date of birth",
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => viewModel.pickDob(context),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(Icons.cake_outlined),
                                      hintText: "Select date of birth",
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          viewModel.dobFormatted ?? "Select date of birth",
                                          style: textTheme.bodyLarge?.copyWith(
                                            color: viewModel.dobFormatted == null
                                                ? cs.onSurfaceVariant
                                                : cs.onSurface,
                                          ),
                                        ),
                                        const Icon(Icons.calendar_today_outlined, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _LabeledField(
                                label: "Phone",
                                child: TextField(
                                  controller: viewModel.phoneController,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.telephoneNumber],
                                  decoration: const InputDecoration(
                                    hintText: "+1 555 0100",
                                    prefixIcon: Icon(Icons.phone_outlined),
                                  ),
                                  onChanged: (_) => viewModel.notifyListeners(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _LabeledField(
                                label: "Email",
                                child: TextField(
                                  controller: viewModel.emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  decoration: InputDecoration(
                                    hintText: "you@example.com",
                                    prefixIcon: const Icon(Icons.mail_outline),
                                    suffixIcon: viewModel.isValidEmail
                                        ? const Icon(Icons.verified_rounded)
                                        : null,
                                  ),
                                  onChanged: (_) => viewModel.notifyListeners(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _LabeledField(
                                label: "Password",
                                child: TextField(
                                  controller: viewModel.passwordController,
                                  obscureText: viewModel.obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.newPassword],
                                  decoration: InputDecoration(
                                    hintText: "Create a strong password",
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      tooltip: viewModel.obscurePassword ? "Show" : "Hide",
                                      onPressed: viewModel.toggleObscure,
                                      icon: Icon(
                                        viewModel.obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                  onChanged: (_) => viewModel.notifyListeners(),
                                  onSubmitted: (_) =>
                                      viewModel.canSubmit ? viewModel.signup() : null,
                                ),
                              ),
                              const SizedBox(height: 18),
                              // CTA
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: viewModel.canSubmit && !viewModel.isBusySignup
                                      ? viewModel.signup
                                      : null,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    child: viewModel.isBusySignup
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(strokeWidth: 2.6),
                                          )
                                        : const Text("Create account"),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: Divider(color: cs.outlineVariant)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text("or continue with",
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        )),
                                  ),
                                  Expanded(child: Divider(color: cs.outlineVariant)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: viewModel.ssoGoogle,
                                      icon: const FaIcon(FontAwesomeIcons.google, size: 18),
                                      label: const Text("Google"),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: viewModel.ssoApple,
                                      icon: const FaIcon(FontAwesomeIcons.apple, size: 20),
                                      label: const Text("Apple"),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
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
                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Already have an account? ",
                              style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                          TextButton(
                            onPressed: viewModel.navigateToLogin,
                            child: const Text("Sign in"),
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
  SignupViewModel viewModelBuilder(BuildContext context) => SignupViewModel();
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(.60),
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

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withOpacity(.3), blurRadius: 40, spreadRadius: 10),
        ],
      ),
    );
  }
}