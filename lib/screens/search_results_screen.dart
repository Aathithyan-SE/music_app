import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:modizk_download/models/sound_cloud_search_response.dart' as t;
import 'package:modizk_download/screens/song_player_screen.dart';
import 'package:modizk_download/services/music_provider.dart';
import 'package:modizk_download/services/sound_cloud_audio_provider.dart';
import 'package:provider/provider.dart';
import 'package:modizk_download/theme.dart';
import 'package:modizk_download/services/storage_service.dart';
import 'package:modizk_download/models/song.dart';
import 'package:modizk_download/widgets/mini_player.dart';

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
        backgroundColor: ModizkColors.primaryBackground,
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
              color: ModizkColors.primaryText,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: ModizkColors.secondaryBackground,
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
                  hintStyle: TextStyle(color: ModizkColors.secondaryText),
                  prefixIcon: Icon(
                    Icons.search,
                    color: ModizkColors.secondaryText,
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
        color: ModizkColors.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: ModizkColors.primaryBackground,
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
            color: ModizkColors.primaryText,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        subtitle: Text(
          song.user.username,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: ModizkColors.secondaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // _buildActionButton(
            //   Icons.add,
            //   ModizkColors.primaryText,
            //   () => _showAddToPlaylistDialog(song),
            // ),

            const SizedBox(width: 8),

            // _buildActionButton(
            //   Icons.download_outlined,
            //   ModizkColors.primaryText,
            //   () => _downloadSong(song),
            // ),
            //
            // const SizedBox(width: 8),
            //
            _buildActionButton(
              Icons.play_arrow,
              ModizkColors.primaryAccent,
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
      color: ModizkColors.primaryBackground,
      child: Icon(
        Icons.music_note,
        color: ModizkColors.secondaryText,
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
              color: ModizkColors.secondaryText,
            ),

            const SizedBox(height: 16),

            Text(
              'No results found for your search.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ModizkColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Try searching for \'popular artists\', \'new playlists\'.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ModizkColors.secondaryText,
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
          backgroundColor: ModizkColors.secondaryBackground,
          foregroundColor: ModizkColors.primaryText,
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
              color: ModizkColors.primaryText,
            ),
          ),
        ),
      ),
    );
  }

  void playMusic(t.Track myTrack, MusicProvider provider, int index) async {
    final songProvider = Provider.of<SoundCloudAudioProvider>(context, listen: false);
    songProvider.setCurrentTrack(myTrack, index);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SongPlayerScreen(
        shouldStartPlaying: true,
      ),),
    );
  }






  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}