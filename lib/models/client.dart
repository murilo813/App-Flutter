import 'package:intl/intl.dart';

class Client {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  );

  final int clientId;
  final String clientName;
  final String responsible;
  final double limitBM;
  final double balanceBM;
  final double limitC;
  final double balanceC;
  final DateTime? birthday;
  final DateTime? lastSale;
  final int priceList;

  Client({
    required this.clientId,
    required this.clientName,
    required this.responsible,
    required this.limitBM,
    required this.balanceBM,
    required this.limitC,
    required this.balanceC,
    this.birthday,
    this.lastSale,
    this.priceList = 1,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      clientId: json['clientId'],
      clientName: json['clientName'],
      responsible: json['responsible'] ?? '',
      limitBM: (json['limitBM'] as num).toDouble(),
      balanceBM: (json['balanceBM'] as num).toDouble(),
      limitC: (json['limitC'] as num).toDouble(),
      balanceC: (json['balanceC'] as num).toDouble(),
      birthday:
          json['birthday'] != null && json['birthday'] != ''
              ? DateTime.tryParse(json['birthday'])
              : null,
      lastSale:
          json['lastSale'] != null && json['lastSale'] != ''
              ? DateTime.tryParse(json['lastSale'])
              : null,
      priceList: json['priceList'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'responsible': responsible,
      'limitBM': limitBM,
      'balanceBM': balanceBM,
      'limitC': limitC,
      'balanceC': balanceC,
      'birthday': birthday?.toIso8601String(),
      'lastSale': lastSale?.toIso8601String(),
      'priceList': priceList,
    };
  }

  String _format(double valor) {
    return _formatter.format(valor).trim();
  }
  String get limitBMF => _format(limitBM);
  String get balanceBMF => _format(balanceBM);
  String get limitCF => _format(limitC);
  String get balanceCF => _format(balanceC);
}
