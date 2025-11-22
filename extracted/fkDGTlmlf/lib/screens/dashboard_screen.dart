import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_strings.dart';
import 'pairing_screen.dart';
import 'settings_screen.dart';
import 'enhanced_settings_screen.dart';
import 'i_miss_you_settings_screen.dart';
import '../widgets/ecg_painter.dart';
import '../widgets/custom_drawer.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  String? _partnerName;
  String? _partnerHeartCode;
  String? _myHeartCode;
  String? _partnerFcmToken;
  DateTime? _lastInteractionTime;

  late AnimationController _leftHeartController;
  late AnimationController _rightHeartController;
  late AnimationController _ecgController;
  late AnimationController _slideController;
  late AnimationController _glowController;

  late Animation<double> _leftHeartAnimation;
  late Animation<double> _rightHeartAnimation;
  late Animation<double> _ecgAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _glowAnimation;

  bool _isAnimating = false;
  double _slideProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPartnerInfo();
    _listenForInteractions();
    _setupAnimations();
  }

  void _setupAnimations() {
    _leftHeartController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _leftHeartAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(parent: _leftHeartController, curve: Curves.easeInOut));

    _rightHeartController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _rightHeartAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
        CurvedAnimation(parent: _rightHeartController, curve: Curves.easeInOut));

    _ecgController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _ecgAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ecgController, curve: Curves.easeInOut));

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeInOut));

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _leftHeartController.dispose();
    _rightHeartController.dispose();
    _ecgController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadPartnerInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _partnerName = prefs.getString('partnerName');
      _partnerHeartCode = prefs.getString('partnerHeartCode');
      _myHeartCode = prefs.getString('userHeartCode');
      _partnerFcmToken = prefs.getString('partnerFcmToken');
    });
    if (_partnerHeartCode != null) {
      _fetchLastInteractionTime();
    }
  }

  Future<void> _fetchLastInteractionTime() async {
    if (_myHeartCode == null || _partnerHeartCode == null) return;
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('interactions')
          .doc('${_myHeartCode}_$_partnerHeartCode')
          .get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['timestamp'] != null) {
          setState(() {
            _lastInteractionTime = (data['timestamp'] as Timestamp).toDate();
          });
        }
      }
    } catch (e) {
      logger.e("Error fetching last interaction: $e");
    }
  }

  void _listenForInteractions() {
    if (_myHeartCode == null || _partnerHeartCode == null) return;

    FirebaseFirestore.instance
        .collection('interactions')
        .doc('${_partnerHeartCode}_$_myHeartCode')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data();
        if (data != null && data['timestamp'] != null) {
          setState(() {
            _lastInteractionTime = (data['timestamp'] as Timestamp).toDate();
          });
        }
      }
    });
    
    FirebaseFirestore.instance
        .collection('interactions')
        .doc('${_myHeartCode}_$_partnerHeartCode')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data();
        if (data != null && data['timestamp'] != null) {
          setState(() {
            _lastInteractionTime = (data['timestamp'] as Timestamp).toDate();
          });
        }
      }
    });
  }

  Future<void> _sendHeartbeat() async {
    if (_isAnimating) return;
    
    if (_myHeartCode == null || _partnerHeartCode == null) {
      _displayMessage(currentStrings['noPartnerPaired'] ?? 'No partner paired yet.');
      return;
    }

    setState(() {
      _isAnimating = true;
    });

    _startHeartPulseAnimation();

    try {
      final interactionId = '${_myHeartCode}_$_partnerHeartCode';
      await FirebaseFirestore.instance
          .collection('interactions')
          .doc(interactionId)
          .set({
        'senderId': _myHeartCode,
        'receiverId': _partnerHeartCode,
        'type': 'heartbeat',
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      _displayMessage(currentStrings['heartbeatSent'] ?? 'Heartbeat sent!');
      _fetchLastInteractionTime();
    } catch (e) {
      _displayMessage('Error sending heartbeat: $e');
    }

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  void _startHeartPulseAnimation() {
    _leftHeartController.forward().then((_) {
      _leftHeartController.reverse();
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      _ecgController.forward().then((_) {
        _ecgController.reset();
      });
    });

    Future.delayed(const Duration(milliseconds: 2100), () {
      _rightHeartController.forward().then((_) {
        _rightHeartController.reverse();
      });
    });
  }

  Future<void> _sendMessage() async {
    if (_myHeartCode == null || _partnerHeartCode == null) {
      _displayMessage(currentStrings['noPartnerPaired'] ?? 'No partner paired yet.');
      return;
    }

    try {
      final messageId = FirebaseFirestore.instance.collection('messages').doc().id;
      await FirebaseFirestore.instance.collection('messages').doc(messageId).set({
        'senderId': _myHeartCode,
        'receiverId': _partnerHeartCode,
        'text': 'I miss you ❤️',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _displayMessage(currentStrings['messageSent'] ?? 'Message sent!');

      final interactionId = '${_myHeartCode}_$_partnerHeartCode';
      await FirebaseFirestore.instance.collection('interactions').doc(interactionId).set({
        'senderId': _myHeartCode,
        'receiverId': _partnerHeartCode,
        'type': 'message',
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      _fetchLastInteractionTime();
    } catch (e) {
      _displayMessage('Error sending message: $e');
    }
  }

  void _displayMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) {
      return currentStrings['never'] ?? 'Never';
    }
    final Duration difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} ${currentStrings['secondsAgo'] ?? 'seconds ago'}';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${currentStrings['minutesAgo'] ?? 'minutes ago'}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${currentStrings['hoursAgo'] ?? 'hours ago'}';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} ${currentStrings['daysAgo'] ?? 'days ago'}';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  void _onSlideUpdate(double progress) {
    setState(() {
      _slideProgress = progress;
    });
  }

  void _onSlideComplete() {
    if (_slideProgress > 0.8) {
      _sendMessage();
      _slideController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _slideController.reset();
          setState(() {
            _slideProgress = 0.0;
          });
        });
      });
    } else {
      _slideController.reverse();
      setState(() {
        _slideProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color tertiaryColor = Theme.of(context).colorScheme.tertiary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _leftHeartAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _leftHeartAnimation.value,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: _leftHeartController.isAnimating
                          ? [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.8),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ]
                          : [],
                    ),
                    child: const Icon(Icons.favorite, color: Colors.red, size: 30),
                  ),
                );
              },
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 80,
              height: 30,
              child: AnimatedBuilder(
                animation: _ecgAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ECGPainter(progress: _ecgAnimation.value, color: primaryColor),
                  );
                },
              ),
            ),
            const SizedBox(width: 20),
            AnimatedBuilder(
              animation: _rightHeartAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _rightHeartAnimation.value,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: _rightHeartController.isAnimating
                          ? [
                              BoxShadow(
                                color: Colors.pink.withOpacity(0.8),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ]
                          : [],
                    ),
                    child: const Icon(Icons.favorite, color: Colors.pink, size: 30),
                  ),
                );
              },
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const EnhancedSettingsScreen()));
            },
          ),
        ],
      ),
      drawer: CustomDrawer(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // المحتوى فارغ - سيتم إضافة الميزات لاحقاً
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: _partnerHeartCode == null || _partnerHeartCode!.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_alt, size: 80, color: tertiaryColor),
                    const SizedBox(height: 20),
                    Text(
                      currentStrings['noPartnerMessage'] ??
                          'It looks like you haven\'t paired with anyone yet. Head to the pairing screen to connect with your partner!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PairingScreen()),
                        );
                      },
                      icon: const Icon(Icons.link),
                      label: Text(currentStrings['goToPairing'] ?? 'Go to Pairing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentStrings['lastInteractionWith'] ??
                                'Last interaction with',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7)),
                          ),
                          Text(
                            _partnerName ??
                                (currentStrings['unknownPartner'] ?? 'Your Partner'),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ],
                      ),
                      Text(
                        _formatTimeAgo(_lastInteractionTime),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: _sendHeartbeat,
                      child: AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(
                                      0.3 + (_glowAnimation.value * 0.4)),
                                  blurRadius: 20 + (_glowAnimation.value * 20),
                                  spreadRadius: 5 + (_glowAnimation.value * 5),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.favorite,
                                color: Colors.white, size: 100),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: SlideToSendButton(
                    onSlideComplete: _onSlideComplete,
                    onSlideUpdate: _onSlideUpdate,
                    slideProgress: _slideProgress,
                    primaryColor: primaryColor,
                    tertiaryColor: tertiaryColor,
                    glowAnimation: _glowAnimation,
                  ),
                ),
              ],
            ),
    );
  }
}

