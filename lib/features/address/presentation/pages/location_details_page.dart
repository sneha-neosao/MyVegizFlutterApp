import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_vegiz_flutter/core/utils/logger.dart';
import 'package:my_vegiz_flutter/core/storage/secure_storage.dart';
import '../../../../routes/app_route_path.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/location_service.dart';
import '../../data/models/address_model.dart';
import '../../bloc/address_bloc.dart';
import '../../bloc/address_event.dart';
import '../../bloc/address_state.dart';

class LocationDetailsPage extends StatefulWidget {
  final AddressModel? address;
  const LocationDetailsPage({super.key, this.address});

  @override
  State<LocationDetailsPage> createState() => _LocationDetailsPageState();
}

class _LocationDetailsPageState extends State<LocationDetailsPage> {
  String selectedType = 'Home';
  bool useAccountDetails = true;

  final TextEditingController _line1Controller = TextEditingController();
  final TextEditingController _line2Controller = TextEditingController();
  final TextEditingController _saveAsController = TextEditingController();

  bool _isAttemptedSave = false;
  bool _isEditingSaveAs = false;

  String _customerName = '';
  String _customerContact = '';

  Future<void> _fetchUserDetails() async {
    final name = await SecureStorage.getCustomerName() ?? '';
    final contact = await SecureStorage.getCustomerContact() ?? '';
    if (mounted) {
      setState(() {
        _customerName = name;
        _customerContact = contact;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    logger.i(
      "📍 LocationDetailsPage: Initializing (Edit: ${widget.address != null})",
    );
    if (widget.address != null) {
      final addr = widget.address!;
      _line1Controller.text = addr.addressLine;
      _line2Controller.text = addr.landmark ?? '';
      selectedType = addr.label;
      if (selectedType != 'Home' && selectedType != 'Office') {
        _isEditingSaveAs = true;
        _saveAsController.text = selectedType;
        selectedType = 'Other';
      }
      logger.d(
        "📍 LocationDetailsPage: Pre-filled address data. uuId: ${addr.uuId}",
      );
    }
  }

  @override
  void dispose() {
    _line1Controller.dispose();
    _line2Controller.dispose();
    _saveAsController.dispose();
    super.dispose();
  }

  String get _line1Hint {
    if (selectedType == 'Home') return 'House / Flat / Floor *';
    if (selectedType == 'Office') return 'Office name / Floor *';
    return 'Building / Floor *';
  }

  String get _line2Hint {
    if (selectedType == 'Other') return 'Street (Recommended)';
    return 'Building / Street (Recommended)';
  }

  bool get _isSaveEnabled {
    if (_line1Controller.text.trim().isEmpty) return false;
    if (_line2Controller.text.trim().isEmpty) return false;
    if (selectedType == 'Other' || _isEditingSaveAs) {
      if (_saveAsController.text.trim().isEmpty) return false;
    }
    return true;
  }

  InputDecoration _getInputDecoration(String labelText, bool showError) {
    return InputDecoration(
      labelText: labelText,
      floatingLabelStyle: TextStyle(
        color: showError ? Colors.red : Colors.grey.shade600,
        fontSize: 13.sp,
      ),
      labelStyle: TextStyle(color: Colors.grey, fontSize: 13.sp),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.w),
        borderSide: BorderSide(
          color: showError ? Colors.red : Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.w),
        borderSide: BorderSide(
          color: showError ? Colors.red : Colors.black,
          width: 1.2,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLoc = locationService.locationNotifier.value;
    final String mainTitle =
        widget.address?.landmark ?? currentLoc?.label ?? 'Location Details';
    final String subTitle =
        widget.address?.addressLine ?? currentLoc?.address ?? 'Select Location';

    return BlocListener<AddressBloc, AddressState>(
      listener: (context, state) async {
        if (state is AddressActionSuccess) {
          logger.i("📍 LocationDetailsPage: Success - Action completed");
          final currentLoc = locationService.locationNotifier.value;
          if (currentLoc != null) {
            await locationService.setLocation(currentLoc, isManual: true);
          }
          if (context.mounted) {
            context.go(AppRoutePath.home);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F3F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black, size: 24.w),
            onPressed: () {
              logger.i("📍 LocationDetailsPage: Back pressed");
              context.pop();
            },
          ),
          title: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: mainTitle,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: ' | $subTitle',
                  style: TextStyle(color: Colors.black54, fontSize: 13.sp),
                ),
              ],
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),
                Text(
                  'Receiver Details',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 12.h),
                _buildReceiverDetailsBox(),
                SizedBox(height: 16.h),
                Text(
                  'Location Details',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 12.h),
                _buildLocationDetailsBox(),
                SizedBox(height: 100.h),
              ],
            ),
          ),
        ),
        bottomSheet: BlocBuilder<AddressBloc, AddressState>(
          builder: (context, state) {
            bool isLoading = state is AddressLoading;
            return Material(
              color: const Color(0xFFF3F3F7),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 15.h,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 42.h,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (!_isSaveEnabled) {
                                logger.w(
                                  "📍 LocationDetailsPage: Save clicked but validation failed",
                                );
                                setState(() {
                                  _isAttemptedSave = true;
                                });
                                return;
                              }
                              logger.i(
                                "📍 LocationDetailsPage: Save clicked - Validation successful",
                              );
                              _showConfirmDialog(context);
                            },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: _isSaveEnabled
                            ? Colors.deepOrange.shade800
                            : Colors.grey.shade300,
                        foregroundColor: _isSaveEnabled
                            ? Colors.white
                            : Colors.grey.shade500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.w),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 20.w,
                              width: 20.w,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              (widget.address != null &&
                                      widget.address!.uuId != null)
                                  ? 'Update Address'
                                  : 'Save Address',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildReceiverDetailsBox() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.w),
      ),
      child: Row(
        children: [
          GestureDetector(
            // onTap: () {
            //   setState(() {
            //     useAccountDetails = !useAccountDetails;
            //   });
            //   logger.d(
            //     "📍 LocationDetailsPage: useAccountDetails changed to $useAccountDetails",
            //   );
            // },
            onTap: () {
              if (useAccountDetails) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.white,
                      title: const Text('Account Details Required'),
                      content: const Text(
                        'Account details are required to save the address. '
                        'You cannot disable this option.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );

                return;
              }

              setState(() {
                useAccountDetails = true;
              });
            },
            child: Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                color: useAccountDetails
                    ? Colors.deepOrange
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6.w),
                border: Border.all(
                  color: useAccountDetails
                      ? Colors.deepOrange
                      : Colors.grey.shade400,
                  width: 2.w,
                ),
              ),
              child: useAccountDetails
                  ? Icon(Icons.check, color: Colors.white, size: 14.w)
                  : null,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use my account details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${_customerName.isNotEmpty ? _customerName : 'User'}, ${_customerContact.isNotEmpty ? _customerContact : 'N/A'}',
                  style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDetailsBox() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.w),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30.w),
            ),
            child: Row(
              children: [
                _buildTypeTab('House', Icons.home_outlined),
                _buildTypeTab('Office', Icons.business_center_outlined),
                _buildTypeTab('Other', Icons.near_me_outlined),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          _buildLine1Field(),
          SizedBox(height: 16.h),
          _buildLine2Field(),
          SizedBox(height: 16.h),
          if (widget.address == null || widget.address!.uuId == null) ...[
            _buildAreaLocality(),
            SizedBox(height: 16.h),
          ],
          if (selectedType == 'Other' || _isEditingSaveAs)
            _buildSaveAsField()
          else
            _buildSaveAsContainer(),
        ],
      ),
    );
  }

  Widget _buildTypeTab(String title, IconData icon) {
    final bool isSelected =
        (title == 'House' && selectedType == 'Home') ||
        (title != 'House' && selectedType == title);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          logger.d("📍 LocationDetailsPage: Type selected: $title");
          setState(() {
            if (title == 'House') {
              selectedType = 'Home';
            } else {
              selectedType = title;
            }
            _isEditingSaveAs = false;
            _isAttemptedSave = false;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(30.w),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                size: 18.w,
              ),
              SizedBox(width: 6.w),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLine1Field() {
    bool showError = _isAttemptedSave && _line1Controller.text.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _line1Controller,
          onChanged: (_) => setState(() {}),
          decoration: _getInputDecoration(_line1Hint, showError),
        ),
        if (showError)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8.w),
                bottomRight: Radius.circular(8.w),
              ),
            ),
            child: Text(
              'This field is mandatory',
              style: TextStyle(color: Colors.red, fontSize: 12.sp),
            ),
          ),
      ],
    );
  }

  Widget _buildLine2Field() {
    bool showError = _isAttemptedSave && _line2Controller.text.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _line2Controller,
          onChanged: (_) => setState(() {}),
          decoration: _getInputDecoration(_line2Hint, showError),
        ),
        if (showError)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8.w),
                bottomRight: Radius.circular(8.w),
              ),
            ),
            child: Text(
              'Please enter Building / Street details.',
              style: TextStyle(color: Colors.red, fontSize: 12.sp),
            ),
          ),
      ],
    );
  }

  Widget _buildSaveAsField() {
    bool showError = _isAttemptedSave && _saveAsController.text.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _saveAsController,
          onChanged: (_) => setState(() {}),
          decoration: _getInputDecoration('Save address as *', showError),
        ),
        if (showError)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8.w),
                bottomRight: Radius.circular(8.w),
              ),
            ),
            child: Text(
              'This field is mandatory',
              style: TextStyle(color: Colors.red, fontSize: 12.sp),
            ),
          ),
      ],
    );
  }

  Widget _buildSaveAsContainer() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.w),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Save address as *',
                style: TextStyle(color: Colors.grey, fontSize: 12.sp),
              ),
              SizedBox(height: 4.h),
              Text(
                selectedType == 'Home' ? 'House' : selectedType,
                style: TextStyle(fontSize: 14.sp),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              logger.i("📍 LocationDetailsPage: Edit Save As clicked");
              setState(() {
                _isEditingSaveAs = true;
                _saveAsController.text = selectedType == 'Home'
                    ? 'House'
                    : selectedType;
              });
            },
            child: Text(
              'Edit',
              style: TextStyle(
                color: Colors.deepOrange.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaLocality() {
    final currentLoc = locationService.locationNotifier.value;
    final addressText =
        widget.address?.addressLine ??
        currentLoc?.address ??
        'Unknown Location';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Area/Locality',
              labelStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13.sp,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.w),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
            child: Text(
              addressText,
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        GestureDetector(
          onTap: () {
            logger.i("📍 LocationDetailsPage: Change Location clicked");
            context.pop();
          },
          child: Container(
            width: 72.w,
            height: 64.h,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12.w),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, color: Colors.deepOrange, size: 22.w),
                SizedBox(height: 2.h),
                Text(
                  'Change',
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showConfirmDialog(BuildContext parentContext) {
    final currentLoc = locationService.locationNotifier.value;
    final addressText =
        widget.address?.addressLine ??
        currentLoc?.address ??
        'Unknown Location';

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.w),
            ),
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirm Details',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    const Icon(Icons.home, color: Colors.deepOrange),
                    SizedBox(width: 8.w),
                    Text(
                      (selectedType == 'Other' || _isEditingSaveAs)
                          ? _saveAsController.text
                          : (selectedType == 'Home' ? 'House' : selectedType),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  '${_line1Controller.text}, $addressText',
                  style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Icon(Icons.phone, color: Colors.deepOrange, size: 18.w),
                    SizedBox(width: 8.w),
                    Text(
                      '${_customerName.isNotEmpty ? _customerName : 'User'}, ${_customerContact.isNotEmpty ? _customerContact : 'N/A'}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          logger.d(
                            "📍 LocationDetailsPage: Confirm dialog - Edit details clicked",
                          );
                          Navigator.pop(dialogContext);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          side: BorderSide(color: Colors.deepOrange.shade100),
                          foregroundColor: Colors.deepOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.w),
                          ),
                        ),
                        child: const Text(
                          'Edit details',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          logger.i(
                            "📍 LocationDetailsPage: Final confirmation clicked",
                          );
                          final addressData = AddressModel(
                            uuId: widget.address?.uuId,
                            label: (selectedType == 'Other' || _isEditingSaveAs)
                                ? _saveAsController.text
                                : selectedType,
                            deliveryName: _customerName.isNotEmpty
                                ? _customerName
                                : 'User',
                            deliveryPhone: _customerContact.isNotEmpty
                                ? _customerContact
                                : 'N/A',
                            addressLine: _line1Controller.text,
                            landmark: _line2Controller.text.isEmpty
                                ? null
                                : _line2Controller.text,
                            city:
                                (widget.address?.city != null &&
                                    widget.address!.city!.isNotEmpty)
                                ? widget.address!.city
                                : "Kolhapur",
                            pincode:
                                (widget.address?.pincode != null &&
                                    widget.address!.pincode!.isNotEmpty)
                                ? widget.address!.pincode
                                : "416001",
                            lat: widget.address?.lat != null
                                ? double.parse(
                                    widget.address!.lat!.toStringAsFixed(6),
                                  )
                                : (currentLoc?.lat != null
                                      ? double.parse(
                                          currentLoc!.lat.toStringAsFixed(6),
                                        )
                                      : null),
                            lng: widget.address?.lng != null
                                ? double.parse(
                                    widget.address!.lng!.toStringAsFixed(6),
                                  )
                                : (currentLoc?.lng != null
                                      ? double.parse(
                                          currentLoc!.lng.toStringAsFixed(6),
                                        )
                                      : null),
                            isDefault: widget.address?.isDefault ?? false,
                          );

                          if (widget.address != null &&
                              widget.address!.uuId != null) {
                            logger.d(
                              "📍 LocationDetailsPage: Dispatching UpdateAddressEvent",
                            );
                            parentContext.read<AddressBloc>().add(
                              UpdateAddressEvent(
                                uuId: widget.address!.uuId!,
                                address: addressData,
                              ),
                            );
                          } else {
                            logger.d(
                              "📍 LocationDetailsPage: Dispatching AddAddressEvent",
                            );
                            parentContext.read<AddressBloc>().add(
                              AddAddressEvent(addressData),
                            );
                          }
                          Navigator.of(dialogContext).pop();

                          if (widget.address != null &&
                              widget.address!.uuId != null) {
                            if (parentContext.canPop()) {
                              parentContext.pop();
                            } else {
                              parentContext.go(AppRoutePath.address);
                            }
                          } else {
                            if (parentContext.canPop()) {
                              parentContext.pop();
                              if (parentContext.canPop()) {
                                parentContext.pop();
                              }
                            } else {
                              parentContext.go(AppRoutePath.address);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.w),
                          ),
                        ),
                        child: Text(
                          (widget.address != null &&
                                  widget.address!.uuId != null)
                              ? 'Update'
                              : 'Confirm',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
