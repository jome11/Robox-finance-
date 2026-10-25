import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../auth/auth_session.dart';

class ImageUploadException implements Exception {
  final String message;
  ImageUploadException(this.message);

  @override
  String toString() => message;
}

class ImageApiService {
  /// Photos are stored in transactions as references like "img:abc123".
  static const String prefix = 'img:';

  static bool isRemote(String ref) => ref.startsWith(prefix);

  static String urlFor(String ref) =>
      '${ApiConstants.baseUrl}${ApiConstants.imagesEndpoint}/${ref.substring(prefix.length)}';

  static Map<String, String> get authHeaders => {
        if (AuthSession.token != null)
          'Authorization': 'Bearer ${AuthSession.token}',
      };

  /// Uploads the image and returns its reference.
  static Future<String> upload(Uint8List bytes, {String mime = 'image/jpeg'}) async {
    final http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.imagesEndpoint}'),
            headers: {'Content-Type': 'application/json', ...authHeaders},
            body: jsonEncode({'mime': mime, 'data': base64Encode(bytes)}),
          )
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      throw ImageUploadException('Cannot reach the server. Check your connection.');
    }

    if (res.statusCode == 401) AuthSession.onUnauthorized?.call();
    if (res.statusCode == 200 || res.statusCode == 201) {
      return '$prefix${jsonDecode(res.body)['id']}';
    }

    var message = 'Upload failed (${res.statusCode})';
    try {
      final detail = jsonDecode(res.body)['detail'];
      if (detail is String) message = detail;
    } catch (_) {}
    throw ImageUploadException(message);
  }
}
