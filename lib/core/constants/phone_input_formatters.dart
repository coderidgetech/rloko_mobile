import 'package:flutter/services.dart';

/// National mobile digits only; max 10 (e.g. IN/US local length before country dial code).
final List<TextInputFormatter> kPhoneLocal10DigitFormatters = [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(10),
];
