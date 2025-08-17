import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce/theme.dart';
import 'package:ecommerce/screens/main_screen.dart';
import 'package:ecommerce/services/supabase_service.dart';
import 'package:ecommerce/services/auth_service.dart';
import 'package:ecommerce/services/data_service.dart';
import 'package:ecommerce/services/app_state.dart';
import 'package:ecommerce/services/delivery_notification_service.dart';
import 'package:ecommerce/screens/auth_screen.dart';
import 'package:ecommerce/widgets/session_restore_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Supabase avec persistance
  await SupabaseService.initialize();
  
  runApp(const ShopFlowApp());
}

class ShopFlowApp extends StatelessWidget {
  const ShopFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DataService()),
        ChangeNotifierProvider(create: (_) => DeliveryNotificationService()),
        ChangeNotifierProxyProvider2<AuthService, DataService, AppState>(
          create: (context) => AppState(
            context.read<AuthService>(),
            context.read<DataService>(),
          ),
          update: (context, authService, dataService, previous) => 
            previous ?? AppState(authService, dataService),
        ),
      ],
      child: MaterialApp(
        title: 'ShopFlow - L\'expérience shopping mobile ultime',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: const SessionRestoreWidget(
          child: AuthWrapper(),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (authService.isAuthenticated) {
          return const MainScreen();
        }
        
        return const AuthScreen();
      },
    );
  }
}
