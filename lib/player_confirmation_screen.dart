import 'package:flutter/material.dart';

import 'career/career_profile.dart';
import 'career/offer_generator.dart';
import 'club_offers_screen.dart';
import 'data/football_repository.dart';
import 'widgets/fc_player_card.dart';

class PlayerConfirmationScreen extends StatefulWidget {
  const PlayerConfirmationScreen({super.key, required this.profile});

  final CareerProfile profile;

  @override
  State<PlayerConfirmationScreen> createState() =>
      _PlayerConfirmationScreenState();
}

class _PlayerConfirmationScreenState extends State<PlayerConfirmationScreen> {
  static const _accent = Color(0xFFC8FF4D);
  bool _isConfirming = false;

  Future<void> _confirm() async {
    setState(() => _isConfirming = true);
    try {
      final dataset = await FootballRepository.load();
      final offers = CareerOfferEngine.generate(
        dataset: dataset,
        profile: widget.profile,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              ClubOffersScreen(profile: widget.profile, offers: offers),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF183A29),
          content: Text('Kulüp verileri yüklenemedi. Tekrar dene.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071A12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    key: const Key('backFromConfirmationButton'),
                    tooltip: 'Geri',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                const Text(
                  'OYUNCUNU ONAYLA',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Text(
                    'Kariyerine bu oyuncuyla başlayacaksın.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 330),
                    child: FcPlayerCard(profile: widget.profile),
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
                key: const Key('confirmPlayerButton'),
                onPressed: _isConfirming ? null : _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                  foregroundColor: const Color(0xFF0A2116),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isConfirming
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Color(0xFF0A2116),
                        ),
                      )
                    : const Text(
                        'ONAYLA',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
