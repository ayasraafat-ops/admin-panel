import 'package:flutter/material.dart';
import '../models/registration.dart';
import '../utils/app_colors.dart';
import '../utils/helpers.dart';

class DataTableWidget extends StatelessWidget {
  final List<Registration> data;
  final bool isLoading;
  final Set<int> visiblePasswords;
  final Function(String) onSearch;
  final Function(String) onFilter;
  final Function(int) onTogglePassword;
  final Function(Registration) onCopy;
  final Function(Registration) onView;
  final Function(int) onDelete;

  const DataTableWidget({
    super.key,
    required this.data,
    required this.isLoading,
    required this.visiblePasswords,
    required this.onSearch,
    required this.onFilter,
    required this.onTogglePassword,
    required this.onCopy,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // شريط الأدوات
          _buildToolbar(context),
          const Divider(
            height: 1,
            color: Color(0x14FFFFFF),
          ),
          // المحتوى
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 البيانات المسجلة',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // حقل البحث
              Expanded(
                child: TextField(
                  onChanged: onSearch,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '🔍 بحث...',
                    hintStyle:
                        TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.blue,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // فلتر
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'all',
                    dropdownColor: const Color(0xFF1A1A2E),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('الكل')),
                      DropdownMenuItem(
                          value: 'today', child: Text('اليوم')),
                      DropdownMenuItem(
                          value: 'week', child: Text('هذا الأسبوع')),
                      DropdownMenuItem(
                          value: 'month', child: Text('هذا الشهر')),
                    ],
                    onChanged: (v) => onFilter(v ?? 'all'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: AppColors.blue,
              strokeWidth: 3,
            ),
            SizedBox(height: 10),
            Text(
              'جاري التحميل...',
              style: TextStyle(color: Color(0x4DFFFFFF)),
            ),
          ],
        ),
      );
    }

    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(50),
        child: Column(
          children: [
            Text(
              '📭',
              style: TextStyle(
                fontSize: 50,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'لا توجد بيانات',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final row = data[index];
        return _buildRow(row, index);
      },
    );
  }

  Widget _buildRow(Registration row, int index) {
    final isPassVisible = visiblePasswords.contains(row.id);
    final date = row.createdAt;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.04),
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onView(row),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الصف الأول: الرقم والبريد
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        row.email,
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // كلمة المرور
                GestureDetector(
                  onTap: () => onTogglePassword(row.id),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isPassVisible
                          ? '${row.password} 👁️'
                          : '•••••• 👁️‍🗨️',
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // IP والتاريخ
                Row(
                  children: [
                    Text(
                      row.ipAddress ?? '---',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.35),
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Helpers.relativeTime(date),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                        Text(
                          '${Helpers.formatDate(date)} ${Helpers.formatTime(date)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.35),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // أزرار الإجراءات
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _ActionButton(
                      icon: Icons.copy_rounded,
                      color: AppColors.blue,
                      onTap: () => onCopy(row),
                    ),
                    const SizedBox(width: 6),
                    _ActionButton(
                      icon: Icons.visibility_rounded,
                      color: AppColors.pink,
                      onTap: () => onView(row),
                    ),
                    const SizedBox(width: 6),
                    _ActionButton(
                      icon: Icons.delete_rounded,
                      color: AppColors.red,
                      onTap: () => onDelete(row.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}