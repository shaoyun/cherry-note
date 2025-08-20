// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_file_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoteFileModel _$NoteFileModelFromJson(Map<String, dynamic> json) =>
    NoteFileModel(
      filePath: json['filePath'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      created: DateTime.parse(json['created'] as String),
      updated: DateTime.parse(json['updated'] as String),
      isSticky: json['isSticky'] as bool? ?? false,
    );

Map<String, dynamic> _$NoteFileModelToJson(NoteFileModel instance) =>
    <String, dynamic>{
      'filePath': instance.filePath,
      'title': instance.title,
      'content': instance.content,
      'tags': instance.tags,
      'created': instance.created.toIso8601String(),
      'updated': instance.updated.toIso8601String(),
      'isSticky': instance.isSticky,
    };
