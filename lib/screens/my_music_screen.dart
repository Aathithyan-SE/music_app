import 'package:flutter/material.dart';
import 'package:modizk_download/models/local_music_model.dart';
import 'package:modizk_download/screens/downloads_screen.dart';
import 'package:modizk_download/screens/local_music_player.dart';
import 'package:modizk_download/services/download_service.dart';
import 'package:modizk_download/services/local_music_provider.dart';
import 'package:modizk_download/services/local_music_service.dart';
import 'package:modizk_download/services/my_music_provider.dart';
import 'package:modizk_download/theme.dart';
import 'package:provider/provider.dart';

class MyMusicScreen extends StatefulWidget {
  const MyMusicScreen({super.key});

  @override
  State<MyMusicScreen> createState() => _MyMusicScreenState();
}

class _MyMusicScreenState extends State<MyMusicScreen>
    with TickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController?.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocalMusicProvider>().loadLocalSongs();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final downloadService = context.watch<DownloadService>();
    final localMusicProvider = context.watch<LocalMusicProvider>();
    final directories = localMusicProvider.allSongs
        .map((e) => e.album)
        .where((element) => element != null)
        .toSet();
    final hasDownloads = downloadService.downloadedSongs.isNotEmpty;
    final tabCount = 1 + (hasDownloads ? 1 : 0) + directories.length;

    if (_tabController == null || _tabController!.length != tabCount) {
      final oldIndex = _tabController?.index ?? 0;
      _tabController?.dispose();
      _tabController = TabController(
        length: tabCount,
        vsync: this,
        initialIndex: oldIndex < tabCount ? oldIndex : 0,
      );
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  List<String> _getSortedDirectories() {
    final localMusicProvider = context.watch<LocalMusicProvider>();
    return localMusicProvider.allSongs
        .map((e) => e.album)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: MyColors.primaryBackground,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: MyColors.primaryBackground,
      elevation: 0,
      title: Text(
        'My Music',
        style: TextStyle(
          color: MyColors.primaryText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final downloadService = context.watch<DownloadService>();
    final directories = _getSortedDirectories();
    final hasDownloads = downloadService.downloadedSongs.isNotEmpty;

    List<Tab> tabs = [
      const Tab(text: 'Songs'),
      if (hasDownloads) const Tab(text: 'Downloads'),
      ...directories.map((dir) => Tab(text: dir)),
    ];

    return TabBar(
      controller: _tabController,
      tabAlignment: TabAlignment.start,
      isScrollable: true,
      tabs: tabs,
      labelColor: MyColors.primaryAccent,
      unselectedLabelColor: MyColors.secondaryText,
      indicatorColor: MyColors.primaryAccent,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: searchController,
        style: TextStyle(color: MyColors.primaryText),
        decoration: InputDecoration(
          hintText: 'Search songs...',
          hintStyle: TextStyle(color: MyColors.secondaryText),
          prefixIcon: Icon(Icons.search, color: MyColors.secondaryText),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: MyColors.secondaryText),
                  onPressed: () {
                    searchController.clear();
                    context.read<LocalMusicProvider>().clearSearch();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: MyColors.secondaryText.withValues(alpha: 0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {});
          context.read<LocalMusicProvider>().searchLocalSongs(value);
        },
      ),
    );
  }

  Widget _buildContent() {
    final downloadService = context.watch<DownloadService>();
    final localMusicProvider = context.watch<LocalMusicProvider>();
    final directories = _getSortedDirectories();
    final hasDownloads = downloadService.downloadedSongs.isNotEmpty;

    List<Widget> children = [
      _buildSongsList(localMusicProvider.songs, showSort: true),
      if (hasDownloads) const DownloadsScreen(),
      ...directories.map((dir) => _buildSongsList(
          localMusicProvider.allSongs
              .where((song) => song.album == dir)
              .toList(),
          showSort: true)),
    ];

    return TabBarView(
      controller: _tabController,
      children: children,
    );
  }

  Widget _buildSongsList(List<LocalMusicModel> songs, {bool showSort = false}) {
    return Column(
      children: [
        if (showSort)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => _showSortOptions(context),
                  icon: Icon(Icons.sort, color: MyColors.primaryAccent, size: 20),
                  label: Text('Sort By', style: TextStyle(color: MyColors.primaryAccent)),
                ),
              ],
            ),
          ),
        Expanded(
          child: Consumer<LocalMusicProvider>(
            builder: (context, provider, child) {
              if (songs.isEmpty) {
                return _buildEmptyState();
              }
              return RefreshIndicator(
                onRefresh: () async {
                  await provider.loadLocalSongs();
                },
                color: MyColors.primaryAccent,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shadowColor:
                          MyColors.secondaryText.withValues(alpha: 0.1),
                      color: MyColors.primaryBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color:
                              MyColors.secondaryText.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _playSong(provider, song, index),
                        borderRadius: BorderRadius.circular(12),
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
                                      MyColors.primaryAccent
                                          .withValues(alpha: 0.2),
                                      MyColors.primaryAccent
                                          .withValues(alpha: 0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: MyColors.primaryAccent
                                        .withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.music_note,
                                  color: MyColors.primaryAccent,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: MyColors.primaryText,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (song.album != null) ...[
                                          Icon(
                                            Icons.album,
                                            size: 12,
                                            color: MyColors.secondaryText
                                                .withValues(alpha: 0.7),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              song.album!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: MyColors
                                                        .secondaryText
                                                        .withValues(
                                                            alpha: 0.7),
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Icon(
                                          Icons.access_time,
                                          size: 12,
                                          color: MyColors.secondaryText
                                              .withValues(alpha: 0.7),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDuration(song.durationAsTime),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: MyColors.secondaryText
                                                    .withValues(alpha: 0.7),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.play_arrow,
                                  color: MyColors.primaryAccent,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off,
              size: 64,
              color: MyColors.secondaryText,
            ),
            const SizedBox(height: 16),
            Text(
              searchController.text.isNotEmpty
                  ? 'No results found'
                  : 'No music found',
              style: TextStyle(
                color: MyColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchController.text.isNotEmpty
                  ? 'Try searching with different keywords'
                  : 'Make sure you have music files on your device',
              style: TextStyle(
                color: MyColors.secondaryText,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (searchController.text.isEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<LocalMusicProvider>().loadLocalSongs();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.primaryAccent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Refresh'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _playSong(
      LocalMusicProvider provider, LocalMusicModel song, int index) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const LocalMusicPlayerScreen(shouldStartPlaying: true),
      ),
    );
    await provider.playLocalTrack(song, index, context: context);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showSortOptions(BuildContext context) {
    final myMusicProvider = context.read<MyMusicProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: MyColors.secondaryBackground,
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.sort_by_alpha, color: MyColors.primaryText),
                title: Text('Sort by Title',
                    style: TextStyle(color: MyColors.primaryText)),
                trailing: myMusicProvider.sortCriteria == SortCriteria.title
                    ? Icon(
                        myMusicProvider.sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: MyColors.primaryAccent,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    myMusicProvider.setSort(SortCriteria.title);
                  });
                  context.read<LocalMusicProvider>().sortSongs(
                        myMusicProvider.sortCriteria,
                        ascending: myMusicProvider.sortAscending,
                      );
                },
              ),
              ListTile(
                leading: Icon(Icons.date_range, color: MyColors.primaryText),
                title: Text('Sort by Date Added',
                    style: TextStyle(color: MyColors.primaryText)),
                trailing:
                    myMusicProvider.sortCriteria == SortCriteria.dateAdded
                        ? Icon(
                            myMusicProvider.sortAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: MyColors.primaryAccent,
                          )
                        : null,
                onTap: () {
                  setState(() {
                    myMusicProvider.setSort(SortCriteria.dateAdded);
                  });
                  context.read<LocalMusicProvider>().sortSongs(
                        myMusicProvider.sortCriteria,
                        ascending: myMusicProvider.sortAscending,
                      );
                },
              ),
            ],
          );
        });
      },
    );
  }
}
