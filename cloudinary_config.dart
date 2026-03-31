// lib/config/cloudinary_config.dart
//
// MOVED FROM: lib/providers/core_providers.dart
// REASON: Configuration class has no business living in a provider registry.
//         Belongs at the config layer, injectable by any service that needs it.
//
// FIX (Security P0): apiKey and apiSecret have been removed entirely from this
// class. The Cloudinary mobile SDK no longer uses signed configuration — it
// uses an unsigned upload preset instead. Embedding apiSecret in client-side
// code exposes full Cloudinary account access to anyone who decompiles the
// APK or IPA. See cloudinary_service.dart for the migration details.
//
// HOW TO CONFIGURE:
//   1. Go to Cloudinary Dashboard → Settings → Upload → Add upload preset
//   2. Set Mode: Unsigned
//   3. Copy the preset name into uploadPreset below
//   4. Replace cloudName with your actual cloud name

class CloudinaryConfig {
  static const String cloudName    = 'YOUR_CLOUD_NAME';
  static const String uploadPreset = 'YOUR_UPLOAD_PRESET';

  // FIX: isConfigured now validates only the two fields that still exist.
  // apiKey and apiSecret are intentionally absent — they must never appear
  // in client-side code.
  static bool get isConfigured {
    return cloudName    != 'YOUR_CLOUD_NAME' &&
           uploadPreset != 'YOUR_UPLOAD_PRESET';
  }

  static void validate() {
    if (!isConfigured) {
      // ignore: avoid_print
      print(
        '[CloudinaryConfig] WARNING: Credentials not configured. '
        'Please update cloudName and uploadPreset in '
        'lib/config/cloudinary_config.dart.',
      );
    }
  }
}
