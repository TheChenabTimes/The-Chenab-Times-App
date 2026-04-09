import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  static const String _createOrderUrl = 'https://api.thechenabtimes.com/payment.php';
  static const String _verifyPaymentUrl =
      'https://api.thechenabtimes.com/payment_verify.php';

  final _razorpay = Razorpay();
  final _amountController = TextEditingController();
  String? _pendingOrderId;
  int? _pendingAmount;

  @override
  void initState() {
    super.initState();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _verifyPayment(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showStatusDialog(
      isSuccess: false,
      title: 'Payment Failed',
      message: 'We couldn\'t process your donation. Please check your connection or payment method and try again.',
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("EXTERNAL_WALLET: ${response.walletName!}")),
    );
  }
  Future<void> _verifyPayment(PaymentSuccessResponse response) async {
    final orderId = response.orderId ?? _pendingOrderId;
    final paymentId = response.paymentId;
    final signature = response.signature;

    if (orderId == null || paymentId == null || signature == null) {
      _showStatusDialog(
        isSuccess: false,
        title: 'Verification Failed',
        message: 'We could not verify your donation. Please contact support if money was deducted.',
      );
      return;
    }

    try {
      final verifyResponse = await http
          .post(
            Uri.parse(_verifyPaymentUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "order_id": orderId,
              "payment_id": paymentId,
              "signature": signature,
              "amount": _pendingAmount,
              "currency": "INR",
            }),
          )
          .timeout(const Duration(seconds: 20));

      final Map<String, dynamic> data = jsonDecode(verifyResponse.body);
      final isVerified = verifyResponse.statusCode == 200 &&
          (data["verified"] == true ||
              data["success"] == true ||
              data["status"] == "verified" ||
              data["status"] == "success");

      if (!mounted) return;

      if (isVerified) {
        _pendingOrderId = null;
        _pendingAmount = null;
        _showStatusDialog(
          isSuccess: true,
          title: 'Payment Successful',
          message:
              'Thank you for your generous donation. Your support helps us continue our work.',
        );
        return;
      }

      _showStatusDialog(
        isSuccess: false,
        title: 'Verification Failed',
        message: data["message"]?.toString() ??
            'Your payment could not be verified. Please contact support if money was deducted.',
      );
    } catch (e) {
      if (!mounted) return;
      _showStatusDialog(
        isSuccess: false,
        title: 'Verification Failed',
        message:
            'We could not verify your donation right now. Please contact support if money was deducted.',
      );
    }
  }

  void _openCheckout(int amount) async {
    if (amount == 0) return;
    try {
      final response = await http
          .post(
            Uri.parse(_createOrderUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"amount": amount, "currency": "INR"}),
          )
          .timeout(const Duration(seconds: 20));
      final Map<String, dynamic> data = jsonDecode(response.body);
      final orderId = data["id"];
      if (response.statusCode != 200 || orderId == null) {
        throw Exception(data["message"] ?? "Failed to create donation order.");
      }

      _pendingOrderId = orderId.toString();
      _pendingAmount = amount;

      var options = {
        "key": "rzp_live_SXocvdfq7NW63I",
        "amount": amount * 100,
        "order_id": orderId,
        "name": "The Chenab Times",
        "description": "Donation",
        "prefill": {"contact": "", "email": ""},
      };
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error: ${e.toString()}");
      _showStatusDialog(
        isSuccess: false,
        title: "Error",
        message: "An unexpected error occurred. Please try again later.",
      );
    }
  }


  Future<void> _showAmountDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Container(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Enter Donation Amount',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'e.g. 100',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      alignment: WrapAlignment.center,
                      children: [100, 500, 1000].map((amount) {
                        return OutlinedButton(
                          onPressed: () {
                            int currentAmount = int.tryParse(_amountController.text) ?? 0;
                            setDialogState(() {
                              _amountController.text = (currentAmount + amount).toString();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text('+ ₹$amount'),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        if (_amountController.text.isNotEmpty) {
                          int amount = int.parse(_amountController.text);
                          Navigator.of(context).pop();
                          _openCheckout(amount);
                        }
                      },
                      child: const Text('Donate'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      child: const Text('Cancel', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showStatusDialog(
      {required bool isSuccess, required String title, required String message}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSuccess ? Colors.green.shade100 : Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess ? Icons.check : Icons.close,
                    color: isSuccess ? Colors.green : Colors.red,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? Colors.green : Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                  ),
                  child: const Text('Close', style: TextStyle(fontSize: 16, color: Colors.white)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Donate'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(Icons.volunteer_activism, color: theme.colorScheme.primary, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Support Independent Journalism',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Empowering local voices, free from corporate influence.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 30),
            _buildInfoCard(
              icon: Icons.info_outline,
              title: 'About Us',
              content:
                  'The Chenab Times is an independent, multilingual news outlet powered by the people. We bring reliable stories, local voices, and in-depth analysis.',
            ),
            _buildInfoCard(
              icon: Icons.lightbulb_outline,
              title: 'How Your Donation Helps',
              items: [
                'Day-to-day operations of The Chenab Times',
                'Development of community journalism projects',
                'Initiatives and social programs run by the Chenab Times Foundation (CTF)',
              ],
            ),
            _buildInfoCard(
              icon: Icons.shield_outlined,
              title: 'Transparency',
              content:
                  'All donations are managed under the Chenab Times Foundation (CTF). Funds will be used for the operation of The Chenab Times and other purposes of CTF, including community and educational initiatives.',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: _showAmountDialog,
          icon: const Icon(Icons.favorite, color: Colors.white),
          label: const Text('Donate Now', style: TextStyle(color: Colors.white, fontSize: 18)),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    String? content,
    List<String>? items,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      shadowColor: theme.colorScheme.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (content != null)
              Text(content, style: theme.textTheme.bodyMedium),
            if (items != null)
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(item, style: theme.textTheme.bodyMedium)),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
