import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/compression_history_item.dart';

class HistoryProvider with ChangeNotifier {
  static const _prefsKey = 'compression_history_v1';

  List<CompressionHistoryItem> _items = const [];
  bool _loaded = false;

  List<CompressionHistoryItem> get items => _items;
  bool get isLoaded => _loaded;

  HistoryProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    final decoded = raw == null ? <CompressionHistoryItem>[] : CompressionHistoryItem.decodeList(raw);
    decoded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _items = decoded;
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(CompressionHistoryItem item) async {
    _items = [item, ..._items];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, CompressionHistoryItem.encodeList(_items));
  }

  Future<void> remove(String id) async {
    _items = _items.where((e) => e.id != id).toList(growable: false);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, CompressionHistoryItem.encodeList(_items));
  }

  Future<void> clear() async {
    _items = const [];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

