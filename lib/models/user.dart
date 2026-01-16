class User {
  final int userId;
  final int companyId;
  final String userName;
  final int sellerId;
  final int deviceCredit;
  final String userType;
  final String nomenclature;
  final String? active;

  const User({
    required this.userId,
    required this.companyId,
    required this.userName,
    required this.sellerId,
    required this.deviceCredit,
    required this.userType,
    required this.nomenclature,
    this.active,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] as int,
      companyId: json['companyId'] as int,
      userName: json['userName'] as String,
      sellerId: json['sellerId'] as int,
      deviceCredit: json['deviceCredit'] as int,
      userType: json['userType'] as String,
      nomenclature: json['nomenclature'] as String,
      active: json['active'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'companyId': companyId,
      'userName': userName,
      'sellerId': sellerId,
      'deviceCredit': deviceCredit,
      'userType': userType,
      'nomenclature': nomenclature,
      'active': active,
    };
  }
}
