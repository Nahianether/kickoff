import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import '../../data/models/team.dart';

/// Shows a team's crest/flag from the network. football-data.org serves most
/// national-team crests as SVG and some as PNG, so we handle both, falling back
/// to the 3-letter country code when there's no image or it fails to load.
class TeamCrest extends StatelessWidget {
  const TeamCrest({super.key, required this.team, this.size = 40});

  final Team team;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = team.crestUrl;
    Widget image;
    if (url == null || url.isEmpty) {
      image = _fallback(context);
    } else if (url.toLowerCase().endsWith('.svg')) {
      // Key by url so a recycled list cell loading a different team forces a
      // fresh State (otherwise the previous team's flag would stick).
      image = _NetworkSvgCrest(
        key: ValueKey(url),
        url: url,
        size: size,
        fallback: _fallback(context),
      );
    } else {
      image = Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _fallback(context),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.12),
      child: SizedBox(width: size, height: size, child: image),
    );
  }

  Widget _fallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Text(
        team.code,
        style: TextStyle(
          fontSize: size * 0.3,
          fontWeight: FontWeight.bold,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Loads an SVG crest by fetching its bytes with our own HTTP call so transient
/// network failures are caught (instead of throwing, as SvgPicture.network
/// does). Results — including failures — are cached for the session.
class _NetworkSvgCrest extends StatefulWidget {
  const _NetworkSvgCrest({
    super.key,
    required this.url,
    required this.size,
    required this.fallback,
  });

  final String url;
  final double size;
  final Widget fallback;

  /// url -> bytes (null means a previous load failed; don't retry this session).
  static final Map<String, Uint8List?> _cache = {};

  @override
  State<_NetworkSvgCrest> createState() => _NetworkSvgCrestState();
}

class _NetworkSvgCrestState extends State<_NetworkSvgCrest> {
  late final Future<Uint8List?> _future = _load(widget.url);

  Future<Uint8List?> _load(String url) async {
    if (_NetworkSvgCrest._cache.containsKey(url)) {
      return _NetworkSvgCrest._cache[url];
    }
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        _NetworkSvgCrest._cache[url] = res.bodyBytes;
        return res.bodyBytes;
      }
    } catch (_) {
      // Swallow transient network errors and fall back to the code chip.
    }
    _NetworkSvgCrest._cache[url] = null;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done || bytes == null) {
          return widget.fallback;
        }
        return SvgPicture.memory(
          bytes,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => widget.fallback,
        );
      },
    );
  }
}
