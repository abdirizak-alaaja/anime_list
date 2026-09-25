/// The curated lists shown on the Discover screen.
enum DiscoverySection {
  thisSeason('This Season', 'Everything airing this season'),
  upcoming('Upcoming', 'Coming next season'),
  popular('Most Popular', 'The most-watched anime of all time'),
  topRated('All-Time Top', 'Highest-scored anime on MyAnimeList');

  const DiscoverySection(this.title, this.description);

  final String title;
  final String description;
}
