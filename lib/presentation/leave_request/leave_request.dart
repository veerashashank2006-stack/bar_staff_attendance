import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Full Leave Request screen connected to Supabase
/// Make sure Supabase is initialized in main.dart before running this page.

class LeaveRequest extends StatefulWidget {
  const LeaveRequest({Key? key}) : super(key: key);

  @override
  State<LeaveRequest> createState() => _LeaveRequestState();
}

class _LeaveRequestState extends State<LeaveRequest>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form fields
  String? _leaveType;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();

  List<Map<String, dynamic>> _leaveRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchLeaveRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  /// Load existing leave requests for the current user
  Future<void> _fetchLeaveRequests() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _showSnack('You must be logged in.', error: true);
        return;
      }
      final data = await supabase
          .from('leave_requests')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _leaveRequests = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      _showSnack('Error fetching requests: $e', error: true);
    }
  }

  /// Submit a new leave request to Supabase
  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      _showSnack('Select start and end dates', error: true);
      return;
    }
    if (_startDate!.isAfter(_endDate!)) {
      _showSnack('End date must be after start date', error: true);
      return;
    }

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _showSnack('You must be logged in.', error: true);
        return;
      }

      final days = _endDate!.difference(_startDate!).inDays + 1;
      final newRow = await supabase.from('leave_requests').insert({
        'user_id': user.id,
        'leave_type': _leaveType,
        'start_date': DateFormat('yyyy-MM-dd').format(_startDate!),
        'end_date': DateFormat('yyyy-MM-dd').format(_endDate!),
        'total_days': days,
        'reason': _reasonController.text.trim(),
      }).select();

      if (newRow.isNotEmpty) {
        setState(() => _leaveRequests.insert(0, newRow.first));
        _tabController.animateTo(1);
        _showSnack('Leave request submitted!');
        _formKey.currentState!.reset();
        _leaveType = null;
        _startDate = _endDate = null;
        _reasonController.clear();
      }
    } catch (e) {
      _showSnack('Failed to submit request: $e', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red : Colors.green),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => isStart ? _startDate = picked : _endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'New Request'), Tab(text: 'My Requests')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestForm(),
          RefreshIndicator(
            onRefresh: _fetchLeaveRequests,
            child: _leaveRequests.isEmpty
                ? const Center(child: Text('No leave requests found.'))
                : ListView.builder(
                    itemCount: _leaveRequests.length,
                    itemBuilder: (context, i) {
                      final l = _leaveRequests[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(
                            '${l['leave_type']} • ${l['status'] ?? 'pending'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                              '${l['start_date']} → ${l['end_date']}\nReason: ${l['reason']}'),
                          trailing: Text('${l['total_days']} days'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const Text('Submit Leave Request',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Leave Type Dropdown
            DropdownButtonFormField<String>(
              value: _leaveType,
              decoration: const InputDecoration(labelText: 'Leave Type'),
              items: const [
                DropdownMenuItem(value: 'sick', child: Text('Sick')),
                DropdownMenuItem(value: 'casual', child: Text('Casual')),
                DropdownMenuItem(value: 'vacation', child: Text('Vacation')),
                DropdownMenuItem(value: 'maternity', child: Text('Maternity')),
                DropdownMenuItem(value: 'paternity', child: Text('Paternity')),
                DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
              ],
              onChanged: (v) => setState(() => _leaveType = v),
              validator: (v) => v == null ? 'Select a leave type' : null,
            ),
            const SizedBox(height: 20),

            // Date pickers
            ListTile(
              title: Text(_startDate == null
                  ? 'Select Start Date'
                  : 'Start: ${DateFormat('yyyy-MM-dd').format(_startDate!)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(isStart: true),
            ),
            ListTile(
              title: Text(_endDate == null
                  ? 'Select End Date'
                  : 'End: ${DateFormat('yyyy-MM-dd').format(_endDate!)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(isStart: false),
            ),
            const SizedBox(height: 20),

            // Reason
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Enter a reason'
                  : (v.trim().length < 10
                      ? 'Reason must be at least 10 characters'
                      : null),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _submitRequest,
              child: const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}
