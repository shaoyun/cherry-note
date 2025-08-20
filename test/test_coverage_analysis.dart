import 'dart:io';
import 'dart:convert';

/// 测试覆盖率分析工具
/// 
/// 这个工具用于分析项目的测试覆盖率，生成详细的覆盖率报告，
/// 并提供改进建议。
class TestCoverageAnalysis {
  static const String projectRoot = '.';
  static const String libPath = 'lib';
  static const String testPath = 'test';
  
  /// 分析测试覆盖率
  static Future<CoverageReport> analyzeCoverage() async {
    print('开始分析测试覆盖率...');
    
    final sourceFiles = await _getSourceFiles();
    final testFiles = await _getTestFiles();
    final coverage = await _calculateCoverage(sourceFiles, testFiles);
    
    final report = CoverageReport(
      totalSourceFiles: sourceFiles.length,
      totalTestFiles: testFiles.length,
      coverageByModule: coverage,
      overallCoverage: _calculateOverallCoverage(coverage),
      recommendations: _generateRecommendations(coverage),
    );
    
    print('测试覆盖率分析完成！');
    return report;
  }
  
  /// 获取所有源文件
  static Future<List<String>> _getSourceFiles() async {
    final libDir = Directory(libPath);
    final files = <String>[];
    
    if (await libDir.exists()) {
      await for (final entity in libDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          files.add(entity.path);
        }
      }
    }
    
