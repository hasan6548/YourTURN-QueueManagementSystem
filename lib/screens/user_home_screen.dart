import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/queue_service.dart';
import 'login_screen.dart';
import 'queue_status_screen.dart'; // ✅ import added

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  bool isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final queue = Provider.of<QueueService>(context);
    final uid = auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('YourTURN'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // 🔹 Now Serving
            StreamBuilder<int>(
              stream: queue.getCurrentToken(),
              builder: (context, snapshot) {
                final current = snapshot.data ?? 0;
                return Card(
                  color: const Color(0xFF1A73E8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 40),
                    child: Column(
                      children: [
                        const Text('Now Serving',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 16)),
                        Text('$current',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 64,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // 🔹 My Token
            StreamBuilder<int?>(
              stream: queue.getUserToken(uid),
              builder: (context, snapshot) {
                final myToken = snapshot.data;

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                // ❌ No token → Show button
                if (myToken == null) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.confirmation_number,
                          color: Colors.white),
                      label: isGenerating
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Get My Token',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 18)),
                      onPressed: isGenerating
                          ? null
                          : () async {
                              setState(() => isGenerating = true);
                              await queue.generateToken(uid);
                              setState(() => isGenerating = false);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                        padding:
                            const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  );
                }

                // ✅ Has token → Show details
                return Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text('Your Token',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey)),
                            Text('$myToken',
                                style: const TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A73E8))),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🔹 People Ahead
                    StreamBuilder<int>(
                      stream: queue.getPeopleAhead(myToken),
                      builder: (context, aheadSnap) {
                        final ahead = aheadSnap.data ?? 0;
                        final waitMins = ahead * 5;

                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Icon(Icons.people,
                                        color: Color(0xFF1A73E8),
                                        size: 36),
                                    const SizedBox(height: 8),
                                    Text('$ahead',
                                        style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold)),
                                    const Text('People Ahead',
                                        style:
                                            TextStyle(color: Colors.grey)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Icon(Icons.timer,
                                        color: Colors.orange, size: 36),
                                    const SizedBox(height: 8),
                                    Text('~$waitMins min',
                                        style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold)),
                                    const Text('Est. Wait',
                                        style:
                                            TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // ✅ NEW BUTTON (Added correctly)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.list_alt),
                        label: const Text('View Full Queue'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const QueueStatusScreen()),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}