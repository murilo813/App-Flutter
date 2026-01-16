import 'package:alembro/models/client.dart';
import 'package:alembro/services/local/storage_service.dart';

class ClientController {
  Future<List<Client>> loadAndSort() async {
    final jsonClients = await BaseStorage.getRawData('clients.json');
    final jsonObs = await BaseStorage.getRawData('observations.json');
      
    if (jsonClients == null) return [];

    final List<Map<String, dynamic>> allObs = jsonObs != null ? List<Map<String, dynamic>>.from(jsonObs['data']) : [];
    final List<Client> list = (jsonClients['data'] as List).map((e) => Client.fromJson(e)).toList();

    final hoje = DateTime.now();

    list.sort((a, b) {
      final aAniv =
          a.birthday != null &&
          a.birthday!.day == hoje.day &&
          a.birthday!.month == hoje.month;
      final bAniv =
          b.birthday != null &&
          b.birthday!.day == hoje.day &&
          b.birthday!.month == hoje.month;

      if (aAniv && !bAniv) return -1;
      if (!aAniv && bAniv) return 1;

      // PRECISA SALVAR A DATA DIRETO FORMATADA PRA NAO PRECISAR FICAR CONVERTENDOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000
      final DateTime? ultimaObsA = allObs
          .where((o) => o['responsible'] == a.responsible)
          .map((o) => DateTime.parse(o['data']))
          .fold<DateTime?>(
            null,
            (prev, e) => prev == null || e.isAfter(prev) ? e : prev,
          );

      final DateTime? ultimaObsB = allObs
          .where((o) => o['responsible'] == b.responsible)
          .map((o) => DateTime.parse(o['data']))
          .fold<DateTime?>(
            null,
            (prev, e) => prev == null || e.isAfter(prev) ? e : prev,
          );

      final refA = _maisRecenteEntre(ultimaObsA, a.lastSale);
      final refB = _maisRecenteEntre(ultimaObsB, b.lastSale);

      if (refA == null && refB == null) {
        return a.clientName.compareTo(b.clientName);
      }
      if (refA == null) return 1;
      if (refB == null) return -1;

      return refA.compareTo(refB);
    });

    return list;
  }

  DateTime? _maisRecenteEntre(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }
}