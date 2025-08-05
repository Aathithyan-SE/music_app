
import 'package:dio/dio.dart';
import 'package:modizk_download/network/dio_network_services.dart';

class MusicService{
  final DioNetworkService _dioService;

  MusicService(this._dioService);

  Future<Response> getToken() async {
    try {
      return _dioService.getToken();
    } catch (e) {
      rethrow;
    }
  }
  Future<Response> getSearchSongs(String key) async {
    try {
      return _dioService.get('/search/tracks?q=$key');
    } catch (e) {
      rethrow;
    }
  }
  Future<Response> getSoundCloudSearchSongs(String key) async {
    try {
      return _dioService.getSoundCloud('/search/tracks?q=$key&downloadable=true&streamable=true&limit=30');
    } catch (e) {
      rethrow;
    }
  }


  Future<Response> getSoundCloudSearchLoadMoreSongs(String url) async {
    try {
      String suffix = url.replaceAll('https://api-v2.soundcloud.com', '');
      return _dioService.getSoundCloud(suffix);
    } catch (e) {
      rethrow;
    }
  }


  Future<Response> getSoundCloudStream(String streamUrl) async {
    try {
      String suffix = streamUrl.replaceAll('https://api-v2.soundcloud.com', '');
      return _dioService.getSoundCloud(suffix);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getDownloadableTrack(String transcodingUrl) async {
    try {
      return _dioService.get('/play/track?link=$transcodingUrl');
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getSoundCloudTrackById(int trackId) async {
    try {
      return _dioService.getSoundCloudTrackById(trackId);
    } catch (e) {
      rethrow;
    }
  }

}