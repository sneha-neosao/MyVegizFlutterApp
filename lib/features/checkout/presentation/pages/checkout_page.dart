import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_vegiz_flutter/features/address/bloc/address_bloc.dart';
import 'package:my_vegiz_flutter/features/address/bloc/address_event.dart';
import 'package:my_vegiz_flutter/features/address/bloc/address_state.dart';

import 'package:my_vegiz_flutter/features/address/data/models/address_model.dart';
import 'package:my_vegiz_flutter/routes/app_route_path.dart';
import 'package:my_vegiz_flutter/features/cart/data/models/cart_model.dart'
    as model;
import 'package:my_vegiz_flutter/features/cart/data/cart_data.dart';
import 'package:my_vegiz_flutter/config/injector_conf.dart';
import 'package:my_vegiz_flutter/features/checkout/data/models/checkout_model.dart';
import 'package:my_vegiz_flutter/core/utils/snackbar_utils.dart';

import '../../bloc/checkout_bloc.dart';
import '../../bloc/checkout_event.dart';
import '../../bloc/checkout_state.dart';

class CheckoutPage extends StatefulWidget {
  final model.CartData? cartData;
  const CheckoutPage({super.key, this.cartData});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? selectedPaymentMethod;
  String? selectedSlotUuid;
  String? selectedSlotLabel;
  AddressModel? selectedAddress;

  late CheckoutBloc _checkoutBloc;
  late AddressBloc _addressBloc;

  @override
  void initState() {
    super.initState();
    _checkoutBloc = getIt<CheckoutBloc>()..add(LoadCheckoutDataEvent());
    _addressBloc = getIt<AddressBloc>()..add(FetchAddressList());
  }

