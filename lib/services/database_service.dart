import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:focus_life/models/contact_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;

  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'contacts_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        position TEXT NOT NULL,
        department TEXT NOT NULL,
        email TEXT,
        profileImagePath TEXT
      )
    ''');

    // Insert initial contacts
    await _insertInitialContacts(db);
  }

  Future<void> _insertInitialContacts(Database db) async {
    final List<String> firstNames = [
      '민수',
      '지훈',
      '서연',
      '정우',
      '하영',
      '우성',
      '예린',
      '준혁',
      '도연',
      '승우',
      '지후',
      '채린',
      '시윤',
      '진호',
      '은비',
      '준호',
      '하윤',
      '우진',
      '예지',
      '태현',
      '민준',
      '서현',
      '지민',
      '현우',
      '소미',
      '재훈',
      '수빈',
      '태양',
      '민지',
      '유진'
    ];

    final List<String> lastNames = [
      '김',
      '이',
      '박',
      '최',
      '정',
      '강',
      '조',
      '윤',
      '장',
      '임',
      '한',
      '오',
      '서',
      '신',
      '권',
      '황',
      '안',
      '송',
      '전',
      '홍',
      '유',
      '고',
      '문',
      '양',
      '손',
      '배',
      '백',
      '곽',
      '허',
      '이'
    ];

    final List<String> departments = [
      '영업1팀',
      '영업2팀',
      '영업3팀',
      '영업지원팀',
      '생산1팀',
      '생산2팀',
      '생산관리팀',
      '품질관리팀',
      '개발1팀',
      '개발2팀',
      '개발3팀',
      'DevOps팀',
      'QA팀',
      '디자인팀',
      'UI/UX팀',
      '그래픽디자인팀',
      '마케팅팀',
      '디지털마케팅팀',
      '브랜드마케팅팀',
      '인사팀',
      '총무팀',
      '법무팀',
      '재무팀',
      '회계팀',
      '고객지원팀',
      '전략기획팀'
    ];

    final List<String> positions = [
      '인턴',
      '계약직',
      '사원',
      '주임',
      '대리',
      '과장',
      '차장',
      '팀장',
      '부장',
      '이사',
      '상무',
      '전무',
      '부사장',
      '사장',
      '대표이사'
    ];

    final List<String> phonePrefixes = [
      '010-1234-',
      '010-5678-',
      '010-9012-',
      '010-3456-',
      '010-7890-',
      '010-2345-',
      '010-6789-',
      '010-0123-'
    ];

    final List<String> emailDomains = [
      'company.com',
      'company.co.kr',
      'focus-life.com',
      'focus-life.co.kr'
    ];

    // Generate at least 50 contacts
    for (int i = 0; i < 60; i++) {
      final lastName = lastNames[i % lastNames.length];
      final firstName = firstNames[i % firstNames.length];
      final name = '$lastName$firstName';

      final dept = departments[i % departments.length];
      final pos = positions[i % positions.length];

      final phoneNumber =
          '${phonePrefixes[i % phonePrefixes.length]}${1000 + i}';
      final email =
          '$firstName$lastName${i % 100}@${emailDomains[i % emailDomains.length]}';

      final contact = Contact(
        name: name,
        phoneNumber: phoneNumber,
        department: dept,
        position: pos,
        email: email,
      );

      await db.insert('contacts', contact.toMap());
    }
  }

  // CRUD Operations

  // Create
  Future<int> insertContact(Contact contact) async {
    final Database db = await database;
    return await db.insert(
      'contacts',
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Read all
  Future<List<Contact>> getContacts() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('contacts');

    return List.generate(maps.length, (i) {
      return Contact.fromMap(maps[i]);
    });
  }

  // Read contacts by department
  Future<List<Contact>> getContactsByDepartment(String department) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contacts',
      where: 'department = ?',
      whereArgs: [department],
    );

    return List.generate(maps.length, (i) {
      return Contact.fromMap(maps[i]);
    });
  }

  // Get all unique departments
  Future<List<String>> getAllDepartments() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT DISTINCT department FROM contacts ORDER BY department');

    return List.generate(maps.length, (i) {
      return maps[i]['department'] as String;
    });
  }

  // Read one
  Future<Contact?> getContact(int id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Contact.fromMap(maps.first);
    }
    return null;
  }

  // Update
  Future<int> updateContact(Contact contact) async {
    final Database db = await database;
    return await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  // Delete
  Future<int> deleteContact(int id) async {
    final Database db = await database;
    return await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Search contacts
  Future<List<Contact>> searchContacts(String query) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contacts',
      where:
          'name LIKE ? OR phoneNumber LIKE ? OR department LIKE ? OR position LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
    );

    return List.generate(maps.length, (i) {
      return Contact.fromMap(maps[i]);
    });
  }
}

class AttendanceDatabase {
  static final AttendanceDatabase _instance = AttendanceDatabase._internal();
  factory AttendanceDatabase() => _instance;

  AttendanceDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'attendance_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  // 출석 체크 기록 추가
  Future<int> insertAttendanceRecord(String date) async {
    final Database db = await database;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return await db.insert(
      'attendance',
      {
        'date': date,
        'timestamp': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 특정 날짜의 출석 체크 여부 확인
  Future<bool> isDateChecked(String date) async {
    final Database db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'attendance',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // 전체 출석 기록 개수 가져오기
  Future<int> getTotalAttendanceCount() async {
    final Database db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM attendance');

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 모든 출석 기록 가져오기
  Future<List<Map<String, dynamic>>> getAllAttendanceRecords() async {
    final Database db = await database;
    return await db.query('attendance', orderBy: 'timestamp DESC');
  }

  // 특정 날짜 범위의 출석 기록 가져오기 (예: 이번 달)
  Future<List<Map<String, dynamic>>> getAttendanceRecordsByDateRange(
      String startDate, String endDate) async {
    final Database db = await database;
    return await db.query(
      'attendance',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
  }

  // 특정 출석 기록 삭제 (예: 관리자 기능)
  Future<int> deleteAttendanceRecord(String date) async {
    final Database db = await database;
    return await db.delete(
      'attendance',
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  // 모든 출석 기록 초기화 (예: 앱 리셋 또는 테스트용)
  Future<void> clearAllAttendanceRecords() async {
    final Database db = await database;
    await db.delete('attendance');
  }
}
