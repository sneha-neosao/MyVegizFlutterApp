import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/responsive_utils.dart';
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
  late Animation<Offset> _slideAnimation;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/signup_bg.png'), context);
    precacheImage(const AssetImage('assets/images/bottom_img.png'), context);
  }

  @override
  void initState() {
    super.initState();
    logger.i('📝 SignupScreen: initState');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
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

  void _onSignup() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final rawMobile = mobileController.text.trim();
    if (rawMobile.length != 10) {
      SnackbarUtils.showErrorSnackbar(
        context,
        'Please enter valid mobile number',
      );
      return;
    }
    logger.i(
      '📝 SignupScreen: "SIGN UP" pressed — name="${nameController.text.trim()}", mobile="$rawMobile"',
    );
    context.read<RegisterBloc>().add(
      RegisterButtonPressed(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        mobile: rawMobile,
      ),
    );
  }

  void _showError(String msg) {
    SnackbarUtils.showErrorSnackbar(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegisterBloc, RegisterState>(
      listener: (context, state) {
        logger.d('📝 SignupScreen: BlocState → ${state.runtimeType}');
        if (state is RegisterSuccess) {
          FocusScope.of(context).unfocus();
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
        resizeToAvoidBottomInset: true,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = MediaQuery.of(context).size.height;
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                height: screenHeight,
                child: Stack(
                  children: [
                    // ── Full-screen Background Image ──
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/signup_bg.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        gaplessPlayback: true,
                      ),
                    ),

                    // ── Bottom Anchored White Sheet ──
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28.w),
                        topRight: Radius.circular(28.w),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28.w),
                        topRight: Radius.circular(28.w),
                      ),
                      child: SafeArea(
                        top: false,
                        bottom: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(24.w, 26.h, 24.w, 0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header: CREATE ACCOUNT 🍃
                                    Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'CREATE ACCOUNT',
                                            style: TextStyle(
                                              fontSize: 22.sp,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.3,
                                              color: Colors.black,
                                            ),
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            '🍃',
                                            style: TextStyle(fontSize: 16.sp),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 16.h),

                                    // Full Name Field
                                    _buildField(
                                      controller: nameController,
                                      label: 'Full Name',
                                      hint: 'Enter your full name',
                                      icon: Icons.person_outline_rounded,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Name required';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 14.h),

                                    // Email Field
                                    _buildField(
                                      controller: emailController,
                                      label: 'Email Address',
                                      hint: 'Enter your email',
                                      icon: Icons.email_outlined,
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
                                    SizedBox(height: 14.h),

                                    // Mobile Number Field
                                    _buildMobileField(),
                                    SizedBox(height: 18.h),

                                    // SUBMIT BUTTON
                                    BlocBuilder<RegisterBloc, RegisterState>(
                                      builder: (context, state) {
                                        final isLoading =
                                            state is RegisterLoading;
                                        return SizedBox(
                                          width: double.infinity,
                                          height: 50.h,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFFFF5722),
                                                  Color(0xFFFF7A00),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(28.w),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFFF5722)
                                                      .withOpacity(0.35),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton(
                                              onPressed:
                                                  isLoading ? null : _onSignup,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.transparent,
                                                shadowColor:
                                                    Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    28.w,
                                                  ),
                                                ),
                                                padding: EdgeInsets.zero,
                                              ),
                                              child: isLoading
                                                  ? const SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child:
                                                          CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2.5,
                                                      ),
                                                    )
                                                  : Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        Center(
                                                          child: Text(
                                                            'Sign Up',
                                                            style: TextStyle(
                                                              fontSize: 15.5.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                        Positioned(
                                                          right: 8.w,
                                                          child: Container(
                                                            width: 34.w,
                                                            height: 34.w,
                                                            decoration:
                                                                const BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child: Icon(
                                                              Icons
                                                                  .arrow_forward_rounded,
                                                              color: const Color(
                                                                0xFFFF5722,
                                                              ),
                                                              size: 18.w,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                    SizedBox(height: 15.h),

                                    // LOGIN LINK
                                    Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Already have an account? ',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 13.sp,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              logger.i(
                                                '📝 SignupScreen: "Login" tapped — navigating to login',
                                              );
                                              context.go(AppRoutePath.login);
                                            },
                                            child: Text(
                                              'Login',
                                              style: TextStyle(
                                                color: const Color(0xFFFF5722),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13.sp,
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
                                    Image.asset(
                                      'assets/images/bottom_img.png',
                                      width: double.infinity,
                                      fit: BoxFit.fitWidth,
                                      gaplessPlayback: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13.5.sp,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 14.sp,
        ),
        filled: true,
        fillColor: const Color(0xFFFBFBFB),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFFFF5722),
          size: 18.sp,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.w),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.w),
          borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.w),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.w),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildMobileField() {
    return TextFormField(
      controller: mobileController,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Mobile number required';
        }
        if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
          return 'Enter valid 10 digit number';
        }
        return null;
      },
      style: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        counterText: '',
        labelText: 'Mobile Number',
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13.5.sp,
        ),
        hintText: 'Enter mobile number',
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 14.sp,
        ),
        filled: true,
        fillColor: const Color(0xFFFBFBFB),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        prefixIcon: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.phone_outlined,
                color: const Color(0xFFFF5722),
                size: 18.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                '+91',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5.sp,
                  color: Colors.black87,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                width: 1,
                height: 20.h,
                color: Colors.grey.shade300,
              ),
              SizedBox(width: 8.w),
            ],
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.w),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.w),
          borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.w),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.w),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}
