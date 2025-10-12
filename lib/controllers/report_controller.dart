// // controllers/report_controller.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'package:intl/intl.dart';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import '../models/water_usage_model.dart';
// import '../models/water_bill_model.dart';
// import '../models/report_data_model.dart';

// class ReportController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final double _ratePerLiter = 0.005; // $0.005 per liter

//   // 📊 Get weekly report data
//   Future<ReportData> getWeeklyReport() async {
//     final user = _auth.currentUser;
//     if (user == null) throw Exception('User not logged in');

//     final now = DateTime.now();
//     final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
//     final endOfWeek = startOfWeek.add(const Duration(days: 6));

//     return await _getReportData(startOfWeek, endOfWeek);
//   }

//   // 📊 Get monthly report data
//   Future<ReportData> getMonthlyReport() async {
//     final user = _auth.currentUser;
//     if (user == null) throw Exception('User not logged in');

//     final now = DateTime.now();
//     final startOfMonth = DateTime(now.year, now.month, 1);
//     final endOfMonth = DateTime(now.year, now.month + 1, 0);

//     return await _getReportData(startOfMonth, endOfMonth);
//   }

//   // 📊 Get custom period report
//   Future<ReportData> getCustomReport(DateTime start, DateTime end) async {
//     return await _getReportData(start, end);
//   }

//   // 🔧 Core report data generation
//   Future<ReportData> _getReportData(DateTime start, DateTime end) async {
//     final user = _auth.currentUser!;

//     // Get water usage records
//     final usageSnapshot = await _firestore
//         .collection('waterUsage')
//         .where('userId', isEqualTo: user.uid)
//         .where('timestamp', isGreaterThanOrEqualTo: start)
//         .where('timestamp', isLessThanOrEqualTo: end)
//         .get();

//     final usageRecords = usageSnapshot.docs
//         .map((doc) => WaterUsage.fromMap(doc.data()))
//         .toList();

//     // Calculate totals and breakdowns
//     double totalLiters = 0;
//     final usageByActivity = <String, double>{};
//     final dailyUsage = <String, double>{};
//     final weeklyUsage = <String, double>{};

//     for (final usage in usageRecords) {
//       // Total liters
//       totalLiters += usage.litersUsed;

//       // By activity
//       usageByActivity.update(
//         usage.activity,
//         (value) => value + usage.litersUsed,
//         ifAbsent: () => usage.litersUsed,
//       );

//       // Daily breakdown
//       final dateKey = DateFormat('MMM dd').format(usage.timestamp);
//       dailyUsage.update(
//         dateKey,
//         (value) => value + usage.litersUsed,
//         ifAbsent: () => usage.litersUsed,
//       );

//       // Weekly breakdown
//       final weekKey = 'Week ${_getWeekNumber(usage.timestamp)}';
//       weeklyUsage.update(
//         weekKey,
//         (value) => value + usage.litersUsed,
//         ifAbsent: () => usage.litersUsed,
//       );
//     }

//     final totalCost = totalLiters * _ratePerLiter;

//     // Get or create current bill
//     final billId = '${user.uid}_${DateFormat('yyyy_MM').format(start)}';
//     final billDoc = await _firestore.collection('waterBills').doc(billId).get();

//     WaterBill? currentBill;
//     if (billDoc.exists) {
//       currentBill = WaterBill.fromMap(billDoc.data()!);
//     } else {
//       currentBill = WaterBill(
//         id: billId,
//         userId: user.uid,
//         periodStart: start,
//         periodEnd: end,
//         totalLiters: totalLiters,
//         totalCost: totalCost,
//         ratePerLiter: _ratePerLiter,
//         usageByActivity: usageByActivity,
//       );
//       // Save new bill
//       await _firestore
//           .collection('waterBills')
//           .doc(billId)
//           .set(currentBill.toMap());
//     }

//     return ReportData(
//       periodStart: start,
//       periodEnd: end,
//       totalLiters: totalLiters,
//       totalCost: totalCost,
//       usageByActivity: usageByActivity,
//       dailyUsage: dailyUsage,
//       weeklyUsage: weeklyUsage,
//       usageRecords: [], // Empty list as fallback
//       currentBill: currentBill,
//     );
//   }

