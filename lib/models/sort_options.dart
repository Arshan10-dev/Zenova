enum SongSortBy { title, artist, album, dateAdded, duration }

extension SongSortByLabel on SongSortBy {
  String get label => switch (this) {
        SongSortBy.title => 'Title',
        SongSortBy.artist => 'Artist',
        SongSortBy.album => 'Album',
        SongSortBy.dateAdded => 'Date Added',
        SongSortBy.duration => 'Duration',
      };
}
