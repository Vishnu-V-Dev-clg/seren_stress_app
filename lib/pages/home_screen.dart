import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/stress_session.dart';
import '../theme/app_theme.dart';
import 'analysis_screen.dart';
import 'analysis_page.dart';
import 'session_viewer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seren Dashboard")),
      body: Row(
        children: [
          Container(
            width: 220,
            color: AppTheme.card,
            child: Column(
              children: [
                const SizedBox(height: 30),

                /// NEW SESSION BUTTON
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AnalysisScreen()),
                    );
                  },
                  child: const Text("New Session"),
                ),

                const SizedBox(height: 20),

                /// MODEL ANALYSIS BUTTON
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AnalysisPage()),
                    );
                  },
                  child: const Text("Analysis"),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stress_sessions')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("No Previous Sessions"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final session = StressSession.fromMap(
                      docs[index].id,
                      docs[index].data() as Map<String, dynamic>,
                    );

                    return Card(
                      child: ListTile(
                        title: Text(
                          session.timestamp.toLocal().toString().split('.')[0],
                        ),
                        subtitle: Text(
                          "Average GSR: ${session.averageStress.toStringAsFixed(2)} µS",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('stress_sessions')
                                .doc(session.id)
                                .delete();
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SessionViewer(session: session),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
