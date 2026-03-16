import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/stress_session.dart';
import '../utils/gsr_converter.dart';
import '../utils/kalman_filter.dart';
import 'analysis_page.dart'; // <-- import AnalysisPage

class SessionViewer extends StatelessWidget {
  final StressSession session;

  const SessionViewer({super.key, required this.session});

  /// ================= CSV EXPORT (WEB) =================
  Future<void> _exportCSV(BuildContext context) async {
    try {
      final rawADC = session.rawValues;

      final rawMicroSiemens = rawADC
          .map((e) => GsrConverter.adcToMicroSiemens(e))
          .toList();

      final kalman = KalmanFilter(processNoise: 0.01, measurementNoise: 0.5);

      final filteredValues = rawMicroSiemens
          .map((v) => kalman.update(v))
          .toList();

      // CSV header
      String csv = "Sample,Raw_ADC,Raw_uS,Filtered_uS\n";

      for (int i = 0; i < rawADC.length; i++) {
        csv += "$i,${rawADC[i]},${rawMicroSiemens[i]},${filteredValues[i]}\n";
      }

      // Create timestamped filename
      final now = DateTime.now();
      final timestamp =
          "${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}_${_twoDigits(now.hour)}-${_twoDigits(now.minute)}-${_twoDigits(now.second)}";
      final filename = "gsr_session_$timestamp.csv";

      final bytes = utf8.encode(csv);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", filename)
        ..click();

      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("CSV downloaded as $filename")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Export failed: $e")));
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final rawMicroSiemens = session.rawValues
        .map((e) => GsrConverter.adcToMicroSiemens(e))
        .toList();

    if (rawMicroSiemens.isEmpty) {
      return const Scaffold(body: Center(child: Text("No Data")));
    }

    /// ================= KALMAN FILTER =================
    final kalman = KalmanFilter(processNoise: 0.01, measurementNoise: 0.5);

    final filteredValues = rawMicroSiemens
        .map((v) => kalman.update(v))
        .toList();

    /// ================= STATS =================
    final avg = filteredValues.reduce((a, b) => a + b) / filteredValues.length;

    final rawSpots = List.generate(
      rawMicroSiemens.length,
      (i) => FlSpot(i.toDouble(), rawMicroSiemens[i]),
    );

    final filteredSpots = List.generate(
      filteredValues.length,
      (i) => FlSpot(i.toDouble(), filteredValues[i]),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        title: const Text("Session Analysis"),
        backgroundColor: const Color(0xFF14141C),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportCSV(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ================= STATS =================
              Text(
                "Filtered Average: ${avg.toStringAsFixed(2)} µS",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              /// ================= RAW GRAPH =================
              const Text(
                "Raw Signal",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 260,
                child: LineChart(_buildChartData(rawSpots, Colors.orange)),
              ),

              const SizedBox(height: 40),

              /// ================= FILTERED GRAPH =================
              const Text(
                "Kalman Filtered Signal",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 260,
                child: LineChart(
                  _buildChartData(filteredSpots, const Color(0xFF00F5A0)),
                ),
              ),

              const SizedBox(height: 40),

              /// ================= PREDICT STRESS BUTTON =================
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnalysisPage(session: session),
                    ),
                  );
                },
                icon: const Icon(Icons.analytics),
                label: const Text("Predict Stress"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LineChartData _buildChartData(List<FlSpot> spots, Color lineColor) {
    final maxX = spots.isNotEmpty ? spots.last.x : 1;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
        getDrawingVerticalLine: (value) =>
            FlLine(color: Colors.white.withOpacity(0.03), strokeWidth: 1),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),

      /// ================= AXIS TITLES =================
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          axisNameWidget: const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              "GSR (µS)",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          axisNameSize: 28,
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 55,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          axisNameWidget: const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              "Time (Samples)",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          axisNameSize: 30,
          sideTitles: SideTitles(
            showTitles: true,
            interval: (maxX / 10).toDouble() > 0 ? (maxX / 10).toDouble() : 1.0,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),

      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 3,
          color: lineColor,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [lineColor.withOpacity(0.3), lineColor.withOpacity(0.05)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}
