class BookingModel {
  final String? id;
  final String? bookingCode;
  final String? carId;
  final String? userId;
  final CarInfo? car;
  final UserInfo? user;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final double totalPrice;
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final String? paymentProof;
  final String? notes;
  final DateTime? confirmedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? pickupLocation;
  final String? dropoffLocation;

  BookingModel({
    this.id,
    this.bookingCode,
    this.carId,
    this.userId,
    this.car,
    this.user,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.totalPrice,
    this.status = 'pending',
    this.paymentStatus = 'unpaid',
    this.paymentMethod,
    this.paymentProof,
    this.notes,
    this.confirmedAt,
    this.createdAt,
    this.updatedAt,
    this.pickupLocation,
    this.dropoffLocation,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // duration bisa dari 'duration' atau 'totalDays'
    final duration = json['duration'] as int? ?? json['totalDays'] as int? ?? 1;

    return BookingModel(
      id: json['_id'] as String?,
      bookingCode: json['bookingCode'] as String?,
      carId: json['car'] is String ? json['car'] as String : null,
      userId: json['user'] is String ? json['user'] as String : null,
      car: json['car'] is Map
          ? CarInfo.fromJson(json['car'] as Map<String, dynamic>)
          : null,
      user: json['user'] is Map
          ? UserInfo.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalDays: duration,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      paymentStatus: json['paymentStatus'] as String? ?? 'unpaid',
      paymentMethod: json['paymentMethod'] as String?,
      paymentProof: json['paymentProof'] as String?,
      notes: json['notes'] as String?,
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.tryParse(json['confirmedAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      pickupLocation: json['pickupLocation'] as String?,
      dropoffLocation:
          json['dropoffLocation'] as String? ??
          json['returnLocation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'startDate': startDate.toIso8601String().substring(0, 10),
      'endDate': endDate.toIso8601String().substring(0, 10),
    };
    if (carId != null) map['car'] = carId;
    if (notes != null) map['notes'] = notes;
    if (paymentMethod != null) map['paymentMethod'] = paymentMethod;
    if (pickupLocation != null) map['pickupLocation'] = pickupLocation;
    if (dropoffLocation != null) map['returnLocation'] = dropoffLocation;
    return map;
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'active':
        return 'Sedang Berjalan';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String get paymentStatusLabel {
    switch (paymentStatus) {
      case 'unpaid':
        return 'Belum Bayar';
      case 'paid':
        return 'Sudah Bayar';
      case 'refunded':
        return 'Dikembalikan';
      default:
        return paymentStatus;
    }
  }
}

class CarInfo {
  final String? id;
  final String name;
  final String brand;
  final String? model;
  final String? type;
  final double? pricePerDay;
  final List<String> images;
  final String? licensePlate;
  final String? transmission;
  final int? seats;
  final String? color;
  final String? fuel;

  CarInfo({
    this.id,
    required this.name,
    required this.brand,
    this.model,
    this.type,
    this.pricePerDay,
    this.images = const [],
    this.licensePlate,
    this.transmission,
    this.seats,
    this.color,
    this.fuel,
  });

  factory CarInfo.fromJson(Map<String, dynamic> json) {
    // Ambil images — bisa berupa List<String> atau List<dynamic>
    List<String> imgs = [];
    final rawImages = json['images'];
    if (rawImages is List) {
      imgs = rawImages
          .where((e) => e != null && e.toString().isNotEmpty)
          .map((e) => e.toString())
          .toList();
    }

    return CarInfo(
      id: json['_id'] as String?,
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String?,
      type: json['type'] as String?,
      pricePerDay: (json['pricePerDay'] as num?)?.toDouble(),
      images: imgs,
      licensePlate: json['licensePlate'] as String?,
      transmission: json['transmission'] as String?,
      seats: json['seats'] as int?,
      color: json['color'] as String?,
      fuel: json['fuel'] as String?,
    );
  }
}

class UserInfo {
  final String? id;
  final String name;
  final String email;
  final String? phone;

  UserInfo({this.id, required this.name, required this.email, this.phone});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['_id'] as String?,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
    );
  }
}
