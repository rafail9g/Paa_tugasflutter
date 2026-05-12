import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:paa_gacor/models/booking.dart';
import 'package:paa_gacor/models/payment.dart';
import 'package:paa_gacor/services/payment_service.dart';
import 'package:paa_gacor/widgets/loading_indicator.dart';

class PaymentScreen extends StatefulWidget {
  final BookingModel booking;

  const PaymentScreen({super.key, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _transactionIdController = TextEditingController();

  String _selectedMethod = 'transfer_bank';
  bool _isSubmitting = false;

  static const _primaryColor = Color(0xFF1A1A2E);

  // Info rekening tujuan
  static const _bankAccounts = [
    {'bank': 'BCA', 'number': '1234567890', 'name': 'PT Paa Gacor Rental'},
    {
      'bank': 'Mandiri',
      'number': '0987654321',
      'name': 'PT Paa Gacor Rental'
    },
  ];

  // Method values sesuai API
  static const _methods = [
    {
      'value': 'transfer_bank',
      'label': 'Transfer Bank',
      'icon': Icons.account_balance,
    },
    {'value': 'cash', 'label': 'Tunai', 'icon': Icons.payments},
    {'value': 'card', 'label': 'Kartu Kredit/Debit', 'icon': Icons.credit_card},
  ];

  @override
  void dispose() {
    _notesController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(price);

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi field transfer
    if (_selectedMethod == 'transfer_bank') {
      if (_bankNameController.text.trim().isEmpty ||
          _accountNumberController.text.trim().isEmpty ||
          _accountNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lengkapi data rekening pengirim'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Pembayaran'),
        content: Text(
          'Konfirmasi pembayaran sebesar ${_formatPrice(widget.booking.totalPrice)} '
          'via ${_getMethodLabel(_selectedMethod)}?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            child:
                const Text('Konfirmasi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      await PaymentService.createPayment(
        bookingId: widget.booking.id!,
        amount: widget.booking.totalPrice,
        method: _selectedMethod,
        bankName: _selectedMethod == 'transfer_bank'
            ? _bankNameController.text.trim()
            : null,
        accountNumber: _selectedMethod == 'transfer_bank'
            ? _accountNumberController.text.trim()
            : null,
        accountName: _selectedMethod == 'transfer_bank'
            ? _accountNameController.text.trim()
            : null,
        transactionId: _transactionIdController.text.trim().isEmpty
            ? null
            : _transactionIdController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Pembayaran berhasil dikirim! Menunggu verifikasi admin.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _getMethodLabel(String method) {
    return _methods.firstWhere(
          (m) => m['value'] == method,
          orElse: () => {'label': method},
        )['label'] as String? ??
        method;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Pembayaran'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isSubmitting
          ? const LoadingIndicator(message: 'Memproses pembayaran...')
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderSummary(),
                    const SizedBox(height: 16),
                    _buildPaymentMethod(),
                    const SizedBox(height: 16),
                    if (_selectedMethod == 'transfer_bank') ...[
                      _buildBankDestinationInfo(),
                      const SizedBox(height: 16),
                      _buildTransferForm(),
                      const SizedBox(height: 16),
                    ],
                    _buildNotesField(),
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Ringkasan pemesanan ──────────────────────────────────────────────────
  Widget _buildOrderSummary() {
    final b = widget.booking;
    return _buildCard(
      'Ringkasan Pemesanan',
      Icons.receipt_long,
      Column(
        children: [
          if (b.car != null) ...[
            Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100),
                child: b.car!.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(b.car!.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.directions_car, color: Colors.grey)))
                    : const Icon(Icons.directions_car, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.car!.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(b.car!.brand,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
            ]),
            const Divider(height: 20),
          ],
          _buildSummaryRow('Durasi', '${b.totalDays} hari'),
          _buildSummaryRow(
            'Tanggal',
            '${DateFormat('dd MMM', 'id_ID').format(b.startDate)} – '
                '${DateFormat('dd MMM yyyy', 'id_ID').format(b.endDate)}',
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pembayaran',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                _formatPrice(b.totalPrice),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: _primaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  // ── Pilih metode ─────────────────────────────────────────────────────────
  Widget _buildPaymentMethod() {
    return _buildCard(
      'Metode Pembayaran',
      Icons.payment,
      Column(
        children: _methods.map((m) {
          final isSelected = _selectedMethod == m['value'];
          return GestureDetector(
            onTap: () =>
                setState(() => _selectedMethod = m['value'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? _primaryColor : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
                color: isSelected
                    ? _primaryColor.withOpacity(0.05)
                    : Colors.grey.shade50,
              ),
              child: Row(
                children: [
                  Icon(m['icon'] as IconData,
                      color: isSelected ? _primaryColor : Colors.grey.shade500,
                      size: 22),
                  const SizedBox(width: 12),
                  Text(
                    m['label'] as String,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? _primaryColor : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(Icons.check_circle,
                        color: _primaryColor, size: 20),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Info rekening tujuan (untuk transfer) ────────────────────────────────
  Widget _buildBankDestinationInfo() {
    return _buildCard(
      'Transfer ke Rekening',
      Icons.account_balance,
      Column(
        children: _bankAccounts.map((acc) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(acc['bank']!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(acc['number']!,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(acc['name']!,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.copy, size: 18, color: Colors.grey),
                  tooltip: 'Salin',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: acc['number']!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Nomor rekening ${acc['bank']} disalin'),
                          duration: const Duration(seconds: 2)),
                    );
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Form data rekening pengirim ──────────────────────────────────────────
  Widget _buildTransferForm() {
    return _buildCard(
      'Data Rekening Pengirim',
      Icons.edit_note,
      Column(
        children: [
          _buildField(
            controller: _bankNameController,
            label: 'Nama Bank *',
            hint: 'Contoh: BCA, Mandiri, BRI',
            icon: Icons.account_balance_outlined,
            required: true,
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _accountNumberController,
            label: 'Nomor Rekening *',
            hint: 'Nomor rekening pengirim',
            icon: Icons.numbers,
            keyboardType: TextInputType.number,
            required: true,
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _accountNameController,
            label: 'Nama Pemilik Rekening *',
            hint: 'Sesuai nama di rekening',
            icon: Icons.person_outline,
            required: true,
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _transactionIdController,
            label: 'ID Transaksi / Bukti Transfer',
            hint: 'Opsional — nomor referensi transfer',
            icon: Icons.receipt_outlined,
            required: false,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primaryColor, width: 1.5)),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  // ── Catatan ──────────────────────────────────────────────────────────────
  Widget _buildNotesField() {
    return _buildCard(
      'Catatan (Opsional)',
      Icons.notes,
      TextFormField(
        controller: _notesController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Tambahkan catatan untuk admin...',
          hintStyle:
              TextStyle(color: Colors.grey.shade400, fontSize: 13),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primaryColor)),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  // ── Tombol submit ────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.send, color: Colors.white),
        label: Text(
          'Kirim Pembayaran ${_formatPrice(widget.booking.totalPrice)}',
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15),
        ),
        onPressed: _submitPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, Widget child) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: _primaryColor),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }
}