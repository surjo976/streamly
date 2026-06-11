import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/main_wrapper.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/details/presentation/screens/details_screen.dart';
import '../../features/player/presentation/screens/player_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/watchlist/presentation/screens/watchlist_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  initialLocation: '/splash',
  navigatorKey: rootNavigatorKey,
  routes: [
    GoRoute(
      path: '/splash',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SplashScreen(),
    ),
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) {
        return MainWrapper(navigationShell: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SearchScreen(),
          ),
        ),
        GoRoute(
          path: '/watchlist',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: WatchlistScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/details/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final heroTag = state.uri.queryParameters['heroTag'] ?? 'default';
        return DetailsScreen(channelId: id, heroTagPrefix: heroTag);
      },
    ),
    GoRoute(
      path: '/player/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return PlayerScreen(channelId: id);
      },
    ),
  ],
);
