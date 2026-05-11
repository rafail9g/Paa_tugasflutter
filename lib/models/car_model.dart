class CarModel {
  final String? id;
  final String name;
  final String brand;
  final String? model;
  final String type;
  final int year;
  final String licensePlate;
  final String? color;
  final double pricePerDay;
  final int seats;
  final String transmission;
  final String fuel;
  final double? mileage;
  final List<String> images;
  final List<String> features;
  final bool isAvailable;
  final String? location;
  final double? rating;
  final int? totalReviews;
  final String? description;

  CarModel({
    this.id,
    required this.name,
    required this.brand,
    this.model,
    required this.type,
    required this.year,
    required this.licensePlate,
    this.color,
    required this.pricePerDay,
    required this.seats,
    required this.transmission,
    required this.fuel,
    this.mileage,
    this.images = const [],
    this.features = const [],
    this.isAvailable = true,
    this.location,
    this.rating,
    this.totalReviews,
    this.description,
  });

  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      id: json['_id'] as String?,
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String?,
      type: json['type'] as String? ?? 'sedan',
      year: json['year'] as int? ?? 0,
      licensePlate: json['licensePlate'] as String? ?? '',
      color: json['color'] as String?,
      pricePerDay: (json['pricePerDay'] as num?)?.toDouble() ?? 0,
      seats: json['seats'] as int? ?? 0,
      transmission: json['transmission'] as String? ?? 'manual',
      fuel: json['fuel'] as String? ?? 'bensin',
      mileage: (json['mileage'] as num?)?.toDouble(),
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [],
      features: json['features'] != null
          ? List<String>.from(json['features'])
          : [],
      isAvailable: json['isAvailable'] as bool? ?? true,
      location: json['location'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      totalReviews: json['totalReviews'] as int?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'brand': brand,
      'type': type,
      'year': year,
      'licensePlate': licensePlate,
      'pricePerDay': pricePerDay,
      'seats': seats,
      'transmission': transmission,
      'fuel': fuel,
      'isAvailable': isAvailable,
    };

    if (model != null) map['model'] = model;
    if (color != null) map['color'] = color;
    if (mileage != null) map['mileage'] = mileage;
    if (images.isNotEmpty) map['images'] = images;
    if (features.isNotEmpty) map['features'] = features;
    if (location != null) map['location'] = location;
    if (description != null) map['description'] = description;

    return map;
  }
}
