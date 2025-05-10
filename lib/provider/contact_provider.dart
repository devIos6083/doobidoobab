import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_life/models/contact_model.dart';
import 'package:focus_life/services/database_service.dart';

// Database service provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Contact list provider - automatically refreshes when database changes
final contactsProvider = FutureProvider<List<Contact>>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getContacts();
});

// Provider for all departments
final departmentsProvider = FutureProvider<List<String>>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getAllDepartments();
});

// Provider for contacts filtered by department
final contactsByDepartmentProvider =
    FutureProvider.family<List<Contact>, String>((ref, department) async {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getContactsByDepartment(department);
});

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Search results provider
final searchResultsProvider = FutureProvider<List<Contact>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) {
    return [];
  }
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.searchContacts(query);
});

// Selected department provider
final selectedDepartmentProvider = StateProvider<String?>((ref) => null);

// Selected contact provider
final selectedContactProvider = StateProvider<Contact?>((ref) => null);

// Contact operations notifier
class ContactNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseService _dbService;
  final Ref _ref;

  ContactNotifier(this._dbService, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> addContact(Contact contact) async {
    state = const AsyncValue.loading();
    try {
      await _dbService.insertContact(contact);
      _ref.refresh(contactsProvider);
      _ref.refresh(departmentsProvider);
      if (contact.department.isNotEmpty) {
        _ref.refresh(contactsByDepartmentProvider(contact.department));
      }
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateContact(Contact contact) async {
    state = const AsyncValue.loading();
    try {
      await _dbService.updateContact(contact);
      _ref.refresh(contactsProvider);
      _ref.refresh(departmentsProvider);
      if (contact.department.isNotEmpty) {
        _ref.refresh(contactsByDepartmentProvider(contact.department));
      }
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteContact(int id) async {
    state = const AsyncValue.loading();
    try {
      await _dbService.deleteContact(id);
      _ref.refresh(contactsProvider);
      _ref.refresh(departmentsProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Contact operations provider
final contactOperationsProvider =
    StateNotifierProvider<ContactNotifier, AsyncValue<void>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ContactNotifier(dbService, ref);
});
