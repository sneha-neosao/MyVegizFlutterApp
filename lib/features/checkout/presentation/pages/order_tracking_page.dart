import 'dart:async';
import 'dart:math' show atan2, cos, pi, sin, sqrt;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:my_vegiz_flutter/routes/app_route_path.dart';
import 'package:my_vegiz_flutter/core/api/api/api_url.dart';
import 'package:dio/dio.dart';
import 'package:my_vegiz_flutter/core/services/socket_connect_service.dart';
import 'package:my_vegiz_flutter/core/storage/secure_storage.dart';
import '../../../../core/utils/logger.dart';

class OrderTrackingPage extends StatefulWidget {
  final LatLng storeLocation;
  final LatLng deliveryLocation;
  final LatLng? initialDeliveryBoyLocation;
  final String storeName;
  final String deliveryName;
  final String orderId;
  final bool isFood;

  const OrderTrackingPage({
    super.key,
    required this.storeLocation,
    required this.deliveryLocation,
    required this.orderId,
    this.initialDeliveryBoyLocation,
    this.storeName = 'Store',
    this.deliveryName = 'Delivery Location',
    this.isFood = true,
  });

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  GoogleMapController? mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  bool _isLoading = true;

  late final CustomerTrackingSocketService _socketService;
  StreamSubscription? _socketSubscription;
  LatLng? _deliveryBoyLocation;
  BitmapDescriptor? _deliveryBoyIcon;
  double _deliveryBoyBearing = 0.0; // rotation angle in degrees (0 = north)

  List<LatLng> _fullRoutePoints = [];
  bool _isFetchingDirections = false;

  @override
  void initState() {
    super.initState();
    _socketService = CustomerTrackingSocketService();
    if (widget.initialDeliveryBoyLocation != null) {
      _deliveryBoyLocation = widget.initialDeliveryBoyLocation;
    }
    // Load icon first, then start map & socket so PNG is ready on first update
    _loadDeliveryBoyIconThenInit();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _socketService.dispose();
    super.dispose();
  }

