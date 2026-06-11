import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/models/channel_model.dart';
import '../../../../core/providers/channels_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/channel_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedCategory = 'All';
  Channel? _featuredChannel;

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsProvider);
    final popularGroups = ref.watch(popularGroupsProvider);

    return Scaffold(
      body: channelsAsync.when(
        data: (channels) {
          if (channels.isEmpty) {
            return const Center(
              child: Text('No channels found in files.json'),
            );
          }

          // Pick a featured channel once on load
          _featuredChannel ??= channels.firstWhere(
            (c) => c.group == 'Bangla' && c.logo.isNotEmpty,
            orElse: () => channels[Random().nextInt(channels.length)],
          );

          // Filter channels by category chip
          final filteredChannels = _selectedCategory == 'All'
              ? channels
              : channels.where((c) => c.group == _selectedCategory).toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live TV Featured Banner
                _buildHeroBanner(context, _featuredChannel!),

                const SizedBox(height: 20),

                // Categories Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Browse Categories',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildCategoriesList(popularGroups),

                const SizedBox(height: 20),

                // Channels Grid/Shelf based on Category Selection
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategory == 'All' ? 'Featured Live TV' : 'Live $_selectedCategory',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Total: ${filteredChannels.length}',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildChannelShelf(filteredChannels),

                const SizedBox(height: 24),

                // Multi-shelf for default "All" view
                if (_selectedCategory == 'All') ...[
                  _buildSectionHeader(context, 'Bangla Channels'),
                  const SizedBox(height: 12),
                  _buildChannelShelf(
                    channels.where((c) => c.group == 'Bangla').toList(),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, 'Live Sports'),
                  const SizedBox(height: 12),
                  _buildChannelShelf(
                    channels.where((c) => c.group == 'Sports' || c.group.contains('IPL') || c.group.contains('PSL')).toList(),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, 'News Networks'),
                  const SizedBox(height: 12),
                  _buildChannelShelf(
                    channels.where((c) => c.group == 'News' || c.group.contains('News')).toList(),
                  ),
                ],

                // Margin to avoid floating navbar
                const SizedBox(height: 110),
              ],
            ),
          );
        },
        loading: () => _buildShimmerLoading(context),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.accentRed, size: 48),
              const SizedBox(height: 12),
              Text('Error loading database: $err', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(channelsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, Channel channel) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        // Dark abstract TV placeholder background
        Container(
          width: double.infinity,
          height: screenHeight * 0.52,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E1E24), Color(0xFF09090B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Logo in the center of the hero with a glow
        Positioned.fill(
          child: Center(
            child: Opacity(
              opacity: 0.35,
              child: Image.network(
                channel.logo,
                width: 180,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.live_tv_rounded,
                  size: 100,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ),
        // Dark linear overlay gradient
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black87,
                  AppTheme.backgroundColor,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.2, 0.75, 1.0],
              ),
            ),
          ),
        ),
        // Channel metadata and actions
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LIVE badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentRed.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Text(
                  'LIVE BROADCAST',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Channel Title
              Text(
                channel.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              // Metadata
              Text(
                'Category: ${channel.group}  •  HD Streaming  •  24/7',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push('/player/${Uri.encodeComponent(channel.name)}');
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 28, color: Colors.black),
                    label: const Text(
                      'Watch Live',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.push('/details/${Uri.encodeComponent(channel.name)}');
                    },
                    icon: const Icon(Icons.info_outline_rounded, size: 22, color: Colors.white),
                    label: const Text(
                      'Info',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white60, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesList(List<String> groups) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          final isSelected = group == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(group),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = group;
                  });
                }
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.25),
              checkmarkColor: AppTheme.primaryColor,
              backgroundColor: AppTheme.surfaceColor,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.05),
                  width: 1.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChannelShelf(List<Channel> channels) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: channels.length,
        itemBuilder: (context, index) {
          return ChannelCard(channel: channels[index]);
        },
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    final size = 130.0;
    return SingleChildScrollView(
      child: Shimmer.fromColors(
        baseColor: Colors.grey[900]!,
        highlightColor: Colors.grey[800]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Placeholder
            Container(
              width: double.infinity,
              height: 350,
              color: Colors.black,
            ),
            const SizedBox(height: 20),
            // Categories Row Placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(width: 120, height: 20, color: Colors.black),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: 5,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Container(width: 80, height: 35, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Shelf Title Placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(width: 160, height: 20, color: Colors.black),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: 4,
                itemBuilder: (_, __) => Container(
                  width: size,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
