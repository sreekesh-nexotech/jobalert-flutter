import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/models/auth_models.dart';
import '../auth_controller.dart';
import '../widgets/auth_widgets.dart';

const _states = <String>[
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh', 'Goa',
  'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka', 'Kerala',
  'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland',
  'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
  'Uttar Pradesh', 'Uttarakhand', 'West Bengal', 'Delhi', 'Chandigarh', 'Puducherry',
];

class DetailsScreen extends ConsumerStatefulWidget {
  const DetailsScreen({super.key});

  @override
  ConsumerState<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends ConsumerState<DetailsScreen> {
  DateTime? _dob;
  String? _state;
  String? _gender;
  bool _loading = false;
  final Map<String, String?> _errs = {};

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        _errs['dob'] = null;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _errs.clear();
      if (_dob == null) _errs['dob'] = 'Date of birth is required';
      if (_state == null) _errs['state'] = 'Please select your state';
      if (_gender == null) _errs['gender'] = 'Please select a gender';
    });
    if (_errs.values.any((v) => v != null)) return;

    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).updateUserDetails(
            dateOfBirth: DateFormat('yyyy-MM-dd').format(_dob!),
            gender: Gender.fromLabel(_gender!),
            state: _state,
          );
      if (mounted) context.push('/signup/done');
    } on ApiException catch (e) {
      setState(() => _errs['gender'] = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BackRow(onBack: () => context.pop()),
              const StepDots(total: 3, current: 2),
              Text('A bit about you', style: AppText.screenTitle),
              const SizedBox(height: 4),
              Text(
                'Helps us match you to the right opportunities',
                style: AppText.screenSubtitle,
              ),
              const SizedBox(height: 24),
              _DateField(
                value: _dob,
                error: _errs['dob'],
                onTap: _pickDob,
              ),
              const SizedBox(height: 14),
              _StateField(
                value: _state,
                error: _errs['state'],
                onChanged: (v) => setState(() {
                  _state = v;
                  _errs['state'] = null;
                }),
              ),
              const SizedBox(height: 14),
              _GenderGrid(
                value: _gender,
                error: _errs['gender'],
                onChanged: (v) => setState(() {
                  _gender = v;
                  _errs['gender'] = null;
                }),
              ),
              const SizedBox(height: 22),
              AuthPrimaryButton(
                label: 'Complete sign up',
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.error, required this.onTap});
  final DateTime? value;
  final String? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date of birth', style: AppText.formLabel),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              border: Border.all(
                color: error != null ? AppColors.danger : AppColors.outlineStrong,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.ink500),
                const SizedBox(width: 12),
                Text(
                  value == null ? 'Select your date of birth' : DateFormat.yMMMd().format(value!),
                  style: AppText.body.copyWith(
                    fontSize: 14,
                    color: value == null ? AppColors.ink400 : AppColors.ink900,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 3),
          Text(error!, style: AppText.captionMuted.copyWith(color: AppColors.danger, fontSize: 11)),
        ],
      ],
    );
  }
}

class _StateField extends StatelessWidget {
  const _StateField({required this.value, required this.error, required this.onChanged});
  final String? value;
  final String? error;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('State', style: AppText.formLabel),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            border: Border.all(
              color: error != null ? AppColors.danger : AppColors.outlineStrong,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.ink500),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    hint: Text(
                      'Select your state',
                      style: AppText.body.copyWith(
                        fontSize: 14,
                        color: AppColors.ink400,
                        height: 1.0,
                      ),
                    ),
                    items: _states
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: onChanged,
                    style: AppText.body.copyWith(fontSize: 14, color: AppColors.ink900),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 3),
          Text(error!, style: AppText.captionMuted.copyWith(color: AppColors.danger, fontSize: 11)),
        ],
      ],
    );
  }
}

class _GenderGrid extends StatelessWidget {
  const _GenderGrid({required this.value, required this.error, required this.onChanged});
  final String? value;
  final String? error;
  final ValueChanged<String> onChanged;

  static const _opts = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender', style: AppText.formLabel),
        const SizedBox(height: 6),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 165 / 46,
          children: _opts.map((g) {
            final selected = g == value;
            return GestureDetector(
              onTap: () => onChanged(g),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: selected ? AppColors.ink900 : AppColors.surfaceMuted,
                  border: Border.all(
                    color: selected ? AppColors.ink900 : AppColors.outlineStrong,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  g,
                  style: AppText.body.copyWith(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? Colors.white : AppColors.ink700,
                    height: 1.0,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error!, style: AppText.captionMuted.copyWith(color: AppColors.danger, fontSize: 11)),
        ],
      ],
    );
  }
}
