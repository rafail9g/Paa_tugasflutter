class PaymentModel {
  final String? id;
  final String? bookingId;
  final String? userId;
  final double amount;
  final String method; // transfer, cash, card
  final String status; // pending, verified, rejected
  final String? notes;
  final String? adminNotes;
  final DateTime? verifiedAt;
  final DateTime? createdAt;

  PaymentModel({
    this.id,
    this.bookingId,
    this.userId,
    required this.amount,
    required this.method,
    this.status = 'pending',
    this.notes,
    this.adminNotes,
    this.verifiedAt,
    this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['_id'] as String?,
      bookingId: json['booking'] is String
          ? json['booking'] as String
          : (json['booking'] as Map<String, dynamic>?)?['_id'] as String?,
      userId: json['user'] is String ? json['user'] as String : null,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      method: json['method'] as String? ?? 'transfer',
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      adminNotes: json['adminNotes'] as String?,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse(json['verifiedAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'method': method,
      if (notes != null) 'notes': notes,
    };
  }

  String get methodLabel {
    switch (method) {
      case 'transfer':
        return 'Transfer Bank';
      case 'cash':
        return 'Tunai';
      case 'card':
        return 'Kartu Kredit/Debit';
      default:
        return method;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu Verifikasi';
      case 'verified':
        return 'Terverifikasi';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }
}