//   int _getWeekNumber(DateTime date) {
//     final firstDay = DateTime(date.year, 1, 1);
//     final days = date.difference(firstDay).inDays;
//     return (days / 7).floor() + 1;
//   }

//   // 💧 Record new water usage
//   Future<void> recordWaterUsage({
//     required String activity,
//     required double litersUsed,
//     String? deviceId,
//     String? location,
//     Duration? duration,
//   }) async {
//     final user = _auth.currentUser;
//     if (user == null) throw Exception('User not logged in');

//     final usage = WaterUsage(
//       id: '${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
//       userId: user.uid,
//       activity: activity,
//       litersUsed: litersUsed,
//       timestamp: DateTime.now(),
//       deviceId: deviceId,
//       location: location,
//       duration: duration,
//       cost: litersUsed * _ratePerLiter,
//     );

//     await _firestore.collection('waterUsage').doc(usage.id).set(usage.toMap());

//     print('✅ Recorded water usage: $litersUsed liters for $activity');
//   }

//   // 📄 Generate PDF Report
//   Future<File> generatePdfReport(
//     ReportData reportData,
//     String reportType,
//   ) async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) {
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               // Header
//               _buildHeader(reportData, reportType),
//               pw.SizedBox(height: 20),

//               // Summary Section
//               _buildSummarySection(reportData),
//               pw.SizedBox(height: 20),

//               // Usage Breakdown
//               _buildUsageBreakdown(reportData),
//               pw.SizedBox(height: 20),

//               // Bill Details
//               _buildBillSection(reportData),
//             ],
//           );
//         },
//       ),
//     );

//     // Save PDF to file
//     final bytes = await pdf.save();
//     final directory = await getApplicationDocumentsDirectory();
//     final file = File(
//       '${directory.path}/water_usage_report_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.pdf',
//     );
//     await file.writeAsBytes(bytes);

//     return file;
//   }

//   // 📄 Share PDF Report
//   Future<void> sharePdfReport(ReportData reportData, String reportType) async {
//     try {
//       final file = await generatePdfReport(reportData, reportType);
//       await Printing.sharePdf(
//         bytes: await file.readAsBytes(),
//         filename:
//             'water_usage_report_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.pdf',
//       );
//     } catch (e) {
//       print('❌ Error sharing PDF: $e');
//       rethrow;
//     }
//   }

//   pw.Widget _buildHeader(ReportData reportData, String reportType) {
//     return pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Text(
//           'Water Usage Report',
//           style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
//         ),
//         pw.Text(
//           '$reportType Report - ${DateFormat('MMM dd, yyyy').format(reportData.periodStart)} to ${DateFormat('MMM dd, yyyy').format(reportData.periodEnd)}',
//           style: pw.TextStyle(fontSize: 14),
//         ),
//         pw.Divider(),
//       ],
//     );
//   }

