import 'package:flutter/material.dart';

import 'career/career_profile.dart';
import 'career/career_save_repository.dart';
import 'career/offer_generator.dart';
import 'career_dashboard_screen.dart';
import 'data/football_repository.dart';

String _formatEuro(int amount) {
  var remaining = amount.toString();
  final groups = <String>[];
  while (remaining.length > 3) {
    groups.insert(0, remaining.substring(remaining.length - 3));
    remaining = remaining.substring(0, remaining.length - 3);
  }
  groups.insert(0, remaining);
  return '€${groups.join('.')}';
}

class ClubOffersScreen extends StatefulWidget {
  const ClubOffersScreen({
    super.key,
    required this.profile,
    required this.offers,
  });

  final CareerProfile profile;
  final List<ClubOffer> offers;

  @override
  State<ClubOffersScreen> createState() => _ClubOffersScreenState();
}

class _ClubOffersScreenState extends State<ClubOffersScreen> {
  static const _accent = Color(0xFFC8FF4D);
  ClubOffer? _selectedOffer;

  Future<void> _acceptOffer() async {
    final offer = _selectedOffer;
    if (offer == null) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF10291C),
        title: const Text('Teklifi kabul et?'),
        content: Text(
          '${offer.club.name} ile ${offer.contractYears} yıllık sözleşme imzalayacaksın.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('VAZGEÇ'),
          ),
          FilledButton(
            key: const Key('signContractButton'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('İMZALA'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    await CareerSaveRepository.save(profile: widget.profile, offer: offer);
    if (!mounted) return;
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) =>
            CareerDashboardScreen(profile: widget.profile, offer: offer),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071A12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          key: const Key('backFromOffersButton'),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Geri',
        ),
        title: const Text(
          'KULÜP TEKLİFLERİ',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PlayerSummary(profile: widget.profile),
                  const SizedBox(height: 12),
                  const Text(
                    '3 kulüp seni kadrosuna katmak istiyor.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final offer in widget.offers) ...[
                    _OfferCard(
                      offer: offer,
                      selected: _selectedOffer == offer,
                      onTap: () => setState(() => _selectedOffer = offer),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                key: const Key('acceptOfferButton'),
                onPressed: _selectedOffer == null ? null : _acceptOffer,
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                  foregroundColor: const Color(0xFF0A2116),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'TEKLİFİ KABUL ET',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
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

class _PlayerSummary extends StatelessWidget {
  const _PlayerSummary({required this.profile});

  final CareerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.asset(
                      profile.avatarAssetPath,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      cacheWidth: 156,
                    ),
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8FF4D),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF10291C),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '${profile.overall}',
                      style: const TextStyle(
                        color: Color(0xFF092115),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${profile.age} yaş  •  ${profile.position}  •  #${profile.shirtNumber}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
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

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.selected,
    required this.onTap,
  });

  final ClubOffer offer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFFC8FF4D).withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.045),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: Key('offer_${offer.club.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFFC8FF4D)
                  : Colors.white.withValues(alpha: 0.08),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ClubLogo(club: offer.club),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.club.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${offer.league.country} • ${offer.league.name}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _TeamRating(rating: offer.club.rating, selected: selected),
                ],
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _InfoChip(label: offer.role),
                  _InfoChip(label: '${offer.contractYears} yıl'),
                  _InfoChip(
                    label: '${_formatEuro(offer.weeklySalaryEuro)} / hafta',
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                'POZİSYON RAKİPLERİ',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.38),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              for (final competitor in offer.competitors)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          competitor.shortName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      Text(
                        '${competitor.overall}',
                        style: const TextStyle(
                          color: Color(0xFFC8FF4D),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClubLogo extends StatelessWidget {
  const _ClubLogo({required this.club});

  final CareerClub club;

  @override
  Widget build(BuildContext context) {
    final initials = club.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(5),
      child: Image.asset(
        'assets/clubs/${club.id}.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Center(
          child: Text(
            initials,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

class _TeamRating extends StatelessWidget {
  const _TeamRating({required this.rating, required this.selected});

  final int rating;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFFC8FF4D)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '$rating',
            style: TextStyle(
              color: selected ? const Color(0xFF092115) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'TAKIM',
            style: TextStyle(
              color: selected
                  ? const Color(0xFF092115).withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.4),
              fontSize: 7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.72),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
