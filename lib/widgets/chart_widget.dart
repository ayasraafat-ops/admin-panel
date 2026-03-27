import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/app_colors.dart';

class ChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const ChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal =
        data.fold<int>(0, (prev, d) => max(prev, d['count'] as int));
    final maxHeight = max(maxVal, 1);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 تسجيلات آخر 7 أيام',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((day) {
                final count = day['count'] as int;
                final heightPercent = count / maxHeight;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: AnimatedContainer(
                            duration: const Duration(seconds: 1),
                            curve: Curves.easeOutCubic,
                            width: 32,
                            height: max(heightPercent * 90, 4),
                            decoration: BoxDecoration(
                              gradient: AppColors.barGradient,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          day['name'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}