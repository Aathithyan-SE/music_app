import 'package:flutter/material.dart';
import 'package:modizk_download/services/music_provider.dart';
import 'package:modizk_download/services/sound_cloud_audio_provider.dart';
import 'package:provider/provider.dart';
import 'package:modizk_download/theme.dart';

class SongPlayerScreen extends StatefulWidget {
  final bool shouldStartPlaying;

  const SongPlayerScreen({
    super.key,
    this.shouldStartPlaying = false,
  });

  @override
  State<SongPlayerScreen> createState() => _SongPlayerScreenState();
}

class _SongPlayerScreenState extends State<SongPlayerScreen> {
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
        final provider = Provider.of<SoundCloudAudioProvider>(context, listen: false);
        if (provider.currentTrack != null) {
          provider.playTrack(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    final provider = Provider.of<SoundCloudAudioProvider>(context);
    final musicProvider = Provider.of<MusicProvider>(context);

    return Scaffold(
      backgroundColor: ModizkColors.primaryBackground,
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
                    _buildPlaybackControls(context, musicProvider),
                    const SizedBox(height: 24),
                    _buildActionButtons(context),
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
              color: ModizkColors.primaryText,
              size: 32,
            ),
          ),
          const Spacer(),
          // IconButton(
          //   onPressed: () {
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(content: Text('Share song coming soon!')),
          //     );
          //   },
          //   icon: Icon(
          //     Icons.share_outlined,
          //     color: ModizkColors.primaryText,
          //     size: 24,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(SoundCloudAudioProvider provider) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ModizkColors.primaryText.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: provider.currentTrack!.artworkUrl != null
            ? Image.network(
          provider.currentTrack!.artworkUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildAlbumPlaceholder(),
        )
            : _buildAlbumPlaceholder(),
      ),
    );
  }

  Widget _buildAlbumPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ModizkColors.primaryAccent.withValues(alpha: 0.3),
            ModizkColors.secondaryAccent.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note,
          color: ModizkColors.primaryAccent,
          size: 100,
        ),
      ),
    );
  }

  Widget _buildSongDetails(BuildContext context, SoundCloudAudioProvider provider) {
    return Column(
      children: [
        Text(
          provider.currentTrack!.title ?? "Unknown Song",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: ModizkColors.primaryText,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          provider.currentTrack!.user.username ?? "Unknown Artist",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: ModizkColors.secondaryText,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Consumer<SoundCloudAudioProvider>(
      builder: (context, audioProvider, child) {
        final currentPosition = _isDragging
            ? Duration(seconds: _dragValue.toInt())
            : audioProvider.currentPosition;
        final totalDuration = audioProvider.totalDuration;

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: ModizkColors.primaryAccent,
                inactiveTrackColor: ModizkColors.secondaryText.withValues(alpha: 0.3),
                thumbColor: ModizkColors.primaryAccent,
                overlayColor: ModizkColors.primaryAccent.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: _isDragging
                    ? _dragValue
                    : currentPosition.inSeconds.toDouble(),
                max: totalDuration.inSeconds.toDouble(),
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
                  audioProvider.seek(Duration(seconds: value.toInt()));
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
                      color: ModizkColors.secondaryText,
                    ),
                  ),
                  Text(
                    _formatDuration(totalDuration),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ModizkColors.secondaryText,
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

  Widget _buildPlaybackControls(BuildContext context, MusicProvider musicProvider) {
    return Consumer<SoundCloudAudioProvider>(
      builder: (context, audioProvider, child) {
        return Column(
          children: [
            // Primary controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  Icons.skip_previous,
                  ModizkColors.primaryText,
                      () {
                        audioProvider.playPrevious(context);
                  },
                  size: 32,
                ),
                _buildControlButton(
                  // audioProvider.isLoading
                  //     ? Icons.hourglass_empty
                  //     :
                  (audioProvider.isPlaying ? Icons.pause : Icons.play_arrow),
                  ModizkColors.primaryAccent,
                  audioProvider.isLoading
                      ? null
                      : () {
                    if (audioProvider.isPlaying) {
                      audioProvider.pause();
                    } else {
                      audioProvider.resume();
                    }
                  },
                  size: 56,
                  isMainButton: true,
                ),
                _buildControlButton(
                  Icons.skip_next,
                  ModizkColors.primaryText,
                      () {
                        audioProvider.playNext(context);
                      },
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        );
      },
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
            ? ModizkColors.primaryAccent.withValues(alpha: 0.1)
            : Colors.transparent,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed == null ? ModizkColors.secondaryText : color,
          size: size,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          context,
          Icons.download_outlined,
          'Download',
              () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Download feature')),
            );
          },
        ),
        _buildActionButton(
          context,
          Icons.add,
          'Add to Playlist',
              () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add to playlist feature')),
            );
          },
        ),
        _buildActionButton(
          context,
          isLiked ? Icons.favorite : Icons.favorite_border,
          'Like',
              () {
            setState(() {
              isLiked = !isLiked;
            });
          },
          color: isLiked ? ModizkColors.primaryAccent : ModizkColors.primaryText,
        ),
        // _buildActionButton(
        //   context,
        //   Icons.more_vert,
        //   'More',
        //       () {
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       const SnackBar(content: Text('More options feature')),
        //     );
        //   },
        // ),
      ],
    );
  }

  Widget _buildActionButton(
      BuildContext context,
      IconData icon,
      String label,
      VoidCallback onPressed, {
        Color? color,
      }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: color ?? ModizkColors.primaryText,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ModizkColors.secondaryText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}