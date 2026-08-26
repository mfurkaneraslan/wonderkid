import 'package:flutter/material.dart';

import 'career/career_profile.dart';
import 'career/offer_generator.dart';
import 'club_offers_screen.dart';
import 'data/football_repository.dart';

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
        leading: IconButton(
          key: const Key('backFromConfirmationButton'),
          tooltip: 'Geri',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'OYUNCUNU ONAYLA',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        centerTitle: true,
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
                    constraints: const BoxConstraints(maxWidth: 310),
                    child: _FcPlayerCard(profile: widget.profile),
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

class _FcPlayerCard extends StatelessWidget {
  const _FcPlayerCard({required this.profile});

  final CareerProfile profile;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF2B1803);
    return AspectRatio(
      key: const Key('fcPlayerCard'),
      aspectRatio: 1086 / 1460,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            profile.avatarAssetPath,
            fit: BoxFit.contain,
            cacheWidth: 620,
          ),
          Positioned(
            left: 48,
            top: 48,
            child: Column(
              children: [
                Text(
                  '${profile.overall}',
                  key: const Key('cardOverall'),
                  style: const TextStyle(
                    color: ink,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.position,
                  key: const Key('cardPosition'),
                  style: const TextStyle(
                    color: ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 48,
            right: 48,
            top: 265,
            bottom: 64,
            child: Column(
              children: [
                Text(
                  profile.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Container(height: 1, color: ink.withValues(alpha: 0.28)),
                const SizedBox(height: 7),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatColumn(
                          stats: [
                            _CardStat('PAC', profile.pace),
                            _CardStat('SHO', profile.shooting),
                            _CardStat('PAS', profile.passing),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: ink.withValues(alpha: 0.22),
                      ),
                      Expanded(
                        child: _StatColumn(
                          stats: [
                            _CardStat('DRI', profile.dribbling),
                            _CardStat('DEF', profile.defending),
                            _CardStat('PHY', profile.physical),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.stats});

  final List<_CardStat> stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final stat in stats)
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _StatLine(stat: stat),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.stat});

  final _CardStat stat;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${stat.value}',
          style: const TextStyle(
            color: Color(0xFF2B1803),
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          stat.label,
          style: TextStyle(
            color: const Color(0xFF2B1803).withValues(alpha: 0.72),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CardStat {
  const _CardStat(this.label, this.value);

  final String label;
  final int value;
}
