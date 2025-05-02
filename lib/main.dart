import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../services/sync_service.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o serviço em segundo plano
  await _initializeBackgroundService();

  // Sincroniza os dados das lojas assim que o app iniciar
  await syncEstoqueDeTodasLojas();

  runApp(MyApp());
}

Future<void> _initializeBackgroundService() async {
  FlutterBackgroundService().configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStart,
      isInBackgroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      onBackground: onServiceStart,
      onForeground: onServiceStart,
    ),
  );

  FlutterBackgroundService().start();
}

void onServiceStart() {
  Timer.periodic(Duration(minutes: 15), (_) {
    syncEstoqueDeTodasLojas();
  });

  print("Serviço em segundo plano iniciado...");
}
