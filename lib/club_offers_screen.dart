import 'package:flutter/material.dart';

import 'career/career_profile.dart';
import 'career/offer_generator.dart';

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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ContractSignedScreen(profile: widget.profile, offer: offer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071A12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PlayerSummary(profile: widget.profile),
                  const SizedBox(height: 22),
                  const Text(
                    '3 kulüp seni kadrosuna katmak istiyor.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Teklifi seçmeden önce forma rekabetini incele.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.48),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final offer in widget.offers) ...[
                    _OfferCard(
                      offer: offer,
                      selected: _selectedOffer == offer,
                      onTap: () => setState(() => _selectedOffer = offer),
                    ),
                    const SizedBox(height: 12),
                  ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFC8FF4D),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${profile.overall}',
                style: const TextStyle(
                  color: Color(0xFF092115),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
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
          padding: const EdgeInsets.all(16),
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
                  _ClubMonogram(name: offer.club.name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.club.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${offer.league.country} • ${offer.league.name}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFFC8FF4D),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(label: 'Takım ${offer.club.rating}'),
                  _InfoChip(label: offer.role),
                  _InfoChip(label: '${offer.contractYears} yıl'),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'POZİSYON RAKİPLERİ',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.38),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              for (final competitor in offer.competitors)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          competitor.shortName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        '${competitor.overall}',
                        style: const TextStyle(
                          color: Color(0xFFC8FF4D),
                          fontSize: 12,
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

class _ClubMonogram extends StatelessWidget {
  const _ClubMonogram({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.72),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ContractSignedScreen extends StatelessWidget {
  const ContractSignedScreen({
    super.key,
    required this.profile,
    required this.offer,
  });

  final CareerProfile profile;
  final ClubOffer offer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071A12),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC8FF4D),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.done_rounded,
                      color: Color(0xFF092115),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'SÖZLEŞME İMZALANDI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${profile.name}, ${offer.club.name} ile profesyonel kariyerine başlıyor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.52),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _PlayerSummary(profile: profile),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Text(
                          offer.club.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${offer.league.name} • ${offer.role}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Kariyer merkezi sıradaki adımda eklenecek.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
