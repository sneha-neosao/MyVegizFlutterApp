import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import '../../home/presentation/pages/home_page.dart';
import '../../../routes/app_route_path.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/responsive_utils.dart';
import '../bloc/signup_blocs/regiVerifyOtp_blocs/regiVerifyOtp_bloc.dart';
import '../bloc/signup_blocs/regiVerifyOtp_blocs/regiVerifyOtp_event.dart';
import '../bloc/signup_blocs/regiVerifyOtp_blocs/regiVerifyOtp_state.dart';
import '../bloc/signup_blocs/signup_bloc/signup_bloc.dart';
import '../bloc/signup_blocs/signup_bloc/signup_event.dart';
import '../bloc/signup_blocs/signup_bloc/signup_state.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/storage/secure_storage.dart';
import '../../address/bloc/address_bloc.dart';
import '../../address/bloc/address_event.dart';
import '../../wishlist/bloc/wishlist_bloc.dart';
import '../../wishlist/bloc/wishlist_event.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/profile_image_notifier.dart';

class RegiverifyOtp extends StatefulWidget {
  final String name;
  final String email;
  final String mobile;
  final String? verificationId;
  final int? resendToken;

  const RegiverifyOtp({
    super.key,
    required this.name,
    required this.email,
    required this.mobile,
    this.verificationId,
    this.resendToken,
  });

