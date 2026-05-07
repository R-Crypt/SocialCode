import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:social_code/core/theme/app_theme.dart';
import 'package:social_code/core/widgets/brutalist_widgets.dart';
import 'package:social_code/features/auth/bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FILL IN ALL FIELDS')),
      );
      return;
    }
    if (_isSignUp) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ENTER YOUR NAME')),
        );
        return;
      }
      context.read<AuthBloc>().add(SignUpRequested(email, password, name));
    } else {
      context.read<AuthBloc>().add(LoginRequested(email, password));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: AppTheme.primaryMagenta,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 48 : 24,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SocialCodeLogo(fontSize: 56),
                        const SizedBox(height: 8),
                        Text(
                          'GOOD IS THE NEW FLEX.',
                          style: GoogleFonts.spaceMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textMain.withOpacity(0.4),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppTheme.textMain, width: 2.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tab toggle
                              Row(
                                children: [
                                  _TabButton(
                                    label: 'LOG IN',
                                    isActive: !_isSignUp,
                                    onTap: () => setState(() => _isSignUp = false),
                                  ),
                                  const SizedBox(width: 8),
                                  _TabButton(
                                    label: 'JOIN',
                                    isActive: _isSignUp,
                                    onTap: () => setState(() => _isSignUp = true),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),

                              // Name field (sign up only)
                              AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                child: _isSignUp
                                    ? Column(
                                        children: [
                                          _BrutalistField(
                                            controller: _nameController,
                                            label: 'YOUR NAME',
                                            hint: 'DISPLAY NAME',
                                          ),
                                          const SizedBox(height: 20),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),

                              _BrutalistField(
                                controller: _emailController,
                                label: 'EMAIL',
                                hint: 'YOUR@EMAIL.COM',
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 20),
                              _BrutalistField(
                                controller: _passwordController,
                                label: 'PASSWORD',
                                hint: '••••••••',
                                isObscure: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppTheme.textMain.withOpacity(0.4),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Submit button
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: state is AuthLoading ? null : _submit,
                                      child: state is AuthLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              _isSignUp
                                                  ? 'JOIN THE MOVEMENT'
                                                  : 'ENTER THE CODE',
                                            ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 20),
                              const _Divider(label: 'OR'),
                              const SizedBox(height: 20),

                              // Google Sign In
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: OutlinedButton.icon(
                                      onPressed: state is AuthLoading
                                          ? null
                                          : () => context
                                              .read<AuthBloc>()
                                              .add(GoogleSignInRequested()),
                                      icon: Image.network(
                                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png',
                                        width: 20,
                                        height: 20,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.g_mobiledata, size: 20),
                                      ),
                                      label: Text(
                                        'CONTINUE WITH GOOGLE',
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textMain,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: AppTheme.textMain, width: 2),
                                        shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.zero),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.textMain : Colors.transparent,
          border: Border.all(color: AppTheme.textMain, width: 2),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceMono(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            color: isActive ? Colors.white : AppTheme.textMain,
          ),
        ),
      ),
    );
  }
}

class _BrutalistField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isObscure;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _BrutalistField({
    required this.controller,
    required this.label,
    required this.hint,
    this.isObscure = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceMono(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppTheme.textMain,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          keyboardType: keyboardType,
          style: GoogleFonts.spaceMono(color: AppTheme.textMain, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.textMain.withOpacity(0.2)),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: suffixIcon,
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppTheme.textMain, width: 2),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppTheme.primaryMagenta, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  final String label;
  const _Divider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppTheme.textMain, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMain.withOpacity(0.4),
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppTheme.textMain, thickness: 1)),
      ],
    );
  }
}
