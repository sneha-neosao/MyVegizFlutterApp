import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../routes/app_route_path.dart';
import '../../../core/utils/logger.dart';
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

class RegiverifyOtp extends StatefulWidget {
  final String name;
  final String email;
  final String mobile;

  const RegiverifyOtp({
    super.key,
    required this.name,
    required this.email,
    required this.mobile,
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

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
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

    context.read<RegiVerifyOtpBloc>().add(
      RegiVerifyOtpPressed(mobile: widget.mobile, otp: otp),
    );
  }

  void _onResend() {
    logger.i('🔄 RegiVerifyOtp: Resend OTP tapped for mobile=${widget.mobile}');
    context.read<RegisterBloc>().add(
      RegisterButtonPressed(
        name: widget.name,
        email: widget.email,
        mobile: widget.mobile,
      ),
    );
  }

  void _showError(String msg) {
    SnackbarUtils.showErrorSnackbar(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<RegisterBloc, RegisterState>(
          listener: (context, state) {
            if (state is RegisterLoading) {
              logger.i('🔐 RegiVerifyOtp: Resending registration OTP to ${widget.mobile}...');
            }
            if (state is RegisterSuccess) {
              logger.i('✅ RegiVerifyOtp: Registration OTP resent successfully!');
              SnackbarUtils.showSuccessSnackbar(context, state.message);
            }
            if (state is RegisterFailure) {
              logger.e('❌ RegiVerifyOtp: Registration OTP resend failed — ${state.error}');
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
        backgroundColor: Colors.grey.shade50,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxHeight < 600;
            final bgHeight = isSmall ? 250.0 : 280.0;
            final cardTop = isSmall ? 150.0 : 180.0;

            return SingleChildScrollView(
              child: Stack(
                children: [
                  /// HEADER
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
                      child: Column(
                        children: const [
                          SizedBox(height: 20),
                          Text(
                            "Registration Verify OTP",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Enter 6 digit code",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// CARD
                  Padding(
                    padding: EdgeInsets.only(top: cardTop, left: 24, right: 24),
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            /// MOBILE TEXT
                            Text(
                              "OTP sent to ${widget.mobile}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),

                            const SizedBox(height: 30),

                            Pinput(
                              length: 6,
                              controller: pinController,
                              focusNode: pinFocusNode,
                              autofocus: true,
                              keyboardType: TextInputType.number,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              defaultPinTheme: PinTheme(
                                width: 45,
                                height: 50,
                                textStyle: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                              ),
                              focusedPinTheme: PinTheme(
                                width: 45,
                                height: 50,
                                textStyle: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.deepOrange, width: 2),
                                ),
                              ),
                              submittedPinTheme: PinTheme(
                                width: 45,
                                height: 50,
                                textStyle: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade400),
                                  color: Colors.grey.shade50,
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            /// VERIFY BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _onVerify,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isLoading
                                    ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                    : const Text(
                                  "VERIFY OTP",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            /// RESEND
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Didn't receive code? "),
                                GestureDetector(
                                  onTap: _onResend,
                                  child: const Text(
                                    "Resend",
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
