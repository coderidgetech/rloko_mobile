import '../entities/calculate_tax_params.dart';

abstract class TaxRepository {
  /// Returns the tax amount (in the subtotal's currency) for the given address
  /// and subtotal. Returns 0 when the backend reports no tax.
  Future<double> calculate(CalculateTaxParams params);
}
