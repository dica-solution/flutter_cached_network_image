import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

/// A FileService for Flutter Cache Manager that implements
/// simple retry logic in the event that fetching fails due
/// to client errors, which typically occur with poor internet
/// connections.
///
/// Note that this service does not retry on certain HTTP error
/// codes, (400, 500, etc), but this would be trivial to extend.
class CaFileService extends FileService {
  CaFileService({
    /// Override the default HTTP client
    http.Client? httpClient,
    this.maxAttempts = 2,
  }) : _httpClient = httpClient ?? http.Client();

  /// The HTTP client to use. A Client will be automatically
  /// created if not set.
  final http.Client _httpClient;

  /// The maximum number of attempts before giving up
  /// on fetching the resource.
  final int maxAttempts;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,

    /// The current attempt
    int attemptNumber = 1,
  }) async {
    final req = http.Request('GET', Uri.parse(url));
    if (headers != null) {
      req.headers.addAll(headers);
    }

    try {
      final httpResponse = await _httpClient.send(req);
      return HttpGetResponse(httpResponse);
    } catch (err) {
      if (attemptNumber < maxAttempts) {
        // We use an increasing delay with each attempt.
        final delay = attemptNumber * 300;
        await Future.delayed(Duration(milliseconds: delay));

        // retry the fetch
        return get(url, headers: headers, attemptNumber: attemptNumber + 1);
      } else {
        // Reached the maximum number of retries, so giving up.
        rethrow;
      }
    }
  }
}
