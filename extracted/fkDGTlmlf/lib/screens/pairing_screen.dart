import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import '../utils/app_strings.dart';
import '../main.dart';
import 'package:logger/logger.dart';
import 'qr_scanner_screen.dart';
import 'dashboard_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

final logger = Logger();

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final TextEditingController _partnerHeartCodeCharController = TextEditingController();
  final TextEditingController _partnerHeartCodeNumController = TextEditingController();

  String _myHeartCode = '';
  String _myFcmToken = '';
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadMyInfo();
  }

  Future<void> _loadMyInfo() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _myHeartCode = prefs.getString('userHeartCode') ?? '';
      _isLoading = false;
    });

    try {
      _myFcmToken = await FirebaseMessaging.instance.getToken() ?? '';
      if (_myFcmToken.isNotEmpty && _myHeartCode.isNotEmpty) {
        await _updateFcmTokenInFirestore(_myHeartCode, _myFcmToken);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  Future<void> _updateFcmTokenInFirestore(String heartCode, String fcmToken) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(heartCode).set(
        {'fcmToken': fcmToken, 'lastUpdated': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      debugPrint('✅ FCM Token updated for $heartCode');
    } catch (e) {
      debugPrint('❌ Error updating FCM token: $e');
    }
  }

  Future<void> _initiatePairing() async {
    if (!_formKey.currentState!.validate()) return;

    final partnerHeartCode = _partnerHeartCodeCharController.text.toUpperCase() +
        _partnerHeartCodeNumController.text;

    if (partnerHeartCode.isEmpty || partnerHeartCode.length != 5) {
      _displayMessage(currentStrings['enterPartnerCode'] ?? 'Please enter a valid partner heart code.');
      return;
    }

    if (partnerHeartCode == _myHeartCode) {
      _displayMessage(currentStrings['cannotPairWithSelf'] ?? 'You cannot pair with your own heart code.');
      return;
    }

    try {
      final partnerDoc = await FirebaseFirestore.instance.collection('users').doc(partnerHeartCode).get();

      if (!partnerDoc.exists) {
        _displayMessage(currentStrings['partnerCodeNotFound'] ?? 'Partner heart code not found.');
        return;
      }

      final partnerData = partnerDoc.data();
      final String? existingPartnerForMe = partnerData?['partnerHeartCode'];

      if (existingPartnerForMe != null && existingPartnerForMe != _myHeartCode) {
        _displayMessage(currentStrings['partnerAlreadyPaired'] ?? 'This partner is already paired with someone else.');
        return;
      }

      final confirmPairing = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(currentStrings['confirmPairingTitle'] ?? 'Confirm Pairing'),
            content: Text(currentStrings['confirmPairingMessage'] ?? 'Do you want to pair with this partner?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(currentStrings['cancel'] ?? 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(currentStrings['yes'] ?? 'Yes'),
              ),
            ],
          );
        },
      );

      if (confirmPairing != true) return;

      final batch = FirebaseFirestore.instance.batch();

      batch.set(
        FirebaseFirestore.instance.collection('users').doc(_myHeartCode),
        {
          'partnerHeartCode': partnerHeartCode,
          'lastPairedDate': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        FirebaseFirestore.instance.collection('users').doc(partnerHeartCode),
        {
          'partnerHeartCode': _myHeartCode,
          'lastPairedDate': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('partnerHeartCode', partnerHeartCode);
      await prefs.setString('partnerName', partnerData?['name'] ?? 'Partner');

      _displayMessage(currentStrings['pairingSuccess'] ?? 'Pairing successful!');

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      _displayMessage('${currentStrings['pairingError'] ?? 'Pairing failed'}: $e');
      logger.e('Pairing error: $e');
    }
  }

  void _displayMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _copyHeartCode() {
    Clipboard.setData(ClipboardData(text: _myHeartCode));
    _displayMessage(currentStrings['copiedToClipboard'] ?? 'Copied to clipboard!');
  }

  void _scanQRCode() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (result != null && result is String) {
      if (result.length == 5) {
        _partnerHeartCodeCharController.text = result[0];
        _partnerHeartCodeNumController.text = result.substring(1);
      } else {
        _displayMessage(currentStrings['invalidQrCode'] ?? 'Invalid QR code format.');
        return;
      }
      _initiatePairing();
    }
  }

  void _showMyQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentStrings['yourHeartCode'] ?? 'Your Heart Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: _myHeartCode,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              _myHeartCode,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(currentStrings['cancel'] ?? 'Close'),
          ),
        ],
      ),
    );
  }

  void _skipPairing() async {
    final confirmSkip = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(currentStrings['skipPairingTitle'] ?? 'Skip Pairing'),
          content: Text(currentStrings['skipPairingMessage'] ?? 'Are you sure you want to skip pairing for now? You can pair later from settings.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(currentStrings['cancel'] ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(currentStrings['yes'] ?? 'Yes'),
            ),
          ],
        );
      },
    );

    if (confirmSkip == true) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color tertiaryColor = Theme.of(context).colorScheme.tertiary;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(currentStrings['pairingTitle'] ?? 'Pairing')),
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentStrings['pairingTitle'] ?? 'Pairing'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            children: [
              Text(
                currentStrings['myHeartCodeLabel'] ?? 'Your Heart Code:',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _myHeartCode,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.qr_code, color: Colors.white70),
                          onPressed: _showMyQRCode,
                          tooltip: 'Show QR Code',
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.white70),
                          onPressed: _copyHeartCode,
                          tooltip: currentStrings['tapToCopy'] ?? 'Tap to copy',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text(
                currentStrings['partnerHeartCodeLabel'] ?? 'Partner\'s Heart Code:',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              Form(
                key: _formKey,
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        controller: _partnerHeartCodeCharController,
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.characters,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          hintText: 'A',
                          counterText: '',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty || !RegExp(r'^[A-Z]$').hasMatch(value.toUpperCase())) {
                            return '';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (value.isNotEmpty) FocusScope.of(context).nextFocus();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _partnerHeartCodeNumController,
                        maxLength: 4,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '1234',
                          counterText: '',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty || value.length != 4 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
                            return '';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _initiatePairing,
                icon: const Icon(Icons.link),
                label: Text(currentStrings['pairNow'] ?? 'Pair Now'),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: _scanQRCode,
                  icon: Icon(Icons.qr_code_scanner, color: primaryColor),
                  label: Text(
                    currentStrings['scanQRCode'] ?? 'Scan QR Code',
                    style: TextStyle(color: primaryColor, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: _skipPairing,
                  child: Text(
                    currentStrings['skipPairing'] ?? 'Skip Pairing for Now',
                    style: TextStyle(color: tertiaryColor, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _partnerHeartCodeCharController.dispose();
    _partnerHeartCodeNumController.dispose();
    super.dispose();
  }
}
