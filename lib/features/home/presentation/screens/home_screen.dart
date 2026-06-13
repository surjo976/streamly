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
                _selectedCategory == 'All'
                    ? _buildChannelShelf(filteredChannels, 'featured')
                    : _buildChannelGrid(filteredChannels, 'category'),

                const SizedBox(height: 24),

                // Multi-shelf for default "All" view
                if (_selectedCategory == 'All') ...[
                  _buildSectionHeader(context, 'Bangla Channels'),
                  const SizedBox(height: 12),
                  _buildChannelShelf(
                    channels.where((c) => c.group == 'Bangla').toList(),
                    'bangla',
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, 'Live Sports'),
                  const SizedBox(height: 12),
                  _buildChannelShelf(
                    channels.where((c) => c.group == 'Sports' || c.group.contains('IPL') || c.group.contains('PSL')).toList(),
                    'sports',
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, 'News Networks'),
                  const SizedBox(height: 12),
                  _buildChannelShelf(
                    channels.where((c) => c.group == 'News' || c.group.contains('News')).toList(),
                    'news',
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
              colors: [Color(0xFF1A1035), Color(0xFF06060F)],
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TVHeroButton(
                    onPressed: () {
                      context.push('/player/${channel.id}');
                    },
                    icon: Icons.play_arrow_rounded,
                    label: 'Watch Live',
                    isPrimary: true,
                  ),
                  const SizedBox(width: 12),
                  TVHeroButton(
                    onPressed: () {
                      context.push('/details/${channel.id}?heroTag=banner');
                    },
                    icon: Icons.info_outline_rounded,
                    label: 'Info',
                    isPrimary: false,
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
            child: FocusHelperChip(
              group: group,
              isSelected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = group;
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildChannelShelf(List<Channel> channels, String heroTagPrefix) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: channels.length,
        itemBuilder: (context, index) {
          return ChannelCard(
            channel: channels[index],
            heroTagPrefix: heroTagPrefix,
          );
        },
      ),
    );
  }

  Widget _buildChannelGrid(List<Channel> channels, String heroTagPrefix) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 144,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        return ChannelCard(
          channel: channels[index],
          size: double.infinity,
          heroTagPrefix: heroTagPrefix,
        );
      },
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

class FocusHelperChip extends StatefulWidget {
  final String group;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const FocusHelperChip({
    super.key,
    required this.group,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  State<FocusHelperChip> createState() => _FocusHelperChipState();
}

class _FocusHelperChipState extends State<FocusHelperChip> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    return AnimatedScale(
      scale: _isFocused ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: InkWell(
        onTap: () => widget.onSelected(!isSelected),
        onFocusChange: (value) {
          setState(() {
            _isFocused = value;
          });
        },
        onHover: (value) {
          setState(() {
            _isFocused = value;
          });
        },
        borderRadius: BorderRadius.circular(12),
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: _isFocused
                ? AppTheme.primaryColor.withOpacity(0.35)
                : (isSelected
                    ? AppTheme.primaryColor.withOpacity(0.25)
                    : AppTheme.surfaceColor),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused
                  ? AppTheme.primaryColor
                  : (isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.05)),
              width: _isFocused ? 2.0 : 1.2,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(
                  Icons.check,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.group,
                style: TextStyle(
                  color: _isFocused
                      ? Colors.white
                      : (isSelected ? AppTheme.primaryColor : AppTheme.textSecondary),
                  fontWeight: (isSelected || _isFocused) ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TVHeroButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isPrimary;

  const TVHeroButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isPrimary,
  });

  @override
  State<TVHeroButton> createState() => _TVHeroButtonState();
}

class _TVHeroButtonState extends State<TVHeroButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isPrimary = widget.isPrimary;
    final primaryColor = AppTheme.primaryColor;

    Color getBgColor() {
      if (_isFocused) return primaryColor;
      return isPrimary ? Colors.white : Colors.transparent;
    }

    Color getTextColor() {
      if (_isFocused) return Colors.black;
      return isPrimary ? Colors.black : Colors.white;
    }

    Color getIconColor() {
      if (_isFocused) return Colors.black;
      return isPrimary ? Colors.black : Colors.white;
    }

    BorderSide getBorder() {
      if (_isFocused) {
        return BorderSide(color: primaryColor, width: 2);
      }
      return isPrimary ? BorderSide.none : const BorderSide(color: Colors.white60, width: 1.5);
    }

    return AnimatedScale(
      scale: _isFocused ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: InkWell(
        onTap: widget.onPressed,
        onFocusChange: (value) {
          setState(() {
            _isFocused = value;
          });
        },
        onHover: (value) {
          setState(() {
            _isFocused = value;
          });
        },
        borderRadius: BorderRadius.circular(14),
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          decoration: BoxDecoration(
            color: getBgColor(),
            borderRadius: BorderRadius.circular(14),
            border: Border.fromBorderSide(getBorder()),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: isPrimary ? 28 : 22, color: getIconColor()),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: getTextColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
