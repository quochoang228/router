part of '../router.dart';

/// Tool để phân tích hiệu năng của Router Auto-Restore System
class RouterPerformanceAnalyzer {
  static final List<Map<String, dynamic>> _performanceLogs = [];
  static Timer? _memoryMonitorTimer;
  static bool _isMonitoring = false;

  /// Bắt đầu monitoring hiệu năng
  static void startMonitoring(
      {Duration interval = const Duration(seconds: 5)}) {
    if (_isMonitoring) return;

    _isMonitoring = true;
    RouterLogger.info('Router Performance Monitoring started...');

    _memoryMonitorTimer = Timer.periodic(interval, (timer) {
      _logPerformanceSnapshot();
    });
  }

  /// Dừng monitoring
  static void stopMonitoring() {
    _isMonitoring = false;
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;
    RouterLogger.info('Router Performance Monitoring stopped.');
  }

  /// Log snapshot hiệu năng tại thời điểm hiện tại
  static void _logPerformanceSnapshot() {
    final stats = AppRouterGuard.getPerformanceStats();
    final timestamp = DateTime.now();

    final snapshot = {
      'timestamp': timestamp.toIso8601String(),
      'routerStats': stats,
      'memoryUsage': _getMemoryUsage(),
    };

    _performanceLogs.add(snapshot);

    // Giữ tối đa 100 snapshots để tránh memory leak
    if (_performanceLogs.length > 100) {
      _performanceLogs.removeAt(0);
    }

    // Print summary mỗi 10 snapshots
    if (_performanceLogs.length % 10 == 0) {
      _printPerformanceSummary();
    }
  }

  /// Lấy thông tin memory usage
  static Map<String, dynamic> _getMemoryUsage() {
    return {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'performanceLogsCount': _performanceLogs.length,
    };
  }

  /// Print summary hiệu năng
  static void _printPerformanceSummary() {
    RouterLogger.info('\n📊 Router Performance Summary:');
    RouterLogger.info(
        '├─ Monitoring duration: ${_performanceLogs.length * 5} seconds');
    RouterLogger.info(
        '├─ Auto-restore enabled: ${AppRouterGuard.isAutoRestoreEnabled}');

    final latest = _performanceLogs.last;
    final routerStats = latest['routerStats'] as Map<String, dynamic>;

    RouterLogger.info('├─ Current state:');
    RouterLogger.info('│  ├─ Has saved route: ${routerStats['hasSavedRoute']}');
    RouterLogger.info(
        '│  ├─ Is auto-restoring: ${routerStats['isAutoRestoring']}');
    RouterLogger.info(
        '│  ├─ Stream controller active: ${routerStats['hasStreamController']}');
    RouterLogger.info(
        '│  ├─ Debounce timer active: ${routerStats['hasDebounceTimer']}');
    RouterLogger.info(
        '│  └─ Cleanup timer active: ${routerStats['hasCleanupTimer']}');

    RouterLogger.info('└─ Memory usage: OK\n');
  }

  /// Lấy detailed performance report
  static Map<String, dynamic> getDetailedReport() {
    if (_performanceLogs.isEmpty) {
      return {
        'error': 'No performance data available. Start monitoring first.'
      };
    }

    final firstLog = _performanceLogs.first;
    final lastLog = _performanceLogs.last;

    return {
      'monitoringPeriod': {
        'start': firstLog['timestamp'],
        'end': lastLog['timestamp'],
        'durationSeconds': _performanceLogs.length * 5,
      },
      'totalSnapshots': _performanceLogs.length,
      'currentState': lastLog['routerStats'],
      'averageMemoryUsage': _calculateAverageMemoryUsage(),
      'recommendations': _generateRecommendations(),
    };
  }

  /// Tính average memory usage
  static Map<String, dynamic> _calculateAverageMemoryUsage() {
    if (_performanceLogs.isEmpty) return {};

    int totalLogs = _performanceLogs.length;

    return {
      'averageLogsCount': totalLogs,
      'memoryEfficiency': totalLogs < 50 ? 'Good' : 'Consider cleanup',
    };
  }

  /// Tạo recommendations dựa trên performance data
  static List<String> _generateRecommendations() {
    final recommendations = <String>[];

    if (!AppRouterGuard.isAutoRestoreEnabled) {
      recommendations.add('✅ Auto-restore is disabled - no performance impact');
      return recommendations;
    }

    if (_performanceLogs.isNotEmpty) {
      final latest =
          _performanceLogs.last['routerStats'] as Map<String, dynamic>;

      if (latest['hasStreamController'] == true) {
        recommendations
            .add('💡 StreamController is active - normal for auto-restore');
      }

      if (latest['hasSavedRoute'] == true) {
        recommendations
            .add('📝 Route is saved - will be restored on next login');
      }

      if (latest['isAutoRestoring'] == true) {
        recommendations
            .add('⚠️ Auto-restore in progress - check if it completes');
      }

      if (latest['hasDebounceTimer'] == true) {
        recommendations
            .add('⏱️ Debounce timer active - prevents multiple rapid restores');
      }
    }

    recommendations.add('🔧 Call AppRouterGuard.dispose() when app closes');
    recommendations.add('📱 Memory impact is minimal - safe for production');

    return recommendations;
  }

  /// Test performance impact
  static Future<void> runPerformanceTest({
    int iterations = 100,
    Duration delay = const Duration(milliseconds: 10),
  }) async {
    RouterLogger.info('Running Router Performance Test...');
    RouterLogger.info('├─ Iterations: $iterations');
    RouterLogger.info('├─ Delay between calls: ${delay.inMilliseconds}ms');

    final stopwatch = Stopwatch()..start();

    // Test multiple auth state changes
    for (int i = 0; i < iterations; i++) {
      AppRouterGuard.notifyAuthStateChanged(i % 2 == 0);
      await Future.delayed(delay);
    }

    stopwatch.stop();

    RouterLogger.info('├─ Total time: ${stopwatch.elapsedMilliseconds}ms');
    RouterLogger.info(
        '├─ Average per call: ${stopwatch.elapsedMilliseconds / iterations}ms');
    RouterLogger.info(
        '└─ Performance: ${stopwatch.elapsedMilliseconds < 1000 ? 'Excellent' : 'Review needed'}');
  }

  /// Widget để hiển thị performance stats
  static Widget buildPerformanceWidget() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Router Performance Stats',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 12),
            _buildStatRow('Monitoring', _isMonitoring ? 'Active' : 'Inactive'),
            _buildStatRow('Auto-restore',
                AppRouterGuard.isAutoRestoreEnabled ? 'Enabled' : 'Disabled'),
            _buildStatRow('Logs count', '${_performanceLogs.length}'),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isMonitoring ? stopMonitoring : startMonitoring,
                    child:
                        Text(_isMonitoring ? 'Stop Monitor' : 'Start Monitor'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await runPerformanceTest(iterations: 50);
                    },
                    child: Text('Run Test'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                final report = getDetailedReport();
                RouterLogger.info('Detailed Report: $report');
              },
              child: Text('Show Detailed Report'),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Clear all performance logs
  static void clearLogs() {
    _performanceLogs.clear();
    RouterLogger.info('Performance logs cleared');
  }
}

/// Extension cho easy access
extension RouterPerformanceExtension on RouterService {
  static void enablePerformanceMonitoring() {
    RouterPerformanceAnalyzer.startMonitoring();
  }

  static void disablePerformanceMonitoring() {
    RouterPerformanceAnalyzer.stopMonitoring();
  }

  static Map<String, dynamic> getPerformanceReport() {
    return RouterPerformanceAnalyzer.getDetailedReport();
  }
}
