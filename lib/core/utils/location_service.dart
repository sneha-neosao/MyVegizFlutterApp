import 'dart:convert';
import 'package:my_vegiz_flutter/core/storage/secure_storage.dart';
import 'package:my_vegiz_flutter/features/address/bloc/address_bloc.dart';
import 'package:my_vegiz_flutter/features/address/data/models/address_model.dart';
import 'package:my_vegiz_flutter/features/address/data/repository/address_repository.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../config/injector_conf.dart';
import '../../features/address/bloc/address_event.dart';
import './logger.dart';

class LocationState {
  final double lat;
  final double lng;
  final String address;
  final String? label;
  final String? city;
  final String? pincode;

  LocationState({
    required this.lat,
    required this.lng,
    required this.address,
    this.label,
    this.city,
    this.pincode,
  });

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'address': address,
    'label': label,
    'city': city,
    'pincode': pincode,
  };

  factory LocationState.fromJson(Map<String, dynamic> json) {
    return LocationState(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String? ?? '',
      label: json['label'] as String?,
      city: json['city'] as String?,
      pincode: json['pincode'] as String?,
    );
  }

  @override
  String toString() => 'LocationState(lat=$lat, lng=$lng, address="$address", label=$label, city=$city, pincode=$pincode)';
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final ValueNotifier<LocationState?> locationNotifier = ValueNotifier(null);
  bool isManuallySelected = false;
  final _geocoding = Geocoding();

  /// Loads previously saved active location from secure storage
  Future<LocationState?> loadSavedLocation() async {
    try {
      final jsonStr = await SecureStorage.getActiveLocationJson();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        final state = LocationState.fromJson(decoded);
        locationNotifier.value = state;
        isManuallySelected = true;
        logger.i('📍 LocationService: Restored saved location: ${state.label} (${state.lat}, ${state.lng})');
        return state;
      }
    } catch (e) {
      logger.e('📍 LocationService: Error restoring saved location: $e');
    }
    return null;
  }

  /// Sets location and saves it to storage. If [isManual] is true, sticky behavior prevents background GPS overrides.
  Future<void> setLocation(LocationState state, {bool isManual = true}) async {
    isManuallySelected = isManual;
    locationNotifier.value = state;
    try {
      await SecureStorage.saveActiveLocationJson(jsonEncode(state.toJson()));
      await SecureStorage.saveLocationConfirmed(true);
      logger.i('📍 LocationService: Location set and saved (manual=$isManual) → ${state.label} (${state.lat}, ${state.lng})');
    } catch (e) {
      logger.e('📍 LocationService: Error saving active location: $e');
    }
  }

  Future<bool> isServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<void> requestPermissionAndFetchLocation({bool force = false}) async {
    if (isManuallySelected && !force && locationNotifier.value != null) {
      logger.i('📍 LocationService: Sticky address active, skipping automatic GPS fetch');
      return;
    }
    logger.i('📍 LocationService: Requesting location permission and fetching... (force=$force)');

    bool serviceEnabled = await isServiceEnabled();
    if (!serviceEnabled) {
      logger.w('📍 LocationService: Location services are disabled on device');
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      logger.d('📍 LocationService: Permission denied — requesting...');
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        logger.w('📍 LocationService: User denied location permission');
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      logger.e('📍 LocationService: Permission permanently denied');
      return Future.error(
        'Location permissions are permanently denied. Please enable them in settings.',
      );
    }

    logger.i('📍 LocationService: Fetching fast location...');
    
    // ⚡️ Step 1: Try to get last known position first (instant)
    Position? position = await Geolocator.getLastKnownPosition();
    if (position != null) {
      logger.i('📍 LocationService: Using last known position (FAST) — lat=${position.latitude}, lng=${position.longitude}');
      await updateLocation(position.latitude, position.longitude);
    }

    // ⚡️ Step 2: Fetch fresh position with Medium accuracy for faster lock
    try {
      logger.i('📍 LocationService: Requesting fresh GPS lock (Medium accuracy)...');
      final freshPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      logger.i('📍 LocationService: Fresh GPS acquired — lat=${freshPosition.latitude}, lng=${freshPosition.longitude}');
      await updateLocation(freshPosition.latitude, freshPosition.longitude);
    } catch (e) {
      logger.w('📍 LocationService: Fresh GPS fetch failed or timed out — $e');
      // If we didn't even have a last known position, we might need to handle this error
      if (locationNotifier.value == null) {
        return Future.error('Could not acquire location: $e');
      }
    }
  }

  bool _isAutoSaving = false;

  Future<void> autoSaveLocationAddress({
    required double lat,
    required double lng,
    required String address,
    String? city,
    String? pincode,
  }) async {
    if (_isAutoSaving) return;
    _isAutoSaving = true;
    try {
      final isLoggedIn = await SecureStorage.isLoggedIn();
      if (!isLoggedIn) {
        logger.d('📍 LocationService: User not logged in, skipping auto-save');
        _isAutoSaving = false;
        return;
      }

      final addressRepo = getIt<AddressRepository>();
      final result = await addressRepo.getAddressList();
      
      await result.fold(
        (failure) async {
          // logger.e('📍 LocationService: Failed to fetch address list for auto-save: ${failure?.message}');
        },
        (response) async {
          bool alreadyExists = false;
          AddressModel? matchingAddress;
          for (var addr in response.addresses) {
            if (addr.lat != null && addr.lng != null) {
              final latDiff = (addr.lat! - lat).abs();
              final lngDiff = (addr.lng! - lng).abs();
              if (latDiff < 0.001 && lngDiff < 0.001) {
                alreadyExists = true;
                matchingAddress = addr;
                break;
              }
            }
          }

          if (alreadyExists && matchingAddress != null) {
            logger.i('📍 LocationService: Address already exists in saved addresses: ${matchingAddress.label}');
            
            // Set the notifier's label to the matching address's label
            final currentVal = locationNotifier.value;
            if (currentVal != null) {
              locationNotifier.value = LocationState(
                lat: currentVal.lat,
                lng: currentVal.lng,
                address: currentVal.address,
                label: matchingAddress.label,
                city: currentVal.city,
                pincode: currentVal.pincode,
              );
            }
            
            // Sync with SecureStorage selected address
            await SecureStorage.saveSelectedAddressUuid(
              matchingAddress.uuId ?? matchingAddress.id.toString(),
            );
            
            _isAutoSaving = false;
            return;
          }

          logger.i('📍 LocationService: Auto-saving current location as default address...');
          final name = await SecureStorage.getCustomerName() ?? 'User';
          final contact = await SecureStorage.getCustomerContact() ?? 'N/A';

          final newAddress = AddressModel(
            label: 'Other',
            deliveryName: name,
            deliveryPhone: contact,
            addressLine: address,
            city: city ?? 'Kolhapur',
            pincode: pincode ?? '416001',
            lat: double.parse(lat.toStringAsFixed(6)),
            lng: double.parse(lng.toStringAsFixed(6)),
            isDefault: true,
          );

          final saveResult = await addressRepo.addAddress(newAddress);
          await saveResult.fold(
            (failure) async {
              // logger.e('📍 LocationService: Auto-save address failed: ${failure.message}');
            },
            (savedAddress) async {
              logger.i('📍 LocationService: Auto-save address successful! Uuid: ${savedAddress.uuId}');
              
              // Set the notifier's label to the saved address's label
              final currentVal = locationNotifier.value;
              if (currentVal != null) {
                locationNotifier.value = LocationState(
                  lat: currentVal.lat,
                  lng: currentVal.lng,
                  address: currentVal.address,
                  label: savedAddress.label,
                  city: currentVal.city,
                  pincode: currentVal.pincode,
                );
              }
              
              // Sync with SecureStorage selected address
              if (savedAddress.uuId != null) {
                await SecureStorage.saveSelectedAddressUuid(savedAddress.uuId!);
              }

              // Dispatch FetchAddressList to update AddressListPage instantly!
              getIt<AddressBloc>().add(FetchAddressList());
            },
          );
        },
      );
    } catch (e) {
      logger.e('📍 LocationService: Error during auto-save: $e');
    } finally {
      _isAutoSaving = false;
    }
  }

  Future<void> updateLocation(double lat, double lng) async {
    logger.d('📍 LocationService: Reverse-geocoding lat=$lat, lng=$lng...');
    String addressString = 'Unknown Location';
    String? city;
    String? pincode;
    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).toList();
        addressString = parts.join(', ');
        city = place.locality ?? place.subAdministrativeArea;
        pincode = place.postalCode;
      }
    } catch (e) {
      logger.w('📍 LocationService: Reverse-geocoding failed — $e');
    }

    final newState = LocationState(
      lat: lat,
      lng: lng,
      address: addressString,
      label: 'Other',
      city: city,
      pincode: pincode,
    );
    locationNotifier.value = newState;
    try {
      await SecureStorage.saveActiveLocationJson(jsonEncode(newState.toJson()));
    } catch (_) {}
    logger.i('📍 LocationService: Location updated → $locationNotifier.value');

    // Trigger auto-save asynchronously
    autoSaveLocationAddress(
      lat: lat,
      lng: lng,
      address: addressString,
      city: city,
      pincode: pincode,
    );
  }
}

final locationService = LocationService();
