import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:modizk_download/network/primary_storage_service.dart';

String apiHost = 'http://31.170.165.102:5000';
String apiSoundHost = 'https://api-v2.soundcloud.com';

class DioNetworkService{
  var dio = Dio()
    ..options.baseUrl = '${apiHost}'
    ..options.connectTimeout = Duration(seconds: 10)
    ..options.receiveTimeout = Duration(seconds: 30);

  var soundCloudDio = Dio()
    ..options.baseUrl = '${apiSoundHost}'
    ..options.connectTimeout = Duration(seconds: 10)
    ..options.receiveTimeout = Duration(seconds: 30);

  setTokenHeaders() async {
    String? token = await PrimaryStorageServices.getAccessToken();

    if (token != null) {
      dio.options.headers['auth'] = 'OAuth $token';
    }
  }

  setSoundTokenHeaders() async {
    String? token = await PrimaryStorageServices.getAccessToken();

    if (token != null) {
      soundCloudDio.options.headers['Authorization'] = 'OAuth $token';
    }
  }


  setGetTokenHeaders() async {
    dio.options.headers['client_id'] = 'dbdsA8b6V6Lw7wzu1x0T4CLxt58yd4Bf';
    dio.options.headers['client_secret'] = 'aBK1xbehZvrBw0dtVYNY3BuJJOuDFrYs';
  }


  Future<Response> get(String url) async {
    await setTokenHeaders();
    try{
      log("raw called: ${url}");
      Response response = await dio.get(url);
      if(response.statusCode == 401){
        await getToken();
        return get(url);
      }
      return response;
    }on DioException catch (e) {
      log("error: ${e.response}");
      throw e;
    }catch (e) {
      log("error: ${e}");
      rethrow;
    }
  }


  Future<Response> getSoundCloud(String url) async {
    await setSoundTokenHeaders();
    try{
      log("raw called: ${url}");
      Response response = await soundCloudDio.get(url);
      if(response.statusCode == 401){
        await getToken();
        return getSoundCloud(url);
      }
      return response;
    }on DioException catch (e) {
      log("error: ${e.message}");
      throw e;
    }catch (e) {
      log("error: ${e}");
      rethrow;
    }
  }


  Future<Response> getToken() async {
    await setGetTokenHeaders();
    try{
      Response response = await dio.get('/token');
      return response;
    }on DioException catch (e) {
      throw e;
    }catch (e) {
      rethrow;
    }
  }

  Future<Response> getSoundCloudTrackById(int trackId) async {
    await setSoundTokenHeaders();
    try{
      log("raw called: /tracks/$trackId");
      Response response = await soundCloudDio.get('/tracks/$trackId');
      if(response.statusCode == 401){
        await getToken();
        return getSoundCloudTrackById(trackId);
      }
      return response;
    }on DioException catch (e) {
      log("error: ${e.message}");
      throw e;
    }catch (e) {
      log("error: ${e}");
      rethrow;
    }
  }


}


