import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/stress_session.dart';
import '../theme/app_theme.dart';
import 'analysis_screen.dart';
import 'session_viewer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final Set<String> openedSessions = {};

  String searchQuery = "";

  Map<String, dynamic> _safeMap(Map<String, dynamic> data) {
    if (data['timestamp'] is Timestamp) {
      data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toString();
    }
    return data;
  }

  String getStressLabel(int value) {
    switch (value) {
      case 0:
        return "Relaxed";
      case 1:
        return "Medium Stress";
      case 2:
        return "High Stress";
      case 3:
        return "Very High Stress";
      default:
        return "Unknown";
    }
  }

  Color getStressColor(int value) {
    switch (value) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.yellow;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // -----------------------------
  // Updated predictStress to send raw signal and use Flask feature extraction
  // -----------------------------
  Future<int> predictStress(List<int> rawADC) async {
    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:5000/predict"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"raw_adc_list": rawADC}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result["stress_level"];
      }
    } catch (e) {
      print("Error predicting stress: $e");
    }

    return 0; // fallback to Relaxed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seren Dashboard")),
      body: Row(
        children: [
          /// LEFT SIDEBAR
          Container(
            width: 220,
            color: AppTheme.card,
            child: Column(
              children: [
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AnalysisScreen()),
                    );
                  },
                  child: const Text("New Session"),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom: 12,
                  ),
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search",
                        prefixIcon: const Icon(Icons.search, size: 18),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        filled: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// MAIN DASHBOARD AREA
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

                final filteredDocs = docs.where((doc) {
                  final rawData = doc.data() as Map<String, dynamic>;
                  final data = _safeMap(rawData);
                  final session = StressSession.fromMap(doc.id, data);

                  final sessionNumber = docs.length - docs.indexOf(doc);
                  final text =
                      "session $sessionNumber ${session.timestamp.toString()}";

                  return text.toLowerCase().contains(searchQuery);
                }).toList();

                return Column(
                  children: [
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final rawData =
                              filteredDocs[index].data()
                                  as Map<String, dynamic>;
                          final data = _safeMap(rawData);
                          final session = StressSession.fromMap(
                            filteredDocs[index].id,
                            data,
                          );
                          final sessionNumber =
                              docs.length - docs.indexOf(filteredDocs[index]);
                          final bool wasOpened = openedSessions.contains(
                            session.id,
                          );

                          // -----------------------------
                          // Convert rawValues to int before sending
                          // -----------------------------
                          final rawADCInts = session.rawValues
                              .map((e) => e.toInt())
                              .toList();

                          return FutureBuilder<int>(
                            future: predictStress(rawADCInts),
                            builder: (context, snapshot) {
                              final level = snapshot.data ?? 0;
                              final stressColor = getStressColor(level);

                              return Card(
                                color: wasOpened
                                    ? Colors.green.withOpacity(0.25)
                                    : null,
                                child: ListTile(
                                  leading: Icon(
                                    Icons.circle,
                                    color: stressColor,
                                    size: 14,
                                  ),
                                  title: Text(
                                    "Session $sessionNumber • ${session.timestamp.toLocal().toString().split('.')[0]}",
                                  ),
                                  subtitle: Text(
                                    snapshot.connectionState ==
                                            ConnectionState.waiting
                                        ? "Predicting..."
                                        : "Stress: ${getStressLabel(level)}",
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('stress_sessions')
                                          .doc(session.id)
                                          .delete();
                                    },
                                  ),
                                  onTap: () {
                                    setState(() {
                                      openedSessions.add(session.id);
                                    });

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            SessionViewer(session: session),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
