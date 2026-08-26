import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_vegiz_flutter/config/injector_conf.dart';
import 'package:my_vegiz_flutter/core/storage/secure_storage.dart';
import 'package:my_vegiz_flutter/core/utils/logger.dart';
import 'package:my_vegiz_flutter/core/utils/profile_image_notifier.dart';
import 'package:my_vegiz_flutter/core/utils/snackbar_utils.dart';
import '../../bloc/profile_blocs/profile_bloc.dart';
import '../../bloc/profile_blocs/profile_event.dart';
import '../../bloc/profile_blocs/profile_state.dart';

/// Shows the Edit Profile modal bottom sheet.
/// Returns `true` if the profile was updated so the caller can refresh.
Future<bool?> showEditProfile(
  BuildContext context, {
  required String name,
  required String email,
  required String contact,
  String? imagePath,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => BlocProvider(
      create: (_) => getIt<ProfileBloc>(),
      child: _EditProfile(
        initialName: name,
        initialEmail: email,
        initialContact: contact,
        initialImagePath: imagePath,
      ),
    ),
  );
}

class _EditProfile extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialContact;
  final String? initialImagePath;

  const _EditProfile({
    required this.initialName,
    required this.initialEmail,
    required this.initialContact,
    this.initialImagePath,
  });

  @override
  State<_EditProfile> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfile>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _mobileCtrl;

  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  File? _imageFile;
  String? _remoteImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.initialName == 'Loading...' ? '' : widget.initialName,
    );
    _emailCtrl = TextEditingController(
      text: (widget.initialEmail == 'Loading...' || widget.initialEmail == 'null') ? '' : widget.initialEmail,
    );
    _mobileCtrl = TextEditingController(
      text: widget.initialContact == 'Loading...' ? '' : widget.initialContact,
    );

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(
      begin: 1,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));

    final path = widget.initialImagePath;
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('http')) {
        _remoteImageUrl = path;
      } else {
        _imageFile = File(path);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _remoteImageUrl = null; // New image picked, clear remote reference
        });
        logger.i("👤 EditProfileSheet: Image picked: ${pickedFile.path}");
      }
    } catch (e) {
      logger.e("👤 EditProfileSheet: Error picking image: $e");
    }
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    logger.i('👤 EditProfileSheet: Dispatching UpdateProfileEvent');
    context.read<ProfileBloc>().add(
      UpdateProfileEvent(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        contact: _mobileCtrl.text.trim(),
        profileImage: _imageFile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewInsets.bottom;

    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          // Persist locally in case the app goes offline later
          SecureStorage.saveCustomerName(state.profile.name);
          SecureStorage.saveCustomerContact(state.profile.contact);

          // If the server returned a Cloudinary URL, broadcast it
          final remoteUrl = state.profile.profileImage;
          if (remoteUrl != null && remoteUrl.isNotEmpty) {
            profileImageNotifier.value = remoteUrl;
          }

          SnackbarUtils.showSuccessSnackbar(context, state.message);
          Navigator.of(context).pop(true);
        } else if (state is ProfileError) {
          SnackbarUtils.showErrorSnackbar(context, state.message);
        }
      },
      builder: (context, state) {
        final isBlocLoading = state is ProfileLoading;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: 24 + bottomInset + MediaQuery.of(context).padding.bottom,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Drag handle ──────────────────────────────────────
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Title ─────────────────────────────────────────────
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Update your personal information',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 28),

                  // ── Avatar ───────────────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      onTapDown: (_) => _animCtrl.forward(),
                      onTapUp: (_) => _animCtrl.reverse(),
                      onTapCancel: () => _animCtrl.reverse(),
                      child: ScaleTransition(
                        scale: _scaleAnim,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            // Avatar Container
                            Container(
                              width: 94,
                              height: 94,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFC8019),
                                image: _imageFile != null
                                    ? DecorationImage(
                                        image: FileImage(_imageFile!),
                                        fit: BoxFit.cover,
                                      )
                                    : _remoteImageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(_remoteImageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFC8019,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child:
                                  (_imageFile == null &&
                                      _remoteImageUrl == null)
                                  ? const Center(
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                    )
                                  : null,
                            ),
                            // Edit badge (Camera icon)
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Color(0xFFFC8019),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Tap to change photo',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Name field ────────────────────────────────────────
                  _label('Full Name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}), // refresh initials
                    decoration: _inputDecoration(
                      hint: 'Enter your full name',
                      icon: Icons.person_outline_rounded,
                    ),
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return 'Name is required';
                      if (val.length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(val)) {
                        return 'Name can only contain letters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Email field ───────────────────────────────────────
                  _label('Email Address'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      hint: 'Enter email',
                      icon: Icons.mail_outline_rounded,
                    ),
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return null;
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Mobile field ──────────────────────────────────────
                  _label('Mobile Number'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _mobileCtrl,
                    readOnly: true,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onFieldSubmitted: (_) => _saveProfile(),
                    decoration: _inputDecoration(
                      hint: '10-digit mobile number',
                      icon: Icons.phone_outlined,
                      prefixIcon: IntrinsicWidth(
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            Icon(
                              Icons.phone_outlined,
                              color: Colors.grey.shade500,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              '+91',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 1,
                              height: 20,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                    ),
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return 'Please enter a valid contact number.';
                      if (val.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(val)) {
                        return 'Please enter a valid contact number.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 36),

                  // ── Update button ─────────────────────────────────────
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isBlocLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        disabledBackgroundColor: const Color(
                          0xFFFF5722,
                        ).withValues(alpha: 0.6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isBlocLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Update Profile',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                  // const SizedBox(height: 12),

                  // ── Cancel ────────────────────────────────────────────
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        letterSpacing: 0.2,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon:
          prefixIcon ?? Icon(icon, color: Colors.grey.shade500, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      errorStyle: const TextStyle(fontSize: 12),
    );
  }
}
