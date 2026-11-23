import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/pending_approval_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const IplFplApp(),
    ),
  );
}

class IplFplApp extends StatelessWidget {
  const IplFplApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        Widget startScreen;
        if (auth.isLoading) {
          startScreen = const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryNeon),
            ),
          );
        } else if (auth.isLoggedIn || auth.isGuest) {
          startScreen = auth.isLoggedIn && !auth.isApproved
              ? const PendingApprovalScreen()
              : const HomeScreen();
        } else {
          startScreen = const LoginScreen();
        }

        return MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: startScreen,
        );
      },
    );
  }
}
