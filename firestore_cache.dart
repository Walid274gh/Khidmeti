// lib/services/repositories/firestore_cache.dart

import 'package:flutter/foundation.dart';

// ============================================================================
// CACHED ITEM
// ============================================================================

class _CachedItem<T> {
  final T item;
  final DateTime cachedAt;

  _CachedItem(this.item) : cachedAt = DateTime.now();

  bool isExpired(Duration ttl) =>
      DateTime.now().difference(cachedAt) > ttl;
}

// ============================================================================
// CACHE
// ============================================================================

class FirestoreCache<T> {
  final Duration ttl;
  final int maxSize;
  final String _tag;

  final Map<String, _CachedItem<T>> _store = {};

  FirestoreCache({
    required this.ttl,
    required this.maxSize,
    required String tag,
  }) : _tag = tag;

  // --------------------------------------------------------------------------
  // Read
  // --------------------------------------------------------------------------

  T? get(String key) {
    final item = _store[key];
    if (item == null) return null;
    if (item.isExpired(ttl)) {
      _store.remove(key);
      return null;
    }
    return item.item;
  }

  // --------------------------------------------------------------------------
  // Write
  // --------------------------------------------------------------------------

  void set(String key, T value) {
    if (_store.length >= maxSize) _evictOldest();
    _store[key] = _CachedItem(value);
  }

  void update(String key, T Function(T existing) updater) {
    final existing = _store[key];
    if (existing != null) {
      _store[key] = _CachedItem(updater(existing.item));
    }
  }

  // --------------------------------------------------------------------------
  // Cleanup
  // --------------------------------------------------------------------------

  void cleanExpired() {
    _store.removeWhere((_, v) => v.isExpired(ttl));
    if (_store.length > maxSize) _store.clear();
    if (kDebugMode) {
      debugPrint('$_tag Cache cleaned — ${_store.length} entries remaining');
    }
  }

  void clear() => _store.clear();

  int get length => _store.length;

  // --------------------------------------------------------------------------
  // Private
  // --------------------------------------------------------------------------

  void _evictOldest() {
    if (_store.isEmpty) return;
    String? oldestKey;
    DateTime? oldestTime;
    for (final entry in _store.entries) {
      if (oldestTime == null ||
          entry.value.cachedAt.isBefore(oldestTime)) {
        oldestKey = entry.key;
        oldestTime = entry.value.cachedAt;
      }
    }
    if (oldestKey != null) _store.remove(oldestKey);
  }
}
