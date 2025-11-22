import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_strings.dart';
import '../main.dart';
import 'pairing_screen.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _nameController = TextEditingController();
  final TextEditingController _heartCodeCharController = TextEditingController();
  final TextEditingController _heartCodeNumController = TextEditingController();

  String? _selectedGender;
  DateTime? _birthDate;
  String? _zodiacSign;
  bool _isLoading = false;

  final Map<String, String> zodiacEmojis = {
    'Aries': '♈️', 'Taurus': '♉️', 'Gemini': '♊️', 'Cancer': '♋️',
    'Leo': '♌️', 'Virgo': '♍️', 'Libra': '♎️', 'Scorpio': '♏️',
    'Sagittarius': '♐️', 'Capricorn': '♑️', 'Aquarius': '♒️', 'Pisces': '♓️',
  };

  @override
  void initState() {
    super.initState();
    _loadExistingInfo();
  }

  Future<void> _loadExistingInfo() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('userName') ?? '';
      final String? savedHeartCode = prefs.getString('userHeartCode');
      if (savedHeartCode != null && savedHeartCode.length == 5) {
        _heartCodeCharController.text = savedHeartCode[0];
        _heartCodeNumController.text = savedHeartCode.substring(1);
      }
      _selectedGender = prefs.getString('userGender');
      final savedBirth = prefs.getString('userBirthDate');
      if (savedBirth != null) {
        _birthDate = DateTime.tryParse(savedBirth);
        if (_birthDate != null) _zodiacSign = _getZodiacSign(_birthDate!);
      }
      _isLoading = false;
    });
  }

  String _getZodiacSign(DateTime date) {
    final day = date.day;
    final month = date.month;
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 'Aries';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 'Taurus';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return 'Gemini';
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return 'Cancer';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'Leo';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 'Virgo';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 'Libra';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return 'Scorpio';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return 'Sagittarius';
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return 'Capricorn';
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return 'Aquarius';
    if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) return 'Pisces';
    return '';
  }

  Future<void> _setThemeColorBasedOnGender(String gender) async {
    final prefs = await SharedPreferences.getInstance();
    Color newThemeColor;
    if (gender == 'male') {
      newThemeColor = Colors.blue;
    } else if (gender == 'female') {
      newThemeColor = Colors.pink;
    } else {
      newThemeColor = Colors.deepPurple;
    }
    await prefs.setInt('appThemeColor', newThemeColor.value);

    if (navigatorKey.currentContext != null) {
      final appState = navigatorKey.currentContext!.findAncestorStateOfType<State<MyApp>>();
      if (appState is _MyAppState) {
        (appState as dynamic).updateTheme(newThemeColor);
      }
    }
  }

  Future<void> _savePersonalInfo() async {
    setState(() => _isLoading = true);

    final userName = _nameController.text.trim();
    final heartCodeChar = _heartCodeCharController.text.toUpperCase().trim();
    final heartCodeNum = _heartCodeNumController.text.trim();
    final fullHeartCode = heartCodeChar + heartCodeNum;

    if (userName.isEmpty || _selectedGender == null || heartCodeChar.isEmpty || heartCodeNum.isEmpty || heartCodeNum.length != 4) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(content: Text(currentStrings['completeBasicInfo'] ?? 'Please enter your name, select gender, and enter a valid 5-character heart code (e.g., A1234).')),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (_birthDate == null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(content: Text(currentStrings['birthdateRequired'] ?? 'Please select your birth date.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final existingUserDoc = await firestore.collection('users').doc(fullHeartCode).get();
      if (existingUserDoc.exists) {
        final prefs = await SharedPreferences.getInstance();
        final String? currentUsersHeartCode = prefs.getString('userHeartCode');
        if (currentUsersHeartCode != fullHeartCode) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            SnackBar(content: Text(currentStrings['heartCodeExists'] ?? 'Heart code already in use. Please choose another.')),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', userName);
      await prefs.setString('userHeartCode', fullHeartCode);
      await prefs.setString('userGender', _selectedGender!);
      await prefs.setString('userBirthDate', _birthDate!.toIso8601String());

      await firestore.collection('users').doc(fullHeartCode).set({
        'name': userName,
        'heartCode': fullHeartCode,
        'gender': _selectedGender,
        'birthDate': _birthDate,
        'zodiacSign': _zodiacSign,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(content: Text(currentStrings['settingsSaved'] ?? 'Settings saved successfully!')),
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PairingScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(content: Text('${currentStrings['errorSavingSettings'] ?? 'Error saving information. Please try again.'} $e')),
      );
      logger.e("Error saving personal info: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
        _zodiacSign = _getZodiacSign(_birthDate!);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heartCodeCharController.dispose();
    _heartCodeNumController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentStrings['personalInfoTitle'] ?? 'Personal Information'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    children: [
                      _buildPage1(),
                      _buildPage2(),
                    ],
                  ),
                ),
                _buildNavigationButtons(),
              ],
            ),
    );
  }

  Widget _buildPage1() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ListView(
        children: [
          Text(
            currentStrings['whatsYourName'] ?? 'What\'s your name?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: currentStrings['yourNameHint'] ?? 'Your Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 30),
          Text(
            currentStrings['whatsYourHeartCode'] ?? 'What\'s your Heart Code?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 60,
                child: TextFormField(
                  controller: _heartCodeCharController,
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: 'A',
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) FocusScope.of(context).nextFocus();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _heartCodeNumController,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '1234',
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            currentStrings['heartCodeExplanation'] ?? 'This unique code will be used by your partner to connect with you.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 30),
          Text(
            currentStrings['whatsYourGender'] ?? 'What\'s your gender?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              _buildGenderOption('male', currentStrings['male'] ?? 'Male', primaryColor),
              _buildGenderOption('female', currentStrings['female'] ?? 'Female', primaryColor),
              _buildGenderOption('other', currentStrings['other'] ?? 'Other', primaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String value, String label, Color primaryColor) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      leading: Radio<String>(
        value: value,
        groupValue: _selectedGender,
        onChanged: (String? val) {
          setState(() => _selectedGender = val);
          if (val != null) _setThemeColorBasedOnGender(val);
        },
        activeColor: primaryColor,
      ),
      onTap: () {
        setState(() => _selectedGender = value);
        _setThemeColorBasedOnGender(value);
      },
    );
  }

  Widget _buildPage2() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ListView(
        children: [
          Text(
            currentStrings['selectBirthdate'] ?? 'Your Birth Date',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: Icon(Icons.calendar_today, color: primaryColor),
            title: Text(
              _birthDate == null
                  ? (currentStrings['tapToPick'] ?? 'Tap to select date')
                  : '🎂 ${_birthDate!.toIso8601String().substring(0, 10)}  |  ${currentStrings['zodiac$_zodiacSign'] ?? _zodiacSign}',
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            OutlinedButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Text(currentStrings['back'] ?? 'Back'),
            ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _isLoading
                ? null
                : () {
                    if (_currentPage == 0) {
                      final userName = _nameController.text.trim();
                      final heartCodeChar = _heartCodeCharController.text.toUpperCase().trim();
                      final heartCodeNum = _heartCodeNumController.text.trim();

                      if (userName.isEmpty || _selectedGender == null || heartCodeChar.isEmpty || heartCodeNum.isEmpty || heartCodeNum.length != 4) {
                        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                          SnackBar(content: Text(currentStrings['completeBasicInfo'] ?? 'Please enter your name, select gender, and enter a valid 5-character heart code (e.g., A1234).')),
                        );
                        return;
                      }
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _savePersonalInfo();
                    }
                  },
            icon: Icon(_currentPage == 0 ? Icons.arrow_forward : Icons.check),
            label: Text(_currentPage == 0
                ? (currentStrings['next'] ?? 'Next')
                : (currentStrings['saveAndContinue'] ?? 'Save and Continue')),
          ),
        ],
      ),
    );
  }
}
