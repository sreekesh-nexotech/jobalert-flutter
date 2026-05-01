import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

/// Shared building blocks used across all auth screens — fields, buttons,
/// step dots, OTP entry. Mirrors the input/button styles from
/// `Job Alert App.html` (48-px input, 50-px black CTA, 1.5-px outline,
/// 10-px radius, blue focus ring).

class AuthInput extends StatelessWidget {
  const AuthInput({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.icon,
    this.error,
    this.obscure = false,
    this.keyboardType,
    this.maxLength,
    this.suffix,
    this.onChanged,
    this.inputFormatters,
    this.padLeft = true,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? icon;
  final String? error;
  final bool obscure;
  final TextInputType? keyboardType;
  final int? maxLength;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final bool padLeft;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: AppText.formLabel),
          const SizedBox(height: 6),
        ],
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            maxLength: maxLength,
            onChanged: onChanged,
            inputFormatters: inputFormatters,
            cursorColor: AppColors.ink900,
            style: AppText.body.copyWith(
              fontSize: 14,
              color: AppColors.ink900,
              height: 1.0,
            ),
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              hintStyle: AppText.body.copyWith(color: AppColors.ink400, height: 1.0),
              filled: true,
              fillColor: AppColors.surfaceMuted,
              prefixIcon: icon == null
                  ? null
                  : Icon(icon, size: 16, color: AppColors.ink500),
              prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 16),
              suffixIcon: suffix,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: icon == null ? 14 : (padLeft ? 0 : 14),
                vertical: 14,
              ),
              enabledBorder: _border(error != null
                  ? AppColors.danger
                  : AppColors.outlineStrong),
              focusedBorder: _border(error != null ? AppColors.danger : AppColors.blue500),
              errorBorder: _border(AppColors.danger),
              focusedErrorBorder: _border(AppColors.danger),
              border: _border(AppColors.outlineStrong),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 3),
          Text(
            error!,
            style: AppText.captionMuted.copyWith(
              color: AppColors.danger,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderSide: BorderSide(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      );
}

/// Primary action — solid black 50px tall pill.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.trailing,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink900,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.ink700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppText.button.copyWith(
                      letterSpacing: -0.01 * 15,
                      height: 1.0,
                    ),
                  ),
                  if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                ],
              ),
      ),
    );
  }
}

/// Step dots progress indicator (used in signup, OTP, details).
class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.total, required this.current});
  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 22),
      child: Row(
        children: List.generate(total, (i) {
          final active = i == current;
          final done = i < current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            width: active ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.ink900
                  : done
                      ? AppColors.success
                      : AppColors.outlineStrong,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}

/// "← Back" header used at the top of inner-flow auth screens.
class BackRow extends StatelessWidget {
  const BackRow({super.key, required this.onBack, this.label = 'Back'});
  final VoidCallback onBack;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onBack,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back, size: 15, color: AppColors.ink700),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink700,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 6-digit OTP input row matching the design — a row of equal-width 48-px
/// boxes with auto-advance + paste-to-fill.
class OtpInputRow extends StatefulWidget {
  const OtpInputRow({
    super.key,
    required this.controllers,
    required this.onChanged,
    this.length = 6,
  });

  final List<TextEditingController> controllers;
  final ValueChanged<String> onChanged;
  final int length;

  @override
  State<OtpInputRow> createState() => _OtpInputRowState();
}

class _OtpInputRowState extends State<OtpInputRow> {
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _nodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _emit() {
    widget.onChanged(widget.controllers.map((c) => c.text).join());
  }

  void _handleChanged(int i, String value) {
    if (value.length > 1) {
      // Paste-to-fill — distribute digits across the remaining boxes.
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (var j = 0; j < digits.length && i + j < widget.length; j++) {
        widget.controllers[i + j].text = digits[j];
      }
      final next = (i + digits.length).clamp(0, widget.length - 1);
      _nodes[next].requestFocus();
      _emit();
      return;
    }
    if (value.isNotEmpty && i < widget.length - 1) {
      _nodes[i + 1].requestFocus();
    }
    _emit();
  }

  void _handleKey(int i, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        widget.controllers[i].text.isEmpty &&
        i > 0) {
      _nodes[i - 1].requestFocus();
      widget.controllers[i - 1].clear();
      _emit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(widget.length, (i) {
        final filled = widget.controllers[i].text.isNotEmpty;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == widget.length - 1 ? 0 : 6),
            child: SizedBox(
              height: 48,
              child: KeyboardListener(
                focusNode: FocusNode(skipTraversal: true),
                onKeyEvent: (e) => _handleKey(i, e),
                child: TextField(
                  controller: widget.controllers[i],
                  focusNode: _nodes[i],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  onChanged: (v) => _handleChanged(i, v),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  cursorColor: AppColors.ink900,
                  style: AppText.h2.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    filled: true,
                    fillColor: filled ? AppColors.ink50 : AppColors.surfaceMuted,
                    enabledBorder: _border(
                      filled ? AppColors.ink900 : AppColors.outlineStrong,
                    ),
                    focusedBorder: _border(AppColors.ink900),
                    border: _border(AppColors.outlineStrong),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderSide: BorderSide(color: c, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      );
}
