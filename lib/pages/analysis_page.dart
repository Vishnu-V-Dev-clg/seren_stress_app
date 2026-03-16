import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

import '../models/stress_session.dart';
import '../utils/gsr_converter.dart';
import '../utils/kalman_filter.dart';

class AnalysisPage extends StatefulWidget {
  final StressSession session;

  const AnalysisPage({super.key, required this.session});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  bool loading = true;
  String? error;

  double mean = 0;
  double std = 0;
  double slope = 0;
  double variance = 0;
  int peaks = 0;
  int stressLevel = 0;

  /// Send raw ADC values to backend
  Future<void> predictStress(List<int> rawAdcValues) async {
    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:5000/predict"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "raw_adc_list": rawAdcValues,
        }), // backend expects this
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        setState(() {
          stressLevel = result["stress_level"] ?? 0;
          mean = result["mean"] ?? 0;
          std = result["std"] ?? 0;
          slope = result["slope"] ?? 0;
          variance = result["variance"] ?? 0;
          peaks = result["peaks"] ?? 0;
          loading = false;
        });
      } else {
        setState(() {
          error = "Server error: ${response.statusCode}";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Connection failed: $e";
        loading = false;
      });
    }
  }

  String stressText(int value) {
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

  Color stressColor(int value) {
    switch (value) {
      case 0:
        return Colors.greenAccent;
      case 1:
        return Colors.yellowAccent;
      case 2:
        return Colors.orangeAccent;
      case 3:
        return Colors.redAccent;
      default:
        return Colors.white;
    }
  }

  late List<double> rawMicroSiemens;
  late List<double> filtered;

  @override
  void initState() {
    super.initState();

    final rawADC = widget.session.rawValues.map((e) => e.toInt()).toList();

    rawMicroSiemens = rawADC
        .map((e) => GsrConverter.adcToMicroSiemens(e.toDouble()))
        .toList();

    final kalman = KalmanFilter(processNoise: 0.01, measurementNoise: 0.5);

    filtered = rawMicroSiemens.map((v) => kalman.update(v)).toList();

    // Send raw ADC values to backend (fixes KeyError and matches HomeScreen)
    predictStress(rawADC);
  }

  @override
  Widget build(BuildContext context) {
    final filteredSpots = List.generate(
      filtered.length,
      (i) => FlSpot(i.toDouble(), filtered[i]),
    );

    final rawSpots = List.generate(
      rawMicroSiemens.length,
      (i) => FlSpot(i.toDouble(), rawMicroSiemens[i]),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E13),
      appBar: AppBar(
        title: const Text("Stress Prediction Analysis"),
        backgroundColor: const Color(0xFF15151C),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Text(
                error!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _resultCard(),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(child: _statsCard()),
                      const SizedBox(width: 20),
                      Expanded(child: _sessionInfo()),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "GSR Signal (Raw vs Filtered)",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 260,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: rawSpots,
                            isCurved: false,
                            barWidth: 2,
                            color: Colors.orange,
                            dotData: const FlDotData(show: false),
                          ),
                          LineChartBarData(
                            spots: filteredSpots,
                            isCurved: true,
                            barWidth: 3,
                            color: Colors.greenAccent,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _resultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF191923),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Model Prediction",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Text(
                stressText(stressLevel),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Icon(
            stressLevel == 0 ? Icons.self_improvement : Icons.psychology,
            color: stressColor(stressLevel),
            size: 50,
          ),
        ],
      ),
    );
  }

  Widget _statsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF191923),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Computed Features",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            "Mean: ${mean.toStringAsFixed(4)}",
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            "Std: ${std.toStringAsFixed(4)}",
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            "Slope: ${slope.toStringAsFixed(6)}",
            style: const TextStyle(color: Colors.white70),
          ),
          Text("Peaks: $peaks", style: const TextStyle(color: Colors.white70)),
          Text(
            "Variance: ${variance.toStringAsFixed(6)}",
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _sessionInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF191923),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Session Info",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          SizedBox(height: 10),
          Text("Samples: 1000", style: TextStyle(color: Colors.white70)),
          Text("Sampling Rate: 20 Hz", style: TextStyle(color: Colors.white70)),
          Text(
            "Recording Time: 50 sec",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
