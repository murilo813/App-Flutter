import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:alembro/services/http_client.dart';

class OfflineQueue {
  static const _key = 'offline_queue';

  static Future<void> addToQueue(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];

    final payload = {...data, "created_at": DateTime.now().toIso8601String()};

    existing.add(jsonEncode(payload));
    await prefs.setStringList(_key, existing);
  }

  static Future<List<Map<String, dynamic>>> getQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_key) ?? [];
    return stored.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static StreamSubscription<List<ConnectivityResult>>? _subscription;

  static void startSyncWhenOnline(String backendUrl) {
    if (_subscription != null) return;

    _subscription = Connectivity().onConnectivityChanged.listen((
      statusList,
    ) async {
      if (statusList.isNotEmpty &&
          !statusList.contains(ConnectivityResult.none)) {
        await trySendQueue(backendUrl);
      }
    });
  }

  static Future<void> trySendQueue(String backendUrl) async {
    final queue = await getQueue();
    if (queue.isEmpty) return;

    final List<Map<String, dynamic>> failed = [];
    final httpClient = HttpClient(baseUrl: backendUrl);

    for (final item in queue) {
      try {
        final String url = item['url'] as String;
        final dynamic body = item['body'];

        await httpClient.post(url, body);
      } catch (_) {
        failed.add(item);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final List<String> updatedQueue = failed.map((e) => jsonEncode(e)).toList();

    await prefs.setStringList(_key, updatedQueue);
  }
}
