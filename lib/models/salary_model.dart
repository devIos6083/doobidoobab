// Salary Calculator Model
class SalaryCalculationModel {
  final double hourlyWage;
  final double hoursWorked;
  final double overtimeHours;
  final double overtimeRate;
  final double incomeTaxRate;
  final double nationalPensionRate;
  final double healthInsuranceRate;
  final double employmentInsuranceRate;

  SalaryCalculationModel({
    this.hourlyWage = 9860.0, // Default minimum wage 2025 (예상)
    this.hoursWorked = 40.0,
    this.overtimeHours = 0.0,
    this.overtimeRate = 1.5,
    this.incomeTaxRate = 0.033, // 소득세 약 3.3%
    this.nationalPensionRate = 0.045, // 국민연금 약 4.5%
    this.healthInsuranceRate = 0.0343, // 건강보험 약 3.43%
    this.employmentInsuranceRate = 0.008, // 고용보험 약 0.8%
  });

  // Calculate gross pay
  double get grossPay {
    return ((hourlyWage * hoursWorked) +
            (hourlyWage * overtimeHours * overtimeRate)) *
        4;
  }

  // Calculate deductions
  double get incomeTax {
    return grossPay * incomeTaxRate;
  }

  double get nationalPension {
    return grossPay * nationalPensionRate;
  }

  double get healthInsurance {
    return grossPay * healthInsuranceRate;
  }

  double get employmentInsurance {
    return grossPay * employmentInsuranceRate;
  }

  // Calculate total deductions
  double get totalDeductions {
    return incomeTax + nationalPension + healthInsurance + employmentInsurance;
  }

  // Calculate net pay
  double get netPay {
    return grossPay - totalDeductions;
  }

  // Create a copy with updated values
  SalaryCalculationModel copyWith({
    double? hourlyWage,
    double? hoursWorked,
    double? overtimeHours,
    double? overtimeRate,
    double? incomeTaxRate,
    double? nationalPensionRate,
    double? healthInsuranceRate,
    double? employmentInsuranceRate,
  }) {
    return SalaryCalculationModel(
      hourlyWage: hourlyWage ?? this.hourlyWage,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      overtimeRate: overtimeRate ?? this.overtimeRate,
      incomeTaxRate: incomeTaxRate ?? this.incomeTaxRate,
      nationalPensionRate: nationalPensionRate ?? this.nationalPensionRate,
      healthInsuranceRate: healthInsuranceRate ?? this.healthInsuranceRate,
      employmentInsuranceRate:
          employmentInsuranceRate ?? this.employmentInsuranceRate,
    );
  }
}
