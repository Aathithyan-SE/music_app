import 'package:flutter/material.dart';
import 'package:modizk_download/models/downloaded_song.dart';
import 'package:modizk_download/services/download_service.dart';
import 'package:modizk_download/services/local_music_provider.dart';
import 'package:modizk_download/services/sound_cloud_audio_provider.dart';
import 'package:modizk_download/screens/local_music_player.dart';
import 'package:modizk_download/theme.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<DownloadService>(
        builder: (context, downloadService, child) {
          return Column(
            children: [
              _buildHeader(context, downloadService),
              Expanded(
                child: downloadService.downloadedSongs.isEmpty
                    ? _buildEmptyState(context)
                    : _buildDownloadsList(context, downloadService),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DownloadService downloadService) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Downloads',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: MyColors.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (downloadService.downloadedSongs.isNotEmpty)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: MyColors.primaryText),
                  onSelected: (value) {
                    switch (value) {
                      case 'clear_all':
                        _showClearAllDialog(context, downloadService);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Text('Clear All', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (downloadService.downloadedSongs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${downloadService.downloadedSongsCount} songs • ${_formatSize(downloadService.totalDownloadedSize)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MyColors.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: MyColors.primaryAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.download_outlined,
                size: 64,
                color: MyColors.primaryAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No downloads yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: MyColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Downloaded songs will appear here for offline listening',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MyColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: MyColors.primaryAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: MyColors.primaryAccent.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '📱 Tap download button on any song',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: MyColors.primaryAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadsList(BuildContext context, DownloadService downloadService) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: downloadService.downloadedSongs.length,
      itemBuilder: (context, index) {
        final song = downloadService.downloadedSongs[index];
        return _buildDownloadedSongCard(context, song, downloadService);
      },
    );
  }

  Widget _buildDownloadedSongCard(BuildContext context, DownloadedSong song, DownloadService downloadService) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: MyColors.secondaryText.withValues(alpha: 0.1),
      color: MyColors.primaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: MyColors.secondaryText.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    MyColors.primaryAccent.withValues(alpha: 0.2),
                    MyColors.primaryAccent.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: MyColors.primaryAccent.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: song.artworkUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        song.artworkUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildMusicIcon(),
                      ),
                    )
                  : _buildMusicIcon(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: MyColors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MyColors.secondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.file_download_done,
                        size: 12,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          song.formattedFileSize,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: MyColors.secondaryText.withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: MyColors.secondaryText.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          song.formattedDuration,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: MyColors.secondaryText.withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _playDownloadedSong(context, song, downloadService),
                  icon: Icon(
                    Icons.play_arrow,
                    color: MyColors.primaryAccent,
                    size: 24,
                  ),
                  tooltip: 'Play',
                ),
                IconButton(
                  onPressed: () => _shareDownloadedSong(song),
                  icon: Icon(
                    Icons.share,
                    color: MyColors.primaryAccent,
                    size: 20,
                  ),
                  tooltip: 'Share',
                ),
                IconButton(
                  onPressed: () => _showDeleteDialog(context, song, downloadService),
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicIcon() {
    return Icon(
      Icons.music_note,
      color: MyColors.primaryAccent,
      size: 28,
    );
  }

  void _playDownloadedSong(BuildContext context, DownloadedSong song, DownloadService downloadService) async {
    try {
      final localMusicProvider = Provider.of<LocalMusicProvider>(context, listen: false);
      final soundCloudProvider = Provider.of<SoundCloudAudioProvider>(context, listen: false);
      
      // Stop any currently playing SoundCloud music
      if (soundCloudProvider.isPlaying) {
        await soundCloudProvider.stop();
      }
      
      // Convert downloaded song to LocalMusicModel
      final localMusicModel = song.toLocalMusicModel();
      
      // Create a collection of all downloaded songs as LocalMusicModel
      final downloadedSongsAsLocal = downloadService.downloadedSongs
          .map((downloadedSong) => downloadedSong.toLocalMusicModel())
          .toList();
      
      // Find the current song index in the collection
      final currentIndex = downloadedSongsAsLocal.indexWhere((track) => track.id == localMusicModel.id);
      
      // Set the downloaded songs as the current collection in LocalMusicProvider
      localMusicProvider.setDownloadedSongsCollection(downloadedSongsAsLocal);
      
      // Play the selected song
      await localMusicProvider.playLocalTrack(localMusicModel, currentIndex, context: context);
      
      // Navigate to the local music player
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LocalMusicPlayerScreen(shouldStartPlaying: true),
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to play song: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareDownloadedSong(DownloadedSong song) async {
    try {
      final file = File(song.localFilePath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(song.localFilePath)],
          text: '🎵 Check out this song: ${song.title} by ${song.artist}',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share file'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, DownloadedSong song, DownloadService downloadService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MyColors.secondaryBackground,
        title: Text(
          'Delete Download',
          style: TextStyle(color: MyColors.primaryText),
        ),
        content: Text(
          'Are you sure you want to delete "${song.title}"? This will remove the downloaded file.',
          style: TextStyle(color: MyColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: MyColors.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await downloadService.deleteDownloadedSong(song.id);
              Navigator.of(context).pop();
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${song.title}"'),
                    backgroundColor: MyColors.secondaryBackground,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete "${song.title}"'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, DownloadService downloadService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MyColors.secondaryBackground,
        title: Text(
          'Clear All Downloads',
          style: TextStyle(color: MyColors.primaryText),
        ),
        content: Text(
          'Are you sure you want to delete all downloaded songs? This action cannot be undone.',
          style: TextStyle(color: MyColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: MyColors.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () async {
              await downloadService.clearAllDownloads();
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('All downloads cleared'),
                  backgroundColor: MyColors.secondaryBackground,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}