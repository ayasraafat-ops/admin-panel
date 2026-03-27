import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class TopBar extends StatelessWidget {
  final bool isConnected;
  final VoidCallback onRefresh;
  final VoidCallback onExportCSV;
  final VoidCallback onExportJSON;
  final VoidCallback onDeleteAll;
  final VoidCallback onLogout;

  const TopBar({
    super.key,
    required this.isConnected,
    required this.onRefresh,
    required this.onExportCSV,
    required this.onExportJSON,
    required this.onDeleteAll,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // العنوان
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: const Text(
                  '🎛️ لوحة الإدارة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // حالة الاتصال
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppColors.green.withOpacity(0.15)
                      : AppColors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isConnected ? '🟢 متصل' : '🔴 غير متصل',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isConnected ? AppColors.green : AppColors.red,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),

          // الأزرار
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _TopButton(
                  label: '🔄 تحديث',
                  color: AppColors.blue,
                  onTap: onRefresh,
                ),
                const SizedBox(width: 6),
                _TopButton(
                  label: '📄 CSV',
                  color: AppColors.green,
                  onTap: onExportCSV,
                ),
                const SizedBox(width: 6),
                _TopButton(
                  label: '📋 JSON',
                  color: AppColors.green,
                  onTap: onExportJSON,
                ),
                const SizedBox(width: 6),
                _TopButton(
                  label: '🗑️ حذف الكل',
                  color: AppColors.red,
                  onTap: onDeleteAll,
                ),
                const SizedBox(width: 6),
                _TopButton(
                  label: '🚪 خروج',
                  color: Colors.white54,
                  onTap: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TopButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}