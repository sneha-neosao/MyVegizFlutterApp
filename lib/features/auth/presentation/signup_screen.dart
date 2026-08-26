import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/logger.dart';
import '../../../routes/app_route_path.dart';
import '../bloc/signup_blocs/signup_bloc/signup_bloc.dart';
import '../bloc/signup_blocs/signup_bloc/signup_event.dart';
import '../bloc/signup_blocs/signup_bloc/signup_state.dart';
import '../../../core/utils/snackbar_utils.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();

  @override
  void initState() {
    super.initState();
    logger.i('📝 SignupScreen: initState');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegisterBloc, RegisterState>(
      listener: (context, state) {
        logger.d('📝 SignupScreen: BlocState → ${state.runtimeType}');
        if (state is RegisterSuccess) {
          final name = nameController.text.trim();
          final email = emailController.text.trim();
          final mobile = mobileController.text.trim();
          logger.i(
            '✅ SignupScreen: Registration successful — navigating to OTP for $mobile',
          );
          context.push(
            AppRoutePath.regiVerifyOtp,
            extra: {'name': name, 'email': email, 'mobile': mobile},
          );
        }
        if (state is RegisterFailure) {
          logger.e('❌ SignupScreen: Registration failed — ${state.error}');
          _showError(state.error);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxHeight < 600;
            final double bgHeight = isSmallScreen ? 300 : 340;
            final double cardTopPosition = isSmallScreen ? 160 : 200;

            return SingleChildScrollView(
              child: Stack(
                children: [
                  /// TOP GRADIENT
                  Container(
                    height: bgHeight,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepOrange, Colors.orange],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: const [
                            SizedBox(height: 20),
                            Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Enter details to continue',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  /// FORM CARD
                  Padding(
                    padding: EdgeInsets.only(
                      top: cardTopPosition,
                      left: 24,
                      right: 24,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildField(
                                controller: nameController,
                                label: 'Full Name',
                                icon: Icons.person,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Name required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildField(
                                controller: emailController,
                                label: 'Email',
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value != null &&
                                      value.isNotEmpty &&
                                      !RegExp(
                                        r'^[^@]+@[^@]+\.[^@]+',
                                      ).hasMatch(value)) {
                                    return 'Invalid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              /// MOBILE
                              TextFormField(
                                controller: mobileController,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Mobile required';
                                  }
                                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                                    return 'Enter valid number';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  counterText: '',
                                  labelText: 'Mobile Number',
                                  prefixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      SizedBox(width: 12),
                                      Text(
                                        '+91',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text('|'),
                                      SizedBox(width: 8),
                                    ],
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              /// SUBMIT BUTTON
                              BlocBuilder<RegisterBloc, RegisterState>(
                                builder: (context, state) {
                                  final isLoading = state is RegisterLoading;
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : _onSignup,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepOrange,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: isLoading
                                          ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                          : const Text(
                                              'SIGN UP',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 20),

                              /// LOGIN LINK
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Already have account? '),
                                  GestureDetector(
                                    onTap: () {
                                      logger.i(
                                        '📝 SignupScreen: "Login" tapped — going back',
                                      );
                                      context.pop();
                                    },
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                        color: Colors.deepOrange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
          },
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _onSignup() {
    final rawMobile = mobileController.text.trim();
    if (rawMobile.length != 10) {
      SnackbarUtils.showErrorSnackbar(
        context,
        'Please enter valid mobile number',
      );
      return;
    }
    final fullMobile = '+91$rawMobile';
    logger.i(
      '📝 SignupScreen: "SIGN UP" pressed — name="${nameController.text.trim()}", mobile="$fullMobile"',
    );
    context.read<RegisterBloc>().add(
      RegisterButtonPressed(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        mobile: fullMobile,
      ),
    );
  }

  void _showError(String msg) {
    SnackbarUtils.showErrorSnackbar(context, msg);
  }
}
