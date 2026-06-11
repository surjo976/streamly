import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/main_wrapper.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/details/presentation/screens/details_screen.dart';
import '../../features/player/presentation/screens/player_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/watchlist/presentation/screens/watchlist_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  initialLocation: '/home',
  navigatorKey: rootNavigatorKey,
  routes: [
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
      path: '/details/:name',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final name = state.pathParameters['name'] ?? '';
        return DetailsScreen(channelName: name);
      },
    ),
    GoRoute(
      path: '/player/:name',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final name = state.pathParameters['name'] ?? '';
        return PlayerScreen(channelName: name);
      },
    ),
  ],
);
