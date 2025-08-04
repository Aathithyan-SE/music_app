import 'package:flutter/material.dart';
import 'package:modizk_download/services/music_provider.dart';
import 'package:modizk_download/services/playlist_service.dart';
import 'package:modizk_download/services/download_service.dart';
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
                    _buildPlaybackControls(context, musicProvider),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _buildActionButtons(context),
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
            color: MyColors.primaryText.withValues(alpha: 0.1),
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
            MyColors.primaryAccent.withValues(alpha: 0.3),
            MyColors.secondaryAccent.withValues(alpha: 0.3),
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

  Widget _buildSongDetails(BuildContext context, SoundCloudAudioProvider provider) {
    return Column(
      children: [
        Text(
          provider.currentTrack!.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: MyColors.primaryText,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          provider.currentTrack!.user.username,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: MyColors.secondaryText,
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
                activeTrackColor: MyColors.primaryAccent,
                inactiveTrackColor: MyColors.secondaryText.withValues(alpha: 0.3),
                thumbColor: MyColors.primaryAccent,
                overlayColor: MyColors.primaryAccent.withValues(alpha: 0.2),
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
                  MyColors.primaryText,
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
                  MyColors.primaryAccent,
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
                  MyColors.primaryText,
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
            ? MyColors.primaryAccent.withValues(alpha: 0.1)
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

  Widget _buildActionButtons(BuildContext context) {
    return Consumer<SoundCloudAudioProvider>(
      builder: (context, audioProvider, child) {
        if (audioProvider.currentTrack == null) {
          return Container();
        }

        return Consumer<PlaylistService>(
          builder: (context, playlistService, child) {
            final track = audioProvider.currentTrack!;
            final isLiked = playlistService.isTrackLiked(track);

            return Consumer<DownloadService>(
              builder: (context, downloadService, child) {
                final trackId = track.id.toString();
                final isDownloaded = downloadService.isTrackDownloaded(trackId);
                final isDownloading = downloadService.isTrackDownloading(trackId);
                final downloadProgress = downloadService.getDownloadProgress(trackId);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      context,
                      Icons.add,
                      'Add to Playlist',
                          () => _showAddToPlaylistDialog(track),
                    ),
                    _buildActionButton(
                      context,
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      'Like',
                          () => _toggleLikeSong(track, playlistService),
                      color: isLiked ? Colors.red : MyColors.primaryText,
                    ),
                    _buildDownloadButton(
                      context,
                      track,
                      isDownloaded,
                      isDownloading,
                      downloadProgress,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
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
              color: color ?? MyColors.primaryText,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: MyColors.secondaryText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDownloadButton(
      BuildContext context,
      track,
      bool isDownloaded,
      bool isDownloading,
      double downloadProgress) {
    
    IconData icon;
    String label;
    Color? color;
    VoidCallback? onPressed;

    if (isDownloaded) {
      icon = Icons.download_done;
      label = 'Downloaded';
      color = Colors.green;
      onPressed = null; // Disable button
    } else if (isDownloading) {
      icon = Icons.downloading;
      label = '${(downloadProgress * 100).toInt()}%';
      color = MyColors.primaryAccent;
      onPressed = null; // Disable button during download
    } else {
      icon = Icons.download_outlined;
      label = 'Download';
      color = MyColors.primaryText;
      onPressed = () => _downloadTrack(track);
    }

    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),
          child: isDownloading
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: downloadProgress,
                      strokeWidth: 2,
                      color: MyColors.primaryAccent,
                      backgroundColor: MyColors.secondaryText.withValues(alpha: 0.3),
                    ),
                    Icon(
                      Icons.downloading,
                      color: MyColors.primaryAccent,
                      size: 20,
                    ),
                  ],
                )
              : IconButton(
                  onPressed: onPressed,
                  icon: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: MyColors.secondaryText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showAddToPlaylistDialog(track) {
    final playlistService = Provider.of<PlaylistService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MyColors.secondaryBackground,
        title: Text(
          'Add to Playlist',
          style: TextStyle(color: MyColors.primaryText),
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.add, color: MyColors.primaryAccent),
                title: Text(
                  'Create New Playlist',
                  style: TextStyle(color: MyColors.primaryText),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showCreatePlaylistDialog(track);
                },
              ),
              if (playlistService.playlists.isNotEmpty) const Divider(),
              ...playlistService.playlists.map((playlist) => ListTile(
                leading: Icon(Icons.playlist_play, color: MyColors.primaryText),
                title: Text(
                  playlist.name,
                  style: TextStyle(color: MyColors.primaryText),
                ),
                subtitle: Text(
                  '${playlist.tracks.length} songs',
                  style: TextStyle(color: MyColors.secondaryText),
                ),
                onTap: () async {
                  await playlistService.addTrackToPlaylist(playlist.id, track);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added "${track.title}" to ${playlist.name}'),
                      backgroundColor: MyColors.secondaryBackground,
                    ),
                  );
                },
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: MyColors.secondaryText)),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(track) {
    final TextEditingController nameController = TextEditingController();
    final playlistService = Provider.of<PlaylistService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MyColors.secondaryBackground,
        title: Text(
          'Create New Playlist',
          style: TextStyle(color: MyColors.primaryText),
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Playlist Name',
            labelStyle: TextStyle(color: MyColors.secondaryText),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: MyColors.secondaryText),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: MyColors.primaryAccent),
            ),
          ),
          style: TextStyle(color: MyColors.primaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: MyColors.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final playlist = await playlistService.createPlaylist(
                  name: nameController.text.trim(),
                );
                await playlistService.addTrackToPlaylist(playlist.id, track);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Created "${playlist.name}" and added "${track.title}"'),
                    backgroundColor: MyColors.secondaryBackground,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.primaryAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create & Add'),
          ),
        ],
      ),
    );
  }

  void _toggleLikeSong(track, PlaylistService playlistService) {
    final wasLiked = playlistService.isTrackLiked(track);
    
    playlistService.toggleLikeSong(track);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasLiked 
              ? 'Removed "${track.title}" from liked songs'
              : 'Added "${track.title}" to liked songs',
        ),
        backgroundColor: MyColors.secondaryBackground,
      ),
    );
  }

  void _downloadTrack(track) async {
    final downloadService = Provider.of<DownloadService>(context, listen: false);
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting download of "${track.title}"...'),
        backgroundColor: MyColors.secondaryBackground,
      ),
    );

    final success = await downloadService.downloadTrack(track, musicProvider);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded "${track.title}" successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download "${track.title}"'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}