    return files;
  }
  
  /// 获取所有测试文件
  static Future<List<String>> _getTestFiles() async {
    final testDir = Directory(testPath);
    final files = <String>[];
    
    if (await testDir.exists()) {
      await for (final entity in testDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          files.add(entity.path);
        }
      }
    }
    
    return files;
  }
  
  /// 计算覆盖率
  static Future<Map<String, ModuleCoverage>> _calculateCoverage(
    List<String> sourceFiles,
    List<String> testFiles,
  ) async {
    final coverage = <String, ModuleCoverage>{};
    
    // 按模块分组源文件
    final moduleFiles = _groupFilesByModule(sourceFiles);
    
    for (final module in moduleFiles.keys) {
      final files = moduleFiles[module]!;
      final testedFiles = <String>[];
      final untestedFiles = <String>[];
      
      for (final file in files) {
        final hasTest = await _hasTestFile(file, testFiles);
        if (hasTest) {
          testedFiles.add(file);
        } else {
          untestedFiles.add(file);
        }
      }
      
      final coveragePercentage = files.isEmpty 
          ? 0.0 
          : (testedFiles.length / files.length) * 100;
      
      coverage[module] = ModuleCoverage(
        moduleName: module,
        totalFiles: files.length,
        testedFiles: testedFiles.length,
        untestedFiles: untestedFiles,
        coveragePercentage: coveragePercentage,
      );
    }
    
    return coverage;
  }
  
  /// 按模块分组文件
  static Map<String, List<String>> _groupFilesByModule(List<String> files) {
    final modules = <String, List<String>>{};
    
    for (final file in files) {
      final parts = file.split('/');
      if (parts.length >= 3) {
        final module = parts[2]; // lib/features/[module] or lib/core/[module]
        modules.putIfAbsent(module, () => []).add(file);
      } else {
        modules.putIfAbsent('root', () => []).add(file);
      }
    }
    
    return modules;
  }
  
  /// 检查文件是否有对应的测试文件
  static Future<bool> _hasTestFile(String sourceFile, List<String> testFiles) async {
    // 将源文件路径转换为测试文件路径
    final testFilePath = sourceFile
        .replaceFirst('lib/', 'test/')
        .replaceFirst('.dart', '_test.dart');
    
    // 检查是否存在对应的测试文件
    return testFiles.contains(testFilePath) || 
           await File(testFilePath).exists();
  }
  
  /// 计算总体覆盖率
  static double _calculateOverallCoverage(Map<String, ModuleCoverage> coverage) {
    if (coverage.isEmpty) return 0.0;
    
    final totalFiles = coverage.values.fold(0, (sum, module) => sum + module.totalFiles);
    final testedFiles = coverage.values.fold(0, (sum, module) => sum + module.testedFiles);
    
    return totalFiles == 0 ? 0.0 : (testedFiles / totalFiles) * 100;
  }
  
  /// 生成改进建议
  static List<String> _generateRecommendations(Map<String, ModuleCoverage> coverage) {
    final recommendations = <String>[];
    
    // 检查低覆盖率模块
    final lowCoverageModules = coverage.values
        .where((module) => module.coveragePercentage < 70)
        .toList();
    
    if (lowCoverageModules.isNotEmpty) {
      recommendations.add('以下模块的测试覆盖率较低，建议优先添加测试：');
      for (final module in lowCoverageModules) {
        recommendations.add('  - ${module.moduleName}: ${module.coveragePercentage.toStringAsFixed(1)}%');
      }
    }
    
    // 检查完全没有测试的模块
    final untestedModules = coverage.values
        .where((module) => module.testedFiles == 0)
        .toList();
    
    if (untestedModules.isNotEmpty) {
      recommendations.add('以下模块完全没有测试，需要立即添加：');
      for (final module in untestedModules) {
        recommendations.add('  - ${module.moduleName}');
      }
    }
    
    // 检查高覆盖率模块
    final highCoverageModules = coverage.values
        .where((module) => module.coveragePercentage >= 90)
        .toList();
    
    if (highCoverageModules.isNotEmpty) {
      recommendations.add('以下模块测试覆盖率良好：');
      for (final module in highCoverageModules) {
        recommendations.add('  - ${module.moduleName}: ${module.coveragePercentage.toStringAsFixed(1)}%');
      }
    }
    
    // 总体建议
    final overallCoverage = _calculateOverallCoverage(coverage);
    if (overallCoverage < 80) {
      recommendations.add('总体测试覆盖率为 ${overallCoverage.toStringAsFixed(1)}%，建议提升至 80% 以上');
    }
    
    return recommendations;
  }
  
  /// 生成详细报告
  static String generateDetailedReport(CoverageReport report) {
    final buffer = StringBuffer();
    
    buffer.writeln('# 测试覆盖率报告');
    buffer.writeln();
    buffer.writeln('## 总体统计');
    buffer.writeln('- 源文件总数: ${report.totalSourceFiles}');
    buffer.writeln('- 测试文件总数: ${report.totalTestFiles}');
    buffer.writeln('- 总体覆盖率: ${report.overallCoverage.toStringAsFixed(1)}%');
    buffer.writeln();
    
    buffer.writeln('## 模块覆盖率详情');
    final sortedModules = report.coverageByModule.values.toList()
      ..sort((a, b) => b.coveragePercentage.compareTo(a.coveragePercentage));
    
    for (final module in sortedModules) {
      buffer.writeln('### ${module.moduleName}');
      buffer.writeln('- 文件总数: ${module.totalFiles}');
      buffer.writeln('- 已测试文件: ${module.testedFiles}');
      buffer.writeln('- 覆盖率: ${module.coveragePercentage.toStringAsFixed(1)}%');
      
      if (module.untestedFiles.isNotEmpty) {
        buffer.writeln('- 未测试文件:');
        for (final file in module.untestedFiles) {
          buffer.writeln('  - $file');
        }
      }
      buffer.writeln();
    }
    
    buffer.writeln('## 改进建议');
    for (final recommendation in report.recommendations) {
      buffer.writeln('- $recommendation');
    }
    
    return buffer.toString();
  }
  
  /// 导出报告到文件
  static Future<void> exportReport(CoverageReport report, String filePath) async {
    final reportContent = generateDetailedReport(report);
    final file = File(filePath);
    await file.writeAsString(reportContent);
    print('报告已导出到: $filePath');
  }
  
  /// 生成JSON格式的报告
  static String generateJsonReport(CoverageReport report) {
    final json = {
      'totalSourceFiles': report.totalSourceFiles,
      'totalTestFiles': report.totalTestFiles,
      'overallCoverage': report.overallCoverage,
      'modules': report.coverageByModule.map((key, value) => MapEntry(key, {
        'moduleName': value.moduleName,
        'totalFiles': value.totalFiles,
        'testedFiles': value.testedFiles,
        'coveragePercentage': value.coveragePercentage,
        'untestedFiles': value.untestedFiles,
      })),
      'recommendations': report.recommendations,
      'generatedAt': DateTime.now().toIso8601String(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(json);
  }
}

/// 覆盖率报告数据类
class CoverageReport {
  final int totalSourceFiles;
  final int totalTestFiles;
  final Map<String, ModuleCoverage> coverageByModule;
  final double overallCoverage;
  final List<String> recommendations;

  CoverageReport({
    required this.totalSourceFiles,
    required this.totalTestFiles,
    required this.coverageByModule,
    required this.overallCoverage,
    required this.recommendations,
  });
}

/// 模块覆盖率数据类
class ModuleCoverage {
  final String moduleName;
  final int totalFiles;
  final int testedFiles;
  final List<String> untestedFiles;
  final double coveragePercentage;

  ModuleCoverage({
    required this.moduleName,
    required this.totalFiles,
    required this.testedFiles,
    required this.untestedFiles,
    required this.coveragePercentage,
  });
}

/// 主函数 - 运行覆盖率分析
void main() async {
  try {
    final report = await TestCoverageAnalysis.analyzeCoverage();
    
    // 打印简要报告
    print('\n=== 测试覆盖率报告 ===');
    print('总体覆盖率: ${report.overallCoverage.toStringAsFixed(1)}%');
    print('源文件总数: ${report.totalSourceFiles}');
    print('测试文件总数: ${report.totalTestFiles}');
    
    // 导出详细报告
    await TestCoverageAnalysis.exportReport(report, 'coverage_report.md');
    
    // 导出JSON报告
    final jsonReport = TestCoverageAnalysis.generateJsonReport(report);
    await File('coverage_report.json').writeAsString(jsonReport);
    
    print('\n详细报告已生成:');
    print('- coverage_report.md (Markdown格式)');
    print('- coverage_report.json (JSON格式)');
    
    // 如果覆盖率低于80%，退出码为1
    if (report.overallCoverage < 80) {
      print('\n警告: 测试覆盖率低于80%，建议增加更多测试！');
      exit(1);
    } else {
      print('\n✅ 测试覆盖率达标！');
      exit(0);
    }
  } catch (e) {
    print('分析过程中出现错误: $e');
    exit(1);
  }
}