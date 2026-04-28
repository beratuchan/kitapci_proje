// lib/screens/sales_chart.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/order_provider.dart';

class SalesChart extends StatefulWidget {
  const SalesChart({super.key});

  @override
  State<SalesChart> createState() => _SalesChartState();
}

class _SalesChartState extends State<SalesChart> {
  Map<String, double> monthlySales = {};
  bool isLoading = true;
  int touchedIndex = -1; // tooltip için

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

  String _formatCurrency(double value) {
    return '${value.toStringAsFixed(2)} TL';
  }

  String _getMonthName(int monthNumber) {
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    return months[monthNumber - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (monthlySales.isEmpty) {
      return const Center(child: Text('Henüz satış verisi yok'));
    }

    final entries = monthlySales.entries.toList();
    final spots = <FlSpot>[];

    for (int i = 0; i < entries.length; i++) {
      spots.add(FlSpot(i.toDouble(), entries[i].value));
    }

    // Y ekseninin maksimum değerini bul (biraz pay bırak)
    double maxY = 0;
    for (var entry in entries) {
      if (entry.value > maxY) maxY = entry.value;
    }
    maxY = maxY * 1.1; // %10 boşluk

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Aylık Satış Tutarı (TL)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${entries.first.key} - ${entries.last.key} arası',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final monthYear = entries[spot.x.toInt()].key;
                        final value = spot.y;
                        return LineTooltipItem(
                          '$monthYear\n${_formatCurrency(value)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < entries.length) {
                          final monthYear = entries[index].key; // "2025-04"
                          final parts = monthYear.split('-');
                          final monthNum = int.parse(parts[1]);
                          final monthName = _getMonthName(monthNum);
                          final yearShort = parts[0].substring(2); // "25"
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('$monthName\n$yearShort',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatCurrency(value),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                      interval: maxY / 5, // 5 eşit aralık
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    bottom: BorderSide(),
                    left: BorderSide(),
                    top: BorderSide.none,
                    right: BorderSide.none,
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(color: Colors.grey, strokeWidth: 0.5, dashArray: [5]);
                  },
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true, // eğri çizgi daha profesyonel
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.blue,
                          strokeWidth: 1,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.2),
                    ),
                  ),
                ],
                minY: 0,
                maxY: maxY,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Grafik açıklaması
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 16, height: 16, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('Aylık toplam satış (TL)'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}