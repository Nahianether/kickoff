import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Thrown when the football-data.org API returns a non-success response.
class FootballApiException implements Exception {
  final int statusCode;
  final String message;
  const FootballApiException(this.statusCode, this.message);

  @override
  String toString() => 'FootballApiException($statusCode): $message';
}

/// Thin wrapper around the football-data.org v4 REST API.
class FootballApiClient {
  FootballApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> get _headers => {
        'X-Auth-Token': ApiConfig.apiKey,
      };

  /// GET /competitions/{code}/matches
  Future<Map<String, dynamic>> getCompetitionMatches(String competitionCode) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/competitions/$competitionCode/matches');
    final response = await _client.get(uri, headers: _headers);

    // football-data.org throttles the free tier (10 req/min). On 429 it returns
    // how many seconds remain until the window resets.
    if (response.statusCode == 429) {
      final reset = response.headers['x-requestcounter-reset'];
      final wait = reset != null ? ' Try again in ${reset}s.' : '';
      throw FootballApiException(429, 'Rate limit reached.$wait');
    }

    if (response.statusCode != 200) {
      throw FootballApiException(
        response.statusCode,
        _extractError(response.body),
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _extractError(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return (decoded['message'] ?? decoded['error'] ?? body).toString();
    } catch (_) {
      return body;
    }
  }

  void dispose() => _client.close();
}
