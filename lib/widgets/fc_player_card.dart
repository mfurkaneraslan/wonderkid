import 'package:flutter/material.dart';

import '../career/career_profile.dart';

class FcPlayerCard extends StatelessWidget {
  const FcPlayerCard({super.key, required this.profile});

  final CareerProfile profile;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF2B1803);
    const designWidth = 310.0;
    const designHeight = designWidth * 1460 / 1086;
    return AspectRatio(
      key: const Key('fcPlayerCard'),
      aspectRatio: 1086 / 1460,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: designWidth,
          height: designHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0xFF071A12),
                  BlendMode.lighten,
                ),
                child: Image.asset(
                  profile.avatarAssetPath,
                  fit: BoxFit.contain,
                  cacheWidth: 620,
                ),
              ),
              Positioned(
                left: 47,
                top: 60,
                child: Column(
                  children: [
                    Text(
                      '${profile.overall}',
                      key: const Key('cardOverall'),
                      style: const TextStyle(
                        color: ink,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        shadows: [
                          Shadow(color: ink, offset: Offset(0.35, 0)),
                          Shadow(color: ink, offset: Offset(-0.35, 0)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.position,
                      key: const Key('cardPosition'),
                      style: const TextStyle(
                        color: ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        shadows: [
                          Shadow(color: ink, offset: Offset(0.3, 0)),
                          Shadow(color: ink, offset: Offset(-0.3, 0)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 48,
                right: 48,
                top: 267,
                bottom: 58,
                child: Column(
                  children: [
                    SizedBox(
                      height: 16,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          profile.name.toUpperCase(),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            shadows: [
                              Shadow(color: ink, offset: Offset(0.3, 0)),
                              Shadow(color: ink, offset: Offset(-0.3, 0)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(height: 1, color: ink.withValues(alpha: 0.28)),
                    const SizedBox(height: 5),
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
        ),
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
          formatCareerAttribute(stat.value),
          style: const TextStyle(
            color: Color(0xFF2B1803),
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          stat.label,
          style: TextStyle(
            color: const Color(0xFF2B1803).withValues(alpha: 0.72),
            fontSize: 12,
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
  final double value;
}
