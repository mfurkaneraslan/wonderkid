import 'package:flutter/material.dart';

import 'career/career_profile.dart';
import 'career/offer_generator.dart';
import 'club_offers_screen.dart';
import 'data/football_repository.dart';

class CreateCareerScreen extends StatefulWidget {
  const CreateCareerScreen({super.key});

  @override
  State<CreateCareerScreen> createState() => _CreateCareerScreenState();
}

class _CreateCareerScreenState extends State<CreateCareerScreen> {
  static const _accent = Color(0xFFC8FF4D);
  static const _nationalities = [
    'Türkiye',
    'Almanya',
    'Arjantin',
    'Belçika',
    'Brezilya',
    'Danimarka',
    'Fas',
    'Fransa',
    'Hırvatistan',
    'Hollanda',
    'İngiltere',
    'İspanya',
    'İsveç',
    'İtalya',
    'Japonya',
    'Kolombiya',
    'Meksika',
    'Norveç',
    'Polonya',
    'Portekiz',
    'Senegal',
    'Sırbistan',
    'Uruguay',
    'ABD',
  ];

  final _nameController = TextEditingController();
  String? _nationality;
  int? _shirtNumber;
  String? _position;
  bool _isCreatingOffers = false;

  bool get _canContinue =>
      _nameController.text.trim().length >= 2 &&
      _nationality != null &&
      _shirtNumber != null &&
      _position != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    setState(() => _isCreatingOffers = true);
    try {
      final dataset = await FootballRepository.load();
      final profile = CareerProfile.create(
        name: _nameController.text.trim(),
        nationality: _nationality!,
        shirtNumber: _shirtNumber!,
        position: _position!,
      );
      final offers = CareerOfferEngine.generate(
        dataset: dataset,
        profile: profile,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ClubOffersScreen(profile: profile, offers: offers),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF183A29),
          content: const Text('Kulüp verileri yüklenemedi. Tekrar dene.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCreatingOffers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071A12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Geri',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'YENİ KARİYER',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: const Key('playerNameField'),
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    maxLength: 24,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    decoration: _inputDecoration(hintText: 'Ad')
                        .copyWith(counterText: ''),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: const Key('nationalityField'),
                          initialValue: _nationality,
                          isExpanded: true,
                          menuMaxHeight: 360,
                          dropdownColor: const Color(0xFF143323),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          hint: Text(
                            'Uyruk',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.38),
                            ),
                          ),
                          decoration: _inputDecoration(),
                          items: _nationalities
                              .map(
                                (country) => DropdownMenuItem(
                                  value: country,
                                  child: Text(
                                    country,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _nationality = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          key: const Key('shirtNumberField'),
                          initialValue: _shirtNumber,
                          isExpanded: true,
                          menuMaxHeight: 360,
                          dropdownColor: const Color(0xFF143323),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          hint: Text(
                            'Forma No',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.38),
                            ),
                          ),
                          decoration: _inputDecoration(),
                          items: List.generate(
                            99,
                            (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text('${index + 1}'),
                            ),
                          ),
                          onChanged: (value) =>
                              setState(() => _shirtNumber = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pozisyonunu seç',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _position == null
                            ? const SizedBox.shrink()
                            : Container(
                                key: ValueKey(_position),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _accent.withValues(alpha: 0.13),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _position!,
                                  style: const TextStyle(
                                    color: _accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _PositionPitch(
                    selectedPosition: _position,
                    onSelected: (value) => setState(() => _position = value),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                key: const Key('continueButton'),
                onPressed: _canContinue && !_isCreatingOffers
                    ? _continue
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                  foregroundColor: const Color(0xFF0A2116),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isCreatingOffers
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Color(0xFF0A2116),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'DEVAM ET',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.055),
      contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.09)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
    );
  }
}

class _PositionPitch extends StatelessWidget {
  const _PositionPitch({
    required this.selectedPosition,
    required this.onSelected,
  });

  static const _positions = <_PositionNode>[
    _PositionNode('ST', 0.50, 0.08),
    _PositionNode('LW', 0.18, 0.20),
    _PositionNode('RW', 0.82, 0.20),
    _PositionNode('CAM', 0.50, 0.31),
    _PositionNode('LM', 0.17, 0.40),
    _PositionNode('RM', 0.83, 0.40),
    _PositionNode('CM', 0.50, 0.48),
    _PositionNode('CDM', 0.50, 0.61),
    _PositionNode('LB', 0.15, 0.73),
    _PositionNode('CB', 0.50, 0.76),
    _PositionNode('RB', 0.85, 0.73),
    _PositionNode('GK', 0.50, 0.91),
  ];

  final String? selectedPosition;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.78,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF0E442A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const nodeWidth = 54.0;
            const nodeHeight = 38.0;
            return Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _CareerPitchPainter()),
                ),
                for (final node in _positions)
                  Positioned(
                    left: constraints.maxWidth * node.x - nodeWidth / 2,
                    top: constraints.maxHeight * node.y - nodeHeight / 2,
                    width: nodeWidth,
                    height: nodeHeight,
                    child: _PositionButton(
                      label: node.label,
                      selected: selectedPosition == node.label,
                      onTap: () => onSelected(node.label),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PositionNode {
  const _PositionNode(this.label, this.x, this.y);

  final String label;
  final double x;
  final double y;
}

class _PositionButton extends StatelessWidget {
  const _PositionButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: '$label pozisyonu',
      child: Material(
        color: selected ? const Color(0xFFC8FF4D) : const Color(0xE61A3526),
        borderRadius: BorderRadius.circular(12),
        elevation: selected ? 8 : 0,
        shadowColor: const Color(0xFFC8FF4D).withValues(alpha: 0.5),
        child: InkWell(
          key: Key('position_$label'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFF092115) : Colors.white,
                fontSize: label.length > 2 ? 11 : 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CareerPitchPainter extends CustomPainter {
  const _CareerPitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stripe = Paint()..color = Colors.white.withValues(alpha: 0.022);
    for (var i = 0; i < 8; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(0, size.height * i / 8, size.width, size.height / 8),
        stripe,
      );
    }

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final field = Rect.fromLTWH(14, 14, size.width - 28, size.height - 28);
    canvas.drawRect(field, line);
    canvas.drawLine(
      Offset(field.left, field.center.dy),
      Offset(field.right, field.center.dy),
      line,
    );
    canvas.drawCircle(field.center, size.width * 0.16, line);
    canvas.drawCircle(field.center, 2.5, line);

    final penaltyWidth = size.width * 0.52;
    final penaltyHeight = size.height * 0.14;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(field.center.dx, field.top),
        width: penaltyWidth,
        height: penaltyHeight,
      ),
      line,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(field.center.dx, field.bottom),
        width: penaltyWidth,
        height: penaltyHeight,
      ),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
