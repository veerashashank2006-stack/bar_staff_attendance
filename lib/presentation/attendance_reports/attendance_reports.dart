import 'dart:convert';
import 'dart:io' if (dart.library.io) 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sizer/sizer.dart';
import 'package:universal_html/html.dart' as html;

import '../../core/app_export.dart';
import './widgets/attendance_table_widget.dart';
import './widgets/date_range_picker_widget.dart';
import './widgets/export_toolbar_widget.dart';
import './widgets/filter_chips_widget.dart';
import './widgets/quick_date_fab_widget.dart';

class AttendanceReports extends StatefulWidget {
  const AttendanceReports({super.key});

  @override
  State<AttendanceReports> createState() => _AttendanceReportsState();
}

class _AttendanceReportsState extends State<AttendanceReports> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<String> _activeFilters = [];
  bool _isLoading = false;
  bool _isExporting = false;
  String? _exportingType;
  List<Map<String, dynamic>> _attendanceData = [];

  // Mock attendance data
  final List<Map<String, dynamic>> _mockAttendanceData = [
    {
      "id": 1,
      "date": "12/20/2024",
      "login": "09:00 AM",
      "logout": "05:30 PM",
      "hours": "8.5",
      "status": "Present",
      "employeeId": "EMP001",
      "location": "Main Office"
    },
    {
      "id": 2,
      "date": "12/19/2024",
      "login": "09:15 AM",
      "logout": "05:45 PM",
      "hours": "8.5",
      "status": "Late",
      "employeeId": "EMP001",
      "location": "Main Office"
    },
    {
      "id": 3,
      "date": "12/18/2024",
      "login": "09:00 AM",
      "logout": "02:00 PM",
      "hours": "5.0",
      "status": "Partial",
      "employeeId": "EMP001",
      "location": "Main Office"
    },
    {
      "id": 4,
      "date": "12/17/2024",
      "login": "--",
      "logout": "--",
      "hours": "0.0",
      "status": "Absent",
      "employeeId": "EMP001",
      "location": "Main Office"
    },
    {
      "id": 5,
      "date": "12/16/2024",
      "login": "08:45 AM",
      "logout": "05:15 PM",
      "hours": "8.5",
      "status": "Present",
      "employeeId": "EMP001",
      "location": "Main Office"
    },
    {
      "id": 6,
      "date": "12/13/2024",
      "login": "09:00 AM",
      "logout": "05:30 PM",
      "hours": "8.5",
      "status": "Present",
      "employeeId": "EMP001",
      "location": "Main Office"
    },
    {
      "id": 7,
      "date": "12/12/2024",
      "login": "09:30 AM",
      "logout": "05:45 PM",
      "hours": "8.25",
      "status": "Late",
      "employeeId": "EMP001",
      "location": "Main Office"
    },
    {
      "id": 8,
      "date": "12/11/2024",
      "login": "09:00 AM",
      "logout": "05:30 PM",
      "hours": "8.5",
      "status": "Present",
      "employeeId": "EMP001",
      "location": "Main Office"
    },
    {
      "id": 9,
      "date": "12/10/2024",
      "login": "08:50 AM",
      "logout": "05:20 PM",
      "hours": "8.5",
      "status": "Present",
      "employeeId": "EMP001",
      "location": "Main Office"
    },
    {
      "id": 10,
      "date": "12/09/2024",
      "login": "09:00 AM",
      "logout": "01:30 PM",
      "hours": "4.5",
      "status": "Partial",
      "employeeId": "EMP001",
      "location": "Main Office"
    }
  ];

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Filter data based on date range
    final filteredData = _mockAttendanceData.where((record) {
      final recordDate = _parseDate(record['date'] as String);
      return recordDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          recordDate.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    setState(() {
      _attendanceData = filteredData;
      _isLoading = false;
      _updateActiveFilters();
    });
  }

  DateTime _parseDate(String dateString) {
    final parts = dateString.split('/');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  void _updateActiveFilters() {
    final filters = <String>[];

    // Add date range filter
    final dateRange = '${_formatDate(_startDate)} - ${_formatDate(_endDate)}';
    filters.add(dateRange);

    // Add status filters based on data
    final statuses = _attendanceData
        .map((record) => record['status'] as String)
        .toSet()
        .toList();

    if (statuses.length < 4) {
      filters.addAll(statuses.map((status) => 'Status: $status'));
    }

    setState(() {
      _activeFilters = filters;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  void _onDateRangeChanged(DateTime startDate, DateTime endDate) {
    setState(() {
      _startDate = startDate;
      _endDate = endDate;
    });
    _loadAttendanceData();
  }

  void _onFilterRemoved(String filter) {
    if (filter.startsWith('Status:')) {
      // Handle status filter removal
      final status = filter.substring(8);
      setState(() {
        _attendanceData = _mockAttendanceData.where((record) {
          final recordDate = _parseDate(record['date'] as String);
          return recordDate
                  .isAfter(_startDate.subtract(const Duration(days: 1))) &&
              recordDate.isBefore(_endDate.add(const Duration(days: 1)));
        }).toList();
      });
    }
    _updateActiveFilters();
  }

  void _onClearAllFilters() {
    setState(() {
      _startDate = DateTime.now().subtract(const Duration(days: 30));
      _endDate = DateTime.now();
    });
    _loadAttendanceData();
  }

  void _onViewDetails(Map<String, dynamic> record) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Attendance Details',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
                'Date', record['date'] as String, theme, colorScheme),
            _buildDetailRow(
                'Login Time', record['login'] as String, theme, colorScheme),
            _buildDetailRow(
                'Logout Time', record['logout'] as String, theme, colorScheme),
            _buildDetailRow(
                'Hours Worked', record['hours'] as String, theme, colorScheme),
            _buildDetailRow(
                'Status', record['status'] as String, theme, colorScheme),
            _buildDetailRow('Employee ID', record['employeeId'] as String,
                theme, colorScheme),
            _buildDetailRow(
                'Location', record['location'] as String, theme, colorScheme),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 25.w,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onExportSingleDay(Map<String, dynamic> record) async {
    setState(() {
      _isExporting = true;
      _exportingType = 'Single';
    });

    try {
      final csvContent = _generateSingleDayCSV(record);
      final fileName =
          'attendance_${record['date']?.toString().replaceAll('/', '_')}.csv';
      await _downloadFile(csvContent, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Single day report exported successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
        _exportingType = null;
      });
    }
  }

  String _generateSingleDayCSV(Map<String, dynamic> record) {
    final buffer = StringBuffer();
    buffer.writeln('Date,Login,Logout,Hours,Status,Employee ID,Location');
    buffer.writeln(
        '${record['date']},${record['login']},${record['logout']},${record['hours']},${record['status']},${record['employeeId']},${record['location']}');
    return buffer.toString();
  }

  Future<void> _onExportPDF() async {
    setState(() {
      _isExporting = true;
      _exportingType = 'PDF';
    });

    try {
      final pdfContent = _generatePDFContent();
      await _downloadFile(pdfContent, 'attendance_report.pdf');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF report exported successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF export failed. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
        _exportingType = null;
      });
    }
  }

  Future<void> _onExportExcel() async {
    setState(() {
      _isExporting = true;
      _exportingType = 'Excel';
    });

    try {
      final csvContent = _generateCSVContent();
      await _downloadFile(csvContent, 'attendance_report.csv');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel report exported successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel export failed. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
        _exportingType = null;
      });
    }
  }

  String _generatePDFContent() {
    final buffer = StringBuffer();
    buffer.writeln('ATTENDANCE REPORT');
    buffer.writeln('================');
    buffer.writeln(
        'Date Range: ${_formatDate(_startDate)} - ${_formatDate(_endDate)}');
    buffer.writeln('Generated: ${_formatDate(DateTime.now())}');
    buffer.writeln('');
    buffer.writeln('Date\t\tLogin\t\tLogout\t\tHours\tStatus');
    buffer.writeln('----\t\t-----\t\t------\t\t-----\t------');

    for (final record in _attendanceData) {
      buffer.writeln(
          '${record['date']}\t${record['login']}\t${record['logout']}\t${record['hours']}\t${record['status']}');
    }

    return buffer.toString();
  }

  String _generateCSVContent() {
    final buffer = StringBuffer();
    buffer.writeln('Date,Login,Logout,Hours,Status,Employee ID,Location');

    for (final record in _attendanceData) {
      buffer.writeln(
          '${record['date']},${record['login']},${record['logout']},${record['hours']},${record['status']},${record['employeeId']},${record['location']}');
    }

    return buffer.toString();
  }

  Future<void> _downloadFile(String content, String filename) async {
    if (kIsWeb) {
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);
    }
  }

  void _onRefresh() {
    _loadAttendanceData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Attendance Reports',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back_ios',
            color: colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              _onRefresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Sticky header with date range picker
          DateRangePickerWidget(
            startDate: _startDate,
            endDate: _endDate,
            onDateRangeChanged: _onDateRangeChanged,
            onClearFilters: _onClearAllFilters,
          ),

          // Filter chips
          FilterChipsWidget(
            activeFilters: _activeFilters,
            onFilterRemoved: _onFilterRemoved,
            onClearAll: _onClearAllFilters,
          ),

          SizedBox(height: 1.h),

          // Attendance table
          Expanded(
            child: AttendanceTableWidget(
              attendanceData: _attendanceData,
              onViewDetails: _onViewDetails,
              onExportSingleDay: _onExportSingleDay,
              onRefresh: _onRefresh,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),

      // Bottom export toolbar
      bottomNavigationBar: ExportToolbarWidget(
        onExportPDF: _onExportPDF,
        onExportExcel: _onExportExcel,
        isExporting: _isExporting,
        exportingType: _exportingType,
      ),

      // Quick date range FAB
      floatingActionButton: QuickDateFabWidget(
        onDateRangeSelected: _onDateRangeChanged,
      ),
    );
  }
}