  @override
  void dispose() {
    _checkoutBloc.close();
    _addressBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartData = widget.cartData;
    final items = cartData?.items ?? [];

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: Text('Your cart is empty')),
      );
    }

    final double itemsTotal = cartData?.productsTotal ?? 0.0;
    final double deliveryFee = cartData?.deliveryInfo?.deliveryCharge ?? 0.0;
    final double totalAmount = cartData?.grandTotal ?? 0.0;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => _checkoutBloc),
        BlocProvider(create: (_) => _addressBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<CheckoutBloc, CheckoutState>(
            listener: (context, state) {
              if (state is OrderPlacedSuccess) {
                // Clear cart locally
                globalCart.clear();
                saveCartToStorage();
                context.pushReplacement(
                  AppRoutePath.success,
                  extra: isFoodCart,
                );
              } else if (state is OrderPlacedFailure) {
                String cleanMessage = state.message;
                if (cleanMessage.startsWith('Invalid Request: ')) {
                  cleanMessage = cleanMessage.replaceFirst(
                    'Invalid Request: ',
                    '',
                  );
                }

                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: const Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Cannot Place Order',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    content: Text(
                      cleanMessage,
                      style: const TextStyle(fontSize: 15),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text(
                          'OK',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          BlocListener<AddressBloc, AddressState>(
            listener: (context, state) {
              if (state is AddressLoaded && state.addresses.isNotEmpty) {
                setState(() {
                  // Keep current if still valid, else select first
                  final exists = state.addresses.any(
                    (a) =>
                        a.uuId == selectedAddress?.uuId &&
                        selectedAddress?.uuId != null,
                  );
                  if (!exists || selectedAddress == null) {
                    selectedAddress = state.addresses.first;
                  }
                });
              } else if (state is AddressError) {
                SnackbarUtils.showErrorSnackbar(context, state.message);
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black,
                size: 20,
              ),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Checkout',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
          ),
          body: BlocBuilder<CheckoutBloc, CheckoutState>(
            buildWhen: (previous, current) =>
                current is CheckoutLoaded ||
                current is CheckoutLoading ||
                current is CheckoutError,
            builder: (context, state) {
              if (state is CheckoutLoading || state is CheckoutInitial) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is CheckoutError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            _checkoutBloc.add(LoadCheckoutDataEvent()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else if (state is CheckoutLoaded) {
                // Auto-select payment method if none selected and COD is enabled
                if (selectedPaymentMethod == null &&
                    state.settings.isCodEnabled) {
                  // Postpone setState to avoid build phase errors
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => selectedPaymentMethod = 'COD');
                  });
                }

                return Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildItemsListSection(items),
                          _buildDeliveryAddressSection(context),
                          _buildDeliveryInfoSection(deliveryFee),
                          _buildDeliverySlotsSection(state.slots),
                          _buildPaymentMethodSection(state.settings),
                          _buildBillDetailsSection(
                            itemsTotal,
                            deliveryFee,
                            totalAmount,
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                    BlocBuilder<CheckoutBloc, CheckoutState>(
                      builder: (context, buttonState) {
                        if (buttonState is OrderPlacing) {
                          return Positioned.fill(
                            child: Container(
                              color: Colors.black12,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          bottomSheet: _buildStickyCTA(totalAmount),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black54,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildItemsListSection(List<model.CartItem> items) {
    return _buildSectionCard(
      title: 'Order Summary',
      child: Column(
        children: items.map((item) {
          final imageUrl = (item.product?.images.isNotEmpty ?? false)
              ? item.product!.images.first.productImage
              : (item.product?.productImage ?? '');
          final title = item.product?.productName ?? 'Unknown Product';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey.shade100,
                      child: const Icon(
                        Icons.fastfood,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Qty: ${item.quantity}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${item.totalPrice.toInt()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeliveryAddressSection(BuildContext context) {
    return _buildSectionCard(
      title: 'Delivery Address',
      child: BlocBuilder<AddressBloc, AddressState>(
        builder: (context, state) {
          if (state is AddressLoading && selectedAddress == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (selectedAddress == null) {
            return Row(
              children: [
                const Icon(Icons.location_off, color: Colors.grey),
                const SizedBox(width: 12),
                const Expanded(child: Text("No address selected")),
                TextButton(
                  onPressed: () async {
                    final result = await context.push(AppRoutePath.address);
                    if (result != null && result is AddressModel) {
                      setState(() {
                        selectedAddress = result;
                      });
                    }
                    if (mounted) {
                      _addressBloc.add(FetchAddressList());
                    }
                  },
                  child: const Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Colors.redAccent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedAddress!.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedAddress!.addressLine,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () async {
                  final result = await context.push(AppRoutePath.address);
                  if (result != null && result is AddressModel) {
                    setState(() {
                      selectedAddress = result;
                    });
                  }
                  if (mounted) {
                    _addressBloc.add(FetchAddressList());
                  }
                },
                child: const Text(
                  'Change',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeliveryInfoSection(double deliveryCharge) {
    return _buildSectionCard(
      title: 'Delivery Information',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(
                Icons.delivery_dining_outlined,
                size: 20,
                color: Colors.black54,
              ),
              SizedBox(width: 8),
              Text(
                'Delivery Fee',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Text(
            '₹${deliveryCharge.toInt()}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySlotsSection(List<SlotModel> slots) {
    if (slots.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      title: 'Delivery Slots',
      child: Column(
        children: slots.map((slot) {
          bool isSelected = selectedSlotUuid == slot.uuId;
          return GestureDetector(
            onTap: () => setState(() {
              selectedSlotUuid = slot.uuId;
              selectedSlotLabel = slot.label;
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.green : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? Colors.green.withValues(alpha: 0.05)
                    : Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: isSelected ? Colors.green : Colors.grey.shade600,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      slot.label,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    )
                  else
                    Icon(
                      Icons.radio_button_off,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentMethodSection(OrderSettingsModel settings) {
    final bool isOnline = settings.isOnlineEnabled ||
        settings.availableModes.any((m) => m.toUpperCase() == 'ONLINE');
    final bool isCod = settings.isCodEnabled ||
        settings.availableModes.any((m) => m.toUpperCase() == 'COD');

    return _buildSectionCard(
      title: 'Payment Method',
      child: Column(
        children: [
          if (isOnline) ...[
            _buildPaymentOption('UPI', Icons.account_balance_wallet_outlined),
            _buildPaymentOption('Card', Icons.credit_card_outlined),
          ],
          if (isCod)
            _buildPaymentOption('COD (Cash on Delivery)', Icons.money_outlined),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon) {
    bool isSelected = selectedPaymentMethod == title;
    return GestureDetector(
      onTap: () => setState(() => selectedPaymentMethod = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Colors.green.withValues(alpha: 0.05)
              : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.green : Colors.grey.shade600,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.green, size: 20)
            else
              Icon(
                Icons.radio_button_off,
                color: Colors.grey.shade400,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillDetailsSection(
    double itemsTotal,
    double deliveryFee,
    double totalAmount,
  ) {
    return _buildSectionCard(
      title: 'Bill Details',
      child: Column(
        children: [
          _buildBillRow('Subtotal', '₹${itemsTotal.toInt()}'),
          const SizedBox(height: 12),
          _buildBillRow('Delivery Fee', '₹${deliveryFee.toInt()}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${totalAmount.toInt()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStickyCTA(double total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹${total.toInt()}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'VIEW DETAILED BILL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: selectedSlotUuid == null
                    ? null
                    : () {
                        String finalPaymentMode = 'COD';
                        if (selectedPaymentMethod == 'UPI' ||
                            selectedPaymentMethod == 'Card') {
                          finalPaymentMode = 'ONLINE';
                          SnackbarUtils.showSuccessSnackbar(
                            context,
                            'Redirecting to Payment Gateway...',
                          );
                        }

                        _checkoutBloc.add(
                          PlaceOrderEvent(
                            paymentMode: selectedPaymentMethod ?? '',
                            addressUuid:
                                selectedAddress?.uuId ??
                                selectedAddress?.id?.toString() ??
                                '',
                            slotUuid: selectedSlotUuid ?? '',
                            customerNote: '',
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Place Order',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
