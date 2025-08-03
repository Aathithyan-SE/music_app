import 'package:flutter/material.dart';
import 'package:modizk_download/screens/downloads_screen.dart';
import 'package:modizk_download/screens/my_music_screen.dart';
import 'package:modizk_download/screens/playlist_screen.dart';
import 'package:modizk_download/screens/premium_screen.dart';
import 'package:modizk_download/screens/song_player_screen.dart';
import 'package:modizk_download/services/music_provider.dart';
import 'package:modizk_download/services/playlist_service.dart';
import 'package:modizk_download/services/sound_cloud_audio_provider.dart';
import 'package:modizk_download/utils/my_color.dart';
import 'package:provider/provider.dart';
import 'package:modizk_download/theme.dart';
import 'package:modizk_download/widgets/mini_player.dart';
import 'package:modizk_download/screens/search_results_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:modizk_download/models/sound_cloud_search_response.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.primaryBackground,
      body: SafeArea(
        child: MiniPlayerWrapper(
          child: _getCurrentScreen(),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return MyMusicScreen();
      case 2:
        return PlaylistScreen();
      case 3:
        return DownloadsScreen();
      case 4:
        return PremiumScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.primaryBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: MyColors.primaryBackground,
        selectedItemColor: MyColors.primaryAccent,
        unselectedItemColor: MyColors.secondaryText,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music_outlined),
            activeIcon: Icon(Icons.library_music),
            label: 'My Music',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_play_outlined),
            activeIcon: Icon(Icons.playlist_play),
            label: 'Playlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download_outlined),
            activeIcon: Icon(Icons.download),
            label: 'Downloads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_outline),
            activeIcon: Icon(Icons.star),
            label: 'Premium',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    final provider = Provider.of<MusicProvider>(context);
    final playlistService = Provider.of<PlaylistService>(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          SizedBox(height: 20,),
          _buildSearchSection(provider),
          SizedBox(height: 20,),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMoodIcon('🎉', 'Hip hop', provider),
                _buildMoodIcon('😎', 'Pop', provider),
                _buildMoodIcon('💪', 'Gym', provider),
                _buildMoodIcon('🥳', 'Party', provider),
                _buildMoodIcon('🧘', 'Relax', provider),
              ],
            ),
          ),
          SizedBox(height: 30,),
          _buildRecentSongsSection(playlistService),
          SizedBox(height: 30,),
          _buildLikedSongsSection(playlistService),
        ],
      ),
    );
  }


  Widget _buildHeader() {
    String greeting;
    final hour = DateTime.now().hour;

    if (hour < 12) {
      greeting = 'Good morning ☀️';
    } else if (hour < 17) {
      greeting = 'Good afternoon 🌤️';
    } else {
      greeting = 'Good evening 🌙';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            greeting,
            style: TextStyle(
              color: MyColor.primaryBlack,
              fontSize: 25,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: Icon(Icons.share, color: MyColor.primaryBlack),
            onPressed: () {
              Share.share(
                'Check out this awesome app: https://yourapp.link',
                subject: 'Try this app!',
              );
            },
          ),
        ],
      ),
    );
  }


  Widget _buildSearchSection(MusicProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: MyColors.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onSubmitted: (query) {
                if (query.trim().isNotEmpty) {
                  provider.searchSong(query);
                  setState(() {
                    _searchController.text = '';
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SearchResultsScreen(query: query)),
                  );
                }
              },
              decoration: InputDecoration(
                hintText: 'What would you like to listen to?',
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
        ],
      ),
    );
  }



  Widget _buildMoodIcon(String emoji, String label, MusicProvider provider) {
    return InkWell(
      onTap: () {
        provider.searchSong(label);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SearchResultsScreen(query: label)),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: MyColors.secondaryBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: MyColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSongsSection(PlaylistService playlistService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Recently Played',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: MyColors.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: playlistService.recentSongs.isEmpty
              ? _buildEmptyRecentSongs()
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: playlistService.recentSongs.length,
                  itemBuilder: (context, index) {
                    final track = playlistService.recentSongs[index];
                    return _buildHorizontalSongCard(track, index, playlistService);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLikedSongsSection(PlaylistService playlistService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Liked Songs',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: MyColors.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (playlistService.likedSongs.isNotEmpty)
                TextButton(
                  onPressed: () => _showAllLikedSongs(playlistService),
                  child: Text(
                    'See All',
                    style: TextStyle(color: MyColors.primaryAccent),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: playlistService.likedSongs.isEmpty
              ? _buildEmptyLikedSongs()
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: playlistService.likedSongs.length > 10 ? 10 : playlistService.likedSongs.length,
                  itemBuilder: (context, index) {
                    final track = playlistService.likedSongs[index];
                    return _buildHorizontalSongCard(track, index, playlistService, isLiked: true);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyRecentSongs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MyColors.primaryAccent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MyColors.primaryAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 32,
                color: MyColors.primaryAccent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No recent songs',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: MyColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Songs you play will appear here',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: MyColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: MyColors.primaryAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: MyColors.primaryAccent.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '🎵 Start exploring music',
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

  Widget _buildEmptyLikedSongs() {
    return Container(
      margin:  EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_outline,
                size: 32,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No liked songs yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: MyColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap ♥ to save songs you love',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: MyColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '❤️ Discover & like music',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalSongCard(Track track, int index, PlaylistService playlistService, {bool isLiked = false}) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _playTrackFromHome(track, index),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: MyColors.secondaryBackground,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    track.artworkUrl != null
                        ? Image.network(
                            track.artworkUrl!,
                            fit: BoxFit.cover,
                            width: 140,
                            height: 140,
                            errorBuilder: (context, error, stackTrace) => _buildMiniAlbumPlaceholder(),
                          )
                        : _buildMiniAlbumPlaceholder(),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: MyColors.primaryAccent.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    if (isLiked)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            track.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: MyColors.primaryText,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            track.user.username,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: MyColors.secondaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAlbumPlaceholder() {
    return Container(
      width: 140,
      height: 140,
      color: MyColors.secondaryBackground,
      child: Icon(
        Icons.music_note,
        color: MyColors.secondaryText,
        size: 40,
      ),
    );
  }

  void _playTrackFromHome(Track track, int index) {
    final audioProvider = Provider.of<SoundCloudAudioProvider>(context, listen: false);
    final playlistService = Provider.of<PlaylistService>(context, listen: false);
    
    // Add to recent songs
    playlistService.addToRecentSongs(track);
    
    audioProvider.setCurrentTrack(track, index);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongPlayerScreen(shouldStartPlaying: true),
      ),
    );
  }

  void _showAllLikedSongs(PlaylistService playlistService) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllLikedSongsScreen(),
      ),
    );
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class AllLikedSongsScreen extends StatelessWidget {
  const AllLikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.primaryBackground,
      body: SafeArea(
        child: Consumer<PlaylistService>(
          builder: (context, playlistService, child) {
            return Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: playlistService.likedSongs.isEmpty
                      ? _buildEmptyState(context)
                      : _buildLikedSongsList(context, playlistService),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          Text(
            'Liked Songs',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: MyColors.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
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
            Icon(
              Icons.favorite_outline,
              size: 80,
              color: MyColors.secondaryText,
            ),
            const SizedBox(height: 16),
            Text(
              'No liked songs yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: MyColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Songs you like will appear here',
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

  Widget _buildLikedSongsList(BuildContext context, PlaylistService playlistService) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: playlistService.likedSongs.length,
      itemBuilder: (context, index) {
        final track = playlistService.likedSongs[index];
        return _buildSongItem(context, track, index, playlistService);
      },
    );
  }

  Widget _buildSongItem(BuildContext context, Track track, int index, PlaylistService playlistService) {
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
              onPressed: () => _playTrack(context, track, index, playlistService),
              icon: Icon(
                Icons.play_arrow,
                color: MyColors.primaryAccent,
                size: 20,
              ),
            ),
            IconButton(
              onPressed: () => _toggleLike(context, track, playlistService),
              icon: Icon(
                Icons.favorite,
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

  void _playTrack(BuildContext context, Track track, int index, PlaylistService playlistService) {
    final audioProvider = Provider.of<SoundCloudAudioProvider>(context, listen: false);
    
    // Add to recent songs
    playlistService.addToRecentSongs(track);
    
    audioProvider.setCurrentTrack(track, index);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongPlayerScreen(shouldStartPlaying: true),
      ),
    );
  }

  void _toggleLike(BuildContext context, Track track, PlaylistService playlistService) {
    playlistService.toggleLikeSong(track);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${track.title}" from liked songs'),
        backgroundColor: MyColors.secondaryBackground,
      ),
    );
  }
}