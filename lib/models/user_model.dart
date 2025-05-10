class UserModel {
  final String name;
  final List<int?> answers;

  const UserModel({
    required this.name,
    required this.answers,
  });

  // JSON 변환 추가
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'answers': answers,
    };
  }

  static UserModel fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] as String,
      answers: (json['answers'] as List?)
              ?.map((e) => e == null ? null : e as int)
              .toList() ??
          [null, null, null, null], // 기본값을 설정하여 Null 방지
    );
  }

  // Getter 추가 (UserInfoCard에서 사용 가능)
  int? get jobTypeIndex => answers.isNotEmpty ? answers[0] : null;
  int? get employmentTypeIndex => answers.length > 1 ? answers[1] : null;
  int? get issueTypeIndex => answers.length > 2 ? answers[2] : null;
  int? get attendanceFrequencyIndex => answers.length > 3 ? answers[3] : null;
}
