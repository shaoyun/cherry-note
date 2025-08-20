import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 虚拟滚动列表组件 - 优化大量数据的渲染性能
class VirtualListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final double itemHeight;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final int? cacheExtent;
  final void Function()? onEndReached;
  final double endReachedThreshold;

  const VirtualListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.itemHeight,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.cacheExtent,
    this.onEndReached,
    this.endReachedThreshold = 200.0,
  });

  @override
  State<VirtualListView<T>> createState() => _VirtualListViewState<T>();
}

class _VirtualListViewState<T> extends State<VirtualListView<T>> {
  late ScrollController _scrollController;
  bool _hasReachedEnd = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (widget.onEndReached == null || _hasReachedEnd) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    if (maxScroll - currentScroll <= widget.endReachedThreshold) {
      _hasReachedEnd = true;
      widget.onEndReached!();
      
      // Reset flag after a delay to allow for new data loading
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _hasReachedEnd = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      cacheExtent: widget.cacheExtent?.toDouble(),
      itemCount: widget.items.length,
      itemExtent: widget.itemHeight,
      itemBuilder: (context, index) {
        if (index >= widget.items.length) return const SizedBox.shrink();
        return widget.itemBuilder(context, widget.items[index], index);
      },
    );
  }
}

/// 虚拟网格视图组件 - 优化大量数据的网格渲染性能
class VirtualGridView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final int? cacheExtent;
  final void Function()? onEndReached;
  final double endReachedThreshold;

  const VirtualGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.gridDelegate,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.cacheExtent,
    this.onEndReached,
    this.endReachedThreshold = 200.0,
  });

  @override
  State<VirtualGridView<T>> createState() => _VirtualGridViewState<T>();
}

class _VirtualGridViewState<T> extends State<VirtualGridView<T>> {
  late ScrollController _scrollController;
  bool _hasReachedEnd = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (widget.onEndReached == null || _hasReachedEnd) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    if (maxScroll - currentScroll <= widget.endReachedThreshold) {
      _hasReachedEnd = true;
      widget.onEndReached!();
      
      // Reset flag after a delay to allow for new data loading
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _hasReachedEnd = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: _scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      cacheExtent: widget.cacheExtent?.toDouble(),
      gridDelegate: widget.gridDelegate,
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        if (index >= widget.items.length) return const SizedBox.shrink();
        return widget.itemBuilder(context, widget.items[index], index);
      },
    );
  }
}

/// 懒加载列表组件 - 支持分页加载
class LazyLoadListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<List<T>> Function(int page, int pageSize) onLoadMore;
  final int pageSize;
  final double itemHeight;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final bool hasMore;

  const LazyLoadListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onLoadMore,
    this.pageSize = 20,
    required this.itemHeight,
    this.padding,
    this.controller,
    this.loadingWidget,
    this.errorWidget,
    this.hasMore = true,
  });

  @override
  State<LazyLoadListView<T>> createState() => _LazyLoadListViewState<T>();
}

class _LazyLoadListViewState<T> extends State<LazyLoadListView<T>> {
  late ScrollController _scrollController;
  bool _isLoading = false;
  bool _hasError = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (_isLoading || !widget.hasMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    if (maxScroll - currentScroll <= 200.0) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final newItems = await widget.onLoadMore(_currentPage + 1, widget.pageSize);
      if (mounted) {
        setState(() {
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      itemExtent: widget.itemHeight,
      itemCount: widget.items.length + (_isLoading || _hasError ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < widget.items.length) {
          return widget.itemBuilder(context, widget.items[index], index);
        }

        // Loading or error indicator
        if (_isLoading) {
          return widget.loadingWidget ?? 
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
        }

        if (_hasError) {
          return widget.errorWidget ?? 
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('加载失败'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadMore,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            );
        }

        return const SizedBox.shrink();
      },
    );
  }
}