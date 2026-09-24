import 'library_entry.dart';

/// Orderings offered on the My List screen.
enum LibrarySort {
  recentlyUpdated('Recently updated'),
  title('Title'),
  score('Score'),
  progress('Progress');

  const LibrarySort(this.label);

  final String label;

  List<LibraryEntry> apply(List<LibraryEntry> entries) {
    final sorted = [...entries];
    switch (this) {
      case recentlyUpdated:
        sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case title:
        sorted.sort(
          (a, b) => a.anime.title.toLowerCase().compareTo(
            b.anime.title.toLowerCase(),
          ),
        );
      case score:
        sorted.sort(
          (a, b) => (b.anime.score ?? -1).compareTo(a.anime.score ?? -1),
        );
      case progress:
        sorted.sort((a, b) => (b.progress ?? -1).compareTo(a.progress ?? -1));
    }
    return sorted;
  }
}
