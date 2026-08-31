import 'package:flutter/material.dart';

import 'career/career_save_repository.dart';
import 'career_dashboard_screen.dart';
import 'create_career_screen.dart';

void main() {
  runApp(const WonderkidApp());
}

class WonderkidApp extends StatelessWidget {
  const WonderkidApp({super.key, this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wonderkid',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC8FF4D),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF071A12),
        useMaterial3: true,
      ),
      home: home ?? const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialCareer});

  final SavedCareer? initialCareer;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SavedCareer? _savedCareer;
  late bool _loading;

  @override
  void initState() {
    super.initState();
    _savedCareer = widget.initialCareer;
    _loading = widget.initialCareer == null;
    if (_loading) _loadCareer();
  }

  Future<void> _loadCareer() async {
    final career = await CareerSaveRepository.load();
    if (!mounted) return;
    setState(() {
      _savedCareer = career;
      _loading = false;
    });
  }

  void _continueCareer() {
    final career = _savedCareer;
    if (career == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CareerDashboardScreen(
          profile: career.profile,
          offer: career.offer,
          currentWeek: career.currentWeek,
          lastTrainingWeek: career.lastTrainingWeek,
          lastTrainingAttribute: career.lastTrainingAttribute,
          shopState: career.shopState,
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF183A29),
          content: Text('$feature yakında hazır olacak.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0D3020), Color(0xFF06140E)],
              ),
            ),
          ),
          CustomPaint(painter: const PitchPainter()),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 0.9,
                colors: [Colors.transparent, Color(0xB305100B)],
                stops: [0.2, 1],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _BrandMark(),
                      const SizedBox(height: 22),
                      const Text(
                        'WONDERKID',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 39,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 5.5,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'YOUR CAREER. YOUR LEGACY.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.54),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.4,
                        ),
                      ),
                      const SizedBox(height: 64),
                      if (_loading) ...[
                        const SizedBox(
                          height: 58,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ] else if (_savedCareer != null) ...[
                        _MenuButton(
                          label: 'KARİYERE DEVAM ET',
                          icon: Icons.play_arrow_rounded,
                          onPressed: _continueCareer,
                        ),
                        const SizedBox(height: 14),
                      ],
                      _MenuButton(
                        label: 'YENİ KARİYER',
                        icon: Icons.add_rounded,
                        isPrimary: true,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CreateCareerScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _MenuButton(
                        label: 'AYARLAR',
                        icon: Icons.tune_rounded,
                        onPressed: () => _showComingSoon(context, 'Ayarlar'),
                      ),
                      const SizedBox(height: 48),
                      Text(
                        'v0.1.0',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.28),
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFFC8FF4D),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC8FF4D).withValues(alpha: 0.22),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'W',
          style: TextStyle(
            color: Color(0xFF0B2518),
            fontSize: 44,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final foreground = isPrimary ? const Color(0xFF0A2116) : Colors.white;
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isPrimary
              ? const Color(0xFFC8FF4D)
              : Colors.white.withValues(alpha: 0.075),
          foregroundColor: foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PitchPainter extends CustomPainter {
  const PitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final fieldWidth = size.width * 1.25;
    final fieldHeight = size.height * 0.9;
    final field = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: fieldWidth,
      height: fieldHeight,
    );

    canvas.drawRect(field, paint);
    canvas.drawLine(
      Offset(field.left, field.center.dy),
      Offset(field.right, field.center.dy),
      paint,
    );
    canvas.drawCircle(field.center, size.shortestSide * 0.17, paint);
    canvas.drawCircle(field.center, 3, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;

    final boxWidth = fieldWidth * 0.42;
    final boxHeight = fieldHeight * 0.16;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(field.center.dx, field.top),
        width: boxWidth,
        height: boxHeight,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(field.center.dx, field.bottom),
        width: boxWidth,
        height: boxHeight,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
