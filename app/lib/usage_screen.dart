import 'package:flutter/material.dart';
import 'usage_data.dart';
import 'usage_data_source.dart';
import 'services/api_service.dart';

/// A screen that allows users to track their inhaler usage and view history.
/// This screen provides functionality to:
/// - Count daily inhaler uses
/// - Add notes for each usage session
/// - View historical usage data grouped by date
/// - Filter and search through usage history
class UsageScreen extends StatefulWidget {
  const UsageScreen({super.key});

  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> {
  final UsageDataSource _dataSource = UsageDataSource();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  int _currentCount = 0;
  List<UsageData> _usageHistory = [];
  DateTime? _lastUsageTime;
  
  // Filtering options
  String _searchQuery = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadUsageHistory();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _loadUsageHistory() async {
    final history = await _dataSource.getUsageData();
    setState(() {
      _usageHistory = history;
      // Update last usage time if there's any history
      if (history.isNotEmpty) {
        _lastUsageTime = history.last.timestamp;
      }
    });
  }

  // Groups usage data by date for better organization
  Map<DateTime, List<UsageData>> _getGroupedUsageData() {
    final Map<DateTime, List<UsageData>> grouped = {};
    
    for (var usage in _filterUsageData()) {
      final date = DateTime(
        usage.timestamp.year,
        usage.timestamp.month,
        usage.timestamp.day,
      );
      
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(usage);
    }
    
    return Map.fromEntries(
      grouped.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key))
    );
  }

  // Filters usage data based on search query and selected date
  List<UsageData> _filterUsageData() {
    return _usageHistory.where((usage) {
      final matchesSearch = _searchQuery.isEmpty ||
          usage.notes.toLowerCase().contains(_searchQuery);
      
      final matchesDate = _selectedDate == null ||
          (usage.timestamp.year == _selectedDate!.year &&
           usage.timestamp.month == _selectedDate!.month &&
           usage.timestamp.day == _selectedDate!.day);
      
      return matchesSearch && matchesDate;
    }).toList();
  }

  Future<void> _saveCurrentUsage() async {
    if (_currentCount > 0) {
      final data = UsageData(
        timestamp: DateTime.now(),
        inhalerUseCount: _currentCount,
        notes: _notesController.text.trim(),
      );
      
      await _dataSource.saveUsageData(data);
      _loadUsageHistory();
      
      setState(() {
        _currentCount = 0;
        _notesController.clear();
        _lastUsageTime = data.timestamp;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usage saved successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage Tracking'),
        backgroundColor: const Color(0xFFF4A7B9),
        actions: [
          // Filter button
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showDatePicker(context),
          ),
          // Clear filters button
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _selectedDate = null),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildUsageCounter(),
          if (_lastUsageTime != null) _buildLastUsageTime(),
          _buildNotesField(),
          _buildSaveButton(),
          _buildSearchField(),
          const Divider(height: 32),
          Expanded(child: _buildUsageHistory()),
        ],
      ),
    );
  }

  // Displays the last time the inhaler was used
  Widget _buildLastUsageTime() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Last used: ${_formatDateTime(_lastUsageTime!)}',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
    );
  }

  // Builds the search field for filtering usage history
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search notes',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildUsageCounter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Today\'s Inhaler Usage',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _currentCount > 0
                    ? () => setState(() => _currentCount--)
                    : null,
                iconSize: 32,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Text(
                  _currentCount.toString(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _currentCount++),
                iconSize: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _notesController,
        decoration: InputDecoration(
          labelText: 'Notes',
          hintText: 'Add any notes about today\'s usage',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        maxLines: 2,
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: _currentCount > 0 ? _saveCurrentUsage : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Save Usage',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _currentCount > 0 
                ? () => _shareWithWebsite() 
                : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              side: const BorderSide(color: Color(0xFF81D4FA)),
            ),
            icon: const Icon(Icons.language),
            label: const Text(
              'Share with Website',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareWithWebsite() async {
    if (_currentCount <= 0) return;
    
    final success = await _apiService.sendUsageData(
      _currentCount,
      _notesController.text.trim(),
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'Data shared with website dashboard!' 
                : 'Failed to share data with website',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Widget _buildUsageHistory() {
    final groupedData = _getGroupedUsageData();
    
    if (groupedData.isEmpty) {
      return const Center(
        child: Text(
          'No usage history yet',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: groupedData.length,
      itemBuilder: (context, index) {
        final date = groupedData.keys.elementAt(index);
        final usages = groupedData[date]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _formatDate(date),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE91E63),
                ),
              ),
            ),
            ...usages.map((usage) => _buildUsageCard(usage)),
          ],
        );
      },
    );
  }

  // Builds individual usage card
  Widget _buildUsageCard(UsageData usage) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF4A7B9),
          child: Text(
            usage.inhalerUseCount.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          'Used ${usage.inhalerUseCount} time${usage.inhalerUseCount == 1 ? '' : 's'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatTime(usage.timestamp)),
            if (usage.notes.isNotEmpty)
              Text(
                usage.notes,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        isThreeLine: usage.notes.isNotEmpty,
      ),
    );
  }

  // Shows date picker for filtering
  Future<void> _showDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'Yesterday';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  // Helper method to format time
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Helper method to format date and time
  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} at ${_formatTime(dateTime)}';
  }

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
