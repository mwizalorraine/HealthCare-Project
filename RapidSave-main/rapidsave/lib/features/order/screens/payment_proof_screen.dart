import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/services/order_service.dart';
import '../../../shared/widgets/app_button.dart';

class PaymentProofScreen extends StatefulWidget {
  final String orderId;
  const PaymentProofScreen({super.key, required this.orderId});

  @override
  State<PaymentProofScreen> createState() => _PaymentProofScreenState();
}

class _PaymentProofScreenState extends State<PaymentProofScreen> {
  File? _image;
  bool _uploading = false;
  final _picker = ImagePicker();
  final _providerCtrl = TextEditingController(text: 'momo');
  final _referenceCtrl = TextEditingController();

  @override
  void dispose() {
    _providerCtrl.dispose();
    _referenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 1024, imageQuality: 80);
      if (picked != null && mounted) setState(() => _image = File(picked.path));
    } catch (_) {}
  }

  Future<void> _upload() async {
    if (_image == null) {
      AppUtils.showError('Please select a payment proof image first');
      return;
    }
    final provider = _providerCtrl.text.trim();
    final reference = _referenceCtrl.text.trim();
    if (provider.isEmpty) {
      AppUtils.showError('Please enter the payment provider');
      return;
    }
    if (reference.isEmpty) {
      AppUtils.showError('Please enter the transaction reference');
      return;
    }
    setState(() => _uploading = true);
    try {
      await OrderService().uploadPaymentProof(
        orderId: widget.orderId,
        filePath: _image!.path,
        provider: provider,
        reference: reference,
      );
      if (!mounted) return;
      AppUtils.showSuccess('Payment proof uploaded successfully!');
      context.pop();
    } catch (e) {
      if (mounted) AppUtils.showError(e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0ABFBC), Color(0xFF0891B2), Color(0xFF1B3A6B)],
              ),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Payment Proof', style: GoogleFonts.workSans(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                          Text('Order ${widget.orderId.length > 6 ? widget.orderId.substring(widget.orderId.length - 6).toUpperCase() : widget.orderId}', style: GoogleFonts.workSans(fontSize: 13, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                // How to pay guide
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.tealLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.teal.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.teal, size: 20),
                          const SizedBox(width: 8),
                          Text('How to pay', style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.tealDark)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _StepRow(number: '1', text: 'Send payment via MoMo or bank transfer'),
                      const SizedBox(height: 8),
                      _StepRow(number: '2', text: 'Take a screenshot of your payment confirmation'),
                      const SizedBox(height: 8),
                      _StepRow(number: '3', text: 'Fill in the details and upload the screenshot below'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Provider & Reference fields
                Text('Payment Details', style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                  child: Column(
                    children: [
                      // Provider dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Payment Provider', style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _providerCtrl.text,
                                isExpanded: true,
                                style: GoogleFonts.workSans(fontSize: 14, color: AppColors.textPrimary),
                                items: const [
                                  DropdownMenuItem(value: 'momo', child: Text('MTN Mobile Money')),
                                  DropdownMenuItem(value: 'airtel', child: Text('Airtel Money')),
                                  DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _providerCtrl.text = v);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Reference field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Transaction Reference / ID', style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _referenceCtrl,
                            style: GoogleFonts.workSans(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'e.g. TXN123456789',
                              hintStyle: GoogleFonts.workSans(fontSize: 14, color: AppColors.textHint),
                              filled: true,
                              fillColor: AppColors.grey50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.teal, width: 2)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Upload area
                Text('Upload Screenshot', style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 12),

                GestureDetector(
                  onTap: _showSourceDialog,
                  child: _image == null
                      ? Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.teal.withOpacity(0.4), width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60, height: 60,
                                decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(16)),
                                child: const Icon(Icons.cloud_upload_rounded, color: AppColors.teal, size: 30),
                              ),
                              const SizedBox(height: 12),
                              Text('Tap to upload payment proof', style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.teal)),
                              const SizedBox(height: 4),
                              Text('JPG or PNG • Max 5MB', style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textHint)),
                            ],
                          ),
                        )
                      : Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(_image!, width: double.infinity, height: 200, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 8, right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _image = null),
                                child: Container(
                                  width: 32, height: 32,
                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.danger),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8, right: 8,
                              child: GestureDetector(
                                onTap: _showSourceDialog,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(20)),
                                  child: Text('Change', style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 28),
                AppButton(text: 'Submit Payment Proof', onPressed: _upload, isLoading: _uploading),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Select Source', style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          const Icon(Icons.camera_alt_rounded, color: AppColors.teal, size: 32),
                          const SizedBox(height: 8),
                          Text('Camera', style: GoogleFonts.workSans(fontWeight: FontWeight.w600, color: AppColors.tealDark)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.primaryPale, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 32),
                          const SizedBox(height: 8),
                          Text('Gallery', style: GoogleFonts.workSans(fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String text;
  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24, height: 24,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.teal),
          child: Center(child: Text(number, style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: GoogleFonts.workSans(fontSize: 13, color: AppColors.tealDark))),
      ],
    );
  }
}