  Future<void> _loadDeliveryBoyIconThenInit() async {
    try {
      final icon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(55, 55)),
        'assets/images/map_marker.png',
      );
      if (mounted) {
        _deliveryBoyIcon = icon;
      }
    } catch (e) {
      logger.e('Failed to load delivery boy icon: $e');
    }
    if (mounted) {
      _initMapData();
      _startSocketTracking();
    }
  }

  void _initMapData() {
    setState(() {
      _updateMarkers();
      if (_deliveryBoyLocation == null) {
        _isLoading = false;
      }
    });
    if (_deliveryBoyLocation != null) {
      _getDirections(origin: _deliveryBoyLocation!);
    }
  }

  /// Rebuilds the _markers set. Must be called inside a setState() by the caller.
  void _updateMarkers() {
    _markers.clear();
    _markers.addAll([
      Marker(
        markerId: const MarkerId('store'),
        position: widget.storeLocation,
        infoWindow: InfoWindow(title: widget.storeName),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
      Marker(
        markerId: const MarkerId('delivery'),
        position: widget.deliveryLocation,
        infoWindow: InfoWindow(title: widget.deliveryName),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    ]);

    if (_deliveryBoyLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('delivery_boy'),
          position: _deliveryBoyLocation!,
          infoWindow: const InfoWindow(title: 'Delivery Partner'),
          icon: _deliveryBoyIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          // Anchor at bottom-center so the marker base sits on the road point
          anchor: const Offset(0.5, 1.0),
          flat: true,        // lies flat on the map surface
          rotation: _deliveryBoyBearing, // rotates to face direction of travel
        ),
      );
    }
  }

  /// Returns the compass bearing (0–360°) from [from] to [to].
  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final dLng = (to.longitude - from.longitude) * pi / 180;

    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);

    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  /// Calculates great-circle distance between two points in meters.
  double _distanceBetween(LatLng p1, LatLng p2) {
    const earthRadius = 6371000.0;
    final dLat = (p2.latitude - p1.latitude) * pi / 180;
    final dLng = (p2.longitude - p1.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(p1.latitude * pi / 180) *
            cos(p2.latitude * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Snaps a raw GPS coordinate to the nearest road using Google Roads API.
  /// Falls back to the original [location] if the API fails.
  Future<LatLng> _snapToRoad(LatLng location) async {
    try {
      final dio = Dio();
      final url =
          'https://roads.googleapis.com/v1/snapToRoads'
          '?path=${location.latitude},${location.longitude}'
          '&key=${ApiUrl.googlePlacesApiKey}';
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;
        final snappedPoints = data['snappedPoints'] as List?;
        if (snappedPoints != null && snappedPoints.isNotEmpty) {
          final loc = snappedPoints[0]['location'];
          final snappedLat = (loc['latitude'] as num).toDouble();
          final snappedLng = (loc['longitude'] as num).toDouble();
          logger.d('Snapped to road: $snappedLat, $snappedLng');
          return LatLng(snappedLat, snappedLng);
        }
      }
    } catch (e) {
      logger.w('Roads API snap failed, using raw GPS: $e');
    }
    return location; // fallback to raw GPS
  }

  Future<void> _startSocketTracking() async {
    try {
      final token = await SecureStorage.getAccessToken();
      if (token == null) {
        logger.e('OrderTrackingPage: Access token not found');
        return;
      }

      await _socketService.startTracking(
        socketUrl: 'https://web.neosao.co.in',
        jwtToken: token,
        orderId: widget.orderId,
      );

      _socketSubscription = _socketService.messageStream.listen((message) async {
        if (message['event'] == 'order:completed') {
          logger.i('OrderTrackingPage: order:completed event received. Returning to order details.');
          if (!mounted) return;

          final completedMsg = message['message']?.toString() ?? 'Order delivered successfully';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(completedMsg),
              backgroundColor: Colors.green,
            ),
          );

          if (context.canPop()) {
            context.pop(true);
          } else {
            context.pushReplacement(
              AppRoutePath.orderDetails,
              extra: {
                'orderId': widget.orderId,
                'isFood': widget.isFood,
              },
            );
          }
          return;
        }

        if (message['event'] == 'location:update') {
          final double? lat = double.tryParse(message['lat']?.toString() ?? '');
          final double? lng = double.tryParse(message['lng']?.toString() ?? '');
          final double? bearing = double.tryParse(message['bearing']?.toString() ?? message['heading']?.toString() ?? '');

          if (lat != null && lng != null) {
            final rawLocation = LatLng(lat, lng);

            // Calculate bearing BEFORE snapping so direction is accurate (if bearing not in event)
            final previousLocation = _deliveryBoyLocation;

            // Snap to nearest road, then update marker
            final snappedLocation = await _snapToRoad(rawLocation);

            if (!mounted) return;
            setState(() {
              // Update bearing from event if provided, otherwise calculate from previous position
              if (bearing != null) {
                _deliveryBoyBearing = bearing;
              } else if (previousLocation != null) {
                _deliveryBoyBearing = _calculateBearing(previousLocation, snappedLocation);
              }
              _deliveryBoyLocation = snappedLocation;
              _updateMarkers();
            });

            // Ensure route always starts at the delivery boy's latest position
            if (_fullRoutePoints.isEmpty) {
              _getDirections(origin: snappedLocation);
            } else {
              _trimOrUpdateRoute(snappedLocation);
            }
            logger.d('Delivery boy location updated (snapped): ${snappedLocation.latitude}, ${snappedLocation.longitude}, bearing: $_deliveryBoyBearing°');
          }
        }
      });
    } catch (e) {
      logger.e('Error starting socket tracking: $e');
    }
  }

  /// Trims points behind the delivery boy so the polyline starts at their current position.
  /// If the delivery boy is off-route by more than 200m, re-fetches directions.
  void _trimOrUpdateRoute(LatLng currentLocation) {
    if (_fullRoutePoints.isEmpty) {
      _getDirections(origin: currentLocation);
      return;
    }

    int closestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < _fullRoutePoints.length; i++) {
      final d = _distanceBetween(currentLocation, _fullRoutePoints[i]);
      if (d < minDistance) {
        minDistance = d;
        closestIndex = i;
      }
    }

    if (minDistance > 200) {
      _getDirections(origin: currentLocation);
      return;
    }

    final remaining = <LatLng>[
      currentLocation,
      ..._fullRoutePoints.sublist(
        closestIndex < _fullRoutePoints.length - 1 ? closestIndex + 1 : closestIndex,
      ),
    ];
    _updatePolylines(remaining);
  }

  void _updatePolylines(List<LatLng> points) {
    if (points.isEmpty) return;
    setState(() {
      _polylines.clear();
      // Outer border for the route (casing)
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route_border'),
          points: points,
          color: const Color(0xFF1967D2), // Darker Google Blue
          width: 10,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
      // Main route line
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: const Color(0xFF4285F4), // Google Maps Blue
          width: 6,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    });
  }

  Future<void> _getDirections({required LatLng origin}) async {
    if (_isFetchingDirections) return;
    _isFetchingDirections = true;
    logger.d('Fetching directions from $origin to ${widget.deliveryLocation}');
    try {
      final dio = Dio();
      final url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${widget.deliveryLocation.latitude},${widget.deliveryLocation.longitude}'
          '&key=${ApiUrl.googlePlacesApiKey}';

      logger.d('Directions API URL: $url');
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          final points = data['routes'][0]['overview_polyline']['points'];
          final decodedPoints = _decodePolyline(points);

          _fullRoutePoints = List.from(decodedPoints);
          final routePoints = [origin, ...decodedPoints];

          _updatePolylines(routePoints);
          _fitBounds(routePoints);
        } else {
          logger.e('Directions API error status: ${data['status']}');
          logger.e('Directions API error message: ${data['error_message'] ?? 'No message'}');
          _showError('Google Directions API Error: ${data['status']}. Please ensure Directions API is enabled in Google Cloud Console.');
        }
      }
    } catch (e) {
      logger.e('Error fetching directions: $e');
      _showError('Failed to load directions.');
    } finally {
      _isFetchingDirections = false;
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _fitBounds(List<LatLng> points) {
    if (mapController == null || points.isEmpty) return;

    double? minLat, maxLat, minLng, maxLng;

    for (final point in points) {
      if (minLat == null || point.latitude < minLat) minLat = point.latitude;
      if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
      if (minLng == null || point.longitude < minLng) minLng = point.longitude;
      if (maxLng == null || point.longitude > maxLng) maxLng = point.longitude;
    }

    if (minLat == maxLat && minLng == maxLng) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(minLat!, minLng!), 15),
      );
      return;
    }

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat!, minLng!),
          northeast: LatLng(maxLat!, maxLng!),
        ),
        50.0,
      ),
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Track Your Order',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.deliveryLocation,
              zoom: 15,
              tilt: 45,
            ),
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
              if (_polylines.isNotEmpty) {
                _fitBounds(_polylines.first.points);
              } else if (_deliveryBoyLocation != null) {
                _fitBounds([_deliveryBoyLocation!, widget.deliveryLocation]);
              } else {
                _fitBounds([widget.storeLocation, widget.deliveryLocation]);
              }
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
