// lib/services/media_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'cloudinary_service.dart';
import '../utils/constants.dart';

class MediaServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  MediaServiceException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() =>
      'MediaServiceException: $message${code != null ? ' (Code: $code)' : ''}';
}

// ============================================================================
// ISOLATE HELPERS
// FIX (Performance): Image encoding/decoding (img.decodeImage, img.encodeJpg)
// is synchronous CPU-bound work that previously ran on the UI thread.
// On a 10MB photo this takes 100–300ms — long enough to drop multiple frames
// and trigger an ANR on Android.
//
// Moved to a background isolate via compute(). The helper classes below are
// top-level (or static) so they can be serialised across isolate boundaries.
// ============================================================================

class _CompressImageParams {
  final String inputPath;
  final String outputPath;
  final int quality;
  final int maxDimension;

  const _CompressImageParams({
    required this.inputPath,
    required this.outputPath,
    required this.quality,
    required this.maxDimension,
  });
}

/// Runs in a background isolate — must not capture any Flutter state.
Future<String> _compressImageIsolate(_CompressImageParams params) async {
  final bytes = await File(params.inputPath).readAsBytes();
  final image = img.decodeImage(bytes);
  if (image == null) {
    throw Exception('Could not decode image: ${params.inputPath}');
  }

  img.Image processed = image;
  if (image.width > params.maxDimension ||
      image.height > params.maxDimension) {
    processed = img.copyResize(
      image,
      width: image.width > image.height ? params.maxDimension : null,
      height: image.height >= image.width ? params.maxDimension : null,
    );
  }

  final compressed = img.encodeJpg(processed, quality: params.quality);
  await File(params.outputPath).writeAsBytes(compressed);
  return params.outputPath;
}

class MediaService {
  static const int maxImageSizeMB = AppConstants.maxImageSizeMB;
  static const int maxVideoSizeMB = AppConstants.maxVideoSizeMB;
  static const int maxImageSizeBytes = maxImageSizeMB * 1024 * 1024;
  static const int maxVideoSizeBytes = maxVideoSizeMB * 1024 * 1024;
  static const int defaultImageQuality = 85;
  static const int defaultImageDimension = 1920;
  static const int thumbnailQuality = 50;
  static const int minImageQuality = 1;
  static const int maxImageQuality = 100;
  static const int maxMultipleImages = 10;
  static const Duration maxVideoDuration = Duration(minutes: 5);
  static const Duration compressionTimeout = Duration(minutes: 3);

