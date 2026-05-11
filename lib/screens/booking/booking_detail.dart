import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paa_gacor/models/booking.dart';
import 'package:paa_gacor/services/booking_service.dart';
import 'package:paa_gacor/widgets/loading_indicator.dart';
import 'package:paa_gacor/widgets/status_badge.dart';
import 'package:paa_gacor/screens/payment/payment.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  final BookingModel? booking;

  const BookingDetailScreen({super.key, required this.bookingId, this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  BookingModel? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.booking != null) {
      _booking = widget.booking;
      _isLoading = false;
    } else {
      _loadBooking();
    }
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    try {
      final booking = await BookingService.getBookingById(widget.bookingId);
      if (mounted) setState(() => _booking = booking);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pemesanan'),
        content: const Text('Apakah Anda yakin ingin membatalkan pemesanan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final updated = await BookingService.cancelBooking(widget.bookingId);
        if (mounted) setState(() => _booking = updated);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  String _formatPrice(double price) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);

  String _formatDate(DateTime date) => DateFormat('dd MMMM yyyy', 'id_ID').format(date);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Detail Pemesanan'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBooking),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Memuat detail...')
          : _booking == null
              ? const Center(child: Text('Data tidak ditemukan'))
              : RefreshIndicator(
                  onRefresh: _loadBooking,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusCard(),
                        const SizedBox(height: 16),
                        _buildCarCard(),
                        const SizedBox(height: 16),
                        _buildBookingInfo(),
                        const SizedBox(height: 16),
                        _buildPaymentInfo(),
                        const SizedBox(height: 20),
                        _buildActions(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    final b = _booking!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('No. Pemesanan', style: TextStyle(color: Colors.white60, fontSize: 12)),
              StatusBadge.booking(b.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            b.id?.substring(b.id!.length > 8 ? b.id!.length - 8 : 0).toUpperCase() ?? '-',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatusItem(Icons.payments_outlined, 'Pembayaran', StatusBadge.payment(b.paymentStatus)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String label, Widget child) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 16),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(color: Colors.white60, fontSize: 13)),
        child,
      ],
    );
  }

  Widget _buildCarCard() {
    final car = _booking?.car;
    if (car == null) return const SizedBox();
    return _buildCard(
      'Informasi Mobil',
      Icons.directions_car,
      Row(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey.shade100),
            child: car.images.isNotEmpty
                ? ClipRRect(borderRadius: BorderRadius.circular(10),
                    child: Image.network(car.images.first, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, color: Colors.grey)))
                : const Icon(Icons.directions_car, color: Colors.grey, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(car.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${car.brand}${car.type != null ? ' • ${car.type!.toUpperCase()}' : ''}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                if (car.licensePlate != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                    child: Text(car.licensePlate!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingInfo() {
    final b = _booking!;
    return _buildCard(
      'Detail Pemesanan',
      Icons.event_note,
      Column(
        children: [
          _buildInfoRow('Tanggal Mulai', _formatDate(b.startDate), Icons.calendar_today),
          _buildInfoRow('Tanggal Selesai', _formatDate(b.endDate), Icons.calendar_today),
          _buildInfoRow('Durasi', '${b.totalDays} hari', Icons.timelapse),
          if (b.pickupLocation != null)
            _buildInfoRow('Lokasi Ambil', b.pickupLocation!, Icons.location_on),
          if (b.notes != null && b.notes!.isNotEmpty)
            _buildInfoRow('Catatan', b.notes!, Icons.notes),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Biaya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(_formatPrice(b.totalPrice),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A2E))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    final b = _booking!;
    return _buildCard(
      'Status Pembayaran',
      Icons.payment,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Status', style: TextStyle(color: Colors.grey.shade600)),
              StatusBadge.payment(b.paymentStatus),
            ],
          ),
          if (b.paymentMethod != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Metode', _getPaymentMethodLabel(b.paymentMethod!), Icons.account_balance_wallet),
          ],
          if (b.paymentStatus == 'unpaid' && b.status != 'cancelled') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selesaikan pembayaran untuk mengaktifkan pemesanan Anda.',
                      style: TextStyle(color: Colors.amber.shade800, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    final b = _booking!;
    final canPay = b.paymentStatus == 'unpaid' && b.status != 'cancelled';
    final canCancel = b.status == 'pending' || b.status == 'confirmed';

    if (!canPay && !canCancel) return const SizedBox();

    return Column(
      children: [
        if (canPay)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.payment, color: Colors.white),
              label: const Text('Bayar Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PaymentScreen(booking: b)),
                );
                if (result == true) _loadBooking();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        if (canPay && canCancel) const SizedBox(height: 10),
        if (canCancel)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              label: const Text('Batalkan Pemesanan', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onPressed: _cancelBooking,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCard(String title, IconData icon, Widget child) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF1A1A2E)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'transfer': return 'Transfer Bank';
      case 'cash': return 'Tunai';
      case 'card': return 'Kartu Kredit/Debit';
      default: return method;
    }
  }
}