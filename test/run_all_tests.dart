import 'dart:io';
import 'dart:async';

/// 综合测试运行器
/// 
/// 这个脚本用于运行所有类型的测试，包括单元测试、集成测试、
/// 性能测试和端到端测试，并生成详细的测试报告。
class TestRunner {
  static const String testPath = 'test';
  static const String integrationTestPath = 'integration_test';
  
  /// 运行所有测试
  static Future<TestResults> runAllTests({
    bool runUnitTests = true,
    bool runIntegrationTests = true,
    bool runPerformanceTests = true,
    bool runE2ETests = true,
    bool generateCoverage = true,
  }) async {
    print('🚀 开始运行综合测试套件...\n');
    
    final results = TestResults();
    final stopwatch = Stopwatch()..start();
    
    try {
      // 1. 运行单元测试
      if (runUnitTests) {
        print('📋 运行单元测试...');
        final unitResults = await _runUnitTests(generateCoverage);
        results.unitTestResults = unitResults;
        _printTestResults('单元测试', unitResults);
      }
      
      // 2. 运行集成测试
      if (runIntegrationTests) {
        print('🔗 运行集成测试...');
        final integrationResults = await _runIntegrationTests();
        results.integrationTestResults = integrationResults;
        _printTestResults('集成测试', integrationResults);
      }
      
      // 3. 运行性能测试
      if (runPerformanceTests) {
        print('⚡ 运行性能测试...');
        final performanceResults = await _runPerformanceTests();
        results.performanceTestResults = performanceResults;
        _printTestResults('性能测试', performanceResults);
      }
      
      // 4. 运行端到端测试
      if (runE2ETests) {
        print('🎯 运行端到端测试...');
        final e2eResults = await _runE2ETests();
        results.e2eTestResults = e2eResults;
        _printTestResults('端到端测试', e2eResults);
      }
      
      stopwatch.stop();
      results.totalDuration = stopwatch.elapsed;
      
      // 生成综合报告
      await _generateComprehensiveReport(results);
      
      print('\n✅ 所有测试完成！');
      print('总耗时: ${_formatDuration(results.totalDuration)}');
      
      return results;
    } catch (e) {
      stopwatch.stop();
      print('\n❌ 测试运行失败: $e');
      results.hasErrors = true;
      results.errorMessage = e.toString();
      return results;
    }
  }
  
  /// 运行单元测试
  static Future<TestResult> _runUnitTests(bool generateCoverage) async {
    final args = ['test'];
    
    if (generateCoverage) {
      args.addAll(['--coverage', 'coverage']);
    }
    
    // 排除集成测试和性能测试
    args.addAll([
      '--exclude-tags', 'integration,performance,e2e',
    ]);
    
    return await _runFlutterTest(args, 'unit');
  }
  
  /// 运行集成测试
  static Future<TestResult> _runIntegrationTests() async {
    final args = [
      'test',
      '--tags', 'integration',
    ];
    
    return await _runFlutterTest(args, 'integration');
  }
  
  /// 运行性能测试
  static Future<TestResult> _runPerformanceTests() async {
    final args = [
      'test',
      '--tags', 'performance',
      'test/performance/',
    ];
    
    return await _runFlutterTest(args, 'performance');
  }
  
  /// 运行端到端测试
  static Future<TestResult> _runE2ETests() async {
    // 检查是否存在集成测试目录
    final integrationDir = Directory(integrationTestPath);
    if (!await integrationDir.exists()) {
      return TestResult(
        testType: 'e2e',
        passed: 0,
        failed: 0,
        skipped: 0,
        duration: Duration.zero,
        success: true,
        output: 'No integration tests found',
      );
    }
    
    final args = [
      'test',
      integrationTestPath,
    ];
    
    return await _runFlutterTest(args, 'e2e');
  }
  
  /// 运行Flutter测试命令
  static Future<TestResult> _runFlutterTest(List<String> args, String testType) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await Process.run('flutter', args);
      stopwatch.stop();
      
      final output = result.stdout.toString() + result.stderr.toString();
      final success = result.exitCode == 0;
      
      // 解析测试结果
      final testCounts = _parseTestOutput(output);
      
