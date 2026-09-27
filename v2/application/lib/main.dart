import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/project_repository_impl.dart';
import 'data/services/firebase_service.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/project_repository.dart';
import 'firebase_options.dart';
import 'presentation/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fault-tolerant Firebase initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[HouseVision] Firebase initialized successfully.');
  } catch (e) {
    debugPrint('[HouseVision] Firebase initialization notice (running with resilient local state): $e');
  }

  // Instantiate core services & repositories
  final firebaseService = AppFirebaseService();
  final authRepository = AuthRepositoryImpl(firebaseService: firebaseService);
  final projectRepository = ProjectRepositoryImpl(firebaseService: firebaseService);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        Provider<ProjectRepository>.value(value: projectRepository),
      ],
      child: const HouseVisionApp(),
    ),
  );
}

class HouseVisionApp extends StatelessWidget {
  const HouseVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
