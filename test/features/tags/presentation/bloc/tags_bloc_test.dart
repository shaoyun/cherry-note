import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:cherry_note/features/tags/domain/entities/tag.dart';
import 'package:cherry_note/features/tags/domain/entities/tag_filter.dart';
import 'package:cherry_note/features/tags/domain/repositories/tag_repository.dart';
import 'package:cherry_note/features/tags/domain/usecases/get_all_tags.dart';
import 'package:cherry_note/features/tags/domain/usecases/create_tag.dart';
import 'package:cherry_note/features/tags/domain/usecases/search_tags.dart';
import 'package:cherry_note/features/tags/domain/usecases/get_tag_suggestions.dart';
import 'package:cherry_note/features/tags/domain/usecases/delete_tag.dart';
import 'package:cherry_note/features/tags/presentation/bloc/tags_bloc.dart';
import 'package:cherry_note/features/tags/presentation/bloc/tags_event.dart';
import 'package:cherry_note/features/tags/presentation/bloc/tags_state.dart';

import 'tags_bloc_test.mocks.dart';

@GenerateMocks([
  TagRepository,
  GetAllTags,
  CreateTag,
  SearchTags,
  GetTagSuggestions,
  DeleteTag,
])
void main() {
  group('TagsBloc', () {
    late TagsBloc tagsBloc;
    late MockTagRepository mockTagRepository;
    late MockGetAllTags mockGetAllTags;
    late MockCreateTag mockCreateTag;
    late MockSearchTags mockSearchTags;
    late MockGetTagSuggestions mockGetTagSuggestions;
    late MockDeleteTag mockDeleteTag;

    // 测试数据
    final testTags = [
      Tag(
        name: 'work',
        color: '#FF5722',
        description: 'Work related notes',
        noteCount: 5,
        createdAt: DateTime(2024, 1, 1),
        lastUsedAt: DateTime(2024, 1, 15),
      ),
      Tag(
        name: 'personal',
        color: '#4CAF50',
        description: 'Personal notes',
        noteCount: 3,
        createdAt: DateTime(2024, 1, 2),
        lastUsedAt: DateTime(2024, 1, 14),
      ),
      Tag(
        name: 'study',
        color: '#2196F3',
        description: 'Study notes',
        noteCount: 8,
        createdAt: DateTime(2024, 1, 3),
        lastUsedAt: DateTime(2024, 1, 16),
      ),
    ];

    final testTag = Tag(
      name: 'test',
      color: '#9C27B0',
      description: 'Test tag',
      noteCount: 0,
      createdAt: DateTime(2024, 1, 4),
      lastUsedAt: DateTime(2024, 1, 4),
    );

    setUp(() {
      mockTagRepository = MockTagRepository();
      mockGetAllTags = MockGetAllTags();
      mockCreateTag = MockCreateTag();
      mockSearchTags = MockSearchTags();
      mockGetTagSuggestions = MockGetTagSuggestions();
      mockDeleteTag = MockDeleteTag();

      tagsBloc = TagsBloc(
        tagRepository: mockTagRepository,
        getAllTags: mockGetAllTags,
        createTag: mockCreateTag,
        searchTags: mockSearchTags,
        getTagSuggestions: mockGetTagSuggestions,
        deleteTag: mockDeleteTag,
      );
    });

    tearDown(() {
      tagsBloc.close();
    });

    test('initial state is TagsInitial', () {
      expect(tagsBloc.state, equals(const TagsInitial()));
    });

    group('LoadTagsEvent', () {
      blocTest<TagsBloc, TagsState>(
        'emits [TagsLoading, TagsLoaded] when LoadTagsEvent succeeds',
        build: () {
          when(mockGetAllTags()).thenAnswer((_) async => testTags);
          return tagsBloc;
        },
        act: (bloc) => bloc.add(const LoadTagsEvent()),
        expect: () => [
          const TagsLoading(),
          isA<TagsLoaded>()
              .having((state) => state.tags.length, 'tags length', 3)
              .having((state) => state.sortBy, 'sortBy', TagSortBy.name)
              .having((state) => state.ascending, 'ascending', true),
        ],
        verify: (_) {
          verify(mockGetAllTags()).called(1);
        },
      );

      blocTest<TagsBloc, TagsState>(
        'emits [TagsLoading, TagsError] when LoadTagsEvent fails',
        build: () {
          when(mockGetAllTags()).thenThrow(Exception('Failed to load tags'));
          return tagsBloc;
        },
        act: (bloc) => bloc.add(const LoadTagsEvent()),
        expect: () => [
          const TagsLoading(),
          isA<TagsError>()
              .having((state) => state.message, 'message', contains('Failed to load tags')),
        ],
      );
    });

    group('CreateTagEvent', () {
      blocTest<TagsBloc, TagsState>(
        'emits correct states when CreateTagEvent succeeds',
        build: () {
          when(mockCreateTag(any)).thenAnswer((_) async => testTag);
          return tagsBloc;
        },
        act: (bloc) => bloc.add(const CreateTagEvent(
          name: 'test',
          color: '#9C27B0',
          description: 'Test tag',
        )),
        expect: () => [
          isA<TagOperationInProgress>()
              .having((state) => state.operation, 'operation', 'create')
              .having((state) => state.tagName, 'tagName', 'test'),
          isA<TagOperationSuccess>()
              .having((state) => state.operation, 'operation', 'create')
              .having((state) => state.tagName, 'tagName', 'test'),
          isA<TagsLoaded>()
              .having((state) => state.tags.length, 'tags length', 1),
        ],
        verify: (_) {
          verify(mockCreateTag(any)).called(1);
        },
      );

      blocTest<TagsBloc, TagsState>(
        'emits error states when CreateTagEvent fails',
        build: () {
          when(mockCreateTag(any)).thenThrow(ArgumentError('Invalid tag name'));
          return tagsBloc;
        },
        act: (bloc) => bloc.add(const CreateTagEvent(name: '')),
        expect: () => [
          isA<TagOperationInProgress>()
              .having((state) => state.operation, 'operation', 'create'),
          isA<TagOperationError>()
              .having((state) => state.operation, 'operation', 'create')
              .having((state) => state.message, 'message', contains('Failed to create tag')),
        ],
      );
    });

    group('DeleteTagEvent', () {
      blocTest<TagsBloc, TagsState>(
        'emits correct states when DeleteTagEvent succeeds',
        build: () {
          when(mockDeleteTag(any)).thenAnswer((_) async {});
          return tagsBloc;
        },
        act: (bloc) => bloc.add(const DeleteTagEvent(name: 'test')),
        expect: () => [
          isA<TagOperationInProgress>()
              .having((state) => state.operation, 'operation', 'delete')
              .having((state) => state.tagName, 'tagName', 'test'),
          isA<TagOperationSuccess>()
              .having((state) => state.operation, 'operation', 'delete')
              .having((state) => state.tagName, 'tagName', 'test'),
          isA<TagsLoaded>(),
        ],
        verify: (_) {
          verify(mockDeleteTag(any)).called(1);
        },
      );

      blocTest<TagsBloc, TagsState>(
        'emits error states when DeleteTagEvent fails',
        build: () {
          when(mockDeleteTag(any)).thenThrow(StateError('Tag not found'));
          return tagsBloc;
        },
        act: (bloc) => bloc.add(const DeleteTagEvent(name: 'nonexistent')),
        expect: () => [
          isA<TagOperationInProgress>()
              .having((state) => state.operation, 'operation', 'delete'),
          isA<TagOperationError>()
              .having((state) => state.operation, 'operation', 'delete')
              .having((state) => state.message, 'message', contains('Failed to delete tag')),
        ],
      );
    });

    group('SearchTagsEvent', () {
      final searchResults = [testTags[0], testTags[2]]; // work and study tags

      blocTest<TagsBloc, TagsState>(
        'emits search states when SearchTagsEvent succeeds',
        build: () {
          when(mockSearchTags(any)).thenAnswer((_) async => searchResults);
          return tagsBloc;
        },
        act: (bloc) => bloc.add(const SearchTagsEvent(query: 'work')),
        expect: () => [
          isA<TagsSearching>()
              .having((state) => state.query, 'query', 'work'),
          isA<TagsSearchResults>()
              .having((state) => state.query, 'query', 'work')
              .having((state) => state.results.length, 'results length', 2),
        ],
        verify: (_) {
          verify(mockSearchTags(any)).called(1);
        },
      );

      blocTest<TagsBloc, TagsState>(
        'emits error when SearchTagsEvent fails',
        build: () {
          when(mockSearchTags(any)).thenThrow(Exception('Search failed'));
          return tagsBloc;
        },
        act: (bloc) => bloc.add(const SearchTagsEvent(query: 'test')),
        expect: () => [
          isA<TagsSearching>(),
          isA<TagsError>()
              .having((state) => state.message, 'message', contains('Search failed')),
        ],
      );
    });

    group('GetTagSuggestionsEvent', () {
      final suggestions = ['work', 'workflow', 'workspace'];

      blocTest<TagsBloc, TagsState>(
        'emits suggestions when GetTagSuggestionsEvent succeeds',
        build: () {
          when(mockGetTagSuggestions(any)).thenAnswer((_) async => suggestions);
          return tagsBloc;
        },
        act: (bloc) => bloc.add(const GetTagSuggestionsEvent(query: 'work')),
        expect: () => [
          isA<TagSuggestions>()
              .having((state) => state.query, 'query', 'work')
              .having((state) => state.suggestions.length, 'suggestions length', 3),
        ],
        verify: (_) {
          verify(mockGetTagSuggestions(any)).called(1);
        },
      );
    });

    group('Tag Filter Events', () {
      blocTest<TagsBloc, TagsState>(
        'SelectTagForFilterEvent adds tag to filter',
        build: () => tagsBloc,
        seed: () => TagsLoaded(
          tags: testTags,
          filter: const TagFilter(),
          sortBy: TagSortBy.name,
          ascending: true,
        ),
        act: (bloc) => bloc.add(const SelectTagForFilterEvent(tagName: 'work')),
        expect: () => [
          isA<TagsLoaded>()
              .having((state) => state.filter.selectedTags, 'selected tags', contains('work'))
              .having((state) => state.filter.enabled, 'filter enabled', true),
        ],
      );

      blocTest<TagsBloc, TagsState>(
        'ToggleTagFilterEvent toggles tag selection',
        build: () => tagsBloc,
        seed: () => TagsLoaded(
          tags: testTags,
          filter: const TagFilter(),
          sortBy: TagSortBy.name,
          ascending: true,
        ),
        act: (bloc) {
          bloc.add(const ToggleTagFilterEvent(tagName: 'work'));
        },
        expect: () => [
          isA<TagsLoaded>()
              .having((state) => state.filter.selectedTags, 'selected tags', contains('work')),
        ],
      );

      blocTest<TagsBloc, TagsState>(
        'ClearTagFilterEvent clears all selected tags',
        build: () => tagsBloc,
        seed: () => TagsLoaded(
          tags: testTags,
          filter: const TagFilter(
            selectedTags: ['work', 'personal'],
            enabled: true,
          ),
          sortBy: TagSortBy.name,
          ascending: true,
        ),
        act: (bloc) => bloc.add(const ClearTagFilterEvent()),
        expect: () => [
          isA<TagsLoaded>()
              .having((state) => state.filter.selectedTags, 'selected tags', isEmpty)
              .having((state) => state.filter.enabled, 'filter enabled', false),
        ],
      );
    });

    group('SetTagSortEvent', () {
      blocTest<TagsBloc, TagsState>(
        'changes sort order',
        build: () => tagsBloc,
        seed: () => TagsLoaded(
          tags: testTags,
          filter: const TagFilter(),
          sortBy: TagSortBy.name,
          ascending: true,
        ),
        act: (bloc) => bloc.add(const SetTagSortEvent(
          sortBy: TagSortBy.noteCount,
          ascending: false,
        )),
        expect: () => [
          isA<TagsLoaded>()
              .having((state) => state.sortBy, 'sortBy', TagSortBy.noteCount)
              .having((state) => state.ascending, 'ascending', false),
        ],
      );
    });

    group('UpdateTagUsageEvent', () {
      blocTest<TagsBloc, TagsState>(
        'updates tag usage statistics silently',
        build: () {
          when(mockTagRepository.updateTagUsage(any)).thenAnswer((_) async {});
          return tagsBloc;
        },
        seed: () => TagsLoaded(
          tags: testTags,
          filter: const TagFilter(),
          sortBy: TagSortBy.name,
          ascending: true,
        ),
        act: (bloc) => bloc.add(const UpdateTagUsageEvent(tagName: 'work')),
        // This event should update silently, so we expect the state to be updated
        // but we can't easily test the internal cache update without exposing internals
        verify: (_) {
          verify(mockTagRepository.updateTagUsage('work')).called(1);
        },
      );
    });

    group('CleanupUnusedTagsEvent', () {
      blocTest<TagsBloc, TagsState>(
        'emits cleanup success when unused tags are cleaned',
        build: () {
          when(mockTagRepository.cleanupUnusedTags())
              .thenAnswer((_) async => ['unused1', 'unused2']);
          return tagsBloc;
        },
        act: (bloc) => bloc.add(const CleanupUnusedTagsEvent()),
        expect: () => [
          isA<TagOperationInProgress>()
              .having((state) => state.operation, 'operation', 'cleanup'),
          isA<TagsCleanupSuccess>()
              .having((state) => state.cleanedTags.length, 'cleaned tags length', 2),
          isA<TagsLoaded>(),
        ],
        verify: (_) {
          verify(mockTagRepository.cleanupUnusedTags()).called(1);
        },
      );
    });

    group('SyncTagsEvent', () {
      blocTest<TagsBloc, TagsState>(
        'emits sync states when SyncTagsEvent succeeds',
        build: () {
          when(mockTagRepository.syncTags()).thenAnswer((_) async {});
          when(mockGetAllTags()).thenAnswer((_) async => testTags);
          return tagsBloc;
        },
        act: (bloc) => bloc.add(const SyncTagsEvent()),
        expect: () => [
          isA<TagsSyncing>(),
          isA<TagsSyncSuccess>()
              .having((state) => state.syncedCount, 'synced count', 3),
          isA<TagsLoaded>()
              .having((state) => state.tags.length, 'tags length', 3),
        ],
        verify: (_) {
          verify(mockTagRepository.syncTags()).called(1);
          verify(mockGetAllTags()).called(1);
        },
      );
    });

    // Test helper methods
    group('Helper Methods', () {
      test('currentFilter returns current filter', () {
        expect(tagsBloc.currentFilter, isA<TagFilter>());
      });

      test('selectedTagCount returns 0 initially', () {
        expect(tagsBloc.selectedTagCount, 0);
      });

      test('hasActiveFilter returns false initially', () {
        expect(tagsBloc.hasActiveFilter, false);
      });

      test('isTagSelectedForFilter returns false for any tag initially', () {
        expect(tagsBloc.isTagSelectedForFilter('work'), false);
      });
    });
  });
}