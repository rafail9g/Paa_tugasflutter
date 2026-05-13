import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paa_gacor/models/booking.dart';
import 'package:paa_gacor/services/booking_service.dart';
import 'package:paa_gacor/widgets/loading_indicator.dart';
import 'package:paa_gacor/widgets/status_badge.dart';
import 'package:paa_gacor/screens/booking/booking_detail.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String?> _statuses = [
    null,
    'pending',
    'confirmed',
    'active',
    'completed',
    'cancelled',
  ];
  final List<String> _tabLabels = [
    'Semua',
    'Menunggu',
    'Dikonfirmasi',
    'Aktif',
    'Selesai',
    'Dibatalkan',
  ];
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _fetchBookings();
    });
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final status = _statuses[_tabController.index];
      final bookings = await BookingService.getMyBookings(status: status);
      if (mounted) setState(() => _bookings = bookings);
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatPrice(double price) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(price);

  String _formatDate(DateTime date) =>
      DateFormat('dd MMM yyyy', 'id_ID').format(date);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Pemesanan Saya'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabAlignment: TabAlignment.start,
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Memuat pemesanan...')
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchBookings,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : _bookings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.car_rental, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada pemesanan',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchBookings,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _bookings.length,
                itemBuilder: (context, i) => _buildBookingCard(_bookings[i]),
              ),
            ),
    );
  }

  /// Label info singkat di bawah harga untuk memberi konteks status bayar
  String _paymentHint(BookingModel booking) {
    switch (booking.paymentStatus) {
      case 'unpaid':
        return '⚠ Belum bayar';
      case 'pending':
        return '🕐 Menunggu verifikasi';
      case 'paid':
        return '✓ Pembayaran terverifikasi';
      default:
        return '';
    }
  }

  Color _paymentHintColor(String paymentStatus) {
    switch (paymentStatus) {
      case 'unpaid':
        return Colors.red.shade600;
      case 'pending':
        return Colors.amber.shade800;
      case 'paid':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade500;
    }
  }

  Widget _buildBookingCard(BookingModel booking) {
    final hint = _paymentHint(booking);
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => BookingDetailScreen(bookingId: booking.id!),
          ),
        );
        // Refresh list setelah kembali (status mungkin berubah)
        _fetchBookings();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withOpacity(0.04),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${booking.id?.substring(booking.id!.length > 6 ? booking.id!.length - 6 : 0).toUpperCase() ?? '-'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                  Row(
                    children: [
                      StatusBadge.booking(booking.status),
                      const SizedBox(width: 6),
                      StatusBadge.payment(booking.paymentStatus),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade100,
                    ),
                    child: booking.car?.images.isNotEmpty == true
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              booking.car!.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.directions_car,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.directions_car,
                            color: Colors.grey,
                            size: 28,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.car?.name ?? 'Mobil',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_formatDate(booking.startDate)} – ${_formatDate(booking.endDate)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${booking.totalDays} hari • ${_formatPrice(booking.totalPrice)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        if (hint.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            hint,
                            style: TextStyle(
                              fontSize: 11,
                              color: _paymentHintColor(booking.paymentStatus),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
