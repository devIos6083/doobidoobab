import 'package:doobi/firebase_initializer.dart';
import 'package:doobi/models/user.dart';
import 'package:doobi/screens/main_screen.dart';
import 'package:doobi/services/navigation_service.dart';
import 'package:doobi/services/user_service.dart';
import 'package:doobi/utils/constants.dart';
import 'package:doobi/utils/logger.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../widgets/gender_selection_button.dart';

class UserInfoScreen extends StatefulWidget {
  final FirebaseInitializer firebase;

  const UserInfoScreen({super.key, required this.firebase});

  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedGender = '';
  int _selectedAge = 10; // 기본 나이 값
  bool _isLoading = false;

  final UserService _userService = UserService();
  final NavigationService _navigationService = NavigationService();

  // Firebase 인스턴스 제거 - 오류 발생 원인
  // late final firebase_auth.FirebaseAuth _auth;

  @override
  void initState() {
    super.initState();
    AppLogger.event('사용자 정보 화면 초기화됨');

    // 디버깅 로그 추가
    print('UserInfoScreen 초기화: Firebase 인스턴스 확인=${widget.firebase != null}');

    // 기존 사용자 데이터 확인
    _checkExistingUserData();

    // 익명 로그인 제거 - 오류 발생 원인
    // _signInAnonymously();
  }

  /// 기존 사용자 데이터 확인
  Future<void> _checkExistingUserData() async {
    try {
      print('기존 사용자 데이터 확인 중...');

      // mounted 확인 추가
      if (!mounted) return;

      // 'fromLogout' 인자 확인
      final args = ModalRoute.of(context)?.settings.arguments;
      final isFromLogout = args != null && args == 'fromLogout';

      if (isFromLogout) {
        print('로그아웃에서 온 것을 확인, 기존 사용자 데이터 삭제 시도');
        await _userService.deleteUser();
        print('기존 사용자 데이터 삭제 완료');
      }
    } catch (e) {
      print('사용자 데이터 확인 중 오류: $e');
    }
  }

  Future<void> _saveUserInfo() async {
    if (_formKey.currentState!.validate() && _selectedGender.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        AppLogger.info('사용자 정보 저장 중');

        // User 객체 생성
        final user = User(
          name: _nameController.text.trim(),
          age: _selectedAge,
          gender: _selectedGender,
        );

        // 서비스를 통해 저장
        final savedUser = await _userService.saveUser(user);

        if (savedUser != null) {
          AppLogger.event('사용자 정보 저장 성공');

          // firebase 인스턴스를 통한 단어 데이터 초기화
          try {
            final wordRepository = widget.firebase.wordRepository;
            await wordRepository.ensureWordsLoaded();
          } catch (e) {
            AppLogger.error('단어 데이터 로드 오류', e);
            // 단어 로드 실패해도 계속 진행
          }

          // 메인 화면으로 이동 - mounted 확인 필요
          if (mounted) {
            _navigateToMainScreen();
          }
        } else {
          _showError(AppStrings.validationError);
        }
      } catch (e) {
        AppLogger.error('사용자 정보 저장 중 오류 발생', e);
        _showError('저장 중 오류가 발생했습니다');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      _showError(AppStrings.validationError);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showAgePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: AppColors.white,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  AppStrings.ageSelection,
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 50,
                  onSelectedItemChanged: (int index) {
                    if (mounted) {
                      setState(() {
                        _selectedAge = index + 1; // 1부터 100까지의 나이
                      });
                    }
                  },
                  scrollController: FixedExtentScrollController(
                    initialItem: _selectedAge - 1,
                  ),
                  children: List.generate(
                    100,
                    (index) => Center(
                      child: Text(
                        '${index + 1}${AppStrings.ageSuffix}',
                        style: GoogleFonts.quicksand(fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppStrings.ageConfirm,
                  style: GoogleFonts.quicksand(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToMainScreen() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => MainScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.defaultPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Lottie 애니메이션
                      Center(
                        child: Lottie.asset(
                          "lottie/cut1.json",
                          width: AppDimensions.avatarSize,
                          height: AppDimensions.avatarSize,
                        ),
                      ),

                      Text(
                        AppStrings.userInfoTitle,
                        style: GoogleFonts.quicksand(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      SizedBox(height: 20),

                      // 이름 입력
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: AppStrings.nameHint,
                          prefixIcon: Icon(
                            Icons.person,
                            color: AppColors.accent,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.defaultRadius,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.white.withOpacity(0.7),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.nameHint;
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 15),

                      // 나이 선택
                      Text(
                        AppStrings.ageSelection,
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _showAgePicker,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white.withOpacity(0.7),
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.defaultRadius,
                            ),
                          ),
                        ),
                        child: Text(
                          '$_selectedAge${AppStrings.ageSuffix}',
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      SizedBox(height: 15),

                      // 성별 선택
                      Text(
                        AppStrings.genderSelection,
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GenderSelectionButton(
                            gender: AppStrings.male,
                            icon: Icons.male,
                            isSelected: _selectedGender == AppStrings.male,
                            onPressed: () {
                              setState(() {
                                _selectedGender = AppStrings.male;
                              });
                            },
                          ),
                          SizedBox(width: 20),
                          GenderSelectionButton(
                            gender: AppStrings.female,
                            icon: Icons.female,
                            isSelected: _selectedGender == AppStrings.female,
                            onPressed: () {
                              setState(() {
                                _selectedGender = AppStrings.female;
                              });
                            },
                          ),
                        ],
                      ),

                      SizedBox(height: 30),

                      // 확인 버튼
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveUserInfo,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 15,
                          ),
                          backgroundColor: AppColors.accent,
                          disabledBackgroundColor: AppColors.accent.withOpacity(
                            0.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child:
                            _isLoading
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  AppStrings.startButton,
                                  style: GoogleFonts.quicksand(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 로딩 오버레이
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              color: AppColors.accent,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            '사용자 정보를 저장하는 중...',
                            style: GoogleFonts.quicksand(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
