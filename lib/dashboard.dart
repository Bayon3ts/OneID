import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'edit_id_screen.dart';
import 'screen/add_id_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late final User? user;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  late final AnimationController _animationController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _setupAnimations();
    fetchUserData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  Future<void> fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid ?? 'test_user')
          .get()
          .timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          userData = doc.data();
          isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      if (mounted) {
        setState(() {
          userData = {}; // fallback to empty map
          isLoading = false;
        });
        _animationController.forward(); // still animate dashboard
      }
    }
  }

  Future<void> pickAndUploadImage() async {
    Navigator.pushNamed(context, '/editProfilePicture');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget buildShimmerBox({double height = 120}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget buildIdTile(
      String idKey,
      String label,
      String value,
      Color bgColor,
      String emoji, {
        Color? textColor,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveTextColor = textColor ?? (isDark ? Colors.white : Colors.black);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditIDScreen(idKey: idKey),
          ),
        );
      },
      child: Container(
        width: (MediaQuery.of(context).size.width - 55) / 2,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: effectiveTextColor)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 12, color: effectiveTextColor.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLoadingShimmer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text("Loading OneID...", style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget buildProfileHeader(Color textColor, Color secondaryColor) {
    return Row(
      children: [
        GestureDetector(
          onTap: pickAndUploadImage,
          child: CircleAvatar(
            radius: 36,
            backgroundImage: userData?['photoUrl'] != null
                ? NetworkImage(userData!['photoUrl'])
                : const AssetImage('assets/user.png') as ImageProvider,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userData?['fullName'] ?? '—',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              'NIN ${userData?['nin'] ?? '—'}',
              style: TextStyle(fontSize: 14, color: secondaryColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildIdTiles() {
    return Wrap(
      spacing: 15,
      runSpacing: 15,
      children: [
        buildIdTile('nin', 'NATIONAL ID', userData?['nin'] ?? '—', const Color(0xFFDEF7E0), '🇳🇬'),
        buildIdTile('voterCard', "VOTER'S CARD", userData?['voterCard'] ?? '—', const Color(0xFFECECEC), '🗳️'),
        buildIdTile('passport', 'PASSPORT', userData?['passport'] ?? '—', const Color(0xFF003366), '🌐', textColor: Colors.white),
        buildIdTile('driversLicense', "DRIVER'S LICENSE", userData?['driversLicense'] ?? '—', const Color(0xFF107A61), '🚗', textColor: Colors.white),
      ],
    );
  }

  Widget buildQrAndAddIdSection(Color textColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, spreadRadius: 1, blurRadius: 4),
            ],
          ),
          child: QrImageView(
            data: userData?['nin']?.toString() ?? '',
            version: QrVersions.auto,
            size: 150.0,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 28),
        Column(
          children: [
            GestureDetector(
              onTap: () async {
                if (user != null) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddIDScreen(userId: user!.uid)),
                  );
                  await fetchUserData(); // refresh dashboard
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please log in again to continue.')),
                  );
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1),
                  ],
                ),
                child: const Icon(Icons.add, size: 32),
              ),
            ),
            const SizedBox(height: 8),
            Text('Add ID', style: TextStyle(color: textColor)),
          ],
        ),
      ],
    );
  }

  Widget buildDashboardContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.white70 : Colors.grey;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
          child: Row(
            children: const [
              Icon(Icons.badge, color: Colors.white, size: 32),
              SizedBox(width: 10),
              Text(
                'OneID',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildProfileHeader(textColor, secondaryColor),
                      const SizedBox(height: 28),
                      buildIdTiles(),
                      const SizedBox(height: 40),
                      buildQrAndAddIdSection(textColor, isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF107A61),
      body: isLoading ? buildLoadingShimmer() : buildDashboardContent(),
    );
  }
}
