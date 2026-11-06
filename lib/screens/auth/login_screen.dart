import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/view_state.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    _userFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    await auth.login(_userController.text.trim(), _passwordController.text);
    if (!mounted) return;
    if (auth.state.isSuccess) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                    ),
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 24),
                Text('Welcome back', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                const Text('Log in to continue to your health profile.'),
                const SizedBox(height: 28),
                CustomTextField(
                  label: 'Username / Phone no',
                  hint: 'Enter your username or phone no',
                  controller: _userController,
                  focusNode: _userFocus,
                  nextFocusNode: _passwordFocus,
                  prefixIcon: Icons.person_outline,
                  keyboardType: TextInputType.text,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  label: 'Password',
                  hint: '••••••',
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      (v == null || v.length < 4) ? 'Min 4 characters' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
                    child: const Text('Forgot password?'),
                  ),
                ),
                if (auth.state.isError) ...[
                  const SizedBox(height: 4),
                  Text(
                    auth.state.errorMessage ?? '',
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 10),
                PrimaryButton(
                  label: 'LOGIN',
                  isLoading: auth.state.status == ViewStatus.loading,
                  onPressed: () => _submit(auth),
                ),
                const SizedBox(height: 22),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Or continue with',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.g_mobiledata, size: 26),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.signup),
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            color: AppColors.primaryStart,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
