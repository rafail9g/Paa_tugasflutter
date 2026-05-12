class UserModel {
  final String? id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final bool isActive;
  final String? avatar;
  final UserAddress? address;
  final DrivingLicense? drivingLicense;
  final DateTime? createdAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role = 'user',
    this.isActive = true,
    this.avatar,
    this.address,
    this.drivingLicense,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String?,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'user',
      isActive: json['isActive'] as bool? ?? true,
      avatar: json['avatar'] as String?,
      address: json['address'] != null
          ? UserAddress.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      drivingLicense: json['drivingLicense'] != null
          ? DrivingLicense.fromJson(
              json['drivingLicense'] as Map<String, dynamic>,
            )
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      'role': role,
    };
  }
}

class UserAddress {
  final String? street;
  final String? city;
  final String? province;
  final String? zipCode;

  UserAddress({this.street, this.city, this.province, this.zipCode});

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      street: json['street'] as String?,
      city: json['city'] as String?,
      province: json['province'] as String?,
      zipCode: json['zipCode'] as String?,
    );
  }

  String get formatted {
    final parts = [
      street,
      city,
      province,
      zipCode,
    ].where((e) => e != null && e.isNotEmpty).toList();
    return parts.join(', ');
  }
}

class DrivingLicense {
  final String? number;
  final DateTime? expiryDate;

  DrivingLicense({this.number, this.expiryDate});

  factory DrivingLicense.fromJson(Map<String, dynamic> json) {
    return DrivingLicense(
      number: json['number'] as String?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'])
          : null,
    );
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  String get expiryFormatted {
    if (expiryDate == null) return '-';
    return '${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}';
  }
}
