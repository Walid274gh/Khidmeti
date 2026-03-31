// lib/services/cloudinary_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloudinary/cloudinary.dart';
import 'package:path/path.dart' as path;

class CloudinaryServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  CloudinaryServiceException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() =>
      'CloudinaryServiceException: $message${code != null ? ' (Code: $code)' : ''}';
}

class CloudinaryService {
  static const int maxImageSizeMB = 10;
  static const int maxVideoSizeMB = 100;
  static const int maxAudioSizeMB = 50;
  static const Duration uploadTimeout = Duration(minutes: 5);
  static const int defaultImageQuality = 80;
  static const int defaultImageMaxWidth = 1920;
  static const int defaultImageMaxHeight = 1080;

  final String cloudName;
  final String uploadPreset;

  // FIX (Security P0): apiKey and apiSecret have been removed from this class.
  // Embedding the Cloudinary apiSecret in a mobile client exposes full account
  // access to anyone who decompiles the APK or IPA — this is a critical
  // credential leak. Uploads are now authenticated exclusively via the
  // upload_preset configured in the Cloudinary dashboard (unsigned preset).
  //
  // Migration notes for callers:
  //   • Remove apiKey and apiSecret from constructor calls.
  //   • Create an unsigned upload preset in Cloudinary Dashboard →
  //     Settings → Upload → Add upload preset → Mode: Unsigned.
  //   • File deletion (deleteFile) must be performed server-side via a
  //     Cloud Function or backend endpoint — it is no longer available
  //     from the mobile client. See deleteFile() for details.

  late final Cloudinary _cloudinary;

  CloudinaryService({
    required this.cloudName,
    required this.uploadPreset,
  }) {
    _validateCredentials();
    _initializeCloudinary();
  }

  void _validateCredentials() {
    if (cloudName.trim().isEmpty) {
      throw CloudinaryServiceException(
        'Cloud name cannot be empty',
        code: 'INVALID_CREDENTIALS',
      );
    }
    if (uploadPreset.trim().isEmpty) {
      throw CloudinaryServiceException(
        'Upload preset cannot be empty',
        code: 'INVALID_CREDENTIALS',
      );
    }
  }

  void _initializeCloudinary() {
    // Use unsigned config: the mobile client never holds the apiSecret.
    _cloudinary = Cloudinary.unsignedConfig(cloudName: cloudName);
    _logInfo('Cloudinary initialized (unsigned) for cloud: $cloudName');
  }

  Future<String> uploadFile(
    File file, {
    CloudinaryResourceType resourceType = CloudinaryResourceType.auto,
    String? folder,
    Map<String, dynamic>? transformations,
  }) async {
    try {
      await _validateFile(file, resourceType);

      final fileName = _generateFileName(file);
      final uploadFolder = folder ?? _getDefaultFolder(resourceType);

      _logInfo('Uploading file: $fileName to folder: $uploadFolder');

      final response = await _cloudinary
          .upload(
            file: file.path,
            resourceType: resourceType,
            folder: uploadFolder,
            fileName: fileName,
            optParams: {
              'upload_preset': uploadPreset,
              if (transformations != null) ...transformations,
            },
          )
          .timeout(
            uploadTimeout,
            onTimeout: () => throw CloudinaryServiceException(
              'Upload timeout after ${uploadTimeout.inMinutes} minutes',
              code: 'UPLOAD_TIMEOUT',
            ),
          );

      if (response.isSuccessful && response.secureUrl != null) {
        _logInfo('Upload successful: ${response.secureUrl}');
        return response.secureUrl!;
      }

      throw CloudinaryServiceException(
        'Upload failed: ${response.error ?? "Unknown error"}',
        code: 'UPLOAD_FAILED',
        originalError: response.error,
      );
    } catch (e) {
      _logError('uploadFile', e);
      if (e is CloudinaryServiceException) rethrow;
      throw CloudinaryServiceException(
        'Error uploading file to Cloudinary',
        code: 'UPLOAD_ERROR',
        originalError: e,
      );
    }
  }

  Future<String> uploadImage(
    File file, {
    String? folder,
    int? maxWidth,
    int? maxHeight,
    int? quality,
  }) async {
    final transformations = <String, dynamic>{
      'quality': quality ?? defaultImageQuality,
      'fetch_format': 'auto',
    };

    if (maxWidth != null || maxHeight != null) {
      transformations['transformation'] = [
        {
          'width': maxWidth ?? defaultImageMaxWidth,
          'height': maxHeight ?? defaultImageMaxHeight,
          'crop': 'limit',
        }
      ];
    }

    return uploadFile(
      file,
      resourceType: CloudinaryResourceType.image,
      folder: folder ?? 'images',
      transformations: transformations,
    );
  }

  Future<String> uploadVideo(
    File file, {
    String? folder,
    int? maxDurationSeconds,
  }) async {
    final transformations = <String, dynamic>{
      'resource_type': 'video',
      'format': 'mp4',
    };

    if (maxDurationSeconds != null) {
      transformations['duration'] = maxDurationSeconds;
    }

    return uploadFile(
      file,
      resourceType: CloudinaryResourceType.video,
      folder: folder ?? 'videos',
      transformations: transformations,
    );
  }

  Future<String> uploadAudio(
    File file, {
    String? folder,
  }) async {
    return uploadFile(
      file,
      resourceType: CloudinaryResourceType.auto,
      folder: folder ?? 'audios',
    );
  }

