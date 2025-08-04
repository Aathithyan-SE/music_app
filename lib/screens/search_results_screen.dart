import 'package:flutter/material.dart';
import 'package:modizk_download/models/sound_cloud_search_response.dart' as t;
import 'package:modizk_download/screens/song_player_screen.dart';
import 'package:modizk_download/services/music_provider.dart';
import 'package:modizk_download/services/playlist_service.dart';
import 'package:modizk_download/services/download_service.dart';
import 'package:modizk_download/services/sound_cloud_audio_provider.dart';
import 'package:provider/provider.dart';
import 'package:modizk_download/theme.dart';
import 'package:modizk_download/widgets/mini_player.dart';
import 'package:share_plus/share_plus.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;

  SearchResultsScreen({super.key, required this.query});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.query;
  }

  @override
  Widget build(BuildContext context) {

    final provider = Provider.of<MusicProvider>(context);

    return MiniPlayerWrapper(
      child: Scaffold(
        backgroundColor: MyColors.primaryBackground,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(provider),
              Expanded(
                child: provider.songsStatus == 1
                    ? const Center(child: CircularProgressIndicator())
                    : _buildSearchResults(provider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(MusicProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: MyColors.primaryText,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: MyColors.secondaryBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (query) {
                  if (query.trim().isNotEmpty) {
                    provider.searchSong(query);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Search song',
                  hintStyle: TextStyle(color: MyColors.secondaryText),
                  prefixIcon: Icon(
                    Icons.search,
                    color: MyColors.secondaryText,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildSearchResults(MusicProvider provider) {
    if (provider.soundCloudResponse == null || provider.soundCloudResponse!.collection.isEmpty) {
      return _buildNoResults();
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: provider.soundCloudResponse!.collection.length,
            itemBuilder: (context, index) {
              return _buildSongItem(provider.soundCloudResponse!.collection[index], provider, index);
            },
          ),
        ),

        if (provider.soundCloudResponse!.nextHref != null) _buildLoadMoreButton(provider),
      ],
    );
  }

  Widget _buildSongItem(t.Track song, MusicProvider provider, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: MyColors.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () => playMusic(song, provider, index),
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
            child: song.artworkUrl != null
                ? Image.network(
                    song.artworkUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildAlbumPlaceholder(),
                  )
                : _buildAlbumPlaceholder(),
          ),
        ),

        title: Text(
          song.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: MyColors.primaryText,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        subtitle: Text(
          song.user.username,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: MyColors.secondaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              Icons.more_vert,
              MyColors.primaryText,
              () => _showMoreOptionsBottomSheet(song),
            ),
            
            const SizedBox(width: 8),
            
            _buildActionButton(
              Icons.play_arrow,
              MyColors.primaryAccent,
              () => playMusic(song, provider, index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 20),
        padding: EdgeInsets.zero,
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

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: MyColors.secondaryText,
            ),

            const SizedBox(height: 16),

            Text(
              'No results found for your search.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: MyColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Try searching for \'popular artists\', \'new playlists\'.',
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

  Widget _buildLoadMoreButton(MusicProvider provider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: provider.songsLoadMoreStatus == 1 ? null: () async{
            provider.searchLoadMoreSong(provider.soundCloudResponse!.nextHref!);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: MyColors.secondaryBackground,
          foregroundColor: MyColors.primaryText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            provider.songsLoadMoreStatus == 1 ? 'Loading...':'Load More',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: MyColors.primaryText,
            ),
          ),
        ),
      ),
    );
  }

  void playMusic(t.Track myTrack, MusicProvider provider, int index) async {
    final songProvider = Provider.of<SoundCloudAudioProvider>(context, listen: false);
    final playlistService = Provider.of<PlaylistService>(context, listen: false);
    
    // Add to recent songs
    playlistService.addToRecentSongs(myTrack);
    
    songProvider.setCurrentTrack(myTrack, index);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SongPlayerScreen(
        shouldStartPlaying: true,
      ),),
    );
  }

  void _showAddToPlaylistDialog(t.Track track) {
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

  void _showCreatePlaylistDialog(t.Track track) {
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

  void _toggleLikeSong(t.Track track) {
    final playlistService = Provider.of<PlaylistService>(context, listen: false);
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

  void _downloadTrack(t.Track track) async {
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

  void _showMoreOptionsBottomSheet(t.Track song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyColors.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with song info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: MyColors.primaryBackground,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: song.artworkUrl != null
                          ? Image.network(
                              song.artworkUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildAlbumPlaceholder(),
                            )
                          : _buildAlbumPlaceholder(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: TextStyle(
                            color: MyColors.primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song.user.username,
                          style: TextStyle(
                            color: MyColors.secondaryText,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Options
            Consumer<PlaylistService>(
              builder: (context, playlistService, child) {
                final isLiked = playlistService.isTrackLiked(song);
                return ListTile(
                  leading: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : MyColors.primaryText,
                  ),
                  title: Text(
                    isLiked ? 'Remove from Liked Songs' : 'Add to Liked Songs',
                    style: TextStyle(color: MyColors.primaryText),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleLikeSong(song);
                  },
                );
              },
            ),
            
            ListTile(
              leading: Icon(Icons.add, color: MyColors.primaryText),
              title: Text(
                'Add to Playlist',
                style: TextStyle(color: MyColors.primaryText),
              ),
              onTap: () {
                Navigator.pop(context);
                                _showAddToPlaylistDialog(song);
               },
             ),
             ListTile(
              leading: Icon(Icons.share, color: MyColors.primaryText),
              title: Text(
                'Share',
                style: TextStyle(color: MyColors.primaryText),
              ),
              onTap: () {
                Navigator.pop(context);
                Share.share('Check out this awesome music app (https://play.google.com/store/apps/details?id=com.mycompany.CounterApp)');
              },
            ),
            
             Consumer<DownloadService>(
               builder: (context, downloadService, child) {
                 final trackId = song.id.toString();
                final isDownloaded = downloadService.isTrackDownloaded(trackId);
                final isDownloading = downloadService.isTrackDownloading(trackId);
                
                IconData icon;
                Color color;
                String title;
                bool isEnabled = true;
                
                if (isDownloaded) {
                  icon = Icons.download_done;
                  color = Colors.green;
                  title = 'Downloaded';
                  isEnabled = false;
                } else if (isDownloading) {
                  icon = Icons.downloading;
                  color = MyColors.primaryAccent;
                  title = 'Downloading...';
                  isEnabled = false;
                } else {
                  icon = Icons.download_outlined;
                  color = MyColors.primaryText;
                  title = 'Download';
                }

                return ListTile(
                  leading: Icon(icon, color: color),
                  title: Text(
                    title,
                    style: TextStyle(
                      color: isEnabled ? MyColors.primaryText : MyColors.secondaryText,
                    ),
                  ),
                  onTap: isEnabled ? () {
                    Navigator.pop(context);
                    _downloadTrack(song);
                  } : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }






  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}