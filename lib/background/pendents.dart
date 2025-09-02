import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../local_log.dart';

class OfflineQueue {
  static const _key = 'offline_queue';

  static Future<void> addToQueue(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];
    existing.add(jsonEncode(data));
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

  static void startSyncWhenOnline(String backendUrl) {
    Connectivity().onConnectivityChanged.listen((status) async {
      if (status != ConnectivityResult.none) {
        final queue = await getQueue();
        if (queue.isEmpty) return;

        List<Map<String, dynamic>> failed = [];

        for (final item in queue) {
            try {
                final String url = item['url'];
                final dynamic body = item['body'];
                final uri = Uri.parse('$backendUrl$url');

                await http.post(
                    uri,
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode(body),
                );
            } catch (e) {
                failed.add(item);
            }
        }

        final prefs = await SharedPreferences.getInstance();
        final updatedQueue = failed.map((e) => jsonEncode(e)).toList();
        await prefs.setStringList(_key, updatedQueue);
      }
    });
  }
    static Future<void> trySendQueue(String backendUrl) async {
    final queue = await getQueue();
    if (queue.isEmpty) return;

    List<Map<String, dynamic>> failed = [];

    for (final item in queue) {
        try {
        final String url = item['url'];
        final dynamic body = item['body'];
        final uri = Uri.parse('$backendUrl$url');

        await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
        );
        } catch (_) {
        failed.add(item);
        }
    }

    final prefs = await SharedPreferences.getInstance();
    final updatedQueue = failed.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList(_key, updatedQueue);
    }
}
