import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:app_v0/features/services/Database_helper.dart';

class SensorGraph extends StatefulWidget {
  final String tipo;

  const SensorGraph({Key? key, required this.tipo}) : super(key: key);

  @override
  _SensorGraphState createState() => _SensorGraphState();
}

class _SensorGraphState extends State<SensorGraph> {
  List<FlSpot> data = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final dados = await DatabaseHelper().getDadosAcelerometro(limite: 100);
      data.clear();

      for (int i = 0; i < dados.length; i++) {
        final d = dados[i];
        double value = 0;

        switch (widget.tipo) {
          case 'x': value = d['x']; break;
          case 'y': value = d['y']; break;
          case 'z': value = d['z']; break;
        }

        data.add(FlSpot(i.toDouble(), value));
      }
    } catch (e) {
      print('Erro ao carregar dados: $e');
    } finally {
      if (mounted) {
        setState(() => carregando = false);
      }
    }
  }

  Color _getColorForType() {
    switch (widget.tipo) {
      case 'x': return Colors.red;
      case 'y': return Colors.green;
      case 'z': return Colors.blue;
      default: return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return carregando
        ? Center(child: CircularProgressIndicator())
        : LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: data.isNotEmpty ? data.last.x : 1,
        minY: data.isNotEmpty ? data.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 1 : 0,
        maxY: data.isNotEmpty ? data.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1 : 1,
        lineBarsData: [
          LineChartBarData(
            spots: data,
            isCurved: true,
            color: _getColorForType(),
            barWidth: 2,
            belowBarData: BarAreaData(
              show: true,
              color: _getColorForType().withOpacity(0.3),
            ),
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}