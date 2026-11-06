import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/view_state.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    for (final c in [_nameController, _phoneController, _emailController, _passwordController]) {
      c.dispose();
    }
    for (final f in [_nameFocus, _phoneFocus, _emailFocus, _passwordFocus]) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    await auth.signUp(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (auth.state.isSuccess) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sign up', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                const Text('Create a profile so first responders know your history.'),
                const SizedBox(height: 24),
                CustomTextField(
                  label: 'Full name',
                  hint: 'Enter your full name',
                  controller: _nameController,
                  focusNode: _nameFocus,
                  nextFocusNode: _phoneFocus,
                  prefixIcon: Icons.badge_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Phone number',
                  hint: 'Enter your phone number',
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  nextFocusNode: _emailFocus,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (v) => (v == null || v.trim().length < 8) ? 'Enter a valid phone' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  focusNode: _emailFocus,
                  nextFocusNode: _passwordFocus,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Password',
                  hint: 'Create a password',
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) => (v == null || v.length < 4) ? 'Min 4 characters' : null,
                ),
                if (auth.state.isError) ...[
                  const SizedBox(height: 10),
                  Text(auth.state.errorMessage ?? '', style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ],
                const SizedBox(height: 22),
                PrimaryButton(
                  label: 'CREATE ACCOUNT',
                  isLoading: auth.state.status == ViewStatus.loading,
                  onPressed: () => _submit(auth),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
