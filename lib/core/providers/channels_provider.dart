import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:http/http.dart' as http;
import '../models/channel_model.dart';

// FutureProvider to load and parse the channels list dynamically from Remote Config URL
final channelsProvider = FutureProvider<List<Channel>>((ref) async {
  List<dynamic> jsonList = [];

  try {
    // 1. Initialize Remote Config
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    // 2. Fetch and activate config values
    await remoteConfig.fetchAndActivate();

    // 3. Get remote channel list JSON directly from parameter
    final channelsJsonString = remoteConfig.getString('channels_json');

    if (channelsJsonString.isNotEmpty) {
      // 4. Parse the JSON string
      jsonList = jsonDecode(channelsJsonString) as List<dynamic>;
    }
  } catch (e) {
    // Fallback gracefully on any configuration or network errors
    print('Firebase Remote Config error: $e. Falling back to local assets.');
  }

  // 5. Fallback to local asset if remote loading failed or returned empty list
  if (jsonList.isEmpty) {
    final jsonString = await rootBundle.loadString('assets/files.json');
    jsonList = jsonDecode(jsonString) as List<dynamic>;
  }
  
  final List<Channel> list = [];
  for (int i = 0; i < jsonList.length; i++) {
    list.add(
      Channel.fromJson(
        jsonList[i] as Map<String, dynamic>,
        i.toString(),
      ),
    );
  }
  return list;
});

// Provider to extract and sort the channel groups based on channel count
final popularGroupsProvider = Provider<List<String>>((ref) {
  final channelsAsync = ref.watch(channelsProvider);
  
  return channelsAsync.maybeWhen(
    data: (channels) {
      // Count channels per group
      final Map<String, int> groupCounts = {};
      for (var channel in channels) {
        groupCounts[channel.group] = (groupCounts[channel.group] ?? 0) + 1;
      }
      
      // Sort groups by channel count descending
      final sortedGroups = groupCounts.keys.toList()
        ..sort((a, b) => groupCounts[b]!.compareTo(groupCounts[a]!));
      
      // Keep "All" as first, and return the top 10 groups
      return ['All', ...sortedGroups.take(10)];
    },
    orElse: () => ['All', 'Bangla', 'Sports', 'News', 'Movies', 'Islamic'],
  );
});
