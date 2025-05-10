import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_life/provider/contact_auth_provider.dart';
import 'package:focus_life/provider/contact_provider.dart';
import 'package:focus_life/models/contact_model.dart';
import 'package:focus_life/screen/add_contact_screen.dart';
import 'package:focus_life/screen/contact_detail_screen.dart';
import 'package:focus_life/utils/constant.dart';
import 'package:google_fonts/google_fonts.dart';

class ContactsTabRiverpod extends ConsumerStatefulWidget {
  const ContactsTabRiverpod({super.key});

  @override
  ConsumerState<ContactsTabRiverpod> createState() =>
      _ContactsTabRiverpodState();
}

class _ContactsTabRiverpodState extends ConsumerState<ContactsTabRiverpod>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(contactAuthProvider);

    // If not authenticated, show password screen
    if (!authState.isAuthenticated) {
      return _buildPasswordScreen(context, ref);
    }

    // If authenticated, show contacts list
    return _buildContactsScreen(context, ref);
  }

  Widget _buildPasswordScreen(BuildContext context, WidgetRef ref) {
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F5F5), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '연락처에 접근하려면\n비밀번호를 입력하세요',
                      style: GoogleFonts.notoSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelText: '비밀번호',
                        prefixIcon: const Icon(Icons.vpn_key_outlined),
                        hintText: '비밀번호를 입력하세요',
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          ref
                              .read(contactAuthProvider.notifier)
                              .authenticate(passwordController.text);
                        },
                        child: const Text('확인', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactsScreen(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              pinned: true,
              snap: false,
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: "이름, 전화번호, 부서 검색",
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                      ),
                      style: const TextStyle(color: AppColors.textPrimary),
                    )
                  : Text(
                      '연락처',
                      style: GoogleFonts.notoSans(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddContactScreen(),
                      ),
                    );
                  },
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: '전체'),
                  Tab(text: '부서별'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // All Contacts Tab
            _buildAllContactsTab(),

            // Departments Tab
            _buildDepartmentsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAllContactsTab() {
    final searchQuery = ref.watch(searchQueryProvider);

    // If search is active, show search results
    if (searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    // Otherwise show all contacts
    return ref.watch(contactsProvider).when(
          data: (contacts) {
            if (contacts.isEmpty) {
              return const Center(
                child: Text('연락처가 없습니다. 새 연락처를 추가해보세요.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8.0),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return _buildContactListTile(contact);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('에러가 발생했습니다: $error'),
          ),
        );
  }

  Widget _buildSearchResults() {
    return ref.watch(searchResultsProvider).when(
          data: (results) {
            if (results.isEmpty) {
              return const Center(
                child: Text('검색 결과가 없습니다.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8.0),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final contact = results[index];
                return _buildContactListTile(contact);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('검색 중 에러가 발생했습니다: $error'),
          ),
        );
  }

  Widget _buildDepartmentsTab() {
    return ref.watch(departmentsProvider).when(
          data: (departments) {
            if (departments.isEmpty) {
              return const Center(
                child: Text('부서 정보가 없습니다. 새 연락처를 추가해보세요.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8.0),
              itemCount: departments.length,
              itemBuilder: (context, index) {
                final department = departments[index];
                return ExpansionTile(
                  title: Text(
                    department,
                    style: GoogleFonts.notoSans(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    _buildDepartmentContacts(department),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('부서 정보를 불러오는 중 에러가 발생했습니다: $error'),
          ),
        );
  }

  Widget _buildDepartmentContacts(String department) {
    return ref.watch(contactsByDepartmentProvider(department)).when(
          data: (contacts) {
            if (contacts.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('이 부서에는 연락처가 없습니다.'),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return _buildContactListTile(contact);
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Text('연락처를 불러오는 중 에러가 발생했습니다: $error'),
          ),
        );
  }

  Widget _buildContactListTile(Contact contact) {
    // Generate an avatar color based on the contact's name
    final int colorIndex = contact.name.hashCode % 8;
    final List<Color> avatarColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    final Color avatarColor = avatarColors[colorIndex];

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: avatarColor,
        child: Text(
          contact.name.isNotEmpty ? contact.name[0] : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        contact.name,
        style: GoogleFonts.notoSans(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${contact.position} | ${contact.department}',
        style: GoogleFonts.notoSans(
          color: Colors.grey.shade600,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        ref.read(selectedContactProvider.notifier).state = contact;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContactDetailScreen(contact: contact),
          ),
        );
      },
    );
  }
}
