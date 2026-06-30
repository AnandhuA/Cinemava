class MarathonCollection {
  const MarathonCollection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.accentColor,
    required this.items,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final int accentColor;
  final List<MarathonItem> items;

  int get totalRuntimeMinutes {
    return items.fold(0, (total, item) => total + item.runtimeMinutes);
  }
}

class MarathonItem {
  const MarathonItem({
    required this.title,
    required this.year,
    required this.releaseDate,
    required this.runtimeMinutes,
    required this.note,
  });

  final String title;
  final String year;
  final String releaseDate;
  final int runtimeMinutes;
  final String note;
}

const marathonCollections = [
  MarathonCollection(
    id: 'marvel',
    title: 'Marvel Movie Marathon',
    subtitle: 'MCU release order',
    description:
        'A theatrical release order for Avengers, Guardians, Spider-Man, and the multiverse films.',
    accentColor: 0xFFE53935,
    items: [
      MarathonItem(
        title: 'Iron Man',
        year: '2008',
        releaseDate: 'May 2, 2008',
        runtimeMinutes: 126,
        note: 'Tony Stark begins the modern MCU.',
      ),
      MarathonItem(
        title: 'Iron Man 2',
        year: '2010',
        releaseDate: 'May 7, 2010',
        runtimeMinutes: 124,
        note: 'Adds Black Widow and War Machine.',
      ),
      MarathonItem(
        title: 'Thor',
        year: '2011',
        releaseDate: 'May 6, 2011',
        runtimeMinutes: 115,
        note: 'Introduces Asgard and Loki.',
      ),
      MarathonItem(
        title: 'Captain America: The First Avenger',
        year: '2011',
        releaseDate: 'July 22, 2011',
        runtimeMinutes: 124,
        note: 'Steve Rogers and the Tesseract arrive in release order.',
      ),
      MarathonItem(
        title: 'The Avengers',
        year: '2012',
        releaseDate: 'May 4, 2012',
        runtimeMinutes: 143,
        note: 'First big team-up.',
      ),
      MarathonItem(
        title: 'Guardians of the Galaxy',
        year: '2014',
        releaseDate: 'August 1, 2014',
        runtimeMinutes: 121,
        note: 'Cosmic side of the Infinity Saga.',
      ),
      MarathonItem(
        title: 'Avengers: Age of Ultron',
        year: '2015',
        releaseDate: 'May 1, 2015',
        runtimeMinutes: 141,
        note: 'Vision, Wanda, and the next fracture.',
      ),
      MarathonItem(
        title: 'Captain America: Civil War',
        year: '2016',
        releaseDate: 'May 6, 2016',
        runtimeMinutes: 147,
        note: 'Avengers split and Spider-Man enters.',
      ),
      MarathonItem(
        title: 'Black Panther',
        year: '2018',
        releaseDate: 'February 16, 2018',
        runtimeMinutes: 134,
        note: 'Wakanda before Infinity War.',
      ),
      MarathonItem(
        title: 'Avengers: Infinity War',
        year: '2018',
        releaseDate: 'April 27, 2018',
        runtimeMinutes: 149,
        note: 'Thanos completes the saga turn.',
      ),
      MarathonItem(
        title: 'Captain Marvel',
        year: '2019',
        releaseDate: 'March 8, 2019',
        runtimeMinutes: 124,
        note: 'Fury and cosmic Marvel history arrive before Endgame.',
      ),
      MarathonItem(
        title: 'Avengers: Endgame',
        year: '2019',
        releaseDate: 'April 26, 2019',
        runtimeMinutes: 181,
        note: 'Finish the Infinity Saga.',
      ),
      MarathonItem(
        title: 'Spider-Man: Far From Home',
        year: '2019',
        releaseDate: 'July 2, 2019',
        runtimeMinutes: 129,
        note: 'Aftermath of Endgame.',
      ),
      MarathonItem(
        title: 'Doctor Strange in the Multiverse of Madness',
        year: '2022',
        releaseDate: 'May 6, 2022',
        runtimeMinutes: 126,
        note: 'Lean into the multiverse era.',
      ),
    ],
  ),
  MarathonCollection(
    id: 'wizarding',
    title: 'Wizarding World',
    subtitle: 'Harry Potter and Fantastic Beasts',
    description:
        'A release-friendly order from Hogwarts discovery through the final battle.',
    accentColor: 0xFF5E35B1,
    items: [
      MarathonItem(
        title: 'Harry Potter and the Sorcerer\'s Stone',
        year: '2001',
        releaseDate: 'November 16, 2001',
        runtimeMinutes: 152,
        note: 'First year at Hogwarts.',
      ),
      MarathonItem(
        title: 'Harry Potter and the Chamber of Secrets',
        year: '2002',
        releaseDate: 'November 15, 2002',
        runtimeMinutes: 161,
        note: 'The mystery under the school.',
      ),
      MarathonItem(
        title: 'Harry Potter and the Prisoner of Azkaban',
        year: '2004',
        releaseDate: 'June 4, 2004',
        runtimeMinutes: 142,
        note: 'Sirius Black and the darker tone.',
      ),
      MarathonItem(
        title: 'Harry Potter and the Goblet of Fire',
        year: '2005',
        releaseDate: 'November 18, 2005',
        runtimeMinutes: 157,
        note: 'Triwizard Tournament and Voldemort returns.',
      ),
      MarathonItem(
        title: 'Harry Potter and the Order of the Phoenix',
        year: '2007',
        releaseDate: 'July 11, 2007',
        runtimeMinutes: 138,
        note: 'Dumbledore\'s Army rises.',
      ),
      MarathonItem(
        title: 'Harry Potter and the Half-Blood Prince',
        year: '2009',
        releaseDate: 'July 15, 2009',
        runtimeMinutes: 153,
        note: 'Secrets of Voldemort\'s past.',
      ),
      MarathonItem(
        title: 'Harry Potter and the Deathly Hallows: Part 1',
        year: '2010',
        releaseDate: 'November 19, 2010',
        runtimeMinutes: 146,
        note: 'The hunt begins.',
      ),
      MarathonItem(
        title: 'Harry Potter and the Deathly Hallows: Part 2',
        year: '2011',
        releaseDate: 'July 15, 2011',
        runtimeMinutes: 130,
        note: 'Battle of Hogwarts.',
      ),
    ],
  ),
  MarathonCollection(
    id: 'fast',
    title: 'Fast & Furious',
    subtitle: 'Family, cars, and chaos',
    description:
        'Release order for the main Fast saga, from street racing roots to global chaos.',
    accentColor: 0xFFFB8C00,
    items: [
      MarathonItem(
        title: 'The Fast and the Furious',
        year: '2001',
        releaseDate: 'June 22, 2001',
        runtimeMinutes: 106,
        note: 'Dom and Brian begin.',
      ),
      MarathonItem(
        title: '2 Fast 2 Furious',
        year: '2003',
        releaseDate: 'June 6, 2003',
        runtimeMinutes: 108,
        note: 'Brian in Miami.',
      ),
      MarathonItem(
        title: 'The Fast and the Furious: Tokyo Drift',
        year: '2006',
        releaseDate: 'June 16, 2006',
        runtimeMinutes: 104,
        note: 'Third theatrical release in the saga.',
      ),
      MarathonItem(
        title: 'Fast & Furious',
        year: '2009',
        releaseDate: 'April 3, 2009',
        runtimeMinutes: 107,
        note: 'The core crew returns.',
      ),
      MarathonItem(
        title: 'Fast Five',
        year: '2011',
        releaseDate: 'April 29, 2011',
        runtimeMinutes: 130,
        note: 'The heist era begins.',
      ),
      MarathonItem(
        title: 'Fast & Furious 6',
        year: '2013',
        releaseDate: 'May 24, 2013',
        runtimeMinutes: 130,
        note: 'The sixth theatrical release raises the scale.',
      ),
      MarathonItem(
        title: 'Furious 7',
        year: '2015',
        releaseDate: 'April 3, 2015',
        runtimeMinutes: 137,
        note: 'A major farewell chapter.',
      ),
      MarathonItem(
        title: 'The Fate of the Furious',
        year: '2017',
        releaseDate: 'April 14, 2017',
        runtimeMinutes: 136,
        note: 'Bigger global stakes.',
      ),
      MarathonItem(
        title: 'F9',
        year: '2021',
        releaseDate: 'June 25, 2021',
        runtimeMinutes: 143,
        note: 'Family history expands.',
      ),
      MarathonItem(
        title: 'Fast X',
        year: '2023',
        releaseDate: 'May 19, 2023',
        runtimeMinutes: 141,
        note: 'The latest main saga turn.',
      ),
    ],
  ),
  MarathonCollection(
    id: 'middle-earth',
    title: 'Middle-earth',
    subtitle: 'Lord of the Rings and Hobbit',
    description:
        'Release order from the original Lord of the Rings trilogy into The Hobbit films.',
    accentColor: 0xFF00897B,
    items: [
      MarathonItem(
        title: 'The Lord of the Rings: The Fellowship of the Ring',
        year: '2001',
        releaseDate: 'December 19, 2001',
        runtimeMinutes: 178,
        note: 'The fellowship forms.',
      ),
      MarathonItem(
        title: 'The Lord of the Rings: The Two Towers',
        year: '2002',
        releaseDate: 'December 18, 2002',
        runtimeMinutes: 179,
        note: 'War spreads across Middle-earth.',
      ),
      MarathonItem(
        title: 'The Lord of the Rings: The Return of the King',
        year: '2003',
        releaseDate: 'December 17, 2003',
        runtimeMinutes: 201,
        note: 'Finish at Mount Doom.',
      ),
      MarathonItem(
        title: 'The Hobbit: An Unexpected Journey',
        year: '2012',
        releaseDate: 'December 14, 2012',
        runtimeMinutes: 169,
        note: 'Return to Middle-earth with Bilbo.',
      ),
      MarathonItem(
        title: 'The Hobbit: The Desolation of Smaug',
        year: '2013',
        releaseDate: 'December 13, 2013',
        runtimeMinutes: 161,
        note: 'The dragon waits.',
      ),
      MarathonItem(
        title: 'The Hobbit: The Battle of the Five Armies',
        year: '2014',
        releaseDate: 'December 17, 2014',
        runtimeMinutes: 144,
        note: 'The prequel trilogy closes.',
      ),
    ],
  ),
  MarathonCollection(
    id: 'conjuring',
    title: 'The Conjuring Universe',
    subtitle: 'Horror release order',
    description: 'Release order for Annabelle, The Nun, and the Warrens cases.',
    accentColor: 0xFF546E7A,
    items: [
      MarathonItem(
        title: 'The Conjuring',
        year: '2013',
        releaseDate: 'July 19, 2013',
        runtimeMinutes: 112,
        note: 'Meet the Warrens.',
      ),
      MarathonItem(
        title: 'Annabelle',
        year: '2014',
        releaseDate: 'October 3, 2014',
        runtimeMinutes: 99,
        note: 'The curse spreads.',
      ),
      MarathonItem(
        title: 'The Conjuring 2',
        year: '2016',
        releaseDate: 'June 10, 2016',
        runtimeMinutes: 134,
        note: 'The Enfield case.',
      ),
      MarathonItem(
        title: 'Annabelle: Creation',
        year: '2017',
        releaseDate: 'August 11, 2017',
        runtimeMinutes: 109,
        note: 'The doll\'s origin arrives in release order.',
      ),
      MarathonItem(
        title: 'The Nun',
        year: '2018',
        releaseDate: 'September 7, 2018',
        runtimeMinutes: 96,
        note: 'Valak gets a theatrical chapter.',
      ),
      MarathonItem(
        title: 'Annabelle Comes Home',
        year: '2019',
        releaseDate: 'June 26, 2019',
        runtimeMinutes: 106,
        note: 'Inside the artifact room.',
      ),
      MarathonItem(
        title: 'The Conjuring: The Devil Made Me Do It',
        year: '2021',
        releaseDate: 'June 4, 2021',
        runtimeMinutes: 112,
        note: 'A later Warrens case.',
      ),
    ],
  ),
];

MarathonCollection? marathonById(String id) {
  for (final marathon in marathonCollections) {
    if (marathon.id == id) return marathon;
  }
  return null;
}
