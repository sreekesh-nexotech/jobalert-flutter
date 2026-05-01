import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/listings_repository.dart';
import '../../data/models/listing.dart';
import '../listings_controller.dart';

/// Bottom sheet for creating a new listing — 4 steps + done view, plus a
/// "pending review" interlock if the user already has a previous submission
/// awaiting moderation. Mirrors `PlusSheet` in `Job Alert App - Main.html`.
class PlusSheet extends ConsumerStatefulWidget {
  const PlusSheet({super.key});

  @override
  ConsumerState<PlusSheet> createState() => _PlusSheetState();
}

class _PlusSheetState extends ConsumerState<PlusSheet> {
  /// step values: 1..4 for the wizard, 'pending' / 'done' for terminal screens.
  Object _step = 1;

  ListingType? _type;
  final _form = <String, String>{};
  final _tags = <String>[];
  final _tagCtl = TextEditingController();
  bool _submitting = false;

  static const _categories = [
    'Design', 'Engineering', 'Marketing', 'Media', 'Finance',
    'Healthcare', 'Education', 'HR & Recruitment', 'Sales', 'Operations',
  ];
  static const _expOpts = ['Fresher', '1–3 yrs', '3–5 yrs', '5+ yrs'];
  static const _bizTypes = ['Franchise', 'Investment', 'Channel Partner', 'Joint Venture'];

  @override
  void initState() {
    super.initState();
    // Check if the user has a pending listing that blocks them from posting again.
    Future.microtask(() async {
      try {
        final res = await ref.read(listingsRepositoryProvider).canSubmit();
        if ((res['can_submit'] as bool?) == false && mounted) {
          setState(() => _step = 'pending');
        }
      } catch (_) {/* fail open */}
    });
  }

