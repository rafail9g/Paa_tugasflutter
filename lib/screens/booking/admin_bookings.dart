import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paa_gacor/models/booking.dart';
import 'package:paa_gacor/services/booking_service.dart';
import 'package:paa_gacor/widgets/loading_indicator.dart';
import 'package:paa_gacor/widgets/status_badge.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = const ['Semua', 'Pending', 'Konfirmasi', 'Aktif', 'Selesai', 'Batal'];
  final _statuses = [null, 'pending', 'confirmed', 'active', 'completed', 'cancelled'];
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _fetchBookings();
    });
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      final status = _statuses[_tabController.index];
      final bookings = await BookingService.getAllBookings(status: status);
      if (mounted) setState(() => _bookings = bookings);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _fmt(double price) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);
  String _fmtDate(DateTime d) => DateFormat('dd MMM yyyy', 'id_ID').format(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Kelola Pesanan'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Memuat pesanan...')
          : _error.isNotEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _fetchBookings, child: const Text('Coba Lagi')),
                  ],
                ))
              : _bookings.isEmpty
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Tidak ada pesanan', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ))
                  : RefreshIndicator(
                      onRefresh: _fetchBookings,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bookings.length,
                        itemBuilder: (ctx, i) => _buildCard(_bookings[i]),
                      ),
                    ),
    );
  }

  Widget _buildCard(BookingModel b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withOpacity(0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${b.id?.substring(b.id!.length > 6 ? b.id!.length - 6 : 0).toUpperCase() ?? '-'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                ),
                Row(children: [
                  StatusBadge.booking(b.status),
                  const SizedBox(width: 6),
                  StatusBadge.payment(b.paymentStatus),
                ]),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pelanggan
                if (b.user != null) ...[
                  Row(children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(b.user!.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text(b.user!.email, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ]),
                  const SizedBox(height: 8),
                ],
                // Mobil
                Row(children: [
                  const Icon(Icons.directions_car, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(b.car?.name ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.date_range, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('${_fmtDate(b.startDate)} – ${_fmtDate(b.endDate)} (${b.totalDays} hari)',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                ]),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(b.totalPrice),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E))),
                    if (b.paymentMethod != null)
                      Text(_methodLabel(b.paymentMethod!),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),

                // Action buttons
                const SizedBox(height: 10),
                _buildActionRow(b),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(BookingModel b) {
    final actions = <Widget>[];

    // Konfirmasi pesanan (pending → confirmed)
    if (b.status == 'pending') {
      actions.add(_actionBtn(
        'Konfirmasi',
        Icons.check_circle_outline,
        Colors.blue,
        () => _updateStatus(b.id!, 'confirmed'),
      ));
    }

    // Aktifkan (confirmed + sudah bayar → active)
    if (b.status == 'confirmed' && b.paymentStatus == 'paid') {
      actions.add(_actionBtn(
        'Aktifkan',
        Icons.play_circle_outline,
        Colors.green,
        () => _updateStatus(b.id!, 'active'),
      ));
    }

    // Selesaikan
    if (b.status == 'active') {
      actions.add(_actionBtn(
        'Selesai',
        Icons.done_all,
        Colors.teal,
        () => _updateStatus(b.id!, 'completed'),
      ));
    }

    // Verifikasi pembayaran (ada bukti, belum verified)
    if (b.paymentStatus == 'unpaid' && b.paymentMethod != null && b.status != 'cancelled') {
      actions.add(_actionBtn(
        'Verifikasi Bayar',
        Icons.verified,
        Colors.orange,
        () => _verifyPayment(b.id!, true),
      ));
      actions.add(_actionBtn(
        'Tolak Bayar',
        Icons.cancel_outlined,
        Colors.red,
        () => _verifyPayment(b.id!, false),
      ));
    }

    // Batalkan
    if (b.status == 'pending' || b.status == 'confirmed') {
      actions.add(_actionBtn(
        'Batalkan',
        Icons.block,
        Colors.red.shade300,
        () => _updateStatus(b.id!, 'cancelled'),
      ));
    }

    if (actions.isEmpty) return const SizedBox();

    return Wrap(spacing: 8, runSpacing: 8, children: actions);
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 12, color: color)),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        side: BorderSide(color: color.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _updateStatus(String bookingId, String status) async {
    try {
      await BookingService.updateBookingStatus(bookingId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status diperbarui: $status'), backgroundColor: Colors.green),
        );
        _fetchBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _verifyPayment(String bookingId, bool isVerified) async {
    try {
      await BookingService.verifyPayment(bookingId, isVerified: isVerified);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isVerified ? 'Pembayaran diverifikasi!' : 'Pembayaran ditolak'),
            backgroundColor: isVerified ? Colors.green : Colors.red,
          ),
        );
        _fetchBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _methodLabel(String m) {
    switch (m) {
      case 'transfer': return 'Transfer Bank';
      case 'cash': return 'Tunai';
      case 'card': return 'Kartu';
      default: return m;
    }
  }
}
