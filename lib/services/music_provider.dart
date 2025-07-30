import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:modizk_download/models/sound_cloud_search_response.dart';
import 'package:modizk_download/network/primary_storage_service.dart';
import 'package:modizk_download/services/music_service.dart';

class MusicProvider extends ChangeNotifier{
  final MusicService _musicService;

  MusicProvider(this._musicService);

  int tokenStatus = 0;
  String tokenError = '';

  Future<int> getUserToken() async {
    try {
      tokenStatus = 1;
      tokenError = '';
      notifyListeners();
      final response = await _musicService.getToken();
      if(response.statusCode! >= 200 || response.statusCode! < 300) {
        tokenStatus = 2;
        PrimaryStorageServices.setAccessToken(response.data);
      }else{
        tokenStatus = 3;
        tokenError = response.data;
      }
      log('response: ${response.data}');
    } catch(e){
      tokenStatus = 3;
      tokenError = e.toString();
    }
    notifyListeners();
    return tokenStatus;
  }

  int streamStatus = 0;
  String streamError = '';
  String? streamUrl = null;

  Future<int> getStreamUrl(String key) async {
    try {
      streamStatus = 1;
      streamError = '';
      notifyListeners();
      final response = await _musicService.getSoundCloudStream(key);
      if(response.statusCode! >= 200 || response.statusCode! < 300) {
        log("res stream: ${response.data}");
        streamUrl = response.data['url'];
        streamStatus = 2;
      }else{
        streamStatus = 3;
        streamError = response.data;
      }
    } catch(e){
      streamStatus = 3;
      streamError = e.toString();
    }
    notifyListeners();
    return streamStatus;
  }


  int songsStatus = 0;
  String songsError = '';
  SoundCloudSearchResponse? soundCloudResponse;

  Future<int> searchSong(String key) async {
    try {
      songsStatus = 1;
      songsError = '';
      soundCloudResponse = null;
      notifyListeners();
      final response = await _musicService.getSoundCloudSearchSongs(key);
      log('music res: ${response.data}');
      if(response.statusCode! >= 200 || response.statusCode! < 300) {
        soundCloudResponse = SoundCloudSearchResponse.fromJson(response.data);
        songsStatus = 2;
      }else{
        songsStatus = 3;
        songsError = response.data;
      }
      log('length: ${soundCloudResponse?.collection.length} \nresponse: ${response.data}');
    } catch(e){
      songsStatus = 3;
      songsError = e.toString();

      log('err1: ${e.toString()}');
    }
    notifyListeners();
    return songsStatus;
  }


  int songsLoadMoreStatus = 0;
  String songsLoadMoreError = '';
  SoundCloudSearchResponse? soundCloudLoadMoreResponse;

  Future<int> searchLoadMoreSong(String url) async {
    try {
      songsLoadMoreStatus = 1;
      songsLoadMoreError = '';
      soundCloudLoadMoreResponse = null;
      notifyListeners();
      final response = await _musicService.getSoundCloudSearchLoadMoreSongs(url);
      log('music res: ${response.data}');
      if(response.statusCode! >= 200 || response.statusCode! < 300) {
        soundCloudLoadMoreResponse = SoundCloudSearchResponse.fromJson(response.data);
        soundCloudResponse!.collection.addAll(soundCloudLoadMoreResponse!.collection);
        soundCloudResponse!.nextHref = soundCloudResponse!.nextHref;
        songsLoadMoreStatus = 2;
        notifyListeners();
      }else{
        songsLoadMoreStatus = 3;
        songsLoadMoreError = response.data;
      }
      log('length: ${soundCloudResponse?.collection.length} \nresponse: ${response.data}');
    } catch(e){
      songsLoadMoreStatus = 3;
      songsLoadMoreError = e.toString();

      log('err1: ${e.toString()}');
    }
    notifyListeners();
    return songsLoadMoreStatus;
  }

}