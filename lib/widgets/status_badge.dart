import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String label;

  const StatusBadge({super.key, required this.status, required this.label});

  factory StatusBadge.booking(String status) {
    String label;
    switch (status) {
      case 'pending':
        label = 'Menunggu';
        break;
      case 'confirmed':
        label = 'Dikonfirmasi';
        break;
      case 'active':
        label = 'Aktif';
        break;
      case 'completed':
        label = 'Selesai';
        break;
      case 'cancelled':
        label = 'Dibatalkan';
        break;
      default:
        label = status;
    }
    return StatusBadge(status: status, label: label);
  }

  factory StatusBadge.payment(String status) {
    String label;
    switch (status) {
      case 'unpaid':
        label = 'Belum Bayar';
        break;
      case 'paid':
        label = 'Sudah Bayar';
        break;
      case 'refunded':
        label = 'Dikembalikan';
        break;
      default:
        label = status;
    }
    return StatusBadge(status: 'payment_$status', label: label);
  }

  Color get _bgColor {
    switch (status) {
      case 'pending':
        return Colors.orange.shade50;
      case 'confirmed':
        return Colors.blue.shade50;
      case 'active':
        return Colors.green.shade50;
      case 'completed':
        return Colors.grey.shade100;
      case 'cancelled':
        return Colors.red.shade50;
      case 'payment_unpaid':
        return Colors.red.shade50;
      case 'payment_paid':
        return Colors.green.shade50;
      case 'payment_refunded':
        return Colors.purple.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color get _textColor {
    switch (status) {
      case 'pending':
        return Colors.orange.shade700;
      case 'confirmed':
        return Colors.blue.shade700;
      case 'active':
        return Colors.green.shade700;
      case 'completed':
        return Colors.grey.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      case 'payment_unpaid':
        return Colors.red.shade700;
      case 'payment_paid':
        return Colors.green.shade700;
      case 'payment_refunded':
        return Colors.purple.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _textColor,
        ),
      ),
    );
  }
}
