import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RolesPanelPage extends StatefulWidget {
  const RolesPanelPage({super.key});

  @override
  State<RolesPanelPage> createState() => _RolesPanelPageState();
}

class _RolesPanelPageState extends State<RolesPanelPage> {
  final Color backgroundColor = const Color(0xFF1E1E2E); // Dark Blue-Gray
  final Color cardColor = const Color(0xFF25273D); // Charcoal Gray
  final Color textColor = const Color(0xFFEAEAEA); // Light Gray
  final Color accentColor = const Color(0xFFC59B76); // Muted Gold
  final Color adminColor = const Color(0xFFE74C3C); // Soft Red
  final Color userColor = const Color(0xFF3498DB); // Muted Blue

  Future<void> _updateUserRole(String userId, String newRole) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'role': newRole,
    });
  }

  Future<void> _deleteUser(String userId) async {
    if (!mounted) return;

    bool confirmDelete = await _showConfirmationDialog(
        "Are you sure you want to delete this user?");

    if (!mounted) return;

    if (confirmDelete) {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User deleted successfully!")),
      );
    }
  }

  Future<bool> _showConfirmationDialog(String message) async {
    return await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: cardColor,
              title: Text("Confirm Action", style: TextStyle(color: textColor)),
              content: Text(message, style: TextStyle(color: textColor)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("Cancel", style: TextStyle(color: textColor)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: adminColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: const Text("Delete",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _addNewUser(BuildContext context) async {
    final TextEditingController firstNameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    String selectedRole = "user";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add New User"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: "First Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: "Last Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: "Role",
                  border: OutlineInputBorder(),
                ),
                items: ["user", "admin"].map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedRole = value!;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (firstNameController.text.isEmpty ||
                    lastNameController.text.isEmpty ||
                    emailController.text.isEmpty ||
                    phoneController.text.isEmpty) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all fields!")),
                  );
                  return;
                }

                var existingUsers = await FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: emailController.text)
                    .get();

                var existingPhones = await FirebaseFirestore.instance
                    .collection('users')
                    .where('phone', isEqualTo: phoneController.text)
                    .get();

                if (!context.mounted) {
                  return;
                }

                if (existingUsers.docs.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Email is already registered!")),
                  );
                  return;
                }

                if (existingPhones.docs.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Phone number already registered!")),
                  );
                  return;
                }

                String userId =
                    FirebaseFirestore.instance.collection('users').doc().id;

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .set({
                  'firstName': firstNameController.text,
                  'lastName': lastNameController.text,
                  'email': emailController.text,
                  'phone': phoneController.text,
                  'role': selectedRole,
                });

                if (!context.mounted) return;

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("User added successfully!")),
                );
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    return role == "admin" ? Colors.redAccent : Colors.blueAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        iconTheme: IconThemeData(color: textColor),
        title: Text("Manage User Roles", style: TextStyle(color: textColor)),
        backgroundColor: cardColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              String userId = user.id;
              String firstName = user['firstName'] ?? "Unknown";
              String lastName = user['lastName'] ?? "";
              String email = user['email'] ?? "No Email";
              String role = user['role'] ?? "user";

              return Card(
                color: cardColor,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _getRoleColor(role), width: 1.2),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$firstName $lastName",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor),
                          ),
                          const SizedBox(height: 4),
                          Text(email,
                              style: TextStyle(
                                  color: textColor.withValues(alpha: 0.7))),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getRoleColor(role).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: TextStyle(
                                color: _getRoleColor(role),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteUser(userId),
                          ),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: role,
                              dropdownColor: cardColor,
                              onChanged: (newRole) {
                                if (newRole != null) {
                                  _updateUserRole(userId, newRole);
                                }
                              },
                              items: ["user", "admin"].map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Text(
                                    role.toUpperCase(),
                                    style: TextStyle(color: textColor),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewUser(context),
        backgroundColor: accentColor,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}
