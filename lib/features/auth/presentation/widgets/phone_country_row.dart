import 'package:flutter/material.dart';

import '../../../../core/constants/dial_countries.dart';
import '../../../../core/constants/phone_input_formatters.dart';
import '../../../../core/theme/app_theme.dart';

/// Country selector + phone — two rounded fields with gap, aligned with web `PhoneCountryRow` (`gap-2`).
class PhoneCountryRow extends StatefulWidget {
  const PhoneCountryRow({
    super.key,
    required this.localPhone,
    required this.onLocalPhoneChanged,
    required this.selectedCountry,
    required this.onSelectCountry,
  });

  final String localPhone;
  final ValueChanged<String> onLocalPhoneChanged;
  final DialCountry selectedCountry;
  final ValueChanged<DialCountry> onSelectCountry;

  @override
  State<PhoneCountryRow> createState() => _PhoneCountryRowState();
}

class _PhoneCountryRowState extends State<PhoneCountryRow> {
  late final TextEditingController _controller;
  final FocusNode _phoneFocus = FocusNode();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.localPhone);
    _phoneFocus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(PhoneCountryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.localPhone != _controller.text) {
      _controller.text = widget.localPhone;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  @override
  void dispose() {
    _phoneFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openPicker() async {
    _search = '';
    final selected = await showModalBottomSheet<DialCountry>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                final filtered = filterDialCountries(_search);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Search country or code',
                                prefixIcon: const Icon(Icons.search, size: 22),
                                filled: true,
                                fillColor: AppTheme.foregroundColor(context).withValues(alpha: 0.06),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.foregroundColor(context).withValues(alpha: 0.12),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              onChanged: (v) => setModalState(() => _search = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final c = filtered[i];
                          return ListTile(
                            leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                            title: Text(c.name),
                            trailing: Text(c.dialCode, style: const TextStyle(fontWeight: FontWeight.w600)),
                            onTap: () => Navigator.pop(ctx, c),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
    if (selected != null) widget.onSelectCountry(selected);
  }

  @override
  Widget build(BuildContext context) {
    final fg = AppTheme.foregroundColor(context);
    final primary = AppTheme.primaryColor(context);
    const h = 52.0;
    const r = 12.0;
    final line = fg.withValues(alpha: 0.12);
    final grey = fg.withValues(alpha: 0.06);
    final focused = _phoneFocus.hasFocus;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openPicker,
            borderRadius: BorderRadius.circular(r),
            child: Container(
              height: h,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              constraints: const BoxConstraints(minWidth: 108),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: grey,
                borderRadius: BorderRadius.circular(r),
                border: Border.all(color: line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.selectedCountry.flag, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text(
                    widget.selectedCountry.dialCode,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: fg.withValues(alpha: 0.88),
                    ),
                  ),
                  Icon(Icons.expand_more, size: 20, color: fg.withValues(alpha: 0.42)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(r),
              border: Border.all(
                color: focused ? primary : line,
                width: focused ? 2 : 1,
              ),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Row(
              children: [
                Icon(Icons.phone_outlined, size: 20, color: fg.withValues(alpha: 0.4)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _phoneFocus,
                    keyboardType: TextInputType.number,
                    inputFormatters: kPhoneLocal10DigitFormatters,
                    textAlignVertical: TextAlignVertical.center,
                    style: TextStyle(fontSize: 16, color: fg),
                    cursorColor: primary,
                    onChanged: widget.onLocalPhoneChanged,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Phone number',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: fg.withValues(alpha: 0.4), fontSize: 16),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
