import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Service upload ảnh lên Cloudinary (chế độ unsigned).
/// Cấu hình: cloud_name: dh3q9ofsa, upload_preset: quanlyquanan.
/// Dùng [XFile] để tương thích Flutter Web (không dùng dart:io File).
class CloudinaryService {
  static const String _cloudName = 'dh3q9ofsa';
  static const String _uploadPreset = 'quanlyquanan';

  static final String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Upload ảnh từ [xFile] lên Cloudinary, trả về [secure_url] hoặc null nếu lỗi.
  /// Dùng [XFile] (từ image_picker) để chạy được trên cả Web và mobile.
  Future<String?> uploadImage(XFile xFile) async {
    try {
      final bytes = await xFile.readAsBytes();
      if (bytes.isEmpty) return null;

      final filename = xFile.name.isNotEmpty ? xFile.name : 'image.jpg';

      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['secure_url'] as String?;
    } catch (_) {
      return null;
    }
  }
}
