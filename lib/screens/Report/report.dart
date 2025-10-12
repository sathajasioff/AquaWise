// screens/report_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/report_controller.dart';
import '../../models/report_data_model.dart';
import '../../widgets/pieChartWidget.dart';
import '../../widgets/BarChartWidget.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportController _controller = ReportController();
  late Future<ReportData> _weeklyReport;
  late Future<ReportData> _monthlyReport;
  ReportData? _currentReport;
  String _selectedPeriod = 'weekly';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    setState(() {
      _weeklyReport = _controller.getWeeklyReport();
      _monthlyReport = _controller.getMonthlyReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text('Water Usage Reports'),
        backgroundColor: const Color(0xFFFF9A00),
        foregroundColor: Colors.white,
        actions: [
          if (_currentReport != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _generatePdfReport,
              tooltip: 'Download PDF',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
            tooltip: 'Refresh Reports',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Selector
                  _buildPeriodSelector(),
                  const SizedBox(height: 20),
                  
                  // Report Content
                  FutureBuilder<ReportData>(
                    future: _selectedPeriod == 'weekly' ? _weeklyReport : _monthlyReport,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError) {
                        return _buildErrorWidget(snapshot.error.toString());
                      }
                      
                      if (snapshot.hasData) {
                        _currentReport = snapshot.data!;
                        return _buildReportContent(_currentReport!);
                      }
                      
                      return const Center(child: Text('No data available'));
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Period',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'weekly',
                  label: Text('Weekly'),
                  icon: Icon(Icons.calendar_view_week),
                ),
                ButtonSegment<String>(
                  value: 'monthly',
                  label: Text('Monthly'),
                  icon: Icon(Icons.calendar_view_month),
                ),
              ],
              selected: {_selectedPeriod},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedPeriod = newSelection.first;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent(ReportData report) {
    return Column(
      children: [
        // Summary Cards
        _buildSummaryCards(report),
        const SizedBox(height: 20),
        
        // Charts
        _buildChartsSection(report),
        const SizedBox(height: 20),
        
        // Bill Details
        _buildBillDetails(report),
      ],
    );
  }

  Widget _buildSummaryCards(ReportData report) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildSummaryCard(
          'Total Water Used',
          '${report.totalLiters.toStringAsFixed(1)} L',
          Icons.water_drop,
          Colors.blue,
        ),
        _buildSummaryCard(
          'Total Cost',
          '\$${report.totalCost.toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.green,
        ),
        _buildSummaryCard(
          'Avg Daily Usage',
          '${report.averageDailyUsage.toStringAsFixed(1)} L/day',
          Icons.trending_up,
          Colors.orange,
        ),
        _buildSummaryCard(
          'Most Used',
          report.mostUsedActivity,
          Icons.emoji_objects,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(ReportData report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Usage Analytics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Pie Chart - Usage by Activity
            _buildPieChart(report),
            const SizedBox(height: 24),
            
            // Bar Chart - Daily Usage
            _buildBarChart(report),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(ReportData report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Water Usage by Activity',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        WaterUsagePieChart(usageByActivity: report.usageByActivity),
      ],
    );
  }

  Widget _buildBarChart(ReportData report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Water Usage',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DailyUsageBarChart(dailyUsage: report.dailyUsage),
      ],
    );
  }

  Widget _buildBillDetails(ReportData report) {
    final bill = report.currentBill;
    if (bill == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Water Bill',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: const Text('Billing Period'),
              subtitle: Text(
                '${DateFormat('MMM dd, yyyy').format(bill.periodStart)} - ${DateFormat('MMM dd, yyyy').format(bill.periodEnd)}',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.speed, color: Colors.green),
              title: const Text('Rate per Liter'),
              subtitle: Text('\$${bill.ratePerLiter.toStringAsFixed(3)}/L'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_money, color: Colors.orange),
              title: const Text('Total Amount Due'),
              subtitle: Text(
                '\$${bill.totalCost.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Icon(
                bill.status == 'paid' ? Icons.check_circle : Icons.pending,
                color: bill.status == 'paid' ? Colors.green : Colors.orange,
              ),
              title: const Text('Status'),
              subtitle: Text(
                bill.status.toUpperCase(),
                style: TextStyle(
                  color: bill.status == 'paid' ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error Loading Report',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadReports,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9A00),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdfReport() async {
    if (_currentReport == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _controller.sharePdfReport(_currentReport!, _selectedPeriod);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF report generated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}