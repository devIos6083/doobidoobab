// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:focus_life/provider/salarycalculator_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_life/utils/constant.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Salary Calculator Widget
class SalaryCalculatorWidget extends ConsumerStatefulWidget {
  final bool showTitle;
  const SalaryCalculatorWidget({super.key, this.showTitle = true});

  @override
  ConsumerState<SalaryCalculatorWidget> createState() =>
      _SalaryCalculatorWidgetState();
}

class _SalaryCalculatorWidgetState
    extends ConsumerState<SalaryCalculatorWidget> {
  final _hourlyWageController = TextEditingController();
  final _hoursWorkedController = TextEditingController();
  final _overtimeHoursController = TextEditingController();

  bool _isExpanded = false; // Changed from final to mutable
  String formatWithCommas(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  @override
  void initState() {
    super.initState();
    final model = ref.read(salaryCalculationProvider);
    _hourlyWageController.text = model.hourlyWage.toString();
    _hoursWorkedController.text = model.hoursWorked.toString();
    _overtimeHoursController.text = model.overtimeHours.toString();
  }

  @override
  void dispose() {
    _hourlyWageController.dispose();
    _hoursWorkedController.dispose();
    _overtimeHoursController.dispose();
    super.dispose();
  }

  void _updateCalculation() {
    final hourlyWage = double.tryParse(_hourlyWageController.text) ?? 9860.0;
    final hoursWorked = double.tryParse(_hoursWorkedController.text) ?? 40.0;
    final overtimeHours = double.tryParse(_overtimeHoursController.text) ?? 0.0;

    final updatedModel = ref.read(salaryCalculationProvider).copyWith(
          hourlyWage: hourlyWage,
          hoursWorked: hoursWorked,
          overtimeHours: overtimeHours,
        );

    ref.read(salaryCalculationProvider.notifier).state = updatedModel;
  }

  @override
  Widget build(BuildContext context) {
    final calculationModel = ref.watch(salaryCalculationProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 부분을 조건부로 표시
          if (widget.showTitle)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calculate_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '급여 계산기',
                      style: GoogleFonts.sora(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            )
          else
            // 제목이 없을 때는 확장/축소 버튼만 표시
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
            ),

          if (_isExpanded) ...[
            const SizedBox(height: 16),

            // Input fields
            Text(
              '기본 정보 입력',
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Hourly wage input
            TextField(
              controller: _hourlyWageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '시간당 임금 (원)',
                labelStyle: GoogleFonts.sora(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.background),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.background),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                suffixText: '원',
              ),
              onChanged: (_) => _updateCalculation(),
            ),
            const SizedBox(height: 12),

            // Weekly hours input
            TextField(
              controller: _hoursWorkedController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '주간 근무 시간',
                labelStyle: GoogleFonts.sora(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.background),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.background),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                suffixText: '시간',
              ),
              onChanged: (_) => _updateCalculation(),
            ),
            const SizedBox(height: 12),

            // Overtime hours input
            TextField(
              controller: _overtimeHoursController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '초과 근무 시간',
                labelStyle: GoogleFonts.sora(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.background),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.background),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                suffixText: '시간',
              ),
              onChanged: (_) => _updateCalculation(),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Results section
          Text(
            '급여 계산 결과',
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Display results in a nice layout
          Row(
            children: [
              _buildResultItem(
                '총 임금',
                '${formatWithCommas(calculationModel.grossPay)}원',
                Icons.monetization_on,
                AppColors.primary,
              ),
              const SizedBox(width: 16),
              _buildResultItem(
                '공제액',
                '${formatWithCommas(calculationModel.totalDeductions)}원',
                Icons.remove_circle_outline,
                AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Net pay display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '실수령액(월)',
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${formatWithCommas(calculationModel.netPay)}원',
                  style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          if (_isExpanded) ...[
            const SizedBox(height: 20),

            // Detailed deductions
            Text(
              '공제 내역',
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            _buildDeductionItem(
              '소득세',
              '${formatWithCommas(calculationModel.incomeTax)}원',
              calculationModel.incomeTaxRate * 100,
            ),
            const SizedBox(height: 8),
            _buildDeductionItem(
              '국민연금',
              '${formatWithCommas(calculationModel.nationalPension)}원',
              calculationModel.nationalPensionRate * 100,
            ),
            const SizedBox(height: 8),
            _buildDeductionItem(
              '건강보험',
              '${formatWithCommas(calculationModel.healthInsurance)}원',
              calculationModel.healthInsuranceRate * 100,
            ),
            const SizedBox(height: 8),
            _buildDeductionItem(
              '고용보험',
              '${formatWithCommas(calculationModel.employmentInsurance)}원',
              calculationModel.employmentInsuranceRate * 100,
            ),
          ],

          const SizedBox(height: 16),

          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              icon: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.primary,
                size: 20,
              ),
              label: Text(
                _isExpanded ? '간단히 보기' : '자세히 보기',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeductionItem(String label, String amount, double percentage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${percentage.toStringAsFixed(1)}%',
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.error,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amount,
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
