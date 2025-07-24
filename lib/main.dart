import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'screens/login_screen.dart';
import 'screens/orders_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/orders_provider.dart';
import 'services/socket_service.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = MyHttpOverrides();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Preload fonts to avoid runtime issues
  await AppTheme.preloadFonts();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => SocketService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        final allowedHosts = [
          'thevillage-backend.onrender.com',
          'fonts.googleapis.com',
          'fonts.gstatic.com',
        ];
        return allowedHosts.any((host) => cert.subject.contains(host)) ||
            allowedHosts.contains(host);
      }
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(seconds: 30);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Surge Driver',
      theme: AppTheme.theme,
      home: const _AppWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _AppWrapper extends StatefulWidget {
  const _AppWrapper({Key? key}) : super(key: key);

  @override
  _AppWrapperState createState() => _AppWrapperState();
}

class _AppWrapperState extends State<_AppWrapper> with WidgetsBindingObserver {
  bool _callbackSetup = false;
  bool _socketConnectInitiated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('🚀 _AppWrapper: initState called');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final socketService = Provider.of<SocketService>(context, listen: false);

    print('📱 App lifecycle changed: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        print('📱 App resumed - checking socket connection');
        if (!socketService.isConnected) {
          print('📱 Socket not connected, reconnecting...');
          socketService.connect();
          // Force callback re-setup after resume
          _setupSocketCallbackWithDelay(socketService, delaySeconds: 3);
        } else {
          print('📱 Socket already connected');
          // Still re-establish callback to be safe
          _setupSocketCallback(socketService, force: true);
        }
        break;
      case AppLifecycleState.paused:
        print('📱 App paused - keeping socket connected for notifications');
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        print('📱 App state: $state - keeping socket connected');
        break;
      default:
        break;
    }
  }

  void _setupSocketCallback(SocketService socketService, {bool force = false}) {
    if (_callbackSetup && !force) {
      print('🔗 Socket callback already setup, skipping...');
      return;
    }

    print('🔗 Setting up socket callback...');
    print('🔗 Socket connected: ${socketService.isConnected}');

    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);

    socketService.setOnOrderStatusChanged((data) {
      print('🔔 *** GLOBAL SOCKET UPDATE RECEIVED *** : $data');
      print('🔔 Timestamp: ${DateTime.now()}');
      print('🔔 Calling ordersProvider.handleSocketUpdate...');

      try {
        ordersProvider.handleSocketUpdate(data);
        print('✅ ordersProvider.handleSocketUpdate completed successfully');
      } catch (e) {
        print('❌ Error in ordersProvider.handleSocketUpdate: $e');
        print('❌ Stack trace: ${StackTrace.current}');
      }
    });

    _callbackSetup = true;
    print('✅ Socket callback setup completed');
  }

  void _setupSocketCallbackWithDelay(SocketService socketService, {int delaySeconds = 2}) {
    print('⏰ Setting up socket callback with ${delaySeconds}s delay...');

    Timer(Duration(seconds: delaySeconds), () {
      print('⏰ Delay completed, setting up callback now...');
      _setupSocketCallback(socketService, force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ _AppWrapper: build called');

    return Consumer2<AuthProvider, SocketService>(
      builder: (context, authProvider, socketService, child) {
        print('🏗️ Consumer2 builder called - isLoggedIn: ${authProvider.isLoggedIn}, socketConnected: ${socketService.isConnected}');

        // Handle user authentication and socket connection
        if (authProvider.isLoggedIn) {
          print('👤 User is logged in, managing socket connection...');

          // Initiate socket connection if not already done
          if (!_socketConnectInitiated) {
            print('🔌 Initiating socket connection...');
            socketService.connect();
            _socketConnectInitiated = true;

            // Set up callback with a delay to allow socket to connect
            _setupSocketCallbackWithDelay(socketService, delaySeconds: 3);
          } else if (socketService.isConnected && !_callbackSetup) {
            print('🔌 Socket connected but callback not set up, setting up now...');
            _setupSocketCallback(socketService);
          } else if (socketService.isConnected && _callbackSetup) {
            print('✅ Socket connected and callback already set up');
          } else {
            print('⏳ Waiting for socket connection...');
          }

          // Additional check in post-frame callback for connection status changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (socketService.isConnected && !_callbackSetup) {
              print('📅 Post-frame: Socket connected, setting up callback');
              _setupSocketCallback(socketService);
            }
          });

        } else {
          print('👤 User not logged in, resetting socket state');
          _callbackSetup = false;
          _socketConnectInitiated = false;

          // Disconnect socket when user logs out
          if (socketService.isConnected) {
            print('🔌 User logged out, disconnecting socket');
            socketService.disconnect();
          }
        }

        return authProvider.isLoggedIn ? OrdersScreen() : LoginScreen();
      },
    );
  }
}