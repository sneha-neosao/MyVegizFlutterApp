import 'package:my_vegiz_flutter/core/storage/secure_storage.dart';
import 'package:my_vegiz_flutter/core/utils/location_service.dart';
import 'package:my_vegiz_flutter/core/utils/logger.dart';
import 'package:my_vegiz_flutter/features/address/data/models/address_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/usecase/address_usecases.dart';
import './address_event.dart';
import './address_state.dart';

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  final GetAddressListUseCase getAddressListUseCase;
  final AddAddressUseCase addAddressUseCase;
  final UpdateAddressUseCase updateAddressUseCase;
  final DeleteAddressUseCase deleteAddressUseCase;

  AddressBloc({
    required this.getAddressListUseCase,
    required this.addAddressUseCase,
    required this.updateAddressUseCase,
    required this.deleteAddressUseCase,
  }) : super(AddressInitial()) {
    on<FetchAddressList>((event, emit) async {
      logger.i("📍 AddressBloc: Fetching address list");
      emit(AddressLoading());
      final result = await getAddressListUseCase();
      await result.fold(
        (failure) async {
          logger.e("📍 AddressBloc Fetch Error: ${failure.message}");
          emit(AddressError(failure.message));
        },
        (response) async {
          logger.d(
            "📍 AddressBloc: Fetched ${response.addresses.length} addresses",
          );
          if (response.addresses.isNotEmpty) {
            final savedUuid = await SecureStorage.getSelectedAddressUuid();
            AddressModel? targetAddress;
            if (savedUuid != null && savedUuid.isNotEmpty) {
              final match = response.addresses.where(
                (a) => (a.uuId ?? a.id.toString()) == savedUuid,
              );
              if (match.isNotEmpty) {
                targetAddress = match.first;
              }
            }
            targetAddress ??= response.addresses.firstWhere(
              (a) => a.isDefault,
              orElse: () => response.addresses.first,
            );

            if (targetAddress.lat != null && targetAddress.lng != null) {
              final currentVal = locationService.locationNotifier.value;
              if (currentVal == null) {
                final newState = LocationState(
                  lat: targetAddress.lat!,
                  lng: targetAddress.lng!,
                  address: targetAddress.addressLine,
                  label: targetAddress.label,
                  city: targetAddress.city,
                  pincode: targetAddress.pincode,
                );
                locationService.setLocation(newState, isManual: false);
                logger.i(
                  "📍 AddressBloc: Set locationNotifier to default/selected address: ${targetAddress.label} (${targetAddress.lat}, ${targetAddress.lng})",
                );
              }
            }
          }
          emit(AddressLoaded(response.addresses));
        },
      );
    });

    on<AddAddressEvent>((event, emit) async {
      logger.i("📍 AddressBloc: Adding new address");
      emit(AddressLoading());
      final result = await addAddressUseCase(event.address);
      result.fold(
        (failure) {
          logger.e("📍 AddressBloc Add Error: ${failure.message}");
          emit(AddressError(failure.message));
        },
        (address) {
          logger.i("📍 AddressBloc: Address added successfully");
          emit(AddressActionSuccess(address.message ?? "Address added successfully"));
          if (!isClosed) add(FetchAddressList());
        },
      );
    });

    on<UpdateAddressEvent>((event, emit) async {
      logger.i("📍 AddressBloc: Updating address ${event.uuId}");
      emit(AddressLoading());
      final result = await updateAddressUseCase(event.uuId, event.address);
      result.fold(
        (failure) {
          logger.e("📍 AddressBloc Update Error: ${failure.message}");
          emit(AddressError(failure.message));
        },
        (address) {
          logger.i("📍 AddressBloc: Address updated successfully");
          emit(AddressActionSuccess(address.message ?? "Address updated successfully"));
          if (!isClosed) add(FetchAddressList());
        },
      );
    });

    on<DeleteAddressEvent>((event, emit) async {
      logger.i("📍 AddressBloc: Deleting address ${event.uuId}");
      emit(AddressLoading());
      final result = await deleteAddressUseCase(event.uuId);
      result.fold(
        (failure) {
          logger.e("📍 AddressBloc Delete Error: ${failure.message}");
          emit(AddressError(failure.message));
        },
        (message) {
          logger.i("📍 AddressBloc: Address deleted successfully");
          emit(AddressActionSuccess(message));
          if (!isClosed) add(FetchAddressList());
        },
      );
    });

    on<ClearAddressEvent>((event, emit) {
      logger.i("📍 AddressBloc: Clearing address list");
      emit(AddressInitial());
    });
  }
}
