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

  // Fix for HTTPS certificate issues in release builds
  HttpOverrides.global = MyHttpOverrides();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Preload fonts to avoid runtime issues
  await AppTheme.preloadFonts();

  runApp(MyApp());
}

// Custom HttpOverrides to handle certificate issues
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Allow specific domains for your backend and Google Fonts
        final allowedHosts = [
          'thevillage-backend.onrender.com',
          'fonts.googleapis.com',
          'fonts.gstatic.com',
        ];

        // In production, implement proper certificate validation
        // For now, allow certificates for specific hosts
        return allowedHosts.any((host) => cert.subject.contains(host)) ||
            allowedHosts.contains(host);
      }
      ..connectionTimeout = Duration(seconds: 30)
      ..idleTimeout = Duration(seconds: 30);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        Provider(create: (_) => SocketService()),
      ],
      child: MaterialApp(
        title: 'Surge Driver',
        theme: AppTheme.theme,
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return authProvider.isLoggedIn
                ? OrdersScreen()
                : LoginScreen();
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}