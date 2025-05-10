// lib/screen/contact_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_life/models/contact_model.dart';
import 'package:focus_life/provider/contact_provider.dart';
import 'package:focus_life/utils/constant.dart';

class ContactDetailScreen extends ConsumerWidget {
  final Contact contact;

  const ContactDetailScreen({super.key, required this.contact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          contact.name,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteConfirmDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 32),
          Center(
            child: Hero(
              tag: 'contact-${contact.id}',
              child: CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.primary,
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0] : '?',
                  style: const TextStyle(fontSize: 48, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            contact.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${contact.department} / ${contact.position}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => _showCallScreen(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.call, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    contact.phoneNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCallScreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CallDialog(contact: contact),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('연락처 삭제'),
        content: Text('${contact.name}님의 연락처를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (contact.id != null) {
                ref
                    .read(contactOperationsProvider.notifier)
                    .deleteContact(contact.id!);
              }
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to contacts list
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class CallDialog extends StatelessWidget {
  final Contact contact;

  const CallDialog({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                const Text(
                  '연결중...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  contact.name,
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  contact.phoneNumber,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              child: Text(
                contact.name.isNotEmpty ? contact.name[0] : '?',
                style: const TextStyle(fontSize: 32, color: Colors.white),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.red,
                child: Icon(Icons.call_end, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
