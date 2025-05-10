// 출석 모델 클래스
class AttendanceModel {
  final int count;
  final bool isTodayChecked;
  final List<String> checkedDates;

  AttendanceModel({
    this.count = 0,
    this.isTodayChecked = false,
    this.checkedDates = const [],
  });

  // copyWith 메서드
  AttendanceModel copyWith({
    int? count,
    bool? isTodayChecked,
    List<String>? checkedDates,
  }) {
    return AttendanceModel(
      count: count ?? this.count,
      isTodayChecked: isTodayChecked ?? this.isTodayChecked,
      checkedDates: checkedDates ?? this.checkedDates,
    );
  }
}
