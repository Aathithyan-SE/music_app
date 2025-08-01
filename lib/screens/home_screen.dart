import 'package:flutter/material.dart';
import 'package:modizk_download/screens/downloads_screen.dart';
import 'package:modizk_download/screens/my_music_screen.dart';
import 'package:modizk_download/screens/playlist_screen.dart';
import 'package:modizk_download/screens/premium_screen.dart';
import 'package:modizk_download/services/music_provider.dart';
import 'package:modizk_download/utils/my_color.dart';
import 'package:provider/provider.dart';
import 'package:modizk_download/theme.dart';
import 'package:modizk_download/widgets/mini_player.dart';
import 'package:modizk_download/screens/search_results_screen.dart';
import 'package:share_plus/share_plus.dart';

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
    final provider = Provider.of<MusicProvider>(context);

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

    return Column(
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
      ],
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


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}