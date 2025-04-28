import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talky/controller/new_message_controller.dart';
import 'package:talky/utils/app_colors.dart';

class NewMessageScreen extends StatelessWidget {
  static const String routeName = '/new_message';
  final NewMessageController controller = Get.put(NewMessageController());

  NewMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Talky Contacts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.permissionDenied.value) {
                return const Center(
                  child: Text(
                    'Permission denied. Enable contacts permission in settings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                );
              }

              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.contacts.isEmpty) {
                return const Center(child: Text('No contacts found.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: controller.contacts.length,
                itemBuilder: (context, index) {
                  final contact = controller.contacts[index];
                  final String phoneNumber =
                      NewMessageController.normalizeNumber(
                        contact.phones.isNotEmpty
                            ? contact.phones.first.number
                            : '',
                      );
                  final bool isTalkyUser = controller.talkyUsers.contains(
                    phoneNumber,
                  );

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: AppColors.background,
                      child: Text(
                        contact.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    title: Text(contact.displayName),
                    subtitle: Text(phoneNumber),
                    trailing:
                        isTalkyUser
                            ? IconButton(
                              icon: const Icon(
                                Icons.message,
                                color: AppColors.buttonColor,
                              ),
                              onPressed:
                                  () => controller.startChat(phoneNumber),
                            )
                            : TextButton(
                              onPressed:
                                  () => controller.inviteUser(phoneNumber),
                              child: const Text(
                                'Invite',
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
