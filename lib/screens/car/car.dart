import 'package:flutter/material.dart';
import 'package:paa_gacor/models/car_model.dart';
import 'package:paa_gacor/services/car_service.dart';
import 'package:paa_gacor/widgets/custom_text_field.dart';
import 'package:paa_gacor/widgets/loading_indicator.dart';

class CarFormScreen extends StatefulWidget {
  final CarModel? car;
  const CarFormScreen({super.key, this.car});

  @override
  State<CarFormScreen> createState() => _CarFormScreenState();
}

class _CarFormScreenState extends State<CarFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _licensePlateController;
  late TextEditingController _colorController;
  late TextEditingController _priceController;
  late TextEditingController _seatsController;
  late TextEditingController _mileageController;
  late TextEditingController _locationController;
  late TextEditingController _descController;

  // Image URLs & Features
  final List<TextEditingController> _imageControllers = [];
  final List<TextEditingController> _featureControllers = [];

  String _selectedType = 'sedan';
  String _selectedTransmission = 'manual';
  String _selectedFuel = 'bensin';
  bool _isAvailable = true;
  bool _isLoading = false;

  final List<String> _types = [
    'sedan',
    'suv',
    'mpv',
    'hatchback',
    'pickup',
    'van',
  ];
  final List<String> _transmissions = ['manual', 'automatic'];
  final List<String> _fuels = ['bensin', 'diesel', 'hybrid', 'electric'];

  @override
  void initState() {
    super.initState();
    final car = widget.car;

    _nameController = TextEditingController(text: car?.name ?? '');
    _brandController = TextEditingController(text: car?.brand ?? '');
    _modelController = TextEditingController(text: car?.model ?? '');
    _yearController = TextEditingController(
      text: car?.year != 0 ? car?.year.toString() : '',
    );
    _licensePlateController = TextEditingController(
      text: car?.licensePlate ?? '',
    );
    _colorController = TextEditingController(text: car?.color ?? '');
    _priceController = TextEditingController(
      text: car?.pricePerDay != null ? car!.pricePerDay.toStringAsFixed(0) : '',
    );
    _seatsController = TextEditingController(
      text: car?.seats != 0 ? car?.seats.toString() : '',
    );
    _mileageController = TextEditingController(
      text: car?.mileage?.toStringAsFixed(0) ?? '',
    );
    _locationController = TextEditingController(text: car?.location ?? '');
    _descController = TextEditingController(text: car?.description ?? '');

    if (car != null) {
      if (_types.contains(car.type)) _selectedType = car.type;
      if (_transmissions.contains(car.transmission))
        _selectedTransmission = car.transmission;
      if (_fuels.contains(car.fuel)) _selectedFuel = car.fuel;
      _isAvailable = car.isAvailable;

      // Isi image URLs yang sudah ada
      for (final url in car.images) {
        _imageControllers.add(TextEditingController(text: url));
      }

      // Isi features yang sudah ada
      for (final f in car.features) {
        _featureControllers.add(TextEditingController(text: f));
      }
    }

    // Minimal 1 field gambar kosong jika belum ada
    if (_imageControllers.isEmpty) {
      _imageControllers.add(TextEditingController());
    }
    // Minimal 1 field fitur kosong
    if (_featureControllers.isEmpty) {
      _featureControllers.add(TextEditingController());
    }
  }

  List<String> get _images => _imageControllers
      .map((c) => c.text.trim())
      .where((url) => url.isNotEmpty)
      .toList();

  List<String> get _features => _featureControllers
      .map((c) => c.text.trim())
      .where((f) => f.isNotEmpty)
      .toList();

  Future<void> _saveCar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final carData = CarModel(
        id: widget.car?.id,
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        model: _modelController.text.trim().isEmpty
            ? null
            : _modelController.text.trim(),
        type: _selectedType,
        year: int.tryParse(_yearController.text.trim()) ?? 0,
        licensePlate: _licensePlateController.text.trim(),
        color: _colorController.text.trim().isEmpty
            ? null
            : _colorController.text.trim(),
        pricePerDay: double.tryParse(_priceController.text.trim()) ?? 0,
        seats: int.tryParse(_seatsController.text.trim()) ?? 0,
        transmission: _selectedTransmission,
        fuel: _selectedFuel,
        mileage: _mileageController.text.trim().isEmpty
            ? null
            : double.tryParse(_mileageController.text.trim()),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        isAvailable: _isAvailable,
        images: _images,
        features: _features,
      );

      if (widget.car == null) {
        await CarService.createCar(carData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mobil berhasil ditambahkan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await CarService.updateCar(widget.car!.id!, carData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mobil berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _licensePlateController.dispose();
    _colorController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    _mileageController.dispose();
    _locationController.dispose();
    _descController.dispose();
    for (final c in _imageControllers) c.dispose();
    for (final c in _featureControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.car == null ? 'Tambah Mobil' : 'Edit Mobil'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Menyimpan data...')
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Info Dasar ───────────────────────────────────
                  _sectionTitle('Informasi Dasar'),
                  CustomTextField(
                    label: 'Nama Mobil *',
                    controller: _nameController,
                    validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Merek *',
                          controller: _brandController,
                          validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Model',
                          controller: _modelController,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Tahun *',
                          controller: _yearController,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v!.isEmpty) return 'Wajib diisi';
                            if (int.tryParse(v) == null) return 'Harus angka';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Plat Nomor *',
                          controller: _licensePlateController,
                          validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Warna',
                          controller: _colorController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Lokasi',
                          controller: _locationController,
                        ),
                      ),
                    ],
                  ),

                  // ── Spesifikasi ──────────────────────────────────
                  _sectionTitle('Spesifikasi'),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Harga/Hari (Rp) *',
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v!.isEmpty) return 'Wajib diisi';
                            if (double.tryParse(v) == null)
                              return 'Harus angka';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Kursi *',
                          controller: _seatsController,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v!.isEmpty) return 'Wajib diisi';
                            if (int.tryParse(v) == null) return 'Harus angka';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  CustomTextField(
                    label: 'Jarak Tempuh (km)',
                    controller: _mileageController,
                    keyboardType: TextInputType.number,
                  ),
                  _buildDropdown(
                    'Tipe Mobil',
                    _types,
                    _selectedType,
                    (v) => setState(() => _selectedType = v!),
                  ),
                  _buildDropdown(
                    'Transmisi',
                    _transmissions,
                    _selectedTransmission,
                    (v) => setState(() => _selectedTransmission = v!),
                  ),
                  _buildDropdown(
                    'Bahan Bakar',
                    _fuels,
                    _selectedFuel,
                    (v) => setState(() => _selectedFuel = v!),
                  ),
                  SwitchListTile(
                    title: const Text('Ketersediaan'),
                    subtitle: Text(
                      _isAvailable
                          ? 'Mobil tersedia untuk disewa'
                          : 'Mobil tidak tersedia',
                    ),
                    value: _isAvailable,
                    activeColor: Colors.green,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _isAvailable = v),
                  ),
                  const SizedBox(height: 8),

                  // ── Gambar (URL) ─────────────────────────────────
                  _sectionTitle('Foto Mobil (URL Gambar)'),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Masukkan URL gambar. Bisa dari Google Drive (share link), Imgur, atau hosting gambar lainnya.\n\nContoh: https://i.imgur.com/xxxxx.jpg',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._imageControllers.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final ctrl = entry.value;
                    return _buildUrlField(
                      controller: ctrl,
                      label: 'URL Gambar ${idx + 1}',
                      hint: 'https://i.imgur.com/contoh.jpg',
                      onRemove: _imageControllers.length > 1
                          ? () => setState(() {
                              ctrl.dispose();
                              _imageControllers.removeAt(idx);
                            })
                          : null,
                    );
                  }),
                  TextButton.icon(
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Tambah URL Gambar'),
                    onPressed: () => setState(() {
                      _imageControllers.add(TextEditingController());
                    }),
                  ),

                  // Preview gambar yang diinput
                  if (_images.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Preview:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        itemBuilder: (ctx, i) => Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade200,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            _images[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  color: Colors.red.shade300,
                                ),
                                const Text(
                                  'URL salah',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // ── Fitur ────────────────────────────────────────
                  _sectionTitle('Fitur Mobil'),
                  ..._featureControllers.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final ctrl = entry.value;
                    return _buildUrlField(
                      controller: ctrl,
                      label: 'Fitur ${idx + 1}',
                      hint: 'Contoh: AC, GPS, Bluetooth',
                      icon: Icons.star_outline,
                      onRemove: _featureControllers.length > 1
                          ? () => setState(() {
                              ctrl.dispose();
                              _featureControllers.removeAt(idx);
                            })
                          : null,
                    );
                  }),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Fitur'),
                    onPressed: () => setState(() {
                      _featureControllers.add(TextEditingController());
                    }),
                  ),
                  const SizedBox(height: 8),

                  // ── Deskripsi ────────────────────────────────────
                  _sectionTitle('Deskripsi'),
                  CustomTextField(
                    label: 'Deskripsi Mobil',
                    controller: _descController,
                    maxLines: 4,
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveCar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Simpan Data Mobil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Color(0xFF1A1A2E),
        ),
      ),
    );
  }

  Widget _buildUrlField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData icon = Icons.image_outlined,
    VoidCallback? onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => setState(() {}), // trigger preview refresh
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                prefixIcon: Icon(icon, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF1A1A2E),
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: onRemove,
              tooltip: 'Hapus',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String value,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item.toUpperCase()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
