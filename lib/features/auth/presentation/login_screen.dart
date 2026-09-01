import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/logger.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../routes/app_route_path.dart';
import '../bloc/login_blocs/login_bloc/sendOtp_bloc.dart';
import '../bloc/login_blocs/login_bloc/sendOtp_event.dart';
import '../bloc/login_blocs/login_bloc/sendOtp_state.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../address/bloc/address_bloc.dart';
import '../../address/bloc/address_event.dart';
import '../../wishlist/bloc/wishlist_bloc.dart';
import '../../wishlist/bloc/wishlist_event.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController mobileController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/login_bg.png'), context);
    precacheImage(const AssetImage('assets/images/bottom_img.png'), context);
  }

  @override
  void initState() {
    super.initState();
    logger.i('🔐 LoginScreen: initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AddressBloc>().add(ClearAddressEvent());
        context.read<WishlistBloc>().add(ClearWishlistEvent());
      }
    });
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
    mobileController.dispose();
    super.dispose();
  }

  void _onGetOtpPressed() {
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
    logger.i('🔐 LoginScreen: "Get OTP" clicked for $rawMobile');
    context.read<SendOtpBloc>().add(SendOtpButtonPressed(rawMobile));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SendOtpBloc, SendOtpState>(
      listener: (context, state) {
        logger.d('🔐 LoginScreen: BlocState changed → ${state.runtimeType}');

        if (state is SendOtpLoading) {
          logger.i('🔐 LoginScreen: OTP sending...');
        }

        if (state is SendOtpSuccess) {
          FocusScope.of(context).unfocus();
          final mobile = mobileController.text.trim();
          logger.i(
            '✅ LoginScreen: OTP sent successfully to $mobile [vId: ${state.verificationId}] — navigating to OTP screen',
          );
          context.push(
            AppRoutePath.otp,
            extra: {
              'mobile': mobile,
              'verificationId': state.verificationId ?? '',
              'resendToken': state.resendToken,
            },
          );
        }

        if (state is SendOtpFailure) {
          logger.e('❌ LoginScreen: OTP send failed — ${state.error}');
          if (state.error.toLowerCase().contains('not registered')) {
            SnackbarUtils.showErrorSnackbar(context, state.error);
            logger.i(
              '🔐 LoginScreen: User not registered — navigating to signup',
            );
            context.push(AppRoutePath.signup);
          } else {
            SnackbarUtils.showErrorSnackbar(context, state.error);
          }
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
                        'assets/images/login_bg.png',
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
                                      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 0),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Header: WELCOME BACK ! 🍃
                                            Center(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'WELCOME BACK !',
                                                    style: TextStyle(
                                                      fontSize: 21.sp,
                                                      fontWeight: FontWeight.w900,
                                                      letterSpacing: -0.3,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  SizedBox(width: 4.w),
                                                  Text(
                                                    '🍃',
                                                    style: TextStyle(fontSize: 15.sp),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 12.h),

                                            // Mobile Number Label
                                            Text(
                                              'Mobile Number',
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade800,
                                              ),
                                            ),
                                            SizedBox(height: 5.h),

                                            // Input Field
                                            _buildTextField(),
                                            SizedBox(height: 14.h),

                                            // Get OTP Button
                                            BlocBuilder<SendOtpBloc, SendOtpState>(
                                              builder: (context, state) {
                                                final isLoading = state is SendOtpLoading;

                                                return SizedBox(
                                                  width: double.infinity,
                                                  height: 46.h,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient: const LinearGradient(
                                                        colors: [
                                                          Color(0xFFFF5722),
                                                          Color(0xFFFF7A00),
                                                        ],
                                                      ),
                                                      borderRadius: BorderRadius.circular(28.w),
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
                                                      onPressed: isLoading
                                                          ? null
                                                          : _onGetOtpPressed,
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.transparent,
                                                        shadowColor: Colors.transparent,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(28.w),
                                                        ),
                                                        padding: EdgeInsets.zero,
                                                      ),
                                                      child: isLoading
                                                          ? const SizedBox(
                                                              width: 24,
                                                              height: 24,
                                                              child: CircularProgressIndicator(
                                                                color: Colors.white,
                                                                strokeWidth: 2.5,
                                                              ),
                                                            )
                                                          : Stack(
                                                              alignment: Alignment.center,
                                                              children: [
                                                                Center(
                                                                  child: Text(
                                                                    'Get OTP',
                                                                    style: TextStyle(
                                                                      fontSize: 15.sp,
                                                                      fontWeight: FontWeight.w700,
                                                                      color: Colors.white,
                                                                    ),
                                                                  ),
                                                                ),
                                                                Positioned(
                                                                  right: 8.w,
                                                                  child: Container(
                                                                    width: 32.w,
                                                                    height: 32.w,
                                                                    decoration: const BoxDecoration(
                                                                      color: Colors.white,
                                                                      shape: BoxShape.circle,
                                                                    ),
                                                                    child: Icon(
                                                                      Icons.arrow_forward_rounded,
                                                                      color: const Color(0xFFFF5722),
                                                                      size: 17.w,
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

                                            SizedBox(height: 12.h),
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

  Widget _buildTextField() {
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
        hintText: 'Enter mobile number',
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 14.sp,
          fontWeight: FontWeight.normal,
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
