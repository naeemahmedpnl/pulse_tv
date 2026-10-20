import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/channel.dart';
import 'channel_logo_resolver.dart';

class PlaylistService {
  /// Pakistan and India live IPTV streams (iptv-org open project).
  static const defaultSources = [
    'https://iptv-org.github.io/iptv/countries/pk.m3u',
    'https://iptv-org.github.io/iptv/countries/in.m3u',
  ];

  static const _cacheKey = 'cache_channels_pk_in_v6';

  Future<List<Channel>> fetchAll(List<String> sources) async {
    final bodies = await Future.wait(sources.map(_fetch));
    final unique = LinkedHashMap<String, Channel>();

    for (var i = 0; i < sources.length; i++) {
      final sourceUrl = sources[i];
      final body = bodies[i];
      final defaultCountry = sourceUrl.contains('/pk.m3u')
          ? 'PK'
          : sourceUrl.contains('/in.m3u')
              ? 'IN'
              : '';

      for (final c in parseM3U(body, defaultCountry: defaultCountry)) {
        // Filter: Keep HD channels (1080p, 720p, 4K, or marked HD)
        if (c.isHD) {
          unique.putIfAbsent(c.url, () => c);
        }
      }
    }

    final list = unique.values.toList();

    // Sort: Pakistan channels first, then India; channels with logos first, 1080p before 720p
    list.sort((a, b) {
      // 1. Group by country: PK first, then IN
      if (a.country != b.country) {
        if (a.country == 'PK') return -1;
        if (b.country == 'PK') return 1;
        if (a.country == 'IN') return -1;
        if (b.country == 'IN') return 1;
      }
      // 2. Channels with logos first
      if (a.logo.isNotEmpty && b.logo.isEmpty) return -1;
      if (a.logo.isEmpty && b.logo.isNotEmpty) return 1;

      // 3. 1080p before 720p
      final a1080 = a.quality.contains('1080') ? 1 : 0;
      final b1080 = b.quality.contains('1080') ? 1 : 0;
      if (a1080 != b1080) return b1080.compareTo(a1080);

      return a.name.compareTo(b.name);
    });

    return list;
  }

  Future<String> _fetch(String url) async {
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return '';
      return utf8.decode(res.bodyBytes, allowMalformed: true);
    } catch (_) {
      return '';
    }
  }

  Future<List<Channel>> loadCache(SharedPreferences prefs) async {
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Channel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCache(SharedPreferences prefs, List<Channel> list) =>
      prefs.setString(_cacheKey, jsonEncode(list.map((c) => c.toJson()).toList()));
}

/// Parses #EXTINF entries, including #EXTVLCOPT user-agent / referrer headers.
List<Channel> parseM3U(String content, {String defaultCountry = ''}) {
  final out = <Channel>[];
  String? info;
  final headers = <String, String>{};

  for (final raw in const LineSplitter().convert(content)) {
    final line = raw.trim();
    if (line.isEmpty) continue;

    if (line.startsWith('#EXTINF')) {
      info = line;
      headers.clear();
    } else if (line.startsWith('#EXTVLCOPT:')) {
      final opt = line.substring(11);
      if (opt.startsWith('http-user-agent=')) headers['User-Agent'] = opt.substring(16);
      if (opt.startsWith('http-referrer=')) headers['Referer'] = opt.substring(14);
    } else if (!line.startsWith('#') && info != null) {
      if (line.startsWith('http')) {
        out.add(_build(info, line, Map.of(headers), defaultCountry: defaultCountry));
      }
      info = null;
    }
  }
  return out;
}

Channel _build(String info, String url, Map<String, String> headers, {String defaultCountry = ''}) {
  String attr(String key) => RegExp('$key="([^"]*)"').firstMatch(info)?.group(1) ?? '';

  final lastQuote = info.lastIndexOf('"');
  final comma = info.indexOf(',', lastQuote < 0 ? 0 : lastQuote);
  var name = comma >= 0 ? info.substring(comma + 1).trim() : 'Unknown';

  // Pull quality tag (1080p, 720p, etc.)
  final qMatch = RegExp(r'\((\d{3,4}p)\)', caseSensitive: false).firstMatch(name) ??
                 RegExp(r'\((\d{3,4}p)\)', caseSensitive: false).firstMatch(info);
  var q = qMatch?.group(1) ?? '';

  final id = attr('tvg-id');
  final dot = id.split('@').first.lastIndexOf('.');
  var country = dot > 0 ? id.split('@').first.substring(dot + 1).toUpperCase() : '';

  if (country.isEmpty) {
    if (id.toLowerCase().contains('.pk') || url.contains('.pk')) {
      country = 'PK';
    } else if (id.toLowerCase().contains('.in') || url.contains('.in')) {
      country = 'IN';
    } else {
      country = defaultCountry;
    }
  }

  // Auto-detect HD if not explicitly in parenthesis
  if (q.isEmpty) {
    if (id.toUpperCase().endsWith('@HD') ||
        id.toUpperCase().contains('.HD') ||
        name.toUpperCase().contains(' HD') ||
        name.toUpperCase().endsWith('HD') ||
        info.toUpperCase().contains('RESOLUTION=1920X1080')) {
      q = '1080p';
    } else if (name.toUpperCase().contains('720P') || info.toUpperCase().contains('RESOLUTION=1280X720')) {
      q = '720p';
    } else {
      q = 'HD';
    }
  }

  // Clean name: remove quality parens and brackets
  name = name
      .replaceAll(RegExp(r'\s*\(\d{3,4}p\)', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s*\[[^\]]*\]'), '')
      .trim();

  var group = attr('group-title').split(';').first.trim();
  if (group.isEmpty || group.toLowerCase() == 'undefined') group = 'General';

  var logo = attr('tvg-logo').trim();

  final initial = Channel(
    id: id,
    name: name.isEmpty ? 'Unknown' : name,
    url: url,
    logo: logo,
    group: group,
    country: country,
    quality: q,
    headers: headers,
  );

  final resolvedLogo = ChannelLogoResolver.resolve(initial);
  if (resolvedLogo.isNotEmpty) {
    logo = resolvedLogo;
  }

  return Channel(
    id: id,
    name: name.isEmpty ? 'Unknown' : name,
    url: url,
    logo: logo,
    group: group,
    country: country,
    quality: q,
    headers: headers,
  );
}
