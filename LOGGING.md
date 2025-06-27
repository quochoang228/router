# Router Logging System

## Overview

Router module đã được cải tiến với hệ thống logging tùy chỉnh để thay thế `print()` statements. Điều này giúp:

- ✅ **Structured logging** với format nhất quán
- ✅ **Prefix identification** `[Router]` cho tất cả logs
- ✅ **Log levels** (INFO, ERROR, WARNING, DEBUG)
- ✅ **Easy integration** với external logging libraries
- ✅ **Production ready** với proper error handling

## RouterLogger API

### Available Methods

```dart
// Information logs - general app flow
RouterLogger.info('Router Performance Monitoring started...');

// Error logs - when something goes wrong (không crash app)
RouterLogger.error('Auto-restore error: Connection timeout');

// Warning logs - potential issues
RouterLogger.warning('Performance impact detected');

// Debug logs - detailed information for debugging
RouterLogger.debug('Internal state: hasStreamController=true');
```

### Log Format

```
[Router INFO] Router Performance Monitoring started...
[Router ERROR] Auto-restore error: Navigation context not available
[Router WARNING] Performance impact detected
[Router DEBUG] Internal state: savedRoute=null
```

## What Gets Logged

### 1. Auto-Restore Activities

```dart
// When auto-restore system starts
[Router INFO] Router Performance Monitoring started...

// When auto-restore completes
[Router INFO] Router Performance Monitoring stopped.

// When errors occur during restore
[Router ERROR] Auto-restore error: Route not found

// Performance summaries
[Router INFO] 📊 Router Performance Summary:
[Router INFO] ├─ Monitoring duration: 25 seconds
[Router INFO] ├─ Auto-restore enabled: true
```

### 2. Performance Monitoring

```dart
// Test results
[Router INFO] Running Router Performance Test...
[Router INFO] ├─ Iterations: 100
[Router INFO] ├─ Delay between calls: 10ms
[Router INFO] ├─ Total time: 156ms
[Router INFO] └─ Performance: Excellent

// Memory cleanup
[Router INFO] Performance logs cleared
```

### 3. Error Handling

```dart
// Auto-restore errors (graceful handling)
[Router ERROR] Auto-restore error: BuildContext was null
[Router ERROR] Auto-restore error: Invalid route state

// Performance issues
[Router WARNING] Performance impact detected
```

## Integration với External Logging

### Current Implementation (Fallback)

```dart
class RouterLogger {
  static void info(String message) {
    // TODO: Replace with actual Logs.i when available
    print('[Router INFO] $message');
  }
  
  static void error(String message) {
    // TODO: Replace with actual Logs.e when available  
    print('[Router ERROR] $message');
  }
  
  // ... other methods
}
```

### Upgrade to External Library

Khi bạn muốn integrate với thư viện logging thực tế:

```dart
class RouterLogger {
  static void info(String message) {
    Logs.i('[Router] $message');  // Your logging library
  }
  
  static void error(String message) {
    Logs.e('[Router] $message');  // Your logging library
  }
  
  static void debug(String message) {
    if (kDebugMode) {  // Only log in debug mode
      Logs.d('[Router] $message');
    }
  }
  
  static void warning(String message) {
    Logs.w('[Router] $message');
  }
}
```

### Firebase Crashlytics Integration

```dart
class RouterLogger {
  static void error(String message) {
    // Log to console
    Logs.e('[Router] $message');
    
    // Also send to Crashlytics for production monitoring
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.log('[Router] $message');
    }
  }
}
```

### Custom Log Destination

```dart
class RouterLogger {
  static final List<String> _logHistory = [];
  
  static void info(String message) {
    final formattedMessage = '[Router INFO] $message';
    
    // Console output
    print(formattedMessage);
    
    // Store in memory for debugging
    _logHistory.add(formattedMessage);
    
    // Send to analytics (optional)
    Analytics.track('router_info', {'message': message});
  }
  
  static List<String> getLogHistory() => List.from(_logHistory);
  static void clearLogHistory() => _logHistory.clear();
}
```

## Configuration Options

### Development vs Production

```dart
class RouterLogger {
  static bool _verbose = kDebugMode;  // Only verbose in debug
  
  static void setVerbose(bool verbose) {
    _verbose = verbose;
  }
  
  static void debug(String message) {
    if (_verbose) {
      print('[Router DEBUG] $message');
    }
  }
}
```

### Log Level Filtering

```dart
enum LogLevel { DEBUG, INFO, WARNING, ERROR }

class RouterLogger {
  static LogLevel _minLevel = kDebugMode ? LogLevel.DEBUG : LogLevel.INFO;
  
  static void setMinLevel(LogLevel level) {
    _minLevel = level;
  }
  
  static void _log(LogLevel level, String message) {
    if (level.index >= _minLevel.index) {
      print('[Router ${level.name}] $message');
    }
  }
}
```

## Best Practices

### 1. Appropriate Log Levels

```dart
// ✅ Good - use appropriate levels
RouterLogger.info('Auto-restore completed successfully');  // Normal flow
RouterLogger.warning('Performance impact detected');       // Potential issue
RouterLogger.error('Failed to restore route');            // Actual error
RouterLogger.debug('Internal state: timer=${timer.isActive}'); // Debug info

// ❌ Avoid - wrong levels
RouterLogger.error('User clicked button');  // This is info, not error
RouterLogger.info('Navigation failed');     // This should be error
```

### 2. Meaningful Messages

```dart
// ✅ Good - descriptive and actionable
RouterLogger.error('Auto-restore failed: BuildContext is null after 300ms timeout');
RouterLogger.info('Performance monitoring started with 5s interval');

// ❌ Avoid - vague messages
RouterLogger.error('Something went wrong');
RouterLogger.info('Started');
```

### 3. Performance Consideration

```dart
// ✅ Good - avoid heavy operations in logs
RouterLogger.debug('Route count: ${routes.length}');

// ❌ Avoid - expensive operations
RouterLogger.debug('All routes: ${routes.map((r) => r.toJson()).join(', ')}');
```

## Demo

Run `example/logging_demo.dart` để xem router logging system hoạt động:

```bash
flutter run example/logging_demo.dart
```

Trong console bạn sẽ thấy:

```
[Router INFO] Router Performance Monitoring started...
[Router INFO] Login button pressed - triggering auto-restore
[Router INFO] Protected page loaded successfully - ID: demo123
[Router DEBUG] Extra data preserved: message, timestamp
```

## Migration Guide

### From print() to RouterLogger

```dart
// Before
print('Auto-restore error: $e');
print('Performance test completed');

// After  
RouterLogger.error('Auto-restore error: $e');
RouterLogger.info('Performance test completed');
```

### Adding Custom Logging

1. Modify `RouterLogger` class trong `lib/src/config.dart`
2. Replace placeholder implementations với actual logging library
3. Configure log levels và destinations
4. Test trong development environment

## Troubleshooting

### Common Issues

1. **Logs không hiển thị**: Check log level settings
2. **Too many logs**: Increase minimum log level  
3. **Performance impact**: Disable debug logs trong production

### Debug Commands

```dart
// Check current logging configuration
final stats = AppRouterGuard.getPerformanceStats();
RouterLogger.debug('Current stats: $stats');

// Force log level
RouterLogger.setMinLevel(LogLevel.ERROR);  // Only errors

// Clear log history
RouterLogger.clearLogHistory();
```
