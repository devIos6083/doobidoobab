class User {
  final int? id;
  final String name;
  final int age;
  final String gender;
  final String? characterPath;
  final int consecutiveDays;
  final String? lastAttendanceDate;
  final List<String>? learnedWords; // 학습한 단어 목록 추가

  /// 새로운 User 인스턴스 생성
  const User({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.characterPath,
    this.consecutiveDays = 0,
    this.lastAttendanceDate,
    this.learnedWords, // 생성자에 추가
  });

  /// User 객체를 Firebase 저장용 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      // id는 Firebase의 키로 사용되므로 제외
      'name': name,
      'age': age,
      'gender': gender,
      'character_path': characterPath,
      'consecutive_days': consecutiveDays,
      'last_attendance_date': lastAttendanceDate,
      'learned_words': learnedWords, // Map에 추가
    };
  }

  // User 클래스의 fromMap 메서드
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] is String ? int.tryParse(map['id'] as String) : map['id'],
      name: map['name'] as String,
      age: map['age'] as int,
      gender: map['gender'] as String,
      characterPath: map['character_path'] as String?,
      consecutiveDays: map['consecutive_days'] as int? ?? 0,
      lastAttendanceDate: map['last_attendance_date'] as String?,
      // 학습한 단어 목록 변환 (List<dynamic>을 List<String>으로)
      learnedWords: map['learned_words'] != null
          ? List<String>.from(map['learned_words'] as List<dynamic>)
          : null,
    );
  }

  /// 선택적 파라미터 업데이트를 통한 User 복사본 생성
  User copyWith({
    int? id,
    String? name,
    int? age,
    String? gender,
    String? characterPath,
    int? consecutiveDays,
    String? lastAttendanceDate,
    List<String>? learnedWords, // copyWith에 추가
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      characterPath: characterPath ?? this.characterPath,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      lastAttendanceDate: lastAttendanceDate ?? this.lastAttendanceDate,
      learnedWords: learnedWords ?? this.learnedWords, // copyWith에 추가
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        age,
        gender,
        characterPath,
        consecutiveDays,
        lastAttendanceDate,
        learnedWords, // props에 추가
      ];

  @override
  String toString() => 'User(id: $id, name: $name, age: $age)';
}
