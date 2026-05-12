import 'package:flutter/material.dart';
import 'package:paa_gacor/services/car_service.dart';
import 'package:paa_gacor/models/car_model.dart';

/// Layar debug sementara — hapus setelah masalah gambar solved.
/// Panggil dari mana saja:
///   Navigator.push(context, MaterialPageRoute(builder: (_) => const ImageDebugScreen()));
class ImageDebugScreen extends StatefulWidget {
  const ImageDebugScreen({super.key});

  @override
  State<ImageDebugScreen> createState() => _ImageDebugScreenState();
}

class _ImageDebugScreenState extends State<ImageDebugScreen> {
  List<CarModel> _cars = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await CarService.getCars(limit: 5);
      setState(() => _cars = result['cars'] as List<CarModel>);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug: Car Images'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
              child: Text(_error, style: const TextStyle(color: Colors.red)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cars.length,
              itemBuilder: (ctx, i) {
                final car = _cars[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Jumlah gambar: ${car.images.length}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        ...car.images.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final url = entry.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                'Image $idx:',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              // Tampilkan URL lengkap
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                color: Colors.grey.shade100,
                                child: SelectableText(
                                  url,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Coba load gambar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  url,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (ctx, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      height: 120,
                                      color: Colors.grey.shade200,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Loading... ${progress.cumulativeBytesLoaded} bytes',
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (ctx, err, stack) {
                                    return Container(
                                      height: 80,
                                      color: Colors.red.shade50,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.broken_image,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '❌ ERROR: $err',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.red,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