  // FIX (Security P0): File deletion requires signed authentication and must
  // be performed server-side. Call your backend endpoint or Cloud Function
  // that holds the apiKey + apiSecret securely.
  // This method returns false and logs a warning — it does NOT throw so that
  // upload pipelines that call deleteFile on cleanup do not crash.
  Future<bool> deleteFile(String publicId) async {
    if (publicId.trim().isEmpty) {
      throw CloudinaryServiceException(
        'Public ID cannot be empty',
        code: 'INVALID_PUBLIC_ID',
      );
    }

    _logWarning(
      'deleteFile: server-side only — call your Cloud Function or backend '
      'endpoint to delete "$publicId". Client-side deletion is not supported '
      'with unsigned Cloudinary configuration.',
    );
    return false;
  }

  String getOptimizedImageUrl(
    String publicId, {
    int? width,
    int? height,
    String crop = 'fill',
    int quality = 80,
    String format = 'auto',
  }) {
    if (publicId.trim().isEmpty) {
      throw CloudinaryServiceException(
        'Public ID cannot be empty',
        code: 'INVALID_PUBLIC_ID',
      );
    }

    final transformations = <String>[];

    if (width != null || height != null) {
      final w = width != null ? 'w_$width' : '';
      final h = height != null ? 'h_$height' : '';
      final c = 'c_$crop';
      transformations.add([w, h, c].where((s) => s.isNotEmpty).join(','));
    }

    transformations.add('q_$quality');
    transformations.add('f_$format');

    final transformationString = transformations.join('/');
    return 'https://res.cloudinary.com/$cloudName/image/upload/$transformationString/$publicId';
  }

  String getVideoUrl(
    String publicId, {
    int? width,
    int? height,
    String format = 'mp4',
  }) {
    if (publicId.trim().isEmpty) {
      throw CloudinaryServiceException(
        'Public ID cannot be empty',
        code: 'INVALID_PUBLIC_ID',
      );
    }

    final transformations = <String>[];

    if (width != null || height != null) {
      final w = width != null ? 'w_$width' : '';
      final h = height != null ? 'h_$height' : '';
      const c = 'c_fit';
      transformations.add([w, h, c].where((s) => s.isNotEmpty).join(','));
    }

    final transformationString = transformations.isEmpty
        ? ''
        : '${transformations.join('/')}/';

    return 'https://res.cloudinary.com/$cloudName/video/upload/$transformationString$publicId.$format';
  }

  Future<void> _validateFile(
    File file,
    CloudinaryResourceType resourceType,
  ) async {
    if (!await file.exists()) {
      throw CloudinaryServiceException(
        'File does not exist: ${file.path}',
        code: 'FILE_NOT_FOUND',
      );
    }

    final fileSize = await file.length();
    final fileSizeMB = fileSize / (1024 * 1024);

    int maxSizeMB;
    String fileType;

    switch (resourceType) {
      case CloudinaryResourceType.image:
        maxSizeMB = maxImageSizeMB;
        fileType = 'Image';
        break;
      case CloudinaryResourceType.video:
        maxSizeMB = maxVideoSizeMB;
        fileType = 'Video';
        break;
      case CloudinaryResourceType.auto:
        final extension = path.extension(file.path).toLowerCase();
        if (_isImageExtension(extension)) {
          maxSizeMB = maxImageSizeMB;
          fileType = 'Image';
        } else if (_isVideoExtension(extension)) {
          maxSizeMB = maxVideoSizeMB;
          fileType = 'Video';
        } else if (_isAudioExtension(extension)) {
          maxSizeMB = maxAudioSizeMB;
          fileType = 'Audio';
        } else {
          maxSizeMB = maxImageSizeMB;
          fileType = 'File';
        }
        break;
      default:
        maxSizeMB = maxImageSizeMB;
        fileType = 'File';
    }

    if (fileSizeMB > maxSizeMB) {
      throw CloudinaryServiceException(
        '$fileType file too large: ${fileSizeMB.toStringAsFixed(2)}MB (max: ${maxSizeMB}MB)',
        code: 'FILE_TOO_LARGE',
      );
    }

    if (fileSize == 0) {
      throw CloudinaryServiceException(
        'File is empty',
        code: 'EMPTY_FILE',
      );
    }
  }

  String _generateFileName(File file) {
    final originalName = path.basenameWithoutExtension(file.path);
    final extension = path.extension(file.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${originalName}_$timestamp$extension';
  }

  String _getDefaultFolder(CloudinaryResourceType resourceType) {
    switch (resourceType) {
      case CloudinaryResourceType.image:
        return 'images';
      case CloudinaryResourceType.video:
        return 'videos';
      case CloudinaryResourceType.auto:
        return 'uploads';
      default:
        return 'uploads';
    }
  }

  bool _isImageExtension(String extension) {
    const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
    return imageExtensions.contains(extension);
  }

  bool _isVideoExtension(String extension) {
    const videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
    return videoExtensions.contains(extension);
  }

  bool _isAudioExtension(String extension) {
    const audioExtensions = ['.mp3', '.m4a', '.wav', '.aac', '.ogg'];
    return audioExtensions.contains(extension);
  }

  void _logInfo(String message) {
    if (kDebugMode) debugPrint('[CloudinaryService] INFO: $message');
  }

  void _logWarning(String message) {
    if (kDebugMode) debugPrint('[CloudinaryService] WARNING: $message');
  }

  void _logError(String method, dynamic error) {
    if (kDebugMode) debugPrint('[CloudinaryService] ERROR in $method: $error');
  }
}
