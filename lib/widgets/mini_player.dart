import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:modizk_download/screens/local_music_player.dart';
import 'package:modizk_download/services/music_provider.dart';
import 'package:modizk_download/services/local_music_provider.dart';
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
    return Consumer2<SoundCloudAudioProvider, LocalMusicProvider>(
      builder: (context, audioProvider, localProvider, child) {
        final bool hasSoundCloudTrack = audioProvider.currentTrack != null;
        final bool hasLocalTrack = localProvider.currentLocalTrack != null;
        if (!hasSoundCloudTrack && !hasLocalTrack) {
          return const SizedBox.shrink();
        }

        bool isUsingSoundCloud = false;
        bool isUsingLocal = false;

        if (hasSoundCloudTrack && hasLocalTrack) {
          isUsingSoundCloud = audioProvider.isPlaying ||
              (!localProvider.isLocalPlaying && hasSoundCloudTrack);
          isUsingLocal = !isUsingSoundCloud;
        } else if (hasSoundCloudTrack) {
          isUsingSoundCloud = true;
        } else {
          isUsingLocal = true;
        }

        return Container(
          height: 80,
          decoration: BoxDecoration(
            color: MyColors.secondaryBackground,
            boxShadow: [
              BoxShadow(
                color: MyColors.primaryText.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Progress bar at the very top - no gap
              _buildProgressBar(audioProvider, localProvider, isUsingSoundCloud),

              // Main content
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (isUsingLocal) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LocalMusicPlayerScreen(shouldStartPlaying: true),
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SongPlayerScreen(
                              shouldStartPlaying: false,
                            ),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _buildAlbumArt(audioProvider, localProvider, isUsingSoundCloud),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSongInfo(audioProvider, localProvider, isUsingSoundCloud),
                          ),
                          const SizedBox(width: 12),
                          _buildPreviousButton(audioProvider, localProvider, isUsingSoundCloud),
                          const SizedBox(width: 8),
                          _buildPlayPauseButton(audioProvider, localProvider, isUsingSoundCloud),
                          const SizedBox(width: 8),
                          _buildNextButton(audioProvider, localProvider, isUsingSoundCloud),
                        ],
                      ),
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

  Widget _buildAlbumArt(SoundCloudAudioProvider audioProvider, LocalMusicProvider localProvider, bool isUsingSoundCloud) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: MyColors.primaryBackground,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: isUsingSoundCloud
            ? (audioProvider.currentTrack?.artworkUrl != null
            ? Image.network(
          audioProvider.currentTrack!.artworkUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        )
            : _buildPlaceholder())
            : FutureBuilder<Uint8List?>(
          future: localProvider.currentLocalTrack != null
              ? localProvider.getSongArtwork(localProvider.currentLocalTrack!.id)
              : Future.value(null),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
              );
            }
            return _buildPlaceholder();
          },
        ),
      ),
    );
  }

  Widget _buildSongInfo(SoundCloudAudioProvider audioProvider, LocalMusicProvider localProvider, bool isUsingSoundCloud) {
    String title = "Unknown Song";
    String artist = "Unknown Artist";

    if (isUsingSoundCloud && audioProvider.currentTrack != null) {
      title = audioProvider.currentTrack!.title ?? "Unknown Song";
      artist = audioProvider.currentTrack!.user.username ?? "Unknown Artist";
    } else if (!isUsingSoundCloud && localProvider.currentLocalTrack != null) {
      title = localProvider.currentLocalTrack!.title;
      artist = localProvider.currentLocalTrack!.artist;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: MyColors.primaryText,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        artist.toLowerCase().contains('unknown')? Container():Text(
          artist,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: MyColors.secondaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPreviousButton(SoundCloudAudioProvider audioProvider, LocalMusicProvider localProvider, bool isUsingSoundCloud) {
    final bool hasPrevious = isUsingSoundCloud
        ? (audioProvider.currentIndex > 0)
        : localProvider.hasPreviousTrack;

    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
      ),
      child: IconButton(
        onPressed: hasPrevious ? () {
          if (isUsingSoundCloud) {
            audioProvider.playPrevious(context);
          } else {
            // Stop SoundCloud if it's playing
            if (audioProvider.isPlaying) {
              audioProvider.pause();
            }
            localProvider.playPreviousLocal();
          }
        } : null,
        icon: Icon(
          Icons.skip_previous,
          color: hasPrevious ? MyColors.primaryText : MyColors.secondaryText,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton(SoundCloudAudioProvider audioProvider, LocalMusicProvider localProvider, bool isUsingSoundCloud) {
    final bool isPlaying = isUsingSoundCloud ? audioProvider.isPlaying : localProvider.isLocalPlaying;
    final bool isLoading = isUsingSoundCloud ? audioProvider.isLoading : localProvider.isLocalLoading;

    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
      ),
      child: IconButton(
        onPressed: isLoading ? null : () async {
          if (isUsingSoundCloud) {
            // Stop local music if it's playing
            if (localProvider.isLocalPlaying) {
              await localProvider.pauseLocal();
            }

            if (audioProvider.isPlaying) {
              await audioProvider.pause();
            } else {
              await audioProvider.resume();
            }
          } else {
            // Stop SoundCloud if it's playing
            if (audioProvider.isPlaying) {
              await audioProvider.pause();
            }

            if (localProvider.isLocalPlaying) {
              await localProvider.pauseLocal();
            } else {
              await localProvider.resumeLocal();
            }
          }
        },
        icon: Icon(
          isLoading
              ? Icons.hourglass_empty
              : (isPlaying ? Icons.pause : Icons.play_arrow),
          color: isLoading
              ? MyColors.secondaryText
              : MyColors.primaryAccent,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildNextButton(SoundCloudAudioProvider audioProvider, LocalMusicProvider localProvider, bool isUsingSoundCloud) {
    final bool hasNext = isUsingSoundCloud
        ? _hasSoundCloudNext(audioProvider, context)
        : localProvider.hasNextTrack;

    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
      ),
      child: IconButton(
        onPressed: hasNext ? () {
          if (isUsingSoundCloud) {
            audioProvider.playNext(context);
          } else {
            if (audioProvider.isPlaying) {
              audioProvider.pause();
            }
            localProvider.playNextLocal();
          }
        } : null,
        icon: Icon(
          Icons.skip_next,
          color: hasNext ? MyColors.primaryText : MyColors.secondaryText,
          size: 24,
        ),
      ),
    );
  }

  bool _hasSoundCloudNext(SoundCloudAudioProvider audioProvider, BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    return musicProvider.soundCloudResponse != null &&
        audioProvider.currentIndex < musicProvider.soundCloudResponse!.collection.length - 1;
  }

  Widget _buildProgressBar(SoundCloudAudioProvider audioProvider, LocalMusicProvider localProvider, bool isUsingSoundCloud) {
    final Duration currentPosition;
    final Duration totalDuration;

    if (isUsingSoundCloud) {
      currentPosition = _isDragging
          ? Duration(seconds: _dragValue.toInt())
          : audioProvider.currentPosition;
      totalDuration = audioProvider.totalDuration;
    } else {
      currentPosition = _isDragging
          ? Duration(seconds: _dragValue.toInt())
          : localProvider.localCurrentPosition;
      totalDuration = localProvider.localTotalDuration;
    }

    return Container(
      height: 5, // Larger container for better touch area
      child: Stack(
        children: [
          // Visual progress bar at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              child: Stack(
                children: [
                  // Background track
                  Container(
                    width: double.infinity,
                    height: 4,
                    color: MyColors.secondaryText.withValues(alpha: 0.2),
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
                      color: MyColors.primaryAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Invisible but interactive slider covering the full area
          Positioned.fill(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 20, // Full height for better touch detection
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0), // Still invisible
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 0), // No visual overlay
                activeTrackColor: Colors.transparent, // Invisible tracks
                inactiveTrackColor: Colors.transparent,
                thumbColor: Colors.transparent,
                overlayColor: Colors.transparent,
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

                  final seekPosition = Duration(seconds: value.toInt());
                  if (isUsingSoundCloud) {
                    audioProvider.seek(seekPosition);
                  } else {
                    localProvider.seekLocal(seekPosition);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: MyColors.primaryBackground,
      child: Icon(
        Icons.music_note,
        color: MyColors.secondaryText,
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
      backgroundColor: MyColors.primaryBackground,
      body: Column(
        children: [
          Expanded(child: child),
          const MiniPlayer(),
        ],
      ),
    );
  }
}