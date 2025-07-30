import 'package:flutter/material.dart';
import 'package:modizk_download/network/dio_network_services.dart';
import 'package:modizk_download/screens/splash_screen.dart';
import 'package:modizk_download/services/music_provider.dart';
import 'package:modizk_download/services/music_service.dart';
import 'package:modizk_download/services/sound_cloud_audio_provider.dart';
import 'package:modizk_download/services/storage_service.dart';
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

class _MusicMp3DownloaderState extends State<MusicMp3Downloader> {

  @override
  void initState() {
    super.initState();
    initializeServices();
  }
  @override
  Widget build(BuildContext context) {

    final DioNetworkService dioNetworkService = DioNetworkService();
    final MusicService _musicService = MusicService(dioNetworkService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StorageService()),
        ChangeNotifierProvider(create: (_) => MusicProvider(_musicService)),
        ChangeNotifierProvider(create: (_) => SoundCloudAudioProvider()),
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
    await StorageService().init();
  }
}
