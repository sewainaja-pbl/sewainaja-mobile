import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'notification_service.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/category_controller.dart';
import 'animated_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);
  } catch (e) {
    debugPrint("Firebase initialization skipped or failed: $e");
  }
  await NotificationService.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => CategoryController()),
        ChangeNotifierProvider<NotificationService>.value(
          value: NotificationService.instance,
        ),
      ],
      child: MaterialApp(
        navigatorKey: NotificationService.navigatorKey,
        title: 'SewainAja',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFF1B4332),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B4332)),
          useMaterial3: true,
          fontFamily: 'Poppins',
        ),
        home: const AnimatedSplashScreen(),
      ),
    );
  }
}
