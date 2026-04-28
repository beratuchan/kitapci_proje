import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class SalesChart extends StatefulWidget {
  const SalesChart({super.key});

  @override
  State<SalesChart> createState() => _SalesChartState();
}

class _SalesChartState extends State<SalesChart> {
  Map<String, double> monthlySales = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final data = await orderProvider.getMonthlySales();
    setState(() {
      monthlySales = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (monthlySales.isEmpty) {
      return const Center(child: Text('Satış verisi yok'));
    }

    final entries = monthlySales.entries.toList();
    final spots = <FlSpot>[];
    for (int i = 0; i < entries.length; i++) {
      spots.add(FlSpot(i.toDouble(), entries[i].value));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Aylık Satış Tutarı (TL)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < entries.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(entries[index].key.split('-')[1]),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
                minY: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}