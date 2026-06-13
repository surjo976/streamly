import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/models/channel_model.dart';
import '../../../../core/theme/app_theme.dart';

class ChannelCard extends StatefulWidget {
  final Channel channel;
  final double size;
  final String heroTagPrefix;

  const ChannelCard({
    super.key,
    required this.channel,
    this.size = 130,
    this.heroTagPrefix = 'default',
  });

  @override
  State<ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<ChannelCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isFullWidth = widget.size == double.infinity;
    return Container(
      width: isFullWidth ? null : widget.size,
      margin: isFullWidth
          ? EdgeInsets.zero
          : const EdgeInsets.only(right: 14),
      child: AnimatedScale(
        scale: _isFocused ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: InkWell(
          onTap: () {
            context.push('/details/${widget.channel.id}?heroTag=${widget.heroTagPrefix}');
          },
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
          borderRadius: BorderRadius.circular(20),
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Square Card with Logo & Live Badge
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isFocused
                              ? AppTheme.primaryColor
                              : Colors.white.withOpacity(0.04),
                          width: _isFocused ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isFocused
                                ? AppTheme.primaryColor.withOpacity(0.5)
                                : Colors.black.withOpacity(0.15),
                            blurRadius: _isFocused ? 16 : 10,
                            offset: _isFocused ? const Offset(0, 6) : const Offset(0, 4),
                            spreadRadius: _isFocused ? 1 : 0,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Hero(
                          tag: 'channel-logo-${widget.heroTagPrefix}-${widget.channel.id}',
                          child: widget.channel.logo.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: CachedNetworkImage(
                                    imageUrl: widget.channel.logo,
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) =>
                                        Shimmer.fromColors(
                                          baseColor: Colors.grey[900]!,
                                          highlightColor: Colors.grey[800]!,
                                          child: Container(color: Colors.black),
                                        ),
                                    errorWidget: (context, url, error) =>
                                        _buildPlaceholder(),
                                  ),
                                )
                              : _buildPlaceholder(),
                        ),
                      ),
                    ),
                  ),
                  // "LIVE" badge on top-right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentRed,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentRed.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Title
              Text(
                widget.channel.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _isFocused ? AppTheme.primaryColor : null,
                ),
              ),
              const SizedBox(height: 2),
              // Category tag
              Text(
                widget.channel.group,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _isFocused
                      ? AppTheme.primaryColor.withOpacity(0.95)
                      : AppTheme.primaryColor.withOpacity(0.85),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.surfaceColor,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.tv_rounded, color: AppTheme.textSecondary, size: 32),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              widget.channel.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
