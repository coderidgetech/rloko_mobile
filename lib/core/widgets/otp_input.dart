import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Six single-digit OTP fields; matches React mobile OTP input.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.otp,
    required this.onChanged,
    this.enabled = true,
  });

  final List<String> otp;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      6,
      (i) => TextEditingController(text: widget.otp[i]),
    );
  }

  @override
  void didUpdateWidget(OtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (var i = 0; i < 6; i++) {
      if (widget.otp[i] != oldWidget.otp[i] && _controllers[i].text != widget.otp[i]) {
        _controllers[i].text = widget.otp[i];
        _controllers[i].selection = TextSelection.collapsed(offset: widget.otp[i].length);
      }
    }
  }

  @override
  void dispose() {
    for (final n in _focusNodes) n.dispose();
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) return;
    if (value.isNotEmpty && !RegExp(r'^\d+$').hasMatch(value)) return;
    final next = List<String>.from(widget.otp);
    next[index] = value;
    widget.onChanged(next);
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _onKey(int index, RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        widget.otp[index].isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SizedBox(
            width: 48,
            height: 56,
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (e) => _onKey(index, e),
              child: TextFormField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                enabled: widget.enabled,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  filled: true,
                  // Match the form fields: white fill, subtle border, primary focus.
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.foregroundColor(context).withValues(alpha: 0.12),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.foregroundColor(context).withValues(alpha: 0.12),
                    ),
                  ),
                    focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor(context),
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => _onChanged(index, v),
              ),
            ),
          ),
        );
      }),
    );
  }
}
