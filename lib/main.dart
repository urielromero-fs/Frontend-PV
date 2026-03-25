import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pv26/features/auth/screens/login_screen.dart';
import 'package:pv26/features/home/screens/home_screen.dart';
import 'package:pv26/features/auth/screens/forgot_password_screen.dart';
import 'package:pv26/features/auth/screens/register_screen.dart';
import 'package:pv26/features/inventory/providers/product_provider.dart';
import 'package:pv26/core/providers/theme_provider.dart';
import 'package:pv26/core/theme/app_theme.dart';
import 'package:showcaseview/showcaseview.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Showcase (nuevo API)
  ShowcaseView.register();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Centli',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/register': (context) => const RegisterScreen(),
          },
        );
      },
    );
  }
}
