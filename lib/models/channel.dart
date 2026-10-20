class Channel {
  final String id;
  final String name;
  final String url;
  final String logo;
  final String group;
  final String country;
  final String quality;
  final Map<String, String> headers;

  const Channel({
    required this.name,
    required this.url,
    this.id = '',
    this.logo = '',
    this.group = 'Other',
    this.country = '',
    this.quality = '',
    this.headers = const {},
  });

  bool get isHD {
    final lq = ['576p', '480p', '360p', '240p', '540p', '614p'];
    for (final tag in lq) {
      if (quality.toLowerCase().contains(tag) || name.toLowerCase().contains(tag)) {
        return false;
      }
    }
    return quality.contains('1080') ||
        quality.contains('720') ||
        quality.contains('4K') ||
        quality.toUpperCase().contains('HD') ||
        name.toUpperCase().contains('HD') ||
        id.toUpperCase().contains('@HD');
  }

  String get displayQuality {
    if (quality.contains('1080')) return '1080p';
    if (quality.contains('720')) return '720p';
    if (quality.contains('4K')) return '4K';
    if (isHD) return 'HD';
    return quality.isNotEmpty ? quality : 'HD';
  }

  String get countryFlag {
    if (country == 'PK') return '🇵🇰 PK';
    if (country == 'IN') return '🇮🇳 IN';
    return country;
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'n': name,
        'u': url,
        'l': logo,
        'g': group,
        'c': country,
        'q': quality,
        'h': headers,
      };

  factory Channel.fromJson(Map<String, dynamic> j) => Channel(
        id: j['id'] ?? '',
        name: j['n'] ?? '',
        url: j['u'] ?? '',
        logo: j['l'] ?? '',
        group: j['g'] ?? 'Other',
        country: j['c'] ?? '',
        quality: j['q'] ?? '',
        headers: Map<String, String>.from(j['h'] ?? const {}),
      );
}
