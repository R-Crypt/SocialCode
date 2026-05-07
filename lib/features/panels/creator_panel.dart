import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:social_code/core/theme/app_theme.dart';
import 'package:social_code/features/challenges/bloc/challenges_bloc.dart';
import 'package:social_code/models/app_user.dart';
import 'package:social_code/models/challenge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_code/core/widgets/challenge_image_picker.dart';

class CreatorPanel extends StatefulWidget {
  final AppUser user;
  const CreatorPanel({super.key, required this.user});

  @override
  State<CreatorPanel> createState() => _CreatorPanelState();
}

class _CreatorPanelState extends State<CreatorPanel> {
  @override
  void initState() {
    super.initState();
    context.read<ChallengesBloc>().add(LoadChallenges());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CREATOR HUB',
                  style: GoogleFonts.outfit(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textMain)),
              const SizedBox(height: 4),
              Text('BUILD YOUR LEGACY. SPARK THE MOVEMENT.',
                  style: GoogleFonts.spaceMono(
                      color: AppTheme.textMain.withOpacity(0.4),
                      fontWeight: FontWeight.bold,
                      fontSize: 10)),
              const SizedBox(height: 28),

              // Quick stats
              BlocBuilder<ChallengesBloc, ChallengesState>(
                builder: (context, state) {
                  final myCount = state is ChallengesLoaded
                      ? state.challenges
                          .where((c) => c.creatorId == widget.user.id)
                          .length
                      : 0;
                  final totalImpact = state is ChallengesLoaded
                      ? state.challenges
                          .where((c) => c.creatorId == widget.user.id)
                          .fold(0, (sum, c) => sum + c.currentCount)
                      : 0;
                  return Row(
                    children: [
                      _StatCard('MY CODES', '$myCount', AppTheme.accentPurple),
                      const SizedBox(width: 16),
                      _StatCard('TOTAL IMPACT', '$totalImpact', AppTheme.primaryMagenta),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // Action buttons
              _ActionButton(
                title: 'NEW IMPACT CHALLENGE',
                subtitle: 'LAUNCH A CODE FOR THE CITY',
                icon: Icons.add_circle,
                color: AppTheme.primaryMagenta,
                onTap: () => _showCreateForm(context),
              ),
              const SizedBox(height: 12),

              // My challenges
              const SizedBox(height: 20),
              Text('MY CHALLENGES',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 12),

              BlocBuilder<ChallengesBloc, ChallengesState>(
                builder: (context, state) {
                  if (state is ChallengesLoading) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryMagenta));
                  }
                  if (state is ChallengesLoaded) {
                    final mine = state.challenges
                        .where((c) => c.creatorId == widget.user.id)
                        .toList();
                    if (mine.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppTheme.textMain.withOpacity(0.2)),
                        ),
                        child: Center(
                          child: Text(
                            'NO CHALLENGES YET.\nCREATE YOUR FIRST CODE.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceMono(
                                color: AppTheme.textMain.withOpacity(0.4),
                                fontWeight: FontWeight.bold,
                                fontSize: 11),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: mine.length,
                      itemBuilder: (ctx, i) => _MyChallengeItem(
                        challenge: mine[i],
                        onEdit: () => _showCreateForm(context, existing: mine[i]),
                        onDelete: () async {
                          try {
                            await Supabase.instance.client.from('challenges').delete().eq('id', mine[i].id);
                            if (mounted) {
                              context.read<ChallengesBloc>().add(LoadChallenges());
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Challenge deleted')));
                            }
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red));
                          }
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateForm(BuildContext context, {Challenge? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final briefingCtrl = TextEditingController(text: existing?.missionBriefing ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? 'Bengaluru');
    final pointsCtrl = TextEditingController(text: '${existing?.pointsReward ?? 50}');
    final targetCtrl = TextEditingController(text: '${existing?.targetCount ?? 100}');
    ChallengeCategory selectedCategory = existing?.category ?? ChallengeCategory.environment;
    String? selectedImageUrl = existing?.imageUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(existing == null ? 'CREATE CHALLENGE' : 'EDIT CHALLENGE',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900, fontSize: 22)),
                const SizedBox(height: 20),

                // Image picker
                ChallengeImagePicker(
                  initialImageUrl: existing?.imageUrl,
                  onUploaded: (url) => selectedImageUrl = url,
                ),
                const SizedBox(height: 16),

                _FormField(controller: titleCtrl, label: 'CHALLENGE TITLE'),
                const SizedBox(height: 12),
                _FormField(controller: descCtrl, label: 'DESCRIPTION', maxLines: 2),
                const SizedBox(height: 12),
                _FormField(controller: briefingCtrl, label: 'MISSION BRIEFING', maxLines: 3),
                const SizedBox(height: 12),

                // Category
                Text('CATEGORY',
                    style: GoogleFonts.spaceMono(
                        fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ChallengeCategory.values.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setModal(() => selectedCategory = cat),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryMagenta
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryMagenta
                                  : AppTheme.textMain,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            cat.name.toUpperCase(),
                            style: GoogleFonts.spaceMono(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppTheme.textMain,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: _FormField(controller: pointsCtrl, label: 'POINTS', keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _FormField(controller: targetCtrl, label: 'TARGET', keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                _FormField(controller: cityCtrl, label: 'CITY'),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      final isEditing = existing != null;
                      
                      try {
                        if (isEditing) {
                          await Supabase.instance.client.from('challenges').update({
                            'title': titleCtrl.text.trim(),
                            'description': descCtrl.text.trim(),
                            'mission_briefing': briefingCtrl.text.trim(),
                            'points_reward': int.tryParse(pointsCtrl.text) ?? 50,
                            'category': selectedCategory.name,
                            'city': cityCtrl.text.trim(),
                            'target_count': int.tryParse(targetCtrl.text) ?? 100,
                            if (selectedImageUrl != null) 'image_url': selectedImageUrl,
                          }).eq('id', existing.id);
                        } else {
                          final challenge = Challenge(
                            id: '',
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            missionBriefing: briefingCtrl.text.trim(),
                            creatorId: widget.user.id,
                            creatorName: widget.user.displayName,
                            startDate: DateTime.now(),
                            endDate: DateTime.now().add(const Duration(days: 30)),
                            pointsReward: int.tryParse(pointsCtrl.text) ?? 50,
                            category: selectedCategory,
                            city: cityCtrl.text.trim(),
                            targetCount: int.tryParse(targetCtrl.text) ?? 100,
                            status: ChallengeStatus.pending,
                            imageUrl: selectedImageUrl,
                          );
                          await Supabase.instance.client.from('challenges').insert(challenge.toMap());
                        }
                        
                        if (mounted) {
                          context.read<ChallengesBloc>().add(LoadChallenges());
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Challenge updated!' : 'Challenge submitted for review!')));
                        }
                      } catch (e) {
                         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    child: Text(existing == null ? 'LAUNCH CHALLENGE →' : 'SAVE CHANGES →'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain.withOpacity(0.4))),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.spaceMono(
                    fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.textMain, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                border: Border.all(color: color, width: 1.5),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.spaceMono(
                          fontWeight: FontWeight.w900, fontSize: 12)),
                  Text(subtitle,
                      style: TextStyle(
                          color: AppTheme.textMain.withOpacity(0.4),
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }
}

class _MyChallengeItem extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _MyChallengeItem({required this.challenge, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.textMain, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(challenge.title.toUpperCase(),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14)),
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onEdit,
                ),
              const SizedBox(width: 8),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${challenge.currentCount}/${challenge.targetCount} PROOFS',
                  style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: AppTheme.primaryMagenta,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Text('${challenge.daysRemaining} DAYS LEFT',
                  style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: AppTheme.textMain.withOpacity(0.4),
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: challenge.status == ChallengeStatus.active
                      ? Colors.green.withOpacity(0.1)
                      : challenge.status == ChallengeStatus.pending 
                          ? Colors.purple.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                  border: Border.all(
                    color: challenge.status == ChallengeStatus.active
                        ? Colors.green
                        : challenge.status == ChallengeStatus.pending
                            ? Colors.purple
                            : Colors.orange,
                  ),
                ),
                child: Text(
                  challenge.status.name.toUpperCase(),
                  style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: challenge.status == ChallengeStatus.active
                          ? Colors.green
                          : Colors.orange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: challenge.progressPercent,
            minHeight: 5,
            backgroundColor: AppTheme.textMain.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryMagenta),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;
  const _FormField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppTheme.textMain, width: 2)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppTheme.primaryMagenta, width: 2)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
