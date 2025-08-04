import 'package:flutter/material.dart';
import 'package:modizk_download/services/local_music_provider.dart';
import 'package:modizk_download/services/local_music_service.dart';

enum MyMusicTab { songs, downloads }

class MyMusicProvider with ChangeNotifier {
  MyMusicTab _currentTab = MyMusicTab.songs;
  SortCriteria _sortCriteria = SortCriteria.title;
  bool _sortAscending = true;

  MyMusicTab get currentTab => _currentTab;
  SortCriteria get sortCriteria => _sortCriteria;
  bool get sortAscending => _sortAscending;

  void setTab(MyMusicTab tab) {
    _currentTab = tab;
    notifyListeners();
  }

  void setSort(SortCriteria criteria) {
    if (_sortCriteria == criteria) {
      _sortAscending = !_sortAscending;
    } else {
      _sortCriteria = criteria;
      _sortAscending = true;
    }
    notifyListeners();
  }
}
