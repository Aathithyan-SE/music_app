import 'package:flutter/material.dart';
import 'package:modizk_download/services/music_provider.dart';
import 'package:provider/provider.dart';
import 'package:modizk_download/services/sound_cloud_audio_provider.dart';
import 'package:modizk_download/theme.dart';
import 'package:modizk_download/screens/song_player_screen.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  Widget build(BuildContext context) {

    final musicProvider = Provider.of<MusicProvider>(context);

    return Consumer<SoundCloudAudioProvider>(
      builder: (context, audioProvider, child) {
        if (audioProvider.currentTrack == null) {
          return const SizedBox.shrink();
        }

        final track = audioProvider.currentTrack!;

        return Container(
          height: 80,
          decoration: BoxDecoration(
            color: ModizkColors.secondaryBackground,
            boxShadow: [
              BoxShadow(
                color: ModizkColors.primaryText.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Progress bar as top border
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildProgressBar(audioProvider),
              ),

              // Main content
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SongPlayerScreen(
                          shouldStartPlaying: false, // Don't restart, just continue
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        // Album Art
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: ModizkColors.primaryBackground,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: track.artworkUrl != null
                                ? Image.network(
                              track.artworkUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholder(),
                            )
                                : _buildPlaceholder(),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Song Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                track.title ?? "Unknown Song",
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: ModizkColors.primaryText,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                track.user.username ?? "Unknown Artist",
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: ModizkColors.secondaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Previous Button
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                          ),
                          child: IconButton(
                            onPressed: (){
                              audioProvider.playPrevious(context);
                            },
                            icon: Icon(
                              Icons.skip_previous,
                              color: ModizkColors.primaryText,
                              size: 24,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Play/Pause Button
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                          ),
                          child: IconButton(
                            onPressed: audioProvider.isLoading
                                ? null
                                : () {
                              if (audioProvider.isPlaying) {
                                audioProvider.pause();
                              } else {
                                audioProvider.resume();
                              }
                            },
                            icon: Icon(
                              // audioProvider.isLoading
                                  // ? Icons.hourglass_empty
                                  // :
                              (audioProvider.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow),
                              color: audioProvider.isLoading
                                  ? ModizkColors.secondaryText
                                  : ModizkColors.primaryAccent,
                              size: 28,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Next Button
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                          ),
                          child: IconButton(
                            onPressed: (){
                              audioProvider.playNext(context);
                            },
                            icon: Icon(
                              Icons.skip_next,
                              color: ModizkColors.primaryText,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(SoundCloudAudioProvider audioProvider) {
    final currentPosition = _isDragging
        ? Duration(seconds: _dragValue.toInt())
        : audioProvider.currentPosition;
    final totalDuration = audioProvider.totalDuration;

    return Container(
      height: 4,
      child: Stack(
        children: [
          // Background track
          Container(
            width: double.infinity,
            height: 4,
            color: ModizkColors.secondaryText.withValues(alpha: 0.2),
          ),
          // Progress track
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: totalDuration.inSeconds > 0
                ? (_isDragging
                ? _dragValue / totalDuration.inSeconds
                : currentPosition.inSeconds / totalDuration.inSeconds)
                : 0.0,
            child: Container(
              height: 4,
              color: ModizkColors.primaryAccent,
            ),
          ),
          // Invisible slider for interaction
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0), // Hidden thumb
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 0), // No overlay
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
            ),
            child: Slider(
              value: _isDragging
                  ? _dragValue
                  : (totalDuration.inSeconds > 0
                  ? currentPosition.inSeconds.toDouble()
                  : 0.0),
              max: totalDuration.inSeconds > 0
                  ? totalDuration.inSeconds.toDouble()
                  : 1.0,
              onChangeStart: (value) {
                setState(() {
                  _isDragging = true;
                  _dragValue = value;
                });
              },
              onChanged: (value) {
                setState(() {
                  _dragValue = value;
                });
              },
              onChangeEnd: (value) {
                setState(() {
                  _isDragging = false;
                });
                audioProvider.seek(Duration(seconds: value.toInt()));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: ModizkColors.primaryBackground,
      child: Icon(
        Icons.music_note,
        color: ModizkColors.secondaryText,
        size: 28,
      ),
    );
  }
}

class MiniPlayerWrapper extends StatelessWidget {
  final Widget child;

  const MiniPlayerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModizkColors.primaryBackground,
      body: Column(
        children: [
          Expanded(child: child),
          const MiniPlayer(),
        ],
      ),
    );
  }
}