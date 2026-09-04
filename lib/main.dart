import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './config/injector_conf.dart';
import './routes/routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import './features/cart/bloc/cart_bloc.dart';
import './features/cart/bloc/food_cart_bloc.dart';
import './features/cart/bloc/cart_state.dart';
import './features/cart/bloc/cart_event.dart';
import './widgets/different_zone_cart_dialog.dart';

import './features/cart/data/cart_data.dart';
import './features/wishlist/bloc/wishlist_bloc.dart';
import './core/storage/secure_storage.dart';
import './core/storage/food_cart_db.dart';
import './routes/app_route_path.dart';
import 'dart:convert';
import './core/utils/logger.dart';
import './core/utils/profile_image_notifier.dart';
import './core/connectivity/connectivity_bloc.dart';
import './core/connectivity/connectivity_state.dart';
import './core/connectivity/connectivity_event.dart';
import 'widgets/no_internet_screen.dart';
import './features/address/bloc/address_bloc.dart';
import './features/address/bloc/address_event.dart';
import './core/utils/responsive_utils.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import './core/services/notification_service.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description: 'This channel is used for important notifications.', // description
  importance: Importance.high,
  playSound: true,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('A bg message just showed up :  ${message.messageId}');
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  logger.i('🚀 App: Starting MyViggies...');

  configureDependencies();
  logger.d('⚙️ App: Dependencies configured via GetIt');

  AppRoutes.initialRoute = AppRoutePath.splash;

  // Run the app immediately so the splash screen video renders instantly
  runApp(
    const MyViggiesApp(isLoggedIn: false),
  );

  // Initialize background services asynchronously without blocking initial UI render
  _initializeBackgroundServices();
}

Future<void> _initializeBackgroundServices() async {
  // ✅ Initialize Firebase
  try {
    await Firebase.initializeApp();

    final token = await NoficationService.getToken();
    print("FCM token: $token");

    // ✅ Configure Firebase Messaging
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // ✅ Initialize notification listener
    NoficationService.initNotificationListener();

    if (token != null) {
      await SecureStorage.saveFirebaseToken(token);
    }
  } catch (e) {
    print("⚠️ Firebase initialization failed (check google-services.json / DefaultFirebaseOptions): $e");
  }

  // ✅ Initialize local notifications
  NoficationService.initLocalNotifications();

  try {
    await loadCartFromStorage();
    logger.d('🛒 App: Local cart loaded — ${globalCart.length} item(s)');

    // Determine persistent isFoodCart state on startup
    final foodItems = await FoodCartDb.instance.getCartItems();
    if (foodItems.isNotEmpty) {
      toggleFoodCartMode(true);
      logger.i('🛒 App: Startup cart mode set to FOOD (local items found)');
    } else {
      final groceryData = await SecureStorage.getCartData(isFood: false);
      if (groceryData != null && groceryData.isNotEmpty) {
        final decoded = jsonDecode(groceryData);
        final items = decoded['data']?['items'] as List?;
        if (items != null && items.isNotEmpty) {
          toggleFoodCartMode(false);
          logger.i('🛒 App: Startup cart mode set to GROCERY (local items found)');
        }
      }
    }
  } catch (e) {
    logger.e('🛒 App: Error determining startup cart mode — $e');
  }

  try {
    final bool isLoggedIn = await SecureStorage.isLoggedIn();
    logger.i('🔐 App: Login status = $isLoggedIn');

    if (isLoggedIn) {
      NoficationService.updateTokenOnServer();
    }

    // Load saved profile image into global notifier
    await ProfileImageNotifier.load();
    logger.d('👤 App: Profile image notifier initialized');
  } catch (e) {
    logger.e('App: Error in background post-startup tasks — $e');
  }
}

class MyViggiesApp extends StatelessWidget {
  final bool? isLoggedIn;
  const MyViggiesApp({super.key, this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    logger.d('🏗️ MyViggiesApp: build() called');
    final appRoutes = getIt<AppRoutes>();

    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFC8019), // Swiggy Orange
      primary: const Color(0xFFFC8019),
      secondary: const Color(0xFF2E7D32), // Grocery Green
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<CartBloc>()),
        BlocProvider.value(value: getIt<FoodCartBloc>()),
        BlocProvider.value(
          value: getIt<WishlistBloc>(),
        ),
        BlocProvider.value(value: getIt<ConnectivityBloc>()),
        BlocProvider.value(
          value: (isLoggedIn ?? false)
              ? (getIt<AddressBloc>()..add(FetchAddressList()))
              : getIt<AddressBloc>(),
        ),
      ],

      child: MaterialApp.router(
        title: 'MyViggies',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: colorScheme,
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey.shade50,
          dialogTheme: const DialogThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
          ),
          textTheme: GoogleFonts.nunitoTextTheme(
            Theme.of(context).textTheme,
          ).apply(bodyColor: Colors.black87, displayColor: Colors.black87),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87),
            titleTextStyle: GoogleFonts.nunito(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: ZoomPageTransitionsBuilder(),
              // TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        routerConfig: appRoutes.router,
        builder: (context, child) {
          Responsive.init(context);
          return MultiBlocListener(
            listeners: [
              BlocListener<CartBloc, CartState>(
                listener: (context, state) {
                  if (state is DifferentZoneCartConflictState) {
                    final navContext = AppRoutes.navigatorKey.currentContext ?? context;
                    showDifferentZoneCartDialog(
                      context: navContext,
                      message: state.message,
                      onEmptyCartAndAdd: () {
                        getIt<CartBloc>().add(
                          ClearCartAndAddToCartEvent(state.pendingEvent),
                        );
                      },
                    );
                  }
                },
              ),
              BlocListener<FoodCartBloc, CartState>(
                listener: (context, state) {
                  if (state is DifferentZoneCartConflictState) {
                    final navContext = AppRoutes.navigatorKey.currentContext ?? context;
                    showDifferentZoneCartDialog(
                      context: navContext,
                      message: state.message,
                      onEmptyCartAndAdd: () {
                        getIt<FoodCartBloc>().add(
                          ClearCartAndAddToCartEvent(state.pendingEvent),
                        );
                      },
                    );
                  }
                },
              ),
            ],
            child: Stack(
              children: [
                child ?? const SizedBox.shrink(),
                BlocBuilder<ConnectivityBloc, ConnectivityState>(
                  builder: (context, state) {
                    if (state is ConnectivityDisconnected) {
                      return NoInternetScreen(
                        onRetry: () {
                          context.read<ConnectivityBloc>().add(
                            CheckConnectivity(),
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
