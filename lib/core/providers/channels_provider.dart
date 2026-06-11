import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/channel_model.dart';

// FutureProvider to load and parse the channels list from assets/files.json
final channelsProvider = FutureProvider<List<Channel>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/files.json');
  final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
  return jsonList.map((json) => Channel.fromJson(json as Map<String, dynamic>)).toList();
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
