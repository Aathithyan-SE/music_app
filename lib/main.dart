import 'package:flutter/material.dart';
import 'package:modizk_download/network/dio_network_services.dart';
import 'package:modizk_download/screens/splash_screen.dart';
import 'package:modizk_download/services/local_music_provider.dart';
import 'package:modizk_download/services/music_provider.dart';
import 'package:modizk_download/services/music_service.dart';
import 'package:modizk_download/services/sound_cloud_audio_provider.dart';
import 'package:modizk_download/services/storage_service.dart';
import 'package:modizk_download/services/native_media_notification_service.dart';
import 'package:modizk_download/services/playlist_service.dart';
import 'package:modizk_download/services/download_service.dart';
import 'package:modizk_download/services/my_music_provider.dart';
import 'package:modizk_download/services/admob_service.dart';
import 'package:provider/provider.dart';
import 'package:modizk_download/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MusicMp3Downloader());
}

class MusicMp3Downloader extends StatefulWidget {
  const MusicMp3Downloader({super.key});



  @override
  State<MusicMp3Downloader> createState() => _MusicMp3DownloaderState();
}

class _MusicMp3DownloaderState extends State<MusicMp3Downloader> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    initializeServices();
  }

  @override
  void dispose() {
    // Remove lifecycle observer and cleanup notification service
    WidgetsBinding.instance.removeObserver(this);
    _cleanupServices();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('🎵 App lifecycle state changed to: $state');
    
    switch (state) {
      case AppLifecycleState.detached:
        // App is being terminated - cleanup notification
        print('🎵 App being terminated - cleaning up notification service');
        _cleanupServices();
        break;
      case AppLifecycleState.paused:
        // App is in background
        print('🎵 App moved to background');
        break;
      case AppLifecycleState.resumed:
        // App is back in foreground
        print('🎵 App resumed from background');
        break;
      case AppLifecycleState.inactive:
        // App is inactive
        print('🎵 App became inactive');
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        print('🎵 App is hidden');
        break;
    }
  }
  @override
  Widget build(BuildContext context) {

    final DioNetworkService dioNetworkService = DioNetworkService();
    final MusicService _musicService = MusicService(dioNetworkService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StorageService()),
        ChangeNotifierProvider(create: (_) => PlaylistService()),
        ChangeNotifierProvider(create: (_) => DownloadService()),
        ChangeNotifierProvider(create: (_) => MusicProvider(_musicService)),
        ChangeNotifierProvider(create: (_) => SoundCloudAudioProvider()),
        ChangeNotifierProvider(create: (_) => LocalMusicProvider()),
        ChangeNotifierProvider(create: (_) => MyMusicProvider()),
      ],
      child: MaterialApp(
        title: 'Music Mp3 Downloader',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: SplashScreen()
      ),
    );
  }

  static Future<void> initializeServices() async {
    print('🔧 Starting service initialization...');
    
    try {
      await StorageService().init();
      print('✅ StorageService initialized');
    } catch (e) {
      print('❌ StorageService failed: $e');
    }
    
    try {
      await PlaylistService().init();
      print('✅ PlaylistService initialized');
    } catch (e) {
      print('❌ PlaylistService failed: $e');
    }
    
    try {
      await DownloadService().init();
      print('✅ DownloadService initialized');
    } catch (e) {
      print('❌ DownloadService failed: $e');
    }
    
    // Initialize AdMob
    try {
      await AdMobService.initialize();
      print('✅ AdMobService initialized');
    } catch (e) {
      print('❌ AdMobService failed: $e');
    }
    
    // Initialize media notification service with detailed logging
    try {
      print('🎵 Attempting to initialize MediaNotificationService...');
      print('🎵 Before calling initialize()');
      await MediaNotificationService.instance.initialize();
      print('✅ MediaNotificationService initialized successfully');
      print('🎵 Service isInitialized: ${MediaNotificationService.instance.isInitialized}');
    } catch (e, stackTrace) {
      print('❌ Failed to initialize notification service: $e');
      print('❌ Stack trace: $stackTrace');
      print('❌ Error type: ${e.runtimeType}');
    }
    
    print('🔧 Service initialization completed');
  }

  static Future<void> _cleanupServices() async {
    print('🔧 Starting service cleanup...');
    
    try {
      // Cleanup notification service
      await NativeMediaNotificationService.instance.dispose();
      print('✅ NativeMediaNotificationService cleaned up');
    } catch (e) {
      print('❌ Failed to cleanup notification service: $e');
    }
    
    print('🔧 Service cleanup completed');
  }
}
