import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/channel_model.dart';
import '../../../../core/providers/channels_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/widgets/channel_card.dart';
import '../providers/search_provider.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(searchQueryProvider);
    final channelsAsync = ref.watch(channelsProvider);
    final popularGroups = ref.watch(popularGroupsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: channelsAsync.when(
          data: (channels) {
            // Instant memory-based filtering
            final filteredChannels = channels.where((channel) {
              final query = searchQuery.toLowerCase();
              final nameMatch = channel.name.toLowerCase().contains(query);
              final groupMatch = channel.group.toLowerCase().contains(query);
              return nameMatch || groupMatch;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text(
                    'Search Channels',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),

                // Search Bar Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      onChanged: (val) {
                        ref.read(searchQueryProvider.notifier).setQuery(val);
                      },
                      controller: TextEditingController.fromValue(
                        TextEditingValue(
                          text: searchQuery,
                          selection: TextSelection.collapsed(offset: searchQuery.length),
                        ),
                      ),
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search channel name, group, news, sports...',
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary),
                                onPressed: () {
                                  ref.read(searchQueryProvider.notifier).clear();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Main Search Display View
                Expanded(
                  child: searchQuery.isEmpty
                      ? _buildSearchSuggestions(context, ref, popularGroups, channels)
                      : _buildSearchResults(filteredChannels),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
          error: (err, stack) => Center(
            child: Text('Error loading search database: $err', style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions(
    BuildContext context,
    WidgetRef ref,
    List<String> groups,
    List<Channel> channels,
  ) {
    // Show top groups (excluding "All") as quick suggestion chips
    final filterChips = groups.where((g) => g != 'All').take(8).toList();
    // Expose 4 popular live channels
    final recommended = channels.where((c) => c.logo.isNotEmpty).take(4).toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Browse Popular Categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: filterChips.map((group) {
                return InkWell(
                  onTap: () {
                    ref.read(searchQueryProvider.notifier).setQuery(group);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                    child: Text(
                      group,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            const Text(
              'Popular Live TV Channels',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recommended.length,
              itemBuilder: (context, index) {
                final channel = recommended[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 70,
                    height: 46,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: channel.logo.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: channel.logo,
                              fit: BoxFit.contain,
                            )
                          : const Icon(Icons.live_tv_rounded, color: AppTheme.textSecondary),
                    ),
                  ),
                  title: Text(
                    channel.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${channel.group} • Live Stream',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.play_arrow_rounded, color: AppTheme.primaryColor),
                  onTap: () {
                    context.push('/player/${channel.id}');
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<Channel> results) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppTheme.primaryColor.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'No channels found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try searching for different keywords or groups',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 144,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final channel = results[index];
        return ChannelCard(
          channel: channel,
          size: double.infinity,
          heroTagPrefix: 'search',
        );
      },
    );
  }
}