//   pw.Widget _buildSummarySection(ReportData reportData) {
//     return pw.Container(
//       padding: const pw.EdgeInsets.all(15),
//       decoration: pw.BoxDecoration(
//         border: pw.Border.all(color: PdfColors.grey300),
//         borderRadius: pw.BorderRadius.circular(8),
//       ),
//       child: pw.Column(
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: [
//           pw.Text(
//             'Summary',
//             style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
//           ),
//           pw.SizedBox(height: 10),
//           pw.Row(
//             mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//             children: [
//               pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Text(
//                     'Total Water Used:',
//                     style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                   ),
//                   pw.Text(
//                     '${reportData.totalLiters.toStringAsFixed(2)} liters',
//                   ),
//                 ],
//               ),
//               pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Text(
//                     'Total Cost:',
//                     style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                   ),
//                   pw.Text('\$${reportData.totalCost.toStringAsFixed(2)}'),
//                 ],
//               ),
//             ],
//           ),
//           pw.SizedBox(height: 8),
//           pw.Row(
//             mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//             children: [
//               pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Text(
//                     'Average Daily Usage:',
//                     style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                   ),
//                   pw.Text(
//                     '${reportData.averageDailyUsage.toStringAsFixed(2)} liters/day',
//                   ),
//                 ],
//               ),
//               pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Text(
//                     'Most Used Activity:',
//                     style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                   ),
//                   pw.Text(reportData.mostUsedActivity),
//                 ],
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   pw.Widget _buildUsageBreakdown(ReportData reportData) {
//     return pw.Container(
//       padding: const pw.EdgeInsets.all(15),
//       decoration: pw.BoxDecoration(
//         border: pw.Border.all(color: PdfColors.grey300),
//         borderRadius: pw.BorderRadius.circular(8),
//       ),
//       child: pw.Column(
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: [
//           pw.Text(
//             'Usage by Activity',
//             style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
//           ),
//           pw.SizedBox(height: 10),
//           ...reportData.usageByActivity.entries.map(
//             (entry) => pw.Padding(
//               padding: const pw.EdgeInsets.only(bottom: 8),
//               child: pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                 children: [
//                   pw.Text(entry.key),
//                   pw.Text('${entry.value.toStringAsFixed(2)} liters'),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   pw.Widget _buildBillSection(ReportData reportData) {
//     final bill = reportData.currentBill;
//     if (bill == null) return pw.SizedBox();

//     return pw.Container(
//       padding: const pw.EdgeInsets.all(15),
//       decoration: pw.BoxDecoration(
//         border: pw.Border.all(color: PdfColors.grey300),
//         borderRadius: pw.BorderRadius.circular(8),
//       ),
//       child: pw.Column(
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: [
//           pw.Text(
//             'Water Bill Details',
//             style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
//           ),
//           pw.SizedBox(height: 10),
//           _buildBillRow(
//             'Billing Period:',
//             '${DateFormat('MMM dd').format(bill.periodStart)} - ${DateFormat('MMM dd, yyyy').format(bill.periodEnd)}',
//           ),
//           _buildBillRow(
//             'Rate per Liter:',
//             '\$${bill.ratePerLiter.toStringAsFixed(3)}/L',
//           ),
//           _buildBillRow(
//             'Total Amount Due:',
//             '\$${bill.totalCost.toStringAsFixed(2)}',
//             isBold: true,
//           ),
//           pw.SizedBox(height: 8),
//           pw.Text(
//             'Status: ${bill.status.toUpperCase()}',
//             style: pw.TextStyle(
//               color: bill.status == 'paid' ? PdfColors.green : PdfColors.orange,
//               fontWeight: pw.FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   pw.Widget _buildBillRow(String label, String value, {bool isBold = false}) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.only(bottom: 6),
//       child: pw.Row(
//         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//         children: [
//           pw.Text(label),
//           pw.Text(
//             value,
//             style: isBold
//                 ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)
//                 : null,
//           ),
//         ],
//       ),
//     );
//   }

//   // 📈 Get historical data for charts
//   Future<Map<String, dynamic>> getChartData(
//     DateTime start,
//     DateTime end,
//   ) async {
//     final reportData = await _getReportData(start, end);

//     return {
//       'pieChartData': reportData.usageByActivity,
//       'barChartData': reportData.dailyUsage,
//       'lineChartData': reportData.weeklyUsage,
//     };
//   }

//   // 📊 Get user's water usage history
//   Stream<List<WaterUsage>> getWaterUsageStream() {
//     final user = _auth.currentUser;
//     if (user == null) return const Stream.empty();

//     return _firestore
//         .collection('waterUsage')
//         .where('userId', isEqualTo: user.uid)
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .map(
//           (snapshot) => snapshot.docs
//               .map((doc) => WaterUsage.fromMap(doc.data()))
//               .toList(),
//         );
//   }

//   // 💰 Get user's bill history
//   Stream<List<WaterBill>> getBillHistoryStream() {
//     final user = _auth.currentUser;
//     if (user == null) return const Stream.empty();

//     return _firestore
//         .collection('waterBills')
//         .where('userId', isEqualTo: user.uid)
//         .orderBy('periodEnd', descending: true)
//         .snapshots()
//         .map(
//           (snapshot) => snapshot.docs
//               .map((doc) => WaterBill.fromMap(doc.data()))
//               .toList(),
//         );
//   }
// }
// controllers/report_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/water_usage_model.dart';
import '../models/water_bill_model.dart';
import '../models/report_data_model.dart';

class ReportController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final double _ratePerLiter = 0.005; // $0.005 per liter

  // 📊 Get weekly report data
  Future<ReportData> getWeeklyReport() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return await _getReportData(startOfWeek, endOfWeek);
  }

  // 📊 Get monthly report data
  Future<ReportData> getMonthlyReport() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return await _getReportData(startOfMonth, endOfMonth);
  }

  // 📊 Get custom period report
  Future<ReportData> getCustomReport(DateTime start, DateTime end) async {
    return await _getReportData(start, end);
  }

  // 🔧 Core report data generation
  Future<ReportData> _getReportData(DateTime start, DateTime end) async {
    final user = _auth.currentUser!;
    
    // Get water usage records
    final usageSnapshot = await _firestore
        .collection('waterUsage')
        .where('userId', isEqualTo: user.uid)
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThanOrEqualTo: end)
        .get();

    // Convert documents to WaterUsage objects safely
    final usageRecords = <WaterUsage>[];
    for (final doc in usageSnapshot.docs) {
      try {
        final usage = WaterUsage.fromMap(doc.data());
        usageRecords.add(usage);
      } catch (e) {
        print('❌ Error parsing water usage record: $e');
      }
    }

    print('📊 Found ${usageRecords.length} water usage records');

    // Calculate totals and breakdowns
    double totalLiters = 0;
    final usageByActivity = <String, double>{};
    final dailyUsage = <String, double>{};
    final weeklyUsage = <String, double>{};

    for (final usage in usageRecords) {
      // Total liters
      totalLiters += usage.litersUsed;

      // By activity
      usageByActivity.update(
        usage.activity,
        (value) => value + usage.litersUsed,
        ifAbsent: () => usage.litersUsed,
      );

      // Daily breakdown
      final dateKey = DateFormat('MMM dd').format(usage.timestamp);
      dailyUsage.update(
        dateKey,
        (value) => value + usage.litersUsed,
        ifAbsent: () => usage.litersUsed,
      );

      // Weekly breakdown
      final weekKey = 'Week ${_getWeekNumber(usage.timestamp)}';
      weeklyUsage.update(
        weekKey,
        (value) => value + usage.litersUsed,
        ifAbsent: () => usage.litersUsed,
      );
    }

    final totalCost = totalLiters * _ratePerLiter;

    // Get or create current bill
    final billId = '${user.uid}_${DateFormat('yyyy_MM').format(start)}';
    final billDoc = await _firestore.collection('waterBills').doc(billId).get();
    
    WaterBill? currentBill;
    if (billDoc.exists) {
      try {
        currentBill = WaterBill.fromMap(billDoc.data()!);
      } catch (e) {
        print('❌ Error parsing water bill: $e');
        currentBill = null;
      }
    } else {
      currentBill = WaterBill(
        id: billId,
        userId: user.uid,
        periodStart: start,
        periodEnd: end,
        totalLiters: totalLiters,
        totalCost: totalCost,
        ratePerLiter: _ratePerLiter,
        usageByActivity: usageByActivity,
      );
      // Save new bill
      try {
        await _firestore.collection('waterBills').doc(billId).set(currentBill.toMap());
      } catch (e) {
        print('❌ Error saving water bill: $e');
      }
    }

    return ReportData(
      periodStart: start,
      periodEnd: end,
      totalLiters: totalLiters,
      totalCost: totalCost,
      usageByActivity: usageByActivity,
      dailyUsage: dailyUsage,
      weeklyUsage: weeklyUsage,
      usageRecords: [],
      currentBill: currentBill,
    );
  }

  int _getWeekNumber(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    final days = date.difference(firstDay).inDays;
    return (days / 7).floor() + 1;
  }

  // 💧 Record new water usage
  Future<void> recordWaterUsage({
    required String activity,
    required double litersUsed,
    String? deviceId,
    String? location,
    Duration? duration,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final usage = WaterUsage(
      id: '${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.uid,
      activity: activity,
      litersUsed: litersUsed,
      timestamp: DateTime.now(),
      deviceId: deviceId,
      location: location,
      duration: duration,
      cost: litersUsed * _ratePerLiter,
    );

    await _firestore
        .collection('waterUsage')
        .doc(usage.id)
        .set(usage.toMap());

    print('✅ Recorded water usage: $litersUsed liters for $activity');
  }

  // 📄 Generate PDF Report
  Future<File> generatePdfReport(ReportData reportData, String reportType) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(reportData, reportType),
              pw.SizedBox(height: 20),
              
              // Summary Section
              _buildSummarySection(reportData),
              pw.SizedBox(height: 20),
              
              // Usage Breakdown
              _buildUsageBreakdown(reportData),
              pw.SizedBox(height: 20),
              
              // Bill Details
              _buildBillSection(reportData),
            ],
          );
        },
      ),
    );

    // Save PDF to file
    final bytes = await pdf.save();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/water_usage_report_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.pdf');
    await file.writeAsBytes(bytes);
    
    return file;
  }

  // 📄 Share PDF Report
  Future<void> sharePdfReport(ReportData reportData, String reportType) async {
    try {
      final file = await generatePdfReport(reportData, reportType);
      await Printing.sharePdf(
        bytes: await file.readAsBytes(),
        filename: 'water_usage_report_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      print('❌ Error sharing PDF: $e');
      rethrow;
    }
  }

  pw.Widget _buildHeader(ReportData reportData, String reportType) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Water Usage Report',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          '$reportType Report - ${DateFormat('MMM dd, yyyy').format(reportData.periodStart)} to ${DateFormat('MMM dd, yyyy').format(reportData.periodEnd)}',
          style: pw.TextStyle(fontSize: 14),
        ),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildSummarySection(ReportData reportData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Total Water Used:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${reportData.totalLiters.toStringAsFixed(2)} liters'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Total Cost:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('\$${reportData.totalCost.toStringAsFixed(2)}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Average Daily Usage:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${reportData.averageDailyUsage.toStringAsFixed(2)} liters/day'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Most Used Activity:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(reportData.mostUsedActivity),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildUsageBreakdown(ReportData reportData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Usage by Activity',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          ...reportData.usageByActivity.entries.map((entry) =>
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(entry.key),
                  pw.Text('${entry.value.toStringAsFixed(2)} liters'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBillSection(ReportData reportData) {
    final bill = reportData.currentBill;
    if (bill == null) return pw.SizedBox();

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Water Bill Details',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildBillRow('Billing Period:', 
              '${DateFormat('MMM dd').format(bill.periodStart)} - ${DateFormat('MMM dd, yyyy').format(bill.periodEnd)}'),
          _buildBillRow('Rate per Liter:', '\$${bill.ratePerLiter.toStringAsFixed(3)}/L'),
          _buildBillRow('Total Amount Due:', 
              '\$${bill.totalCost.toStringAsFixed(2)}', 
              isBold: true),
          pw.SizedBox(height: 8),
          pw.Text(
            'Status: ${bill.status.toUpperCase()}',
            style: pw.TextStyle(
              color: bill.status == 'paid' ? PdfColors.green : PdfColors.orange,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBillRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(
            value,
            style: isBold ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16) : null,
          ),
        ],
      ),
    );
  }

  // 📊 Get user's water usage history
  Stream<List<WaterUsage>> getWaterUsageStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('waterUsage')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WaterUsage.fromMap(doc.data()))
            .toList());
  }

  // 💰 Get user's bill history
  Stream<List<WaterBill>> getBillHistoryStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('waterBills')
        .where('userId', isEqualTo: user.uid)
        .orderBy('periodEnd', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WaterBill.fromMap(doc.data()))
            .toList());
  }
}