class SlideToSendButton extends StatefulWidget {
  final VoidCallback onSlideComplete;
  final Function(double) onSlideUpdate;
  final double slideProgress;
  final Color primaryColor;
  final Color tertiaryColor;
  final Animation<double> glowAnimation;

  const SlideToSendButton({
    super.key,
    required this.onSlideComplete,
    required this.onSlideUpdate,
    required this.slideProgress,
    required this.primaryColor,
    required this.tertiaryColor,
    required this.glowAnimation,
  });

  @override
  State<SlideToSendButton> createState() => _SlideToSendButtonState();
}

class _SlideToSendButtonState extends State<SlideToSendButton> {
  double _dragPosition = 0.0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.glowAnimation,
      builder: (context, child) {
        return Container(
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            gradient: LinearGradient(
              colors: [
                widget.primaryColor.withOpacity(0.3),
                widget.tertiaryColor.withOpacity(0.3),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor
                    .withOpacity(0.3 * widget.glowAnimation.value),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  currentStrings['swipeToSend'] ?? 'Swipe to Send "I Miss You"',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Positioned(
                left: _dragPosition,
                top: 5,
                child: GestureDetector(
                  onPanStart: (_) {
                    setState(() {
                      _isDragging = true;
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _dragPosition = (_dragPosition + details.delta.dx)
                          .clamp(0.0, MediaQuery.of(context).size.width - 120);
                      widget.onSlideUpdate(_dragPosition /
                          (MediaQuery.of(context).size.width - 120));
                    });
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _isDragging = false;
                    });
                    widget.onSlideComplete();
                    if (_dragPosition <
                        (MediaQuery.of(context).size.width - 120) * 0.8) {
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: widget.primaryColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withOpacity(0.5),
                          blurRadius: _isDragging ? 15 : 8,
                          spreadRadius: _isDragging ? 3 : 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: _isDragging ? 30 : 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