  static const List<String> supportedImageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
  ];

  static const List<String> supportedVideoExtensions = [
    '.mp4',
    '.mov',
    '.avi',
    '.mkv',
  ];

  final CloudinaryService cloudinaryService;
  final ImagePicker _picker = ImagePicker();

  bool _isDisposed = false;

  MediaService(this.cloudinaryService);

  Future<File?> pickImage({required bool fromCamera}) async {
    _ensureNotDisposed();

    try {
      _logInfo('Picking image from ${fromCamera ? 'camera' : 'gallery'}');

      final XFile? pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: defaultImageDimension.toDouble(),
        maxHeight: defaultImageDimension.toDouble(),
        imageQuality: defaultImageQuality,
      );

      if (pickedFile == null) {
        _logInfo('Image picking cancelled by user');
        return null;
      }

      final file = File(pickedFile.path);
      await _validateImageFile(file);

      _logInfo('Image picked: ${pickedFile.path}');
      return file;
    } catch (e) {
      _logError('pickImage', e);
      if (e is MediaServiceException) rethrow;
      throw MediaServiceException(
        'Failed to pick image',
        code: 'PICK_IMAGE_ERROR',
        originalError: e,
      );
    }
  }

  Future<List<File>> pickMultipleImages({int maxImages = 5}) async {
    _ensureNotDisposed();
    _validateMaxImages(maxImages);

    try {
      _logInfo('Picking multiple images (max: $maxImages)');

      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: defaultImageDimension.toDouble(),
        maxHeight: defaultImageDimension.toDouble(),
        imageQuality: defaultImageQuality,
      );

      if (pickedFiles.isEmpty) {
        _logInfo('No images selected');
        return [];
      }

      final limitedFiles = pickedFiles.take(maxImages).toList();
      final files = <File>[];

      for (final xFile in limitedFiles) {
        try {
          final file = File(xFile.path);
          await _validateImageFile(file);
          files.add(file);
        } catch (e) {
          _logWarning('Skipping invalid image: ${xFile.path} - $e');
        }
      }

      _logInfo('Picked ${files.length} valid images');
      return files;
    } catch (e) {
      _logError('pickMultipleImages', e);
      if (e is MediaServiceException) rethrow;
      throw MediaServiceException(
        'Failed to pick multiple images',
        code: 'PICK_MULTIPLE_ERROR',
        originalError: e,
      );
    }
  }

  Future<File?> pickVideo({required bool fromCamera}) async {
    _ensureNotDisposed();

    try {
      _logInfo('Picking video from ${fromCamera ? 'camera' : 'gallery'}');

      final XFile? pickedFile = await _picker.pickVideo(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxDuration: maxVideoDuration,
      );

      if (pickedFile == null) {
        _logInfo('Video picking cancelled by user');
        return null;
      }

      final file = File(pickedFile.path);
      await _validateVideoFile(file);

      _logInfo('Video picked: ${pickedFile.path}');
      return file;
    } catch (e) {
      _logError('pickVideo', e);
      if (e is MediaServiceException) rethrow;
      throw MediaServiceException(
        'Failed to pick video',
        code: 'PICK_VIDEO_ERROR',
        originalError: e,
      );
    }
  }

  // FIX (Performance): compressImage previously decoded and encoded the image
  // synchronously on the UI thread. img.decodeImage on a 10MB photo blocks
  // the UI isolate for 100–300ms — enough to trigger dropped frames and an
  // ANR dialog on Android. Work is now delegated to a background isolate via
  // compute(). The output file path is returned to the main isolate; no Flutter
  // objects cross the isolate boundary.
  Future<File> compressImage(File file,
      {int quality = defaultImageQuality}) async {
    _ensureNotDisposed();
    await _validateImageFile(file);
    _validateImageQuality(quality);

    try {
      _logInfo('Compressing image: ${file.path}');

      final originalSize = await file.length();
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Run CPU-bound work in a background isolate.
      final resultPath = await compute(
        _compressImageIsolate,
        _CompressImageParams(
          inputPath: file.path,
          outputPath: outputPath,
          quality: quality,
          maxDimension: defaultImageDimension,
        ),
      );

      final compressedFile = File(resultPath);
      final compressedSize = await compressedFile.length();
      final compressionRatio =
          ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);

      _logInfo(
        'Image compressed: ${_formatBytes(originalSize)} → '
        '${_formatBytes(compressedSize)} ($compressionRatio% reduction)',
      );

      return compressedFile;
    } catch (e) {
      _logError('compressImage', e);
      if (e is MediaServiceException) rethrow;
      throw MediaServiceException(
        'Failed to compress image',
        code: 'COMPRESS_ERROR',
        originalError: e,
      );
    }
  }

  Future<File?> compressVideo(File file) async {
    _ensureNotDisposed();
    await _validateVideoFile(file);

    try {
      _logInfo('Compressing video: ${file.path}');

      final originalSize = await file.length();

      // VideoCompress already runs on a background thread internally.
      final info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      ).timeout(
        compressionTimeout,
        onTimeout: () => throw MediaServiceException(
          'Video compression timed out',
          code: 'COMPRESSION_TIMEOUT',
        ),
      );

      if (info == null) {
        _logWarning('Video compression returned null');
        return null;
      }

      if (info.file == null) {
        throw MediaServiceException(
          'Video compression failed',
          code: 'COMPRESS_FAILED',
        );
      }

      final compressedSize = info.filesize ?? 0;
      final compressionRatio = compressedSize > 0
          ? ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1)
          : '0.0';

      _logInfo(
        'Video compressed: ${_formatBytes(originalSize)} → '
        '${_formatBytes(compressedSize)} ($compressionRatio% reduction)',
      );

      return info.file;
    } catch (e) {
      _logError('compressVideo', e);
      if (e is MediaServiceException) rethrow;
      throw MediaServiceException(
        'Failed to compress video',
        code: 'COMPRESS_VIDEO_ERROR',
        originalError: e,
      );
    }
  }

  Future<String> uploadImage(File file, {String? folder}) async {
    _ensureNotDisposed();
    await _validateImageFile(file);

    File? compressedFile;

    try {
      _logInfo('Uploading image: ${file.path}');

      compressedFile = await compressImage(file);

      final url = await cloudinaryService.uploadImage(
        compressedFile,
        folder: folder,
      );

      _logInfo('Image uploaded successfully: $url');
      return url;
    } catch (e) {
      _logError('uploadImage', e);
      if (e is MediaServiceException) rethrow;
      throw MediaServiceException(
        'Failed to upload image',
        code: 'UPLOAD_IMAGE_ERROR',
        originalError: e,
      );
    } finally {
      await _cleanupTempFile(compressedFile, file);
    }
  }

  Future<String> uploadVideo(File file, {String? folder}) async {
    _ensureNotDisposed();
    await _validateVideoFile(file);

    File? compressedFile;

    try {
      _logInfo('Uploading video: ${file.path}');

      compressedFile = await compressVideo(file);
      final fileToUpload = compressedFile ?? file;

      final url = await cloudinaryService.uploadVideo(
        fileToUpload,
        folder: folder,
      );

      _logInfo('Video uploaded successfully: $url');
      return url;
    } catch (e) {
      _logError('uploadVideo', e);
      if (e is MediaServiceException) rethrow;
      throw MediaServiceException(
        'Failed to upload video',
        code: 'UPLOAD_VIDEO_ERROR',
        originalError: e,
      );
    } finally {
      await _cleanupTempFile(compressedFile, file);
    }
  }

  Future<List<String>> uploadMultipleImages(
    List<File> files, {
    String? folder,
  }) async {
    _ensureNotDisposed();

    if (files.isEmpty) {
      _logWarning('uploadMultipleImages called with empty list');
      return [];
    }

    if (files.length > maxMultipleImages) {
      throw MediaServiceException(
        'Too many images: ${files.length} (max: $maxMultipleImages)',
        code: 'TOO_MANY_IMAGES',
      );
    }

    _logInfo('Uploading ${files.length} images');

    final List<String> urls = [];
    final List<String> errors = [];

    for (int i = 0; i < files.length; i++) {
      try {
        final url = await uploadImage(files[i], folder: folder);
        urls.add(url);
        _logInfo('Uploaded image ${i + 1}/${files.length}');
      } catch (e) {
        _logWarning('Failed to upload image ${i + 1}/${files.length}: $e');
        errors.add('Image ${i + 1}: $e');
      }
    }

    if (urls.isEmpty && errors.isNotEmpty) {
      throw MediaServiceException(
        'All image uploads failed: ${errors.join(', ')}',
        code: 'ALL_UPLOADS_FAILED',
      );
    }

    if (errors.isNotEmpty) {
      _logWarning('Some uploads failed: ${errors.length}/${files.length}');
    }

    _logInfo('Successfully uploaded ${urls.length}/${files.length} images');
    return urls;
  }

  Future<File?> getVideoThumbnail(String videoPath) async {
    _ensureNotDisposed();

    if (videoPath.trim().isEmpty) {
      throw MediaServiceException(
        'Video path cannot be empty',
        code: 'INVALID_VIDEO_PATH',
      );
    }

    final videoFile = File(videoPath);
    if (!await videoFile.exists()) {
      throw MediaServiceException(
        'Video file does not exist: $videoPath',
        code: 'FILE_NOT_FOUND',
      );
    }

    try {
      _logInfo('Generating thumbnail for: $videoPath');

      final thumbnail = await VideoCompress.getFileThumbnail(
        videoPath,
        quality: thumbnailQuality,
      );

      if (thumbnail != null) {
        _logInfo('Thumbnail generated: ${thumbnail.path}');
      } else {
        _logWarning('Thumbnail generation returned null');
      }

      return thumbnail;
    } catch (e) {
      _logError('getVideoThumbnail', e);
      return null;
    }
  }

  void cancelVideoCompression() {
    _ensureNotDisposed();

    try {
      VideoCompress.cancelCompression();
      _logInfo('Video compression cancelled');
    } catch (e) {
      _logError('cancelVideoCompression', e);
    }
  }

  Future<void> _validateImageFile(File file) async {
    if (!await file.exists()) {
      throw MediaServiceException(
        'Image file does not exist: ${file.path}',
        code: 'FILE_NOT_FOUND',
      );
    }

    final fileSize = await file.length();
    if (fileSize == 0) {
      throw MediaServiceException(
        'Image file is empty',
        code: 'EMPTY_FILE',
      );
    }

    if (fileSize > maxImageSizeBytes) {
      throw MediaServiceException(
        'Image size exceeds ${maxImageSizeMB}MB: ${_formatBytes(fileSize)}',
        code: 'FILE_TOO_LARGE',
      );
    }

    final extension = _getFileExtension(file.path);
    if (!supportedImageExtensions.contains(extension)) {
      throw MediaServiceException(
        'Unsupported image format: $extension',
        code: 'UNSUPPORTED_FORMAT',
      );
    }
  }

  Future<void> _validateVideoFile(File file) async {
    if (!await file.exists()) {
      throw MediaServiceException(
        'Video file does not exist: ${file.path}',
        code: 'FILE_NOT_FOUND',
      );
    }

    final fileSize = await file.length();
    if (fileSize == 0) {
      throw MediaServiceException(
        'Video file is empty',
        code: 'EMPTY_FILE',
      );
    }

    if (fileSize > maxVideoSizeBytes) {
      throw MediaServiceException(
        'Video size exceeds ${maxVideoSizeMB}MB: ${_formatBytes(fileSize)}',
        code: 'FILE_TOO_LARGE',
      );
    }

    final extension = _getFileExtension(file.path);
    if (!supportedVideoExtensions.contains(extension)) {
      throw MediaServiceException(
        'Unsupported video format: $extension',
        code: 'UNSUPPORTED_FORMAT',
      );
    }
  }

  void _validateImageQuality(int quality) {
    if (quality < minImageQuality || quality > maxImageQuality) {
      throw MediaServiceException(
        'Invalid image quality: $quality (must be between $minImageQuality and $maxImageQuality)',
        code: 'INVALID_QUALITY',
      );
    }
  }

  void _validateMaxImages(int maxImages) {
    if (maxImages < 1 || maxImages > maxMultipleImages) {
      throw MediaServiceException(
        'Invalid maxImages: $maxImages (must be between 1 and $maxMultipleImages)',
        code: 'INVALID_MAX_IMAGES',
      );
    }
  }

  String _getFileExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return '';
    return path.substring(lastDot).toLowerCase();
  }

  Future<void> _cleanupTempFile(File? tempFile, File originalFile) async {
    if (tempFile != null && tempFile.path != originalFile.path) {
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
          _logInfo('Cleaned up temp file: ${tempFile.path}');
        }
      } catch (e) {
        _logWarning('Failed to cleanup temp file: $e');
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024)
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw MediaServiceException(
        'MediaService has been disposed',
        code: 'SERVICE_DISPOSED',
      );
    }
  }

  void _logInfo(String message) {
    if (kDebugMode) debugPrint('[MediaService] INFO: $message');
  }

  void _logWarning(String message) {
    if (kDebugMode) debugPrint('[MediaService] WARNING: $message');
  }

  void _logError(String method, dynamic error) {
    if (kDebugMode) debugPrint('[MediaService] ERROR in $method: $error');
  }

  Future<void> dispose() async {
    if (_isDisposed) return;

    _isDisposed = true;

    try {
      await VideoCompress.deleteAllCache();
      _logInfo('MediaService disposed');
    } catch (e) {
      _logError('dispose', e);
    }
  }
}


