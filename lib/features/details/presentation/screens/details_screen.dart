import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/providers/channels_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../watchlist/presentation/providers/watchlist_provider.dart';
import '../../../home/presentation/widgets/channel_card.dart';

class DetailsScreen extends ConsumerWidget {
  final String channelId;
  final String heroTagPrefix;

  const DetailsScreen({
    super.key,
    required this.channelId,
    this.heroTagPrefix = 'default',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelsProvider);
    final watchlist = ref.watch(watchlistProvider);

    return Scaffold(
      body: channelsAsync.when(
        data: (channels) {
          // Find the active channel
          final channel = channels.firstWhere(
            (c) => c.id == channelId,
            orElse: () => channels.first,
          );

          final isInWatchlist = watchlist.contains(channel.id);

          // Find recommendations (same group, different channel)
          final recommendations = channels
              .where((c) => c.group == channel.group && c.id != channel.id)
              .take(15) // Limit recommendations count for smooth scrolling
              .toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Backdrop Header
                Stack(
                  children: [
                    // Glassmorphic background blur using logo
                    Hero(
                      tag: 'channel-logo-${heroTagPrefix}-${channel.id}',
                      child: Container(
                        width: double.infinity,
                        height: 380,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1A1035), Color(0xFF06060F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: channel.logo.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: channel.logo,
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.contain,
                                  errorWidget: (_, __, ___) => const Icon(
                                    Icons.live_tv_rounded,
                                    size: 80,
                                    color: Colors.white24,
                                  ),
                                )
                              : const Icon(
                                  Icons.live_tv_rounded,
                                  size: 80,
                                  color: Colors.white24,
                                ),
                        ),
                      ),
                    ),
                    // Overlay Gradient
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppTheme.backgroundColor,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Floating App Bar / Back & Bookmark Buttons
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.black.withOpacity(0.5),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                                onPressed: () => context.pop(),
                              ),
                            ),
                            CircleAvatar(
                              backgroundColor: Colors.black.withOpacity(0.5),
                              child: IconButton(
                                icon: Icon(
                                  isInWatchlist ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                  color: isInWatchlist ? AppTheme.primaryColor : Colors.white,
                                ),
                                onPressed: () {
                                  ref.read(watchlistProvider.notifier).toggleWatchlist(channel.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppTheme.surfaceColor,
                                      duration: const Duration(milliseconds: 1500),
                                      content: Text(
                                        isInWatchlist 
                                            ? 'Removed from Favorites' 
                                            : 'Added to Favorites',
                                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Details Text Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LIVE Indicator Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentRed,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white.withOpacity(0.06)),
                            ),
                            child: Text(
                              channel.group,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '•  HD 1080p  •  Stereo',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        channel.name,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      
                      const SizedBox(height: 24),

                      // Actions Play Button
                      TVPlayButton(
                        onPressed: () {
                          context.push('/player/${channel.id}');
                        },
                        label: 'Stream Live Now',
                      ),
                      
                      const SizedBox(height: 30),

                      // Description
                      const Text(
                        'About Channel',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Watch ${channel.name} live stream online. Enjoy 24/7 continuous high quality digital transmission of your favorite programs, dramas, news reports, and entertainment specials direct from the ${channel.group} broadcast network.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              height: 1.5,
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 32),

                      // Similar Recommendations (More Like This)
                      if (recommendations.isNotEmpty) ...[
                        Text(
                          'More from ${channel.group}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 170,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: recommendations.length,
                            itemBuilder: (context, index) {
                              final recChannel = recommendations[index];
                              return ChannelCard(
                                channel: recChannel,
                                size: 100,
                                heroTagPrefix: 'rec',
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (err, stack) => Center(
          child: Text('Error loading channel details: $err', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

class TVPlayButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;

  const TVPlayButton({
    super.key,
    required this.onPressed,
    required this.label,
  });

  @override
  State<TVPlayButton> createState() => _TVPlayButtonState();
}

class _TVPlayButtonState extends State<TVPlayButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isFocused ? 1.04 : 1.0,
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
        borderRadius: BorderRadius.circular(16),
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: _isFocused
                ? const LinearGradient(
                    colors: [Colors.white, Colors.white],
                  )
                : AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _isFocused
                    ? Colors.white.withOpacity(0.4)
                    : AppTheme.primaryColor.withOpacity(0.35),
                blurRadius: _isFocused ? 20 : 16,
                offset: _isFocused ? const Offset(0, 6) : const Offset(0, 8),
              ),
            ],
            border: _isFocused
                ? Border.all(color: AppTheme.primaryColor, width: 2.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                color: _isFocused ? Colors.black : Colors.white,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: _isFocused ? Colors.black : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
