//  沒有拿來用，

class PlayList {
  static PlayList? _instance;

  PlayList._internal() {
    _instance = this;
  }

  factory PlayList() => _instance ?? PlayList._internal();
}

// final playlist = PlayList();