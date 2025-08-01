// 6. screens/local_music_player_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/local_music_provider.dart';
import '../theme.dart'; // Assuming you have this

class LocalMusicPlayerScreen extends StatefulWidget {
  final bool shouldStartPlaying;

  const LocalMusicPlayerScreen({
    super.key,
    this.shouldStartPlaying = false,
  });

  @override
  State<LocalMusicPlayerScreen> createState() => _LocalMusicPlayerScreenState();
}

class _LocalMusicPlayerScreenState extends State<LocalMusicPlayerScreen> {
  bool isRepeat = false;
  bool isShuffled = false;
  bool isLiked = false;
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.shouldStartPlaying) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<LocalMusicProvider>(context, listen: false);
        if (provider.currentLocalTrack != null && !provider.isLocalPlaying) {
          provider.resumeLocal();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocalMusicProvider>(context);

    if (provider.currentLocalTrack == null) {
      return Scaffold(
        backgroundColor: MyColors.primaryBackground,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Center(
                  child: Text(
                    'No song selected',
                    style: TextStyle(
                      color: MyColors.secondaryText,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MyColors.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildAlbumArt(provider),
                    const SizedBox(height: 32),
                    _buildSongDetails(context, provider),
                    const SizedBox(height: 32),
                    _buildProgressBar(context),
                    const SizedBox(height: 32),
                    _buildPlaybackControls(context, provider),
                    const SizedBox(height: 24),
                    // _buildActionButtons(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: MyColors.primaryText,
              size: 32,
            ),
          ),
          const Spacer(),
          Text(
            'Local Music',
            style: TextStyle(
              color: MyColors.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildAlbumArt(LocalMusicProvider provider) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MyColors.primaryText.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FutureBuilder<Uint8List?>(
          future: provider.getSongArtwork(provider.currentLocalTrack!.id),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
              );
            }
            return _buildAlbumPlaceholder();
          },
        ),
      ),
    );
  }

  Widget _buildAlbumPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MyColors.primaryAccent.withOpacity(0.3),
            MyColors.secondaryAccent.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note,
          color: MyColors.primaryAccent,
          size: 100,
        ),
      ),
    );
  }

  Widget _buildSongDetails(BuildContext context, LocalMusicProvider provider) {
    final track = provider.currentLocalTrack!;
    return Column(
      children: [
        Text(
          track.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: MyColors.primaryText,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        // if (track.album != null) ...[
        //   const SizedBox(height: 14),
        //   Text(
        //     track.album!,
        //     style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        //       color: MyColors.secondaryText.withOpacity(0.7),
        //     ),
        //     textAlign: TextAlign.center,
        //     maxLines: 1,
        //     overflow: TextOverflow.ellipsis,
        //   ),
        // ],
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Consumer<LocalMusicProvider>(
      builder: (context, provider, child) {
        final currentPosition = _isDragging
            ? Duration(seconds: _dragValue.toInt())
            : provider.localCurrentPosition;
        final totalDuration = provider.localTotalDuration;

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: MyColors.primaryAccent,
                inactiveTrackColor: MyColors.secondaryText.withOpacity(0.3),
                thumbColor: MyColors.primaryAccent,
                overlayColor: MyColors.primaryAccent.withOpacity(0.2),
              ),
              child: Slider(
                value: _isDragging
                    ? _dragValue
                    : currentPosition.inSeconds.toDouble(),
                max: totalDuration.inSeconds.toDouble().clamp(0.0, double.infinity),
                onChangeStart: (value) {
                  _isDragging = true;
                  _dragValue = value;
                },
                onChanged: (value) {
                  setState(() {
                    _dragValue = value;
                  });
                },
                onChangeEnd: (value) {
                  _isDragging = false;
                  provider.seekLocal(Duration(seconds: value.toInt()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(currentPosition),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MyColors.secondaryText,
                    ),
                  ),
                  Text(
                    _formatDuration(totalDuration),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MyColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaybackControls(BuildContext context, LocalMusicProvider provider) {
    return Column(
      children: [
        // Primary controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(
              Icons.skip_previous,
              MyColors.primaryText,
              provider.currentLocalIndex > 0
                  ? () => provider.playPreviousLocal(context: context) // CRITICAL FIX: Pass context
                  : null,
              size: 32,
            ),
            _buildControlButton(
              provider.isLocalLoading
                  ? Icons.hourglass_empty
                  : (provider.isLocalPlaying ? Icons.pause : Icons.play_arrow),
              MyColors.primaryAccent,
              provider.isLocalLoading
                  ? null
                  : () {
                if (provider.isLocalPlaying) {
                  provider.pauseLocal();
                } else {
                  provider.resumeLocal();
                }
              },
              size: 56,
              isMainButton: true,
            ),
            _buildControlButton(
              Icons.skip_next,
              MyColors.primaryText,
              provider.currentLocalIndex < provider.songs.length - 1
                  ? () => provider.playNextLocal(context: context) // CRITICAL FIX: Pass context
                  : null,
              size: 32,
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildControlButton(
      IconData icon,
      Color color,
      VoidCallback? onPressed, {
        double size = 24,
        bool isMainButton = false,
      }) {
    return Container(
      width: isMainButton ? 80 : 48,
      height: isMainButton ? 80 : 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isMainButton
            ? MyColors.primaryAccent.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed == null ? MyColors.secondaryText : color,
          size: size,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}