import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/logger.dart';
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
  final _formKey = GlobalKey<FormState>();

  final TextEditingController mobileController = TextEditingController();

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
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    mobileController.dispose();
    super.dispose();
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
          final mobile = mobileController.text.trim();
          logger.i(
            '✅ LoginScreen: OTP sent successfully to $mobile — navigating to OTP screen',
          );
          context.push(AppRoutePath.otp, extra: mobile);
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
        backgroundColor: Colors.grey.shade50,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxHeight < 600;
            final double bgHeight = isSmallScreen ? 340 : 380;
            final double cardTopPosition = isSmallScreen ? 180 : 220;

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
                        padding: const EdgeInsets.all(34),
                        child: Column(
                          children: [
                            const SizedBox(height: 30),
                            const Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Login with mobile number to get OTP',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  /// CARD
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
                            children: [
                              const SizedBox(height: 5),
                              _buildTextField(),
                              const SizedBox(height: 20),

                              /// BUTTON WITH LOADING
                              BlocBuilder<SendOtpBloc, SendOtpState>(
                                builder: (context, state) {
                                  final isLoading = state is SendOtpLoading;
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      onPressed: isLoading
                                          ? null
                                          : () {
                                              logger.i(
                                                '🔐 LoginScreen: "GET OTP" button tapped',
                                              );
                                              final mobile = mobileController
                                                  .text
                                                  .trim();
                                              if (mobile.length != 10) {
                                                SnackbarUtils.showErrorSnackbar(
                                                  context,
                                                  'Please enter valid mobile number',
                                                );
                                                return;
                                              }
                                              logger.i(
                                                '📱 LoginScreen: Sending OTP to $mobile',
                                              );
                                              context.read<SendOtpBloc>().add(
                                                SendOtpButtonPressed(mobile),
                                              );
                                            },
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
                                              'GET OTP',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(color: Colors.grey.shade300),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text('OR'),
                                  ),
                                  Expanded(
                                    child: Divider(color: Colors.grey.shade300),
                                  ),
                                ],
                              ),

                              // const SizedBox(height: 25),

                              /// GOOGLE BUTTON
                              // Row(
                              //   mainAxisAlignment: MainAxisAlignment.center,
                              //   children: [
                              //     Image.network(
                              //       NetworkImages.googleLogo,
                              //       height: 20,
                              //       errorBuilder: (_, __, ___) => const Icon(
                              //         Icons.g_mobiledata,
                              //         size: 30,
                              //       ),
                              //     ),
                              //     const SizedBox(width: 10),
                              //     GestureDetector(
                              //       onTap: () {
                              //         logger.i(
                              //           '🔐 LoginScreen: "Continue with Google" tapped (not implemented)',
                              //         );
                              //         // TODO: Google login
                              //       },
                              //       child: const Text(
                              //         'Continue with Google',
                              //         style: TextStyle(
                              //           fontWeight: FontWeight.bold,
                              //         ),
                              //       ),
                              //     ),
                              //   ],
                              // ),

                              const SizedBox(height: 25),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Don't have account? "),
                                  GestureDetector(
                                    onTap: () {
                                      logger.i(
                                        '🔐 LoginScreen: "Sign Up" tapped — navigating to signup',
                                      );
                                      context.push(AppRoutePath.signup);
                                    },
                                    child: const Text(
                                      'Sign Up',
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
      decoration: InputDecoration(
        counterText: '',
        labelText: 'Mobile Number',
        prefixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(width: 12),
            Text(
              '+91',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(width: 8),
            Text('|'),
            SizedBox(width: 8),
          ],
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
