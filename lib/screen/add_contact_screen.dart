// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_life/models/contact_model.dart';
import 'package:focus_life/provider/contact_provider.dart';
import 'package:focus_life/utils/constant.dart';
import 'package:google_fonts/google_fonts.dart';

class AddContactScreen extends ConsumerStatefulWidget {
  const AddContactScreen({super.key});

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

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

  String? _selectedDepartment;
  String? _selectedPosition;
  String _avatarText = '?';
  Color _avatarColor = AppColors.primary;

  final List<Color> _avatarColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateAvatarText);
  }

  void _updateAvatarText() {
    if (_nameController.text.isNotEmpty) {
      setState(() {
        _avatarText = _nameController.text[0];
      });
    } else {
      setState(() {
        _avatarText = '?';
      });
    }
  }

  void _changeAvatarColor() {
    setState(() {
      final currentIndex = _avatarColors.indexOf(_avatarColor);
      final nextIndex = (currentIndex + 1) % _avatarColors.length;
      _avatarColor = _avatarColors[nextIndex];
    });
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateAvatarText);
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '새 연락처 추가',
          style: GoogleFonts.notoSans(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveContact,
            child: Text(
              '저장',
              style: GoogleFonts.notoSans(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Profile Avatar with tap to change color
                GestureDetector(
                  onTap: _changeAvatarColor,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: _avatarColor,
                        child: Text(
                          _avatarText,
                          style: GoogleFonts.notoSans(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.colorize,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Name input
                TextFormField(
                  controller: _nameController,
                  decoration: _buildInputDecoration(
                    labelText: '이름',
                    prefixIcon: Icons.person_outline,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이름을 입력해주세요';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Phone input
                TextFormField(
                  controller: _phoneController,
                  decoration: _buildInputDecoration(
                    labelText: '전화번호',
                    prefixIcon: Icons.phone_outlined,
                    hintText: '010-0000-0000',
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '전화번호를 입력해주세요';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email input
                TextFormField(
                  controller: _emailController,
                  decoration: _buildInputDecoration(
                    labelText: '이메일 (선택)',
                    prefixIcon: Icons.email_outlined,
                    hintText: 'example@company.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 24),

                // Department dropdown
                DropdownButtonFormField<String>(
                  decoration: _buildInputDecoration(
                    labelText: '부서',
                    prefixIcon: Icons.business_outlined,
                  ),
                  value: _selectedDepartment,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  items: departments.map((String dept) {
                    return DropdownMenuItem<String>(
                      value: dept,
                      child: Text(dept),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value;
                    });
                  },
                  validator: (value) => value == null ? '부서를 선택해주세요' : null,
                ),

                const SizedBox(height: 16),

                // Position dropdown
                DropdownButtonFormField<String>(
                  decoration: _buildInputDecoration(
                    labelText: '직책',
                    prefixIcon: Icons.work_outline,
                  ),
                  value: _selectedPosition,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  items: positions.map((String pos) {
                    return DropdownMenuItem<String>(
                      value: pos,
                      child: Text(pos),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPosition = value;
                    });
                  },
                  validator: (value) => value == null ? '직책을 선택해주세요' : null,
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: AppColors.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  void _saveContact() {
    if (_formKey.currentState!.validate()) {
      final newContact = Contact(
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        position: _selectedPosition!,
        department: _selectedDepartment!,
        email: _emailController.text.isEmpty ? null : _emailController.text,
      );

      ref.read(contactOperationsProvider.notifier).addContact(newContact);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('연락처가 추가되었습니다'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Navigator.pop(context);
    }
  }
}
