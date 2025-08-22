# Code Specification - Cherry Note

## Flutter 跨平台开发规范

### 1. Provider 配置最佳实践

#### 1.1 平台感知的BLoC注册
```dart
// ❌ 避免：直接条件表达式在Provider列表中
providers: [
  kIsWeb ? BlocProvider<WebBloc>(...) : BlocProvider<NativeBloc>(...) // 编译错误
]

// ✅ 正确：动态构建Provider列表
final providers = <BlocProvider>[];
if (kIsWeb) {
  providers.add(BlocProvider<WebBloc>(...));
} else {
  providers.add(BlocProvider<NativeBloc>(...));
}
return MultiBlocProvider(providers: providers, child: widget);
```

#### 1.2 跨平台Widget中的BLoC访问
```dart
// ❌ 避免：直接指定具体BLoC类型
BlocBuilder<NotesBloc, NotesState>(...)

// ✅ 正确：平台感知的BLoC访问
Widget _buildContent() {
  return kIsWeb
    ? BlocBuilder<WebNotesBloc, NotesState>(
        builder: (context, state) => _buildNotesContent(context, state),
      )
    : BlocBuilder<NotesBloc, NotesState>(
        builder: (context, state) => _buildNotesContent(context, state),
      );
}

// 辅助方法模式
dynamic _getNotesBloc(BuildContext context) {
  if (kIsWeb) {
    return context.read<WebNotesBloc>();
  } else {
    return context.read<NotesBloc>();
  }
}
```

### 2. 跨平台存储实现

#### 2.1 Web存储实现
```dart
// Web平台使用SharedPreferences/localStorage
class WebDataSource implements DataSource {
  static const String _dataKey = 'app_data_key';
  
  @override
  Future<List<Model>> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_dataKey);
    
    if (jsonString == null) {
      await _createDefaultData();
      return await loadData();
    }

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Model.fromJson(json)).toList();
  }
  
  @override
  Future<void> saveData(List<Model> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(data.map((item) => item.toJson()).toList());
    await prefs.setString(_dataKey, jsonString);
  }
}
```

#### 2.2 原生平台存储实现
```dart
// 其他平台使用文件系统
class NativeDataSource implements DataSource {
  final String _basePath;
  
  @override
  Future<List<Model>> loadData() async {
    final directory = Directory(_basePath);
    if (!await directory.exists()) {
      return [];
    }
    
    // 文件系统操作
    // ...
  }
}
```

#### 2.3 依赖注入配置
```dart
@module
abstract class AppModule {
  @lazySingleton
  DataSource dataSource(@Named('dataDirectory') String basePath) {
    if (kIsWeb) {
      return WebDataSource();
    } else {
      return NativeDataSource(basePath: basePath);
    }
  }
  
  @Named('dataDirectory')
  @preResolve
  @lazySingleton
  Future<String> dataDirectory() async {
    if (kIsWeb) {
      return 'web_storage_key';
    } else {
      final documentsDir = await getApplicationDocumentsDirectory();
      return path.join(documentsDir.path, 'AppData');
    }
  }
}
```

### 3. 错误处理规范

#### 3.1 安全的上下文检查
```dart
// ✅ 安全的错误显示
void _handleError(AppError error) {
  if (!mounted) return;

  if (widget.showDialogs && error.severity.index >= ErrorSeverity.high.index) {
    // 检查Navigator是否可用
    final navigator = Navigator.maybeOf(context);
    if (navigator != null) {
      ErrorDialog.show(context, error);
    } else {
      debugPrint('Error (Navigator not available): ${error.message}');
    }
  } else if (widget.showSnackBars) {
    // 检查ScaffoldMessenger是否可用
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger != null) {
      scaffoldMessenger.showSnackBar(ErrorSnackBar(error: error));
    } else {
      debugPrint('Error (ScaffoldMessenger not available): ${error.message}');
    }
  }
}
```

### 4. 实体类规范