      return TestResult(
        testType: testType,
        passed: testCounts['passed'] ?? 0,
        failed: testCounts['failed'] ?? 0,
        skipped: testCounts['skipped'] ?? 0,
        duration: stopwatch.elapsed,
        success: success,
        output: output,
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        testType: testType,
        passed: 0,
        failed: 1,
        skipped: 0,
        duration: stopwatch.elapsed,
        success: false,
        output: 'Error running tests: $e',
      );
    }
  }
  
  /// 解析测试输出
  static Map<String, int> _parseTestOutput(String output) {
    final counts = <String, int>{
      'passed': 0,
      'failed': 0,
      'skipped': 0,
    };
    
    // 简单的正则表达式解析（实际实现可能需要更复杂的解析）
    final passedMatch = RegExp(r'(\d+) passing').firstMatch(output);
    final failedMatch = RegExp(r'(\d+) failing').firstMatch(output);
    final skippedMatch = RegExp(r'(\d+) skipped').firstMatch(output);
    
    if (passedMatch != null) {
      counts['passed'] = int.parse(passedMatch.group(1)!);
    }
    if (failedMatch != null) {
      counts['failed'] = int.parse(failedMatch.group(1)!);
    }
    if (skippedMatch != null) {
      counts['skipped'] = int.parse(skippedMatch.group(1)!);
    }
    
    // 如果没有找到具体数字，尝试从输出中推断
    if (counts['passed'] == 0 && counts['failed'] == 0) {
      if (output.contains('All tests passed')) {
        counts['passed'] = 1;
      } else if (output.contains('FAILED') || output.contains('Error')) {
        counts['failed'] = 1;
      }
    }
    
    return counts;
  }
  
  /// 打印测试结果
  static void _printTestResults(String testType, TestResult result) {
    final status = result.success ? '✅' : '❌';
    print('$status $testType 结果:');
    print('  通过: ${result.passed}');
    print('  失败: ${result.failed}');
    print('  跳过: ${result.skipped}');
    print('  耗时: ${_formatDuration(result.duration)}');
    
    if (!result.success) {
      print('  错误信息:');
      print('  ${result.output.split('\n').take(5).join('\n  ')}');
    }
    print('');
  }
  
  /// 格式化持续时间
  static String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分${duration.inSeconds % 60}秒';
    } else {
      return '${duration.inSeconds}秒';
    }
  }
  
  /// 生成综合报告
  static Future<void> _generateComprehensiveReport(TestResults results) async {
    final buffer = StringBuffer();
    
    buffer.writeln('# 综合测试报告');
    buffer.writeln();
    buffer.writeln('生成时间: ${DateTime.now()}');
    buffer.writeln('总耗时: ${_formatDuration(results.totalDuration)}');
    buffer.writeln();
    
    // 总体统计
    final totalPassed = (results.unitTestResults?.passed ?? 0) +
                       (results.integrationTestResults?.passed ?? 0) +
                       (results.performanceTestResults?.passed ?? 0) +
                       (results.e2eTestResults?.passed ?? 0);
    
    final totalFailed = (results.unitTestResults?.failed ?? 0) +
                       (results.integrationTestResults?.failed ?? 0) +
                       (results.performanceTestResults?.failed ?? 0) +
                       (results.e2eTestResults?.failed ?? 0);
    
    final totalSkipped = (results.unitTestResults?.skipped ?? 0) +
                        (results.integrationTestResults?.skipped ?? 0) +
                        (results.performanceTestResults?.skipped ?? 0) +
                        (results.e2eTestResults?.skipped ?? 0);
    
    buffer.writeln('## 总体统计');
    buffer.writeln('- 通过: $totalPassed');
    buffer.writeln('- 失败: $totalFailed');
    buffer.writeln('- 跳过: $totalSkipped');
    buffer.writeln('- 总计: ${totalPassed + totalFailed + totalSkipped}');
    buffer.writeln();
    
    // 各类测试详情
    _addTestResultToReport(buffer, '单元测试', results.unitTestResults);
    _addTestResultToReport(buffer, '集成测试', results.integrationTestResults);
    _addTestResultToReport(buffer, '性能测试', results.performanceTestResults);
    _addTestResultToReport(buffer, '端到端测试', results.e2eTestResults);
    
    // 建议
    buffer.writeln('## 建议');
    if (totalFailed > 0) {
      buffer.writeln('- ❌ 存在失败的测试，请检查并修复');
    }
    if (totalPassed == 0) {
      buffer.writeln('- ⚠️ 没有通过的测试，请检查测试配置');
    }
    if (results.unitTestResults == null || results.unitTestResults!.passed < 10) {
      buffer.writeln('- 📝 建议增加更多单元测试以提高代码质量');
    }
    if (results.performanceTestResults == null || results.performanceTestResults!.passed == 0) {
      buffer.writeln('- ⚡ 建议添加性能测试以确保应用性能');
    }
    
    // 保存报告
    final reportFile = File('test_report.md');
    await reportFile.writeAsString(buffer.toString());
    print('📊 测试报告已生成: test_report.md');
  }
  
  /// 添加测试结果到报告
  static void _addTestResultToReport(StringBuffer buffer, String testType, TestResult? result) {
    buffer.writeln('### $testType');
    
    if (result == null) {
      buffer.writeln('- 状态: 未运行');
    } else {
      final status = result.success ? '✅ 成功' : '❌ 失败';
      buffer.writeln('- 状态: $status');
      buffer.writeln('- 通过: ${result.passed}');
      buffer.writeln('- 失败: ${result.failed}');
      buffer.writeln('- 跳过: ${result.skipped}');
      buffer.writeln('- 耗时: ${_formatDuration(result.duration)}');
      
      if (!result.success && result.output.isNotEmpty) {
        buffer.writeln('- 错误信息:');
        buffer.writeln('```');
        buffer.writeln(result.output.split('\n').take(10).join('\n'));
        buffer.writeln('```');
      }
    }
    buffer.writeln();
  }
  
  /// 运行代码覆盖率分析
  static Future<void> runCoverageAnalysis() async {
    print('📊 运行代码覆盖率分析...');
    
    try {
      // 运行覆盖率分析脚本
      final result = await Process.run('dart', ['test/test_coverage_analysis.dart']);
      
      if (result.exitCode == 0) {
        print('✅ 覆盖率分析完成');
      } else {
        print('⚠️ 覆盖率分析完成，但存在警告');
      }
      
      print(result.stdout);
      if (result.stderr.toString().isNotEmpty) {
        print('错误信息: ${result.stderr}');
      }
    } catch (e) {
      print('❌ 覆盖率分析失败: $e');
    }
  }
}

