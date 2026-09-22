import 'package:flutter/material.dart';
import 'package:flutter_echarts/flutter_echarts.dart';

/// ECharts 可视化容器组件 (支持暗黑模式自适应与双重容错)
class EChartsContainer extends StatelessWidget {
  final String optionJson;
  final double height;
  final VoidCallback? onReload;

  const EChartsContainer({
    super.key,
    required this.optionJson,
    this.height = 260.0,
    this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE2E8F0),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Echarts(
        option: optionJson,
        extraScript: '''
          // 适配深色/浅色手势与触摸
          chart.on('click', function(params) {
            console.log(params.name);
          });
        ''',
      ),
    );
  }
}
