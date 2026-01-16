import 'dart:convert';
import 'dart:io';

import 'package:alembro/services/local/pendents.dart';
import 'package:flutter/material.dart';

import 'package:alembro/services/local/local_log.dart';
import 'package:alembro/services/local/storage_service.dart';
import 'package:alembro/services/connectivity.dart';
import 'package:alembro/services/api/http_client.dart';
import 'package:alembro/services/api/sync_data.dart';
import 'package:alembro/models/user.dart';
import 'package:path_provider/path_provider.dart';


class UserController extends ChangeNotifier {
  final SyncService _syncService = SyncService();

  List<User> allUsers = [];
  List<User> filteredUsers = [];
  bool isLoading = true;
  bool criticalError = false;

  Future<void> checkConnectionAndLoadData() async {
    isLoading = true;
    criticalError = false;
    notifyListeners();
    try {
      final hasInternet = await hasInternetConnection();

      if (hasInternet) {
        try {
          await _syncService.syncUsers();
        } catch (e, stack) {
          await LocalLogger.log('Erro na sincronização: $e\n$stack');
        }
      }

      final users = await _loadUsers();

      allUsers = users;
      filteredUsers = users;
      criticalError = allUsers.isEmpty; 
    } catch (e, stack) {
      await LocalLogger.log('Erro crítico: $e\n$stack');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<User>> _loadUsers() async {
    final json = await BaseStorage.getRawData('users.json');
    if (json == null || json['data'] == null) return [];
    return (json['data'] as List)
        .map((j) => User.fromJson(j))
        .toList();
  }
  
  Future<void> addUser({
    required Map<String, dynamic> body,
    required User newUser,
  }) async {
    // 1: atualiza a UI
    allUsers.add(newUser);
    filteredUsers = List<User>.from(allUsers);
    notifyListeners();

    // 2: atualiza o banco local
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/users.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> jsonData = json.decode(content);

        final usersList = jsonData['data'] as List;
        usersList.add(body);

        await file.writeAsString(jsonEncode(jsonData));
      }

    } catch (e) {
      await LocalLogger.log('Erro ao salvar em users.json: $e');
    }

    final url = "/usuarios";
    debugPrint('ENVIANDO REQUISIÇÃO POST');
    debugPrint('URL: $url');
    debugPrint('Payload: ${jsonEncode(body)}');
    // 3: envia pro back ou queue
    try {
      final httpClient = HttpClient();
      await httpClient.post(url, body);
    } catch (_) {
      await OfflineQueue.addToQueue({
        'url': url,
        'body': body,
      });
    }
  }

  Future<void> updateUser({
    required int userId,
    required Map<String, dynamic> body,
    required String userType,
  }) async {
    // 1: atualiza a UI
    final index = allUsers.indexWhere((usr) => usr.userId == userId);
    if (index != -1) {
      final oldUser = allUsers[index];
      final updateUser = User(
        userId: oldUser.userId,
        companyId: oldUser.companyId,
        userName: oldUser.userName,
        sellerId: body['sellerId'] ?? oldUser.sellerId,
        deviceCredit: body['deviceCredit'] ?? oldUser.deviceCredit,
        userType: userType,
        nomenclature: oldUser.nomenclature,
        active: body['active'] ?? oldUser.active,        
      );

      allUsers[index] = updateUser;

      final fIndex = filteredUsers.indexWhere((usr) => usr.userId == userId);
      if (fIndex != -1) filteredUsers[fIndex] = updateUser;

      notifyListeners();
    }

    // 2: Atualiza o banco local
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/users.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> jsonData = json.decode(content);
        final usersList = jsonData['data'] as List;
        final jsonIndex = usersList.indexWhere((item) => item['id'] == userId);

        if (jsonIndex != -1) {
          body.forEach((key, value) {
            usersList[jsonIndex][key] = value;
          });
          await file.writeAsString(json.encode(jsonData));
        }
      }
    } catch (e) {
      await LocalLogger.log('Erro ao editar localmente: $e');
    }

    // 3: envia pro back ou queue
    final url = "/usuarios/$userId";

    debugPrint('ENVIANDO REQUISIÇÃO');
    debugPrint('URL: $url');
    debugPrint('Payload: ${jsonEncode(body)}');

    try {
      final httpClient = HttpClient();
      await httpClient.patch(url, body);
    } catch (e) {
      await OfflineQueue.addToQueue({'url': url, 'body': body});
    }
  }

  void filterUsers(String query) {
    if (query.isEmpty) {
      filteredUsers = allUsers;
    } else {
      filteredUsers = allUsers.where((u) => 
        u.userName.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
    notifyListeners();
  }
}