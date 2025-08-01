import 'package:flutter/material.dart';
import 'package:modizk_download/models/playlist.dart';
import 'package:modizk_download/models/sound_cloud_search_response.dart';
import 'package:modizk_download/screens/song_player_screen.dart';
import 'package:modizk_download/services/playlist_service.dart';
import 'package:modizk_download/services/sound_cloud_audio_provider.dart';
import 'package:modizk_download/theme.dart';
import 'package:provider/provider.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<PlaylistService>(
        builder: (context, playlistService, child) {
          return Column(
            children: [
              _buildHeader(context, playlistService),
              Expanded(
                child: playlistService.playlists.isEmpty
                    ? _buildEmptyState(context, playlistService)
                    : _buildPlaylistList(context, playlistService),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PlaylistService playlistService) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'My Playlists',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: MyColors.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () => _showCreatePlaylistDialog(context, playlistService),
            icon: Icon(
              Icons.add,
              color: MyColors.primaryAccent,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, PlaylistService playlistService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_play,
              size: 80,
              color: MyColors.secondaryText,
            ),
            const SizedBox(height: 16),
            Text(
              'No playlists yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: MyColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first playlist to organize your favorite songs',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MyColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreatePlaylistDialog(context, playlistService),
              icon: const Icon(Icons.add),
              label: const Text('Create Playlist'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.primaryAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistList(BuildContext context, PlaylistService playlistService) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: playlistService.playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlistService.playlists[index];
        return _buildPlaylistItem(context, playlist, playlistService);
      },
    );
  }

  Widget _buildPlaylistItem(BuildContext context, Playlist playlist, PlaylistService playlistService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: MyColors.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: MyColors.primaryAccent.withOpacity(0.1),
          ),
          child: playlist.tracks.isNotEmpty && playlist.tracks.first.artworkUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    playlist.tracks.first.artworkUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaylistPlaceholder(),
                  ),
                )
              : _buildPlaylistPlaceholder(),
        ),
        title: Text(
          playlist.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: MyColors.primaryText,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${playlist.tracks.length} ${playlist.tracks.length == 1 ? 'song' : 'songs'}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: MyColors.secondaryText,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: MyColors.primaryText),
          onSelected: (value) {
            switch (value) {
              case 'rename':
                _showRenamePlaylistDialog(context, playlist, playlistService);
                break;
              case 'delete':
                _showDeletePlaylistDialog(context, playlist, playlistService);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit, color: MyColors.primaryText, size: 20),
                  const SizedBox(width: 8),
                  Text('Rename', style: TextStyle(color: MyColors.primaryText)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _openPlaylistDetail(context, playlist),
      ),
    );
  }

  Widget _buildPlaylistPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.primaryAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.playlist_play,
        color: MyColors.primaryAccent,
        size: 28,
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, PlaylistService playlistService) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MyColors.secondaryBackground,
        title: Text(
          'Create Playlist',
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
                await playlistService.createPlaylist(
                  name: nameController.text.trim(),
                );
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.primaryAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenamePlaylistDialog(BuildContext context, Playlist playlist, PlaylistService playlistService) {
    final TextEditingController nameController = TextEditingController(text: playlist.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MyColors.secondaryBackground,
        title: Text(
          'Rename Playlist',
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
                await playlistService.renamePlaylist(playlist.id, nameController.text.trim());
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.primaryAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeletePlaylistDialog(BuildContext context, Playlist playlist, PlaylistService playlistService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MyColors.secondaryBackground,
        title: Text(
          'Delete Playlist',
          style: TextStyle(color: MyColors.primaryText),
        ),
        content: Text(
          'Are you sure you want to delete "${playlist.name}"? This action cannot be undone.',
          style: TextStyle(color: MyColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: MyColors.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () async {
              await playlistService.deletePlaylist(playlist.id);
              Navigator.of(context).pop();
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

  void _openPlaylistDetail(BuildContext context, Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }
}

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.primaryBackground,
      body: SafeArea(
        child: Consumer<PlaylistService>(
          builder: (context, playlistService, child) {
            final currentPlaylist = playlistService.getPlaylistById(playlist.id);
            if (currentPlaylist == null) {
              return Center(
                child: Text(
                  'Playlist not found',
                  style: TextStyle(color: MyColors.primaryText),
                ),
              );
            }

            return Column(
              children: [
                _buildHeader(context, currentPlaylist),
                Expanded(
                  child: currentPlaylist.tracks.isEmpty
                      ? _buildEmptyPlaylist(context)
                      : _buildTrackList(context, currentPlaylist),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Playlist playlist) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back,
                  color: MyColors.primaryText,
                ),
              ),
              Expanded(
                child: Text(
                  playlist.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: MyColors.primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const SizedBox(width: 48),
              Expanded(
                child: Text(
                  '${playlist.tracks.length} ${playlist.tracks.length == 1 ? 'song' : 'songs'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MyColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaylist(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              size: 80,
              color: MyColors.secondaryText,
            ),
            const SizedBox(height: 16),
            Text(
              'No songs in this playlist',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: MyColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add songs from search results',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MyColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackList(BuildContext context, Playlist playlist) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: playlist.tracks.length,
      itemBuilder: (context, index) {
        final track = playlist.tracks[index];
        return _buildTrackItem(context, track, index, playlist);
      },
    );
  }

  Widget _buildTrackItem(BuildContext context, Track track, int index, Playlist playlist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: MyColors.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: MyColors.primaryBackground,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: track.artworkUrl != null
                ? Image.network(
                    track.artworkUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildAlbumPlaceholder(),
                  )
                : _buildAlbumPlaceholder(),
          ),
        ),
        title: Text(
          track.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: MyColors.primaryText,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          track.user.username,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: MyColors.secondaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _playTrack(context, track, index),
              icon: Icon(
                Icons.play_arrow,
                color: MyColors.primaryAccent,
                size: 20,
              ),
            ),
            IconButton(
              onPressed: () => _removeFromPlaylist(context, playlist, track),
              icon: Icon(
                Icons.remove,
                color: Colors.red,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumPlaceholder() {
    return Container(
      color: MyColors.primaryBackground,
      child: Icon(
        Icons.music_note,
        color: MyColors.secondaryText,
        size: 28,
      ),
    );
  }

  void _playTrack(BuildContext context, Track track, int index) {
    final audioProvider = Provider.of<SoundCloudAudioProvider>(context, listen: false);
    audioProvider.setCurrentTrack(track, index);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongPlayerScreen(shouldStartPlaying: true),
      ),
    );
  }

  void _removeFromPlaylist(BuildContext context, Playlist playlist, Track track) {
    final playlistService = Provider.of<PlaylistService>(context, listen: false);
    playlistService.removeTrackFromPlaylist(playlist.id, track.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${track.title}" from playlist'),
        backgroundColor: MyColors.secondaryBackground,
      ),
    );
  }
}