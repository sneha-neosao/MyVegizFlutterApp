import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../routes/app_route_path.dart';
import '../../../core/utils/logger.dart';
import '../bloc/login_blocs/verifyOtp_bloc/verifyOtp_bloc.dart';
import '../bloc/login_blocs/verifyOtp_bloc/verifyOtp_event.dart';
import '../bloc/login_blocs/verifyOtp_bloc/verifyOtp_state.dart';
import '../bloc/login_blocs/login_bloc/sendOtp_bloc.dart';
import '../bloc/login_blocs/login_bloc/sendOtp_event.dart';
import '../bloc/login_blocs/login_bloc/sendOtp_state.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../address/bloc/address_bloc.dart';
import '../../address/bloc/address_event.dart';
import '../../wishlist/bloc/wishlist_bloc.dart';
import '../../wishlist/bloc/wishlist_event.dart';
import '../../../core/services/notification_service.dart';

class LoginVerifyOtpScreen extends StatefulWidget {
  final String mobile;

  const LoginVerifyOtpScreen({super.key, required this.mobile});

  @override
  State<LoginVerifyOtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<LoginVerifyOtpScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  final TextEditingController pinController = TextEditingController();
  final FocusNode pinFocusNode = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fade = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    pinController.dispose();
    pinFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  String getOtp() {
    return pinController.text;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SendOtpBloc, SendOtpState>(
          listener: (context, state) {
            if (state is SendOtpLoading) {
              logger.i('🔐 LoginVerifyOtp: Resending OTP to ${widget.mobile}...');
            }
            if (state is SendOtpSuccess) {
              logger.i('✅ LoginVerifyOtp: OTP resent successfully!');
              SnackbarUtils.showSuccessSnackbar(context, state.message);
            }
            if (state is SendOtpFailure) {
              logger.e('❌ LoginVerifyOtp: OTP resend failed — ${state.error}');
              SnackbarUtils.showErrorSnackbar(context, state.error);
            }
          },
        ),
        BlocListener<VerifyOtpBloc, VerifyOtpState>(
          listener: (context, state) async {
            if (state is VerifyOtpSuccess) {
          try {
            final data = state.data.data;
            if (data != null) {
              await SecureStorage.saveAccessToken(data.accessToken);
              await SecureStorage.saveRefreshToken(data.refreshToken);
              await SecureStorage.saveCustomerId(data.customer.id);
              await SecureStorage.saveCustomerName(data.customer.name);
              await SecureStorage.saveCustomerContact(data.customer.contact);
              await SecureStorage.saveCustomerEmail(data.customer.email);
              await SecureStorage.saveCustomerUuid(data.customer.uuId);

              // Update FCM Token on server
              NoficationService.updateTokenOnServer();

              logger.i(
                '✅ LoginVerifyOtp: Login successful — navigating to home',
              );
              if (context.mounted) {
                context.read<WishlistBloc>().add(FetchWishlist());
                context.read<AddressBloc>().add(FetchAddressList());
                context.go(AppRoutePath.home);
              }
            }
          } catch (e) {
            logger.e('❌ LoginVerifyOtp: STORAGE ERROR — $e');
          }
        }

        if (state is VerifyOtpFailure) {
          SnackbarUtils.showErrorSnackbar(context, state.error);
        }
      },
    ),
  ],
  child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxHeight < 600;
            final bgHeight = isSmall ? 340.0 : 380.0;
            final cardTop = isSmall ? 180.0 : 220.0;

            return SingleChildScrollView(
              child: Stack(
                children: [
                  /// 🔥 TOP GRADIENT
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
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            const Text(
                              "Verify OTP",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  /// 🔥 CARD
                  Padding(
                    padding: EdgeInsets.only(top: cardTop, left: 24, right: 24),
                    child: FadeTransition(
                      opacity: _fade,
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
                          children: [
                            RichText(
                              text: TextSpan(
                                text: "Enter OTP sent to ",
                                style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.black.withValues(alpha: 0.7),
                                ),
                                children: [
                                  TextSpan(
                                    text: widget.mobile,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

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

                            const SizedBox(height: 25),

                            /// 🔥 VERIFY BUTTON
                            BlocBuilder<VerifyOtpBloc, VerifyOtpState>(
                              builder: (context, state) {
                                final isLoading = state is VerifyOtpLoading;

                                return SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                      final otp = getOtp();

                                      context.read<VerifyOtpBloc>().add(
                                        VerifyOtpPressed(
                                          widget.mobile,
                                          otp,
                                        ),
                                      );
                                    },
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
                                      "Continue",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 25),

                            /// 🔥 RESEND OPTIONS
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                                children: [
                                  const TextSpan(
                                    text: "Didn't receive it? ",
                                  ),
                                  TextSpan(
                                    text: "Resend OTP",
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        logger.i('📱 LoginVerifyOtp: Resending OTP to ${widget.mobile}');
                                        context.read<SendOtpBloc>().add(
                                              SendOtpButtonPressed(widget.mobile),
                                            );
                                      },
                                  ),
                                ],
                              ),
                            )

                            // const SizedBox(height: 15),

                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.center,
                            //   children: [
                            //     /// SMS
                            //     Container(
                            //       padding: const EdgeInsets.symmetric(
                            //         horizontal: 20,
                            //         vertical: 10,
                            //       ),
                            //       decoration: BoxDecoration(
                            //         color: Colors.orange.shade50,
                            //         borderRadius: BorderRadius.circular(10),
                            //       ),
                            //       child: const Text(
                            //         "SMS",
                            //         style: TextStyle(
                            //           color: Colors.deepOrange,
                            //           fontWeight: FontWeight.bold,
                            //         ),
                            //       ),
                            //     ),
                            //
                            //     const SizedBox(width: 15),
                            //
                            //     /// CALL
                            //     Container(
                            //       padding: const EdgeInsets.symmetric(
                            //         horizontal: 20,
                            //         vertical: 10,
                            //       ),
                            //       decoration: BoxDecoration(
                            //         color: Colors.orange.shade50,
                            //         borderRadius: BorderRadius.circular(10),
                            //       ),
                            //       child: const Text(
                            //         "CALL",
                            //         style: TextStyle(
                            //           color: Colors.deepOrange,
                            //           fontWeight: FontWeight.bold,
                            //         ),
                            //       ),
                            //     ),
                            //   ],
                            // ),
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
