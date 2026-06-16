import 'football_api_client.dart';

/// Turns any thrown error into a short, friendly sentence for the UI — so users
/// never see a raw `FootballApiException(...)` or `SocketException`. The free
/// tier's 10 req/min limit means 429s are expected, so they get clear guidance.
String friendlyError(Object error) {
  if (error is FootballApiException) {
    switch (error.statusCode) {
      case 429:
        return 'Too many requests. The free plan allows 10 per minute — '
            'please wait a moment, then pull down to refresh.';
      case 401:
      case 403:
        return 'This data isn’t available on the current API plan.';
      case 404:
        return 'We couldn’t find this data.';
      default:
        return error.message;
    }
  }

  final text = error.toString();
  if (text.contains('SocketException') ||
      text.contains('Failed host lookup') ||
      text.contains('ClientException') ||
      text.contains('Connection')) {
    return 'No internet connection. Check your network and try again.';
  }

  return 'Something went wrong. Please try again.';
}
