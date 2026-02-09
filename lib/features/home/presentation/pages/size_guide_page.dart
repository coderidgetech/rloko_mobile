import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';

/// Size Guide – clothing size charts with real measurements.
class SizeGuidePage extends StatelessWidget {
  const SizeGuidePage({super.key});

  /// Men's top / shirt (inches).
  static const _menTop = [
    ['Size', 'Chest', 'Waist', 'Hip', 'Length'],
    ['S', '35-37"', '29-31"', '35-37"', '27"'],
    ['M', '38-40"', '32-34"', '38-40"', '28"'],
    ['L', '41-43"', '35-37"', '41-43"', '29"'],
    ['XL', '44-46"', '38-40"', '44-46"', '30"'],
    ['XXL', '47-49"', '41-43"', '47-49"', '31"'],
  ];

  static const _womenTop = [
    ['Size', 'Bust', 'Waist', 'Hip', 'Length'],
    ['XS', '31-32"', '24-25"', '34-35"', '24"'],
    ['S', '33-34"', '26-27"', '36-37"', '25"'],
    ['M', '35-36"', '28-29"', '38-39"', '26"'],
    ['L', '37-39"', '30-32"', '40-42"', '27"'],
    ['XL', '40-42"', '33-35"', '43-45"', '28"'],
  ];

  static const _footwear = [
    ['US', 'UK', 'EU', 'Length (approx.)'],
    ['6', '5.5', '39', '9.25"'],
    ['7', '6', '40', '9.6"'],
    ['8', '7', '41', '9.9"'],
    ['9', '8', '42', '10.25"'],
    ['10', '9', '43', '10.6"'],
    ['11', '10', '44', '10.9"'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Size Guide',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Measure yourself and compare to the charts below. When in doubt, size up.',
              style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context)),
            ),
            const SizedBox(height: 24),
            _SectionTitle('How to measure'),
            _Paragraph('Chest/Bust: Measure under arms, around the fullest part. Waist: Natural waist. Hip: Around the fullest part. Length: From top of shoulder (or neck) to hem.'),
            const SizedBox(height: 24),
            _SectionTitle('Men\'s tops & shirts'),
            _SizeTable(rows: _menTop),
            const SizedBox(height: 24),
            _SectionTitle('Women\'s tops & dresses'),
            _SizeTable(rows: _womenTop),
            const SizedBox(height: 24),
            _SectionTitle('Footwear'),
            _SizeTable(rows: _footwear),
            const SizedBox(height: 16),
            _Paragraph('Shoe sizes may vary by brand. We recommend referring to the product page for brand-specific size charts.'),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context), height: 1.5),
    );
  }
}

class _SizeTable extends StatelessWidget {
  const _SizeTable({required this.rows});

  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final header = rows.first;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppTheme.foregroundColor(context).withValues(alpha: 0.06)),
        columns: [
          for (var i = 0; i < header.length; i++)
            DataColumn(
              label: Text(
                header[i],
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
        ],
        rows: [
          for (var r = 1; r < rows.length; r++)
            DataRow(
              cells: [
                for (var c = 0; c < header.length; c++)
                  DataCell(Text(
                    c < rows[r].length ? rows[r][c] : '',
                    style: c == 0 ? const TextStyle(fontWeight: FontWeight.w500) : null,
                  )),
              ],
            ),
        ],
      ),
    );
  }
}
