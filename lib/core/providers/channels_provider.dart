import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/channel_model.dart';

// FutureProvider to load and parse the channels list from assets/files.json with index-based unique IDs
final channelsProvider = FutureProvider<List<Channel>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/files.json');
  final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
  
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
