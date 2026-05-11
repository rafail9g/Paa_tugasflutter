import 'package:flutter/material.dart';
import 'package:paa_gacor/models/car_model.dart';

class CarCard extends StatelessWidget {
  final CarModel car;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CarCard({
    super.key,
    required this.car,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Gambar mobil
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade200,
                ),
                child: car.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          car.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.directions_car,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.directions_car,
                        size: 40,
                        color: Colors.grey,
                      ),
              ),
              const SizedBox(width: 12),
              // Info mobil
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${car.brand} • ${car.type.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_formatPrice(car.pricePerDay)}/hari',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      '${car.mileage} miles',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildChip(
                          car.transmission == 'automatic' ? 'AT' : 'MT',
                          Icons.settings,
                        ),
                        const SizedBox(width: 6),
                        _buildChip('${car.seats}', Icons.airline_seat_recline_normal),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: car.isAvailable
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            car.isAvailable ? 'Tersedia' : 'Tidak',
                            style: TextStyle(
                              fontSize: 11,
                              color: car.isAvailable
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action buttons
              Column(
                children: [
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF1A1A2E)),
                      onPressed: onEdit,
                      iconSize: 20,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                      iconSize: 20,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    String priceStr = price.toStringAsFixed(0);
    String result = '';
    int count = 0;
    for (int i = priceStr.length - 1; i >= 0; i--) {
      count++;
      result = priceStr[i] + result;
      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }
    return result;
  }
}
