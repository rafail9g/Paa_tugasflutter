import 'package:flutter/material.dart';
import 'package:paa_gacor/models/car_model.dart';
import 'package:paa_gacor/services/car_service.dart';
import 'package:paa_gacor/services/auth_service.dart';
import 'package:paa_gacor/widgets/car_card.dart';
import 'package:paa_gacor/widgets/loading_indicator.dart';
import 'package:paa_gacor/screens/car/car.dart';
import 'package:paa_gacor/screens/booking/booking_form.dart';
import 'package:paa_gacor/screens/booking/my_booking.dart';
import 'package:paa_gacor/screens/booking/admin_bookings.dart';
import 'package:paa_gacor/screens/auth/login.dart';

class CarListScreen extends StatefulWidget {
  const CarListScreen({super.key});

  @override
  State<CarListScreen> createState() => _CarListScreenState();
}

class _CarListScreenState extends State<CarListScreen> {
  List<CarModel> _cars = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _role = 'user';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRole();
    _fetchCars();
  }

  Future<void> _loadRole() async {
    final role = await AuthService.getRole();
    if (mounted) setState(() => _role = role ?? 'user');
  }

  Future<void> _fetchCars([String? searchQuery]) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final result = await CarService.getCars(search: searchQuery);
      if (mounted) setState(() => _cars = result['cars'] as List<CarModel>);
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

  Future<void> _deleteCar(CarModel car) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Mobil'),
        content: Text('Hapus ${car.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await CarService.deleteCar(car.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mobil berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchCars();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _role == 'admin';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(isAdmin ? 'Car Rental — Admin' : 'Sewa Mobil'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        actions: [
          if (!isAdmin)
            IconButton(
              icon: const Icon(Icons.receipt_long),
              tooltip: 'Pesanan Saya',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
              ),
            ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.assignment),
              tooltip: 'Kelola Pesanan',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminBookingsScreen()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: const Color(0xFF1A1A2E),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari mobil...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          _fetchCars();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (q) =>
                  _fetchCars(q.trim().isEmpty ? null : q.trim()),
            ),
          ),

          // Car list
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Memuat data mobil...')
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
                          onPressed: _fetchCars,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                : _cars.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_car_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada mobil tersedia',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _fetchCars(),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: _cars.length,
                      itemBuilder: (context, index) {
                        final car = _cars[index];
                        return CarCard(
                          car: car,
                          onBook: !isAdmin && car.isAvailable
                              ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BookingFormScreen(car: car),
                                  ),
                                )
                              : null,
                          onEdit: isAdmin
                              ? () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CarFormScreen(car: car),
                                    ),
                                  );
                                  if (result == true) _fetchCars();
                                }
                              : null,
                          onDelete: isAdmin ? () => _deleteCar(car) : null,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CarFormScreen()),
                );
                if (result == true) _fetchCars();
              },
              backgroundColor: const Color(0xFF1A1A2E),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Tambah Mobil',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}
