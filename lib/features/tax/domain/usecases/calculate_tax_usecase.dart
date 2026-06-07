import '../entities/calculate_tax_params.dart';
import '../repositories/tax_repository.dart';

class CalculateTaxUseCase {
  CalculateTaxUseCase(this._repository);

  final TaxRepository _repository;

  Future<double> call(CalculateTaxParams params) => _repository.calculate(params);
}
