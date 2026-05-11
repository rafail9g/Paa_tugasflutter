import 'package:flutter/material.dart';
import 'package:paa_gacor/models/car_model.dart';
import 'package:paa_gacor/services/car_service.dart';
import 'package:paa_gacor/widgets/car_card.dart';
import 'package:paa_gacor/widgets/loading_indicator.dart';
import 'package:paa_gacor/screens/car/car.dart';
import 'package:paa_gacor/services/auth_service.dart';
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
    if (mounted) {
      setState(() {
        _role = role ?? 'user';
      });
    }
  }

  Future<void> _fetchCars([String? searchQuery]) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await CarService.getCars(search: searchQuery);
      if (mounted) {
        setState(() {
          _cars = result['cars'] as List<CarModel>;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCar(CarModel car) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Mobil'),
        content: Text('Apakah Anda yakin ingin menghapus ${car.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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
          MaterialPageRoute(builder: (context) => const LoginScreen()),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Rental Admin'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
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
                              onPressed: () => _fetchCars(),
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : _cars.isEmpty
                        ? const Center(
                            child: Text('Tidak ada data mobil'),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _fetchCars(),
                            child: ListView.builder(
                              itemCount: _cars.length,
                              itemBuilder: (context, index) {
                                final car = _cars[index];
                                return CarCard(
                                  car: car,
                                  onEdit: _role == 'admin' ? () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CarFormScreen(car: car),
                                      ),
                                    );
                                    if (result == true) {
                                      _fetchCars();
                                    }
                                  } : null,
                                  onDelete: _role == 'admin' ? () => _deleteCar(car) : null,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: _role == 'admin' ? FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CarFormScreen(),
            ),
          );
          if (result == true) {
            _fetchCars();
          }
        },
        backgroundColor: const Color(0xFF1A1A2E),
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }
}
