class TokenModel {
  final String userId;
  final int tokenNumber;
  final DateTime createdAt;
  final String status; // 'waiting' or 'served'

  TokenModel({
    required this.userId,
    required this.tokenNumber,
    required this.createdAt,
    required this.status,
  });

  factory TokenModel.fromMap(Map<String, dynamic> map) {
    return TokenModel(
      userId: map['userId'],
      tokenNumber: map['tokenNumber'],
      createdAt: (map['createdAt'] as dynamic).toDate(),
      status: map['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tokenNumber': tokenNumber,
      'createdAt': createdAt,
      'status': status,
    };
  }
}