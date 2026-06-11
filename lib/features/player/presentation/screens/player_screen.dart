import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
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

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final chewieController = _chewieController;
    final isPlayerInitialized = chewieController != null &&
        _videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video player fills screen
          Positioned.fill(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  )
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
                        : const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                            ),
                          )),
          ),
          
          // Back float button overlay
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
        ],
      ),
    );
  }
}
