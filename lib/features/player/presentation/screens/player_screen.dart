import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/channel_model.dart';
import '../../../../core/providers/channels_provider.dart';
import '../../../../core/theme/app_theme.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String channelId;

  const PlayerScreen({super.key, required this.channelId});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;
  Channel? _channel;
  List<Channel> _allChannels = [];
  String _searchQuery = "";
  
  int _loadingProgress = 0;
  Timer? _loadingTimer;

  void _startLoadingProgress() {
    _loadingTimer?.cancel();
    setState(() {
      _loadingProgress = 0;
    });
    
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (_loadingProgress < 75) {
          _loadingProgress += 5; // Fast progress up to 75%
        } else if (_loadingProgress < 95) {
          _loadingProgress += 1; // Slower progress up to 95%
        } else if (_loadingProgress < 99) {
          // Increment by fractional steps or stay at 99%
          if (timer.tick % 5 == 0) {
            _loadingProgress += 1;
          }
        }
      });
    });
  }

  void _stopLoadingProgress() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
    setState(() {
      _loadingProgress = 100;
    });
  }

  @override
  void initState() {
    super.initState();
    // Lock screen to landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Immersive fullscreen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_channel == null) {
      _loadChannelAndInitialize();
    }
  }

  void _loadChannelAndInitialize() async {
    final channelsAsync = ref.read(channelsProvider);

    channelsAsync.when(
      data: (channels) {
        _allChannels = channels;
        final found = channels.firstWhere(
          (c) => c.id == widget.channelId,
          orElse: () => channels.first,
        );
        _channel = found;
        _initializePlayer(found);
      },
      loading: () {
        setState(() {
          _isLoading = true;
        });
      },
      error: (err, stack) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not load channel data: $err';
        });
      },
    );
  }

  void _initializePlayer(Channel channel) async {
    _disposeControllers();
    _startLoadingProgress();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _channel = channel;
    });

    try {
      final uri = Uri.parse(channel.url);
      debugPrint("INITIALIZING PLAYER WITH URL: ${channel.url}");
      
      // Determine format hint from URL extension to guarantee ExoPlayer/AVPlayer uses the right HLS driver
      VideoFormat? formatHint;
      if (channel.url.toLowerCase().contains('.m3u8')) {
        formatHint = VideoFormat.hls;
      }

      _videoPlayerController = VideoPlayerController.networkUrl(
        uri,
        formatHint: formatHint,
        videoPlayerOptions: VideoPlayerOptions(
          allowBackgroundPlayback: false,
          mixWithOthers: false,
        ),
      );
      
      await _videoPlayerController!.initialize();

      double aspectRatio = 16 / 9;
      if (_videoPlayerController!.value.size.width > 0 &&
          _videoPlayerController!.value.size.height > 0) {
        aspectRatio = _videoPlayerController!.value.aspectRatio;
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        isLive: true,
        aspectRatio: aspectRatio,
        allowFullScreen: true,
        fullScreenByDefault: false,
        allowedScreenSleep: false,
        draggableProgressBar: false,
        showControlsOnInitialize: false,
        allowMuting: true,
        hideControlsTimer: const Duration(seconds: 3),
        placeholder: Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 3),
                ),
                const SizedBox(height: 12),
                Text(
                  '$_loadingProgress%',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.accentRed, size: 42),
                const SizedBox(height: 12),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _initializePlayer(channel),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: const Text('Retry'),
                )
              ],
            ),
          );
        },
      );

      _videoPlayerController!.addListener(_videoPlayerListener);

      _stopLoadingProgress();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _stopLoadingProgress();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to stream HLS channel: $e\nVerify connection or stream availability.';
        });
      }
    }
  }

  void _videoPlayerListener() {
    if (_videoPlayerController == null) return;
    
    final value = _videoPlayerController!.value;
    if (value.hasError) {
      debugPrint("PLAYER ERROR: ${value.errorDescription}");
      setState(() {
        _errorMessage = value.errorDescription;
      });
      _videoPlayerController!.removeListener(_videoPlayerListener);
    }
  }

  void _disposeControllers() {
    if (_videoPlayerController != null) {
      _videoPlayerController!.removeListener(_videoPlayerListener);
      _videoPlayerController!.dispose();
      _videoPlayerController = null;
    }
    if (_chewieController != null) {
      _chewieController!.dispose();
      _chewieController = null;
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    // Restore default portrait configurations on exit
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Widget _buildProgressBar() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: _loadingProgress / 100,
                  strokeWidth: 4,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
              Text(
                '$_loadingProgress%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _loadingProgress < 40
                ? 'Connecting to channel stream...'
                : _loadingProgress < 85
                    ? 'Downloading stream chunks...'
                    : 'Buffering live video & audio...',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chewieController = _chewieController;
    final isPlayerInitialized = chewieController != null &&
        _videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      endDrawer: _buildRightDrawer(),
      body: Stack(
        children: [
          // Video player fills screen
          Positioned.fill(
            child: _isLoading
                ? _buildProgressBar()
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.signal_wifi_connected_no_internet_4_rounded,
                              color: AppTheme.accentRed,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40.0),
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (_channel != null) {
                                  _initializePlayer(_channel!);
                                } else {
                                  _loadChannelAndInitialize();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Try Reconnecting'),
                            ),
                          ],
                        ),
                      )
                    : (isPlayerInitialized
                        ? Center(
                            child: AspectRatio(
                              aspectRatio: chewieController.aspectRatio ?? 16/9,
                              child: Chewie(
                                controller: chewieController,
                              ),
                            ),
                          )
                        : _buildProgressBar()),
          ),
          
          // Back float button overlay (Left Side)
          Positioned(
            top: 24,
            left: 24,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.5),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // Menu / Channel List float button overlay (Right Side)
          Positioned(
            top: 24,
            right: 24,
            child: Builder(
              builder: (context) {
                return CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: IconButton(
                    icon: const Icon(Icons.menu_open_rounded, color: Colors.white),
                    tooltip: 'Channel List',
                    onPressed: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0F0F1A),
      width: 320,
      child: StatefulBuilder(
        builder: (context, setDrawerState) {
          // Filter channels based on search query
          final filteredChannels = _allChannels.where((c) {
            return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   c.group.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drawer Title
                const Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text(
                    'All Channels',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    onChanged: (value) {
                      setDrawerState(() {
                        _searchQuery = value;
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search TV channel...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                      fillColor: Colors.white.withOpacity(0.06),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const Divider(color: Colors.white10),

                // Channel List
                Expanded(
                  child: filteredChannels.isEmpty
                      ? const Center(
                          child: Text(
                            'No channels found',
                            style: TextStyle(color: Colors.white38, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredChannels.length,
                          itemBuilder: (context, index) {
                            final c = filteredChannels[index];
                            final isPlaying = _channel?.id == c.id;

                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  color: Colors.white.withOpacity(0.04),
                                  padding: const EdgeInsets.all(4),
                                  child: c.logo.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: c.logo,
                                          fit: BoxFit.contain,
                                          errorWidget: (_, __, ___) => const Icon(
                                            Icons.live_tv_rounded,
                                            color: Colors.white30,
                                            size: 20,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.live_tv_rounded,
                                          color: Colors.white30,
                                          size: 20,
                                        ),
                                ),
                              ),
                              title: Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isPlaying ? AppTheme.primaryColor : Colors.white70,
                                  fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                c.group,
                                style: TextStyle(
                                  color: isPlaying ? AppTheme.primaryColor.withOpacity(0.7) : Colors.white30,
                                  fontSize: 11,
                                ),
                              ),
                              trailing: isPlaying
                                  ? const Icon(
                                      Icons.play_circle_fill_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 20,
                                    )
                                  : null,
                              tileColor: isPlaying ? Colors.white.withOpacity(0.04) : null,
                              onTap: () {
                                // Close the drawer
                                Navigator.pop(context);
                                // Play selected channel
                                _initializePlayer(c);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
