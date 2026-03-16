import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

import '../models/stress_session.dart';
import '../utils/gsr_converter.dart';
import '../theme/app_theme.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool _running = false;

  final int _maxSamples = 1000;

  final List<double> _rawValues = [];
  final List<FlSpot> _graph = [];

  double _liveValue = 0;
  double _liveAdcValue = 0;

  double _sum = 0;
  int _count = 0;
  int _t = 0;

  WebSocketChannel? _channel;

  void _startSession() {
    setState(() {
      _running = true;
      _rawValues.clear();
      _graph.clear();
      _sum = 0;
      _count = 0;
      _t = 0;
    });

    /// Connect to Node WebSocket server
    _channel = WebSocketChannel.connect(Uri.parse("ws://localhost:5000"));

    _channel!.stream.listen((message) {
      if (!_running) return;

      try {
        final data = jsonDecode(message);

        final adc = (data["value"] as num).toDouble();

        final conductance = GsrConverter.adcToMicroSiemens(adc);

        setState(() {
          _liveAdcValue = adc;
          _liveValue = conductance;

          _sum += conductance;
          _count++;

          _rawValues.add(adc);
          _graph.add(FlSpot(_t.toDouble(), adc));

          _t++;

          if (_t >= _maxSamples) {
            _stopSession();
          }
        });
      } catch (e) {
        print("WebSocket parse error: $e");
      }
    });
  }

  void _stopSession() async {
    _running = false;

    /// close websocket
    _channel?.sink.close();

    if (_count > 0) {
      final session = StressSession(
        id: const Uuid().v4(),
        averageStress: _sum / _count,
        rawValues: _rawValues,
        timestamp: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('stress_sessions')
          .doc(session.id)
          .set(session.toMap());
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _running = false;
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Session")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Live ADC: ${_liveAdcValue.toStringAsFixed(0)}",
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _running ? _stopSession : _startSession,
              child: Text(_running ? "Stop Session" : "Start Session"),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: _t > 0 ? _t.toDouble() : 1,
                  minY: _graph.isNotEmpty
                      ? _graph.map((e) => e.y).reduce((a, b) => a < b ? a : b)
                      : 0,
                  maxY: _graph.isNotEmpty
                      ? _graph.map((e) => e.y).reduce((a, b) => a > b ? a : b) *
                            1.1
                      : 1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _graph,
                      isCurved: true,
                      color: AppTheme.accent,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          "ADC Value",
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
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
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
                        interval: (_t > 100) ? (_t / 10).toDouble() : 1,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