/// 测试结果数据类
class TestResult {
  final String testType;
  final int passed;
  final int failed;
  final int skipped;
  final Duration duration;
  final bool success;
  final String output;

  TestResult({
    required this.testType,
    required this.passed,
    required this.failed,
    required this.skipped,
    required this.duration,
    required this.success,
    required this.output,
  });
}

/// 综合测试结果数据类
class TestResults {
  TestResult? unitTestResults;
  TestResult? integrationTestResults;
  TestResult? performanceTestResults;
  TestResult? e2eTestResults;
  Duration totalDuration = Duration.zero;
  bool hasErrors = false;
  String? errorMessage;
}

/// 主函数
void main(List<String> args) async {
  // 解析命令行参数
  final runUnitTests = !args.contains('--skip-unit');
  final runIntegrationTests = !args.contains('--skip-integration');
  final runPerformanceTests = !args.contains('--skip-performance');
  final runE2ETests = !args.contains('--skip-e2e');
  final generateCoverage = !args.contains('--skip-coverage');
  final runCoverageAnalysis = args.contains('--coverage-analysis');
  
  try {
    // 运行所有测试
    final results = await TestRunner.runAllTests(
      runUnitTests: runUnitTests,
      runIntegrationTests: runIntegrationTests,
      runPerformanceTests: runPerformanceTests,
      runE2ETests: runE2ETests,
      generateCoverage: generateCoverage,
    );
    
    // 运行覆盖率分析
    if (runCoverageAnalysis) {
      await TestRunner.runCoverageAnalysis();
    }
    
    // 确定退出码
    final hasFailures = (results.unitTestResults?.failed ?? 0) > 0 ||
                       (results.integrationTestResults?.failed ?? 0) > 0 ||
                       (results.performanceTestResults?.failed ?? 0) > 0 ||
                       (results.e2eTestResults?.failed ?? 0) > 0 ||
                       results.hasErrors;
    
    if (hasFailures) {
      print('\n❌ 测试套件执行完成，但存在失败的测试');
      exit(1);
    } else {
      print('\n✅ 所有测试都通过了！');
      exit(0);
    }
  } catch (e) {
    print('\n💥 测试运行器出现异常: $e');
    exit(1);
  }
}