  @override
  State<RegiverifyOtp> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<RegiverifyOtp>
    with SingleTickerProviderStateMixin {
  final TextEditingController pinController = TextEditingController();
  final FocusNode pinFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _isResending = false;
  bool isLoading = false;
  late String _verificationId;
  int? _resendToken;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/login_bg.png'), context);
    precacheImage(const AssetImage('assets/images/bottom_img.png'), context);
  }

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId ?? '';
    _resendToken = widget.resendToken;
    FocusManager.instance.primaryFocus?.unfocus();
    _startTimer();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
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

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    pinController.dispose();
    pinFocusNode.dispose();
    super.dispose();
  }

  String getOtp() {
    return pinController.text;
  }

  void _onVerify() {
    final otp = getOtp();
    if (otp.length != 6) {
      SnackbarUtils.showErrorSnackbar(context, 'Please enter 6 digit OTP');
      return;
    }

    context.read<RegiVerifyOtpBloc>().add(
      RegiVerifyOtpPressed(
        mobile: widget.mobile,
        otp: otp,
        verificationId: _verificationId,
      ),
    );
  }

  void _onResend() {
    logger.i('🔄 RegiVerifyOtp: Resend OTP tapped for mobile=${widget.mobile}');
    context.read<RegisterBloc>().add(
      RegisterButtonPressed(
        name: widget.name,
        email: widget.email,
        mobile: widget.mobile,
        resendToken: _resendToken,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<RegisterBloc, RegisterState>(
          listener: (context, state) {
            if (state is RegisterLoading) {
              logger.i('🔐 RegiVerifyOtp: Resending registration OTP to ${widget.mobile}...');
              setState(() {
                _isResending = true;
              });
            }
            if (state is RegisterSuccess) {
              logger.i('✅ RegiVerifyOtp: Registration OTP resent successfully! [vId: ${state.verificationId}]');
              setState(() {
                _isResending = false;
                if (state.verificationId != null && state.verificationId!.isNotEmpty) {
                  _verificationId = state.verificationId!;
                }
                if (state.resendToken != null) {
                  _resendToken = state.resendToken;
                }
              });
              _startTimer();
              SnackbarUtils.showSuccessSnackbar(context, state.message);
            }
            if (state is RegisterFailure) {
              logger.e('❌ RegiVerifyOtp: Registration OTP resend failed — ${state.error}');
              setState(() {
                _isResending = false;
              });
              SnackbarUtils.showErrorSnackbar(context, state.error);
            }
          },
        ),
        BlocListener<RegiVerifyOtpBloc, RegiVerifyOtpState>(
          listener: (context, state) async {
            if (state is RegiVerifyOtpLoading) {
              setState(() => isLoading = true);
            } else if (state is RegiVerifyOtpSuccess) {
              setState(() => isLoading = false);

              try {
                final data = state.model.data;
                if (data != null) {
                  await SecureStorage.saveAccessToken(data.accessToken);
                  await SecureStorage.saveRefreshToken(data.refreshToken);
                  await SecureStorage.saveCustomerId(data.customer.id);
                  await SecureStorage.saveCustomerName(data.customer.name);
                  await SecureStorage.saveCustomerContact(data.customer.contact);
                  await SecureStorage.saveCustomerEmail(data.customer.email ?? '');
                  await SecureStorage.saveCustomerUuid(data.customer.uuId);
                  if (data.customer.profileImage != null &&
                      data.customer.profileImage!.isNotEmpty) {
                    await SecureStorage.saveCustomerProfileImage(
                      data.customer.profileImage!,
                    );
                    profileImageNotifier.value = data.customer.profileImage!;
                  }

                  // Update FCM Token on server
                  NoficationService.updateTokenOnServer();

                  logger.i(
                    '✅ RegiVerifyOtp: Account created & logged in successfully — navigating to home',
                  );

                  if (context.mounted) {
                    context.read<WishlistBloc>().add(FetchWishlist());
                    context.read<AddressBloc>().add(FetchAddressList());

                    SnackbarUtils.showSuccessSnackbar(
                      context,
                      state.model.message,
                    );
                    HomePage.resetLocationSheetFlag();
                    context.go(AppRoutePath.home);
                  }
                }
              } catch (e) {
                logger.e('❌ RegiVerifyOtp: STORAGE ERROR — $e');
              }
            } else if (state is RegiVerifyOtpError) {
              setState(() => isLoading = false);

              SnackbarUtils.showErrorSnackbar(context, state.message);
            }
          },
        ),
      ],
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
                              padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header: VERIFY OTP 🍃
                                  Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'VERIFY OTP',
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
                                  SizedBox(height: 8.h),

                                  // Sent to mobile subtitle
                                  Center(
                                    child: RichText(
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                        text: "Enter OTP sent to ",
                                        style: TextStyle(
                                          fontSize: 13.5.sp,
                                          color: Colors.grey.shade600,
                                          fontFamily:
                                              GoogleFonts.nunito().fontFamily,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: widget.mobile,
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 22.h),

                                  // Pinput Field
                                  Center(
                                     child: Pinput(
                                       length: 6,
                                       controller: pinController,
                                       focusNode: pinFocusNode,
                                       autofocus: false,
                                      keyboardType: TextInputType.number,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      defaultPinTheme: PinTheme(
                                        width: 46.w,
                                        height: 50.h,
                                        textStyle: TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFBFBFB),
                                          borderRadius:
                                              BorderRadius.circular(14.w),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      focusedPinTheme: PinTheme(
                                        width: 46.w,
                                        height: 50.h,
                                        textStyle: TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(14.w),
                                          border: Border.all(
                                            color: const Color(0xFFFF5722),
                                            width: 1.8,
                                          ),
                                        ),
                                      ),
                                      submittedPinTheme: PinTheme(
                                        width: 46.w,
                                        height: 50.h,
                                        textStyle: TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(14.w),
                                          border: Border.all(
                                            color: Colors.grey.shade400,
                                          ),
                                          color: Colors.grey.shade50,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 22.h),

                                  // VERIFY Button with circular right arrow
                                  SizedBox(
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
                                        onPressed: isLoading ? null : _onVerify,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(28.w),
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
                                                alignment: Alignment.center,
                                                children: [
                                                  Center(
                                                    child: Text(
                                                      'Verify & Continue',
                                                      style: TextStyle(
                                                        fontSize: 15.5.sp,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Colors.white,
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
                                                        color: Colors.white,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        Icons
                                                            .arrow_forward_rounded,
                                                        color: const Color(
                                                            0xFFFF5722),
                                                        size: 18.w,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 18.h),

                                  // RESEND OPTIONS
                                  Center(
                                    child: _isResending
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 14.w,
                                                height: 14.w,
                                                child: const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Color(0xFFFF5722),
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              Text(
                                                'Resending OTP...',
                                                style: TextStyle(
                                                  color: const Color(0xFFFF5722),
                                                  fontSize: 13.5.sp,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily:
                                                      GoogleFonts.nunito().fontFamily,
                                                ),
                                              ),
                                            ],
                                          )
                                        : _secondsRemaining > 0
                                            ? RichText(
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 13.5.sp,
                                                    fontFamily:
                                                        GoogleFonts.nunito().fontFamily,
                                                  ),
                                                  children: [
                                                    const TextSpan(
                                                      text: "Resend OTP in ",
                                                    ),
                                                    TextSpan(
                                                      text: "00:${_secondsRemaining.toString().padLeft(2, '0')}",
                                                      style: const TextStyle(
                                                        color: Color(0xFFFF5722),
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : RichText(
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 13.5.sp,
                                                    fontFamily:
                                                        GoogleFonts.nunito().fontFamily,
                                                  ),
                                                  children: [
                                                    const TextSpan(
                                                      text: "Didn't receive OTP? ",
                                                    ),
                                                    TextSpan(
                                                      text: "Resend",
                                                      style: TextStyle(
                                                        color: const Color(0xFFFF5722),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13.5.sp,
                                                      ),
                                                      recognizer: TapGestureRecognizer()
                                                        ..onTap = _isResending
                                                            ? null
                                                            : _onResend,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                  ),
                                ],
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
}