#### 4.1 JSON序列化支持
所有用于跨平台存储的实体类必须包含：
```dart
class NoteFile extends Equatable {
  // 属性定义...
  
  /// Convert to JSON for web storage
  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'title': title,
      'content': content,
      'tags': tags,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
      'isSticky': isSticky,
    };
  }

  /// Create from JSON for web storage
  factory NoteFile.fromJson(Map<String, dynamic> json) {
    return NoteFile(
      filePath: json['filePath'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      tags: List<String>.from(json['tags'] as List),
      created: DateTime.parse(json['created'] as String),
      updated: DateTime.parse(json['updated'] as String),
      isSticky: json['isSticky'] as bool? ?? false,
    );
  }
}
```

#### 4.2 枚举处理
确保所有switch语句处理所有枚举值：
```dart
int comparison;
switch (_currentSortBy) {
  case NotesSortBy.title:
    comparison = a.title.compareTo(b.title);
    break;
  case NotesSortBy.createdDate:
    comparison = a.created.compareTo(b.created);
    break;
  case NotesSortBy.modifiedDate:
    comparison = a.updated.compareTo(b.updated);
    break;
  case NotesSortBy.size:
    comparison = a.content.length.compareTo(b.content.length);
    break;
  case NotesSortBy.tags:
    comparison = a.tags.join(',').compareTo(b.tags.join(','));
    break;
  // 确保所有枚举值都被处理
}
```

### 5. 路由配置规范

#### 5.1 平台感知的路由设置
```dart
GoRoute(
  path: AppRoutes.home,
  builder: (context, state) {
    final providers = <BlocProvider>[
      BlocProvider<FoldersBloc>(
        create: (context) => GetIt.instance<FoldersBloc>(),
      ),
      BlocProvider<TagsBloc>(
        create: (context) => GetIt.instance<TagsBloc>(),
      ),
    ];
    
    // 根据平台添加不同的Provider
    if (kIsWeb) {
      providers.add(BlocProvider<WebNotesBloc>(
        create: (context) => WebNotesBloc(),
      ));
    } else {
      providers.add(BlocProvider<NotesBloc>(
        create: (context) => NotesBloc(
          notesDirectory: GetIt.instance<String>(instanceName: 'notesDirectory')
        ),
      ));
    }
    
    return MultiBlocProvider(
      providers: providers,
      child: const MainScreen(),
    );
  },
),
```

### 6. 测试规范

#### 6.1 跨平台测试
```dart
// 确保测试覆盖两个平台的实现
testWidgets('should work on web platform', (tester) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.web;
  // Web平台测试逻辑
});

testWidgets('should work on mobile platform', (tester) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  // 移动平台测试逻辑
});
```

### 7. 性能优化

#### 7.1 平台特定优化
```dart
// Web平台优化
if (kIsWeb) {
  // 使用Web特定的优化
  WebPlatformService.updateTitle('App Title');
  
  // 检查浏览器兼容性
  if (!WebPlatformService.supportsRequiredFeatures) {
    debugPrint('Warning: Browser may not support all features');
  }
}
```

### 8. 常见问题与解决方案

#### 8.1 Provider错误
- **问题**: `Could not find the correct Provider<BlocType>`
- **解决**: 确保Provider在正确的层级注册，使用平台感知的动态Provider列表

#### 8.2 Navigator上下文错误
- **问题**: `Navigator operation requested with a context that does not include a Navigator`
- **解决**: 使用`Navigator.maybeOf(context)`进行安全检查

#### 8.3 Web存储错误
- **问题**: `Unsupported operation: _Namespace`
- **解决**: 为Web平台创建基于SharedPreferences的存储实现

#### 8.4 类型系统错误
- **问题**: BlocBuilder泛型类型不匹配
- **解决**: 使用平台条件分支提供正确的泛型类型

### 9. 代码审查清单

- [ ] 是否为跨平台存储实现了对应的DataSource？
- [ ] 实体类是否包含toJson/fromJson方法？
- [ ] BLocBuilder是否使用了正确的泛型类型？
- [ ] Provider配置是否支持平台感知？
- [ ] 错误处理是否包含上下文安全检查？
- [ ] 所有枚举的switch语句是否穷尽？
- [ ] 是否避免了在Provider列表中使用条件表达式？

---

**注意**: 本规范基于Cherry Note项目的实际问题总结，旨在避免跨平台Flutter开发中的常见陷阱和错误。