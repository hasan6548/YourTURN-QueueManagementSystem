import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/queue_service.dart';

class QueueStatusScreen extends StatelessWidget {
  const QueueStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final queue = Provider.of<QueueService>(context);
    final uid = auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue Status'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // Current serving banner
            StreamBuilder<int>(
              stream: queue.getCurrentToken(),
              builder: (context, snapshot) {
                final current = snapshot.data ?? 0;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('Now Serving',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 16)),
                      Text('$current',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 56,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Full queue list
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Waiting Queue',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tokens')
                    .where('status', isEqualTo: 'waiting')
                    .orderBy('tokenNumber')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 64, color: Colors.green),
                          SizedBox(height: 12),
                          Text('Queue is empty!',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data =
                          docs[index].data() as Map<String, dynamic>;
                      final tokenNum = data['tokenNumber'];
                      final isMyToken = data['userId'] == uid;

                      return Card(
                        color: isMyToken
                            ? const Color(0xFFE8F0FE)
                            : null,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isMyToken
                                ? const Color(0xFF1A73E8)
                                : Colors.grey.shade300,
                            child: Text(
                              '$tokenNum',
                              style: TextStyle(
                                  color: isMyToken
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            isMyToken ? 'Your Token' : 'Token #$tokenNum',
                            style: TextStyle(
                                fontWeight: isMyToken
                                    ? FontWeight.bold
                                    : FontWeight.normal),
                          ),
                          subtitle: Text('Position: ${index + 1}'),
                          trailing: isMyToken
                              ? const Icon(Icons.person,
                                  color: Color(0xFF1A73E8))
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}