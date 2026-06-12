import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/utils/clarity_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

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

  // Set up Firebase Messaging background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request push notification permissions
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  debugPrint('User granted permission: ${settings.authorizationStatus}');

  // Retrieve FCM Token for testing
  try {
    String? token = await messaging.getToken();
    debugPrint('FCM Token: $token');
    
    // Subscribe to topic 'all' on app open
    await messaging.subscribeToTopic('all');
    debugPrint('Successfully subscribed to topic: all');
  } catch (e) {
    debugPrint('Error fetching FCM Token or subscribing to topic: $e');
  }

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification!.title}');
    }
  });

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
