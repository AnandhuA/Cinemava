class MarathonCollection {
  const MarathonCollection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.accentColor,
    required this.collectionQueries,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final int accentColor;
  final List<String> collectionQueries;
}

const marathonCollections = [
  MarathonCollection(
    id: 'marvel',
    title: 'Marvel Movie Marathon',
    subtitle: 'MCU series from TMDb collections',
    description:
        'Builds a release-order marathon from Marvel franchise collections on TMDb.',
    accentColor: 0xFFE53935,
    collectionQueries: [
      'Iron Man Collection',
      'Thor Collection',
      'Captain America Collection',
      'The Avengers Collection',
      'Guardians of the Galaxy Collection',
      'Black Panther Collection',
      'Doctor Strange Collection',
      'Captain Marvel Collection',
      'Ant-Man Collection',
      'Spider-Man Homecoming Collection',
    ],
  ),
  MarathonCollection(
    id: 'wizarding',
    title: 'Wizarding World',
    subtitle: 'Harry Potter and Fantastic Beasts',
    description:
        'Loads Harry Potter and Fantastic Beasts movies from TMDb collections.',
    accentColor: 0xFF5E35B1,
    collectionQueries: [
      'Harry Potter Collection',
      'Fantastic Beasts Collection',
    ],
  ),
  MarathonCollection(
    id: 'fast',
    title: 'Fast & Furious',
    subtitle: 'Main saga and spin-offs',
    description:
        'Loads the Fast & Furious movie series from TMDb collection data.',
    accentColor: 0xFFFB8C00,
    collectionQueries: [
      'The Fast and the Furious Collection',
      'Hobbs & Shaw Collection',
    ],
  ),
  MarathonCollection(
    id: 'middle-earth',
    title: 'Middle-earth',
    subtitle: 'Lord of the Rings and Hobbit',
    description: 'Loads Tolkien movie series from TMDb collections.',
    accentColor: 0xFF00897B,
    collectionQueries: [
      'The Lord of the Rings Collection',
      'The Hobbit Collection',
    ],
  ),
  MarathonCollection(
    id: 'conjuring',
    title: 'The Conjuring Universe',
    subtitle: 'Conjuring, Annabelle, and The Nun',
    description: 'Loads the horror universe from TMDb collection data.',
    accentColor: 0xFF546E7A,
    collectionQueries: [
      'The Conjuring Collection',
      'Annabelle Collection',
      'The Nun Collection',
    ],
  ),
  MarathonCollection(
    id: 'john-wick',
    title: 'John Wick',
    subtitle: 'Baba Yaga saga',
    description: 'Loads the John Wick movies from TMDb collections.',
    accentColor: 0xFF1565C0,
    collectionQueries: ['John Wick Collection'],
  ),
  MarathonCollection(
    id: 'jurassic',
    title: 'Jurassic Park & World',
    subtitle: 'Dinosaur series',
    description: 'Loads Jurassic Park and Jurassic World movies from TMDb.',
    accentColor: 0xFF2E7D32,
    collectionQueries: [
      'Jurassic Park Collection',
      'Jurassic World Collection',
    ],
  ),
  MarathonCollection(
    id: 'mission-impossible',
    title: 'Mission: Impossible',
    subtitle: 'Ethan Hunt missions',
    description: 'Loads the Mission: Impossible series from TMDb.',
    accentColor: 0xFF37474F,
    collectionQueries: ['Mission: Impossible Collection'],
  ),
  MarathonCollection(
    id: 'star-wars',
    title: 'Star Wars',
    subtitle: 'Skywalker saga and stories',
    description: 'Loads Star Wars movie collections from TMDb.',
    accentColor: 0xFFFDD835,
    collectionQueries: [
      'Star Wars Collection',
      'Star Wars: The Ewok Adventures Collection',
    ],
  ),
];

MarathonCollection? marathonById(String id) {
  for (final marathon in marathonCollections) {
    if (marathon.id == id) return marathon;
  }
  return null;
}
