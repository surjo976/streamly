import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/utils/clarity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBR6XJrYQpzOeCWdmGIRuS7xXtRi2teyBo",
        authDomain: "streamly-ee877.firebaseapp.com",
        projectId: "streamly-ee877",
        storageBucket: "streamly-ee877.firebasestorage.app",
        messagingSenderId: "149272084035",
        appId: "1:149272084035:web:dc68d98aa9f15969b09ef6",
        measurementId: "G-VSJEBP1ZNH",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(ProviderScope(child: wrapWithClarity(child: const MyApp())));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Streamly - OTT Platform',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