  @override
  void dispose() {
    _tagCtl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step is int) {
      final s = _step as int;
      if (s == 1 && _type == null) return;
      if (s < 4) {
        setState(() => _step = s + 1);
      } else {
        _submit();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final payload = <String, dynamic>{
      'title': _form['title'] ?? '',
      'category': _form['cat'] ?? '',
      'sub_category': _form['sub'] ?? '',
      'description': _form['desc'] ?? '',
      'tags': _tags.map((t) => t.startsWith('#') ? t : '#$t').toList(),
      'source_url': _form['src'] ?? '',
      if (_type == ListingType.job) 'location': _form['loc'] ?? '',
      if (_type == ListingType.job)
        'experience_level': _wireExp(_form['exp'] ?? ''),
      if (_type == ListingType.job) 'salary_display': _form['salary'] ?? '',
      if (_type == ListingType.job && (_form['deadline'] ?? '').isNotEmpty)
        'application_deadline': _form['deadline'],
      if (_type == ListingType.biz)
        'opportunity_type': _wireOpportunity(_form['loc'] ?? ''),
      if (_type == ListingType.biz) 'venue': _form['venue'] ?? '',
      if (_type == ListingType.biz) 'investment_display': _form['investment'] ?? '',
      if (_type == ListingType.biz) 'date_info': _form['date'] ?? '',
    };
    try {
      await ref.read(listingsRepositoryProvider).createListing(
            type: _type ?? ListingType.job,
            payload: payload,
          );
      if (mounted) setState(() => _step = 'done');
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _wireExp(String label) => switch (label) {
        'Fresher' => 'fresher',
        '1–3 yrs' => '1-3_yrs',
        '3–5 yrs' => '3-5_yrs',
        '5+ yrs' => '5+_yrs',
        _ => '',
      };

  String _wireOpportunity(String label) => switch (label) {
        'Franchise' => 'franchise',
        'Investment' => 'investment',
        'Channel Partner' => 'channel_partner',
        'Joint Venture' => 'joint_venture',
        _ => 'other',
      };

  void _addTag() {
    final t = _tagCtl.text.trim().replaceFirst(RegExp(r'^#'), '');
    if (t.isNotEmpty && !_tags.contains(t)) setState(() => _tags.add(t));
    _tagCtl.clear();
  }

  String get _actionLabel {
    if (_step == 'pending' || _step == 'done') return 'Okay';
    if (_step == 4) return _submitting ? 'Submitting…' : 'Submit ✓';
    return 'Next →';
  }

  String get _title {
    if (_step == 'pending') return 'Post pending ⏳';
    if (_step == 'done') return 'All done!';
    return switch (_step as int) {
      1 => 'What are you posting?',
      2 => 'Basic details',
      3 => 'Specific info',
      _ => 'Description & tags',
    };
  }

  String get _subtitle {
    if (_step == 'pending') return 'You have a listing under review';
    if (_step == 'done') return '';
    return switch (_step as int) {
      1 => 'Choose listing type',
      2 => 'Fill in the basics',
      3 => 'Add relevant details',
      _ => 'Almost there!',
    };
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: size.height * 0.78),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(_title, style: AppText.h3.copyWith(fontSize: 16))),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(999),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close, size: 18, color: AppColors.ink500),
                        ),
                      ),
                    ],
                  ),
                  if (_subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(_subtitle,
                        style: AppText.captionMuted.copyWith(fontSize: 12, color: AppColors.ink400)),
                  ],
                  if (_step is int) ...[
                    const SizedBox(height: 10),
                    _StepDots(current: _step as int),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.ink50),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: _stepContent(),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.ink50),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink900,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: Text(
                      _actionLabel,
                      style: AppText.button.copyWith(fontSize: 14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepContent() {
    if (_step == 'pending') return _PendingView();
    if (_step == 'done') return _DoneView();
    final s = _step as int;
    return switch (s) {
      1 => _Step1Type(value: _type, onChange: (v) => setState(() => _type = v)),
      2 => _Step2Basic(form: _form, categories: _categories),
      3 => _type == ListingType.job
          ? _Step3Job(form: _form, expOpts: _expOpts, onSetState: setState)
          : _Step3Biz(form: _form, bizTypes: _bizTypes, onSetState: setState),
      _ => _Step4Final(
          form: _form,
          tags: _tags,
          tagCtl: _tagCtl,
          onAddTag: _addTag,
          onRemoveTag: (t) => setState(() => _tags.remove(t)),
        ),
    };
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) {
        final s = i + 1;
        final active = s == current;
        final done = s < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(right: i == 3 ? 0 : 5),
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? AppColors.ink900
                : done
                    ? AppColors.sage
                    : const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _Step1Type extends StatelessWidget {
  const _Step1Type({required this.value, required this.onChange});
  final ListingType? value;
  final ValueChanged<ListingType> onChange;

  @override
  Widget build(BuildContext context) {
    Widget card(ListingType t, String emoji, String label, String sub) {
      final selected = value == t;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChange(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? Colors.white : AppColors.surfaceMuted,
              border: Border.all(
                color: selected ? AppColors.ink900 : AppColors.outline,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                Text(label, style: AppText.body.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(sub, style: AppText.captionMuted.copyWith(fontSize: 11, color: AppColors.ink400)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card(ListingType.job, '💼', 'Job Opening', 'Share a job role'),
        const SizedBox(width: 12),
        card(ListingType.biz, '📊', 'Biz Opportunity', 'Franchise, Investment…'),
      ],
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.label,
    required this.field,
    required this.form,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.formatters,
  });
  final String label;
  final String field;
  final Map<String, String> form;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 5),
          child: Text(
            label,
            style: AppText.formLabel.copyWith(fontSize: 12, color: AppColors.ink700),
          ),
        ),
        TextFormField(
          initialValue: form[field],
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          onChanged: (v) => form[field] = v,
          style: AppText.body.copyWith(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.captionMuted.copyWith(fontSize: 13, color: AppColors.ink400),
            isDense: true,
            filled: true,
            fillColor: AppColors.surfaceMuted,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.ink900, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _Step2Basic extends StatelessWidget {
  const _Step2Basic({required this.form, required this.categories});
  final Map<String, String> form;
  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SheetField(
          label: 'Title',
          field: 'title',
          form: form,
          hint: 'e.g. Senior iOS Developer at Zomato',
        ),
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 5),
          child: Text('Category', style: AppText.formLabel.copyWith(fontSize: 12, color: AppColors.ink700)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: form['cat']?.isEmpty ?? true ? null : form['cat'],
              isExpanded: true,
              hint: Text(
                'Select category',
                style: AppText.captionMuted.copyWith(fontSize: 13, color: AppColors.ink400),
              ),
              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => form['cat'] = v ?? '',
            ),
          ),
        ),
        _SheetField(
          label: 'Sub-category',
          field: 'sub',
          form: form,
          hint: 'e.g. Mobile Development / QSR Franchise',
        ),
        _SheetField(
          label: 'Source / Apply link',
          field: 'src',
          form: form,
          hint: 'https://...',
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }
}

class _Step3Job extends StatelessWidget {
  const _Step3Job({required this.form, required this.expOpts, required this.onSetState});
  final Map<String, String> form;
  final List<String> expOpts;
  // ignore: avoid_positional_boolean_parameters
  final void Function(VoidCallback) onSetState;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SheetField(
          label: 'Location',
          field: 'loc',
          form: form,
          hint: 'Remote / Bengaluru / Mumbai…',
        ),
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 5),
          child: Text(
            'Experience level',
            style: AppText.formLabel.copyWith(fontSize: 12, color: AppColors.ink700),
          ),
        ),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: expOpts.map((o) {
            final selected = form['exp'] == o;
            return GestureDetector(
              onTap: () => onSetState(() => form['exp'] = o),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.ink900 : Colors.white,
                  border: Border.all(
                    color: selected ? AppColors.ink900 : const Color(0xFFEEEEEE),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  o,
                  style: AppText.captionMuted.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : const Color(0xFF555555),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        _SheetField(
          label: 'Salary range (optional)',
          field: 'salary',
          form: form,
          hint: 'e.g. ₹8L – ₹14L / yr',
        ),
        _SheetField(
          label: 'Application deadline',
          field: 'deadline',
          form: form,
          hint: 'YYYY-MM-DD',
        ),
      ],
    );
  }
}

class _Step3Biz extends StatelessWidget {
  const _Step3Biz({required this.form, required this.bizTypes, required this.onSetState});
  final Map<String, String> form;
  final List<String> bizTypes;
  final void Function(VoidCallback) onSetState;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(
            'Opportunity type',
            style: AppText.formLabel.copyWith(fontSize: 12, color: AppColors.ink700),
          ),
        ),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: bizTypes.map((o) {
            final selected = form['loc'] == o;
            return GestureDetector(
              onTap: () => onSetState(() => form['loc'] = o),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.ink900 : Colors.white,
                  border: Border.all(
                    color: selected ? AppColors.ink900 : const Color(0xFFEEEEEE),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  o,
                  style: AppText.captionMuted.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : const Color(0xFF555555),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        _SheetField(
          label: 'Venue / Location',
          field: 'venue',
          form: form,
          hint: 'Pan India / Chennai / Remote…',
        ),
        _SheetField(
          label: 'Investment range',
          field: 'investment',
          form: form,
          hint: 'e.g. ₹10L – ₹50L',
        ),
        _SheetField(
          label: 'Date / Deadline',
          field: 'date',
          form: form,
          hint: 'Ongoing / Closes 20 May 2026',
        ),
      ],
    );
  }
}

class _Step4Final extends StatelessWidget {
  const _Step4Final({
    required this.form,
    required this.tags,
    required this.tagCtl,
    required this.onAddTag,
    required this.onRemoveTag,
  });
  final Map<String, String> form;
  final List<String> tags;
  final TextEditingController tagCtl;
  final VoidCallback onAddTag;
  final ValueChanged<String> onRemoveTag;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SheetField(
          label: 'Description',
          field: 'desc',
          form: form,
          hint: "Describe the role, responsibilities, what's on offer…",
          maxLines: 4,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 5),
          child: Text(
            'Tags',
            style: AppText.formLabel.copyWith(fontSize: 12, color: AppColors.ink700),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: tagCtl,
                  onSubmitted: (_) => onAddTag(),
                  style: AppText.body.copyWith(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: '#RemoteWork',
                    hintStyle: AppText.captionMuted.copyWith(fontSize: 12),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: AppColors.ink900, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onAddTag,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink900,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: Text('Add', style: AppText.body.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags
                .map(
                  (t) => Container(
                    padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('#$t', style: AppText.captionMuted.copyWith(fontSize: 12, color: AppColors.ink700)),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => onRemoveTag(t),
                          child: const Icon(Icons.close, size: 14, color: AppColors.ink400),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "✅ Your listing will be reviewed by our team before going live.\n📬 You'll be notified once approved.",
            style: AppText.captionMuted.copyWith(fontSize: 11, color: AppColors.ink400, height: 1.6),
          ),
        ),
      ],
    );
  }
}

class _PendingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Text('⏳', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Already submitted!', style: AppText.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            'Your previous post is pending admin approval. Please wait before submitting another to avoid spam.',
            style: AppText.captionMuted.copyWith(fontSize: 13, color: AppColors.ink400, height: 1.55),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DoneView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.sageBg,
              borderRadius: BorderRadius.circular(34),
            ),
            child: const Icon(Icons.check, size: 32, color: AppColors.sage),
          ),
          const SizedBox(height: 16),
          Text('Submitted for review!', style: AppText.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              'Our team will verify your listing. Approved posts earn you points.',
              style: AppText.captionMuted.copyWith(fontSize: 13, color: AppColors.ink400, height: 1.55),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.peachBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '🏅 +50 points on approval',
              style: AppText.captionMuted.copyWith(
                fontSize: 12,
                color: AppColors.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
