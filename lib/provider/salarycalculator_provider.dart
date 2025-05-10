// Provider for salary calculation
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_life/models/salary_model.dart';

final salaryCalculationProvider = StateProvider<SalaryCalculationModel>((ref) {
  return SalaryCalculationModel();
});
