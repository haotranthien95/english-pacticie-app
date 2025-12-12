import '../../core/constants/enums.dart';
import '../../domain/entities/speech.dart';

/// Speech model for data layer with JSON serialization
class SpeechModel extends Speech {
  const SpeechModel({
    required super.id,
    required super.text,
    required super.audioUrl,
    required super.level,
    required super.type,
    required super.tagIds,
    required super.createdAt,
  });

  /// Create SpeechModel from JSON response
  factory SpeechModel.fromJson(Map<String, dynamic> json) {
    return SpeechModel(
      id: json['id'] as String,
      text: json['text'] as String,
      audioUrl: json['audio_url'] as String,
      level: SpeechLevelExtension.fromValue(json['level'] as String),
      type: SpeechTypeExtension.fromValue(json['type'] as String),
      tagIds:
          (json['tag_ids'] as List<dynamic>).map((e) => e as String).toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert SpeechModel to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'audio_url': audioUrl,
      'level': level.value,
      'type': type.value,
      'tag_ids': tagIds,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create SpeechModel from Speech entity
  factory SpeechModel.fromEntity(Speech speech) {
    return SpeechModel(
      id: speech.id,
      text: speech.text,
      audioUrl: speech.audioUrl,
      level: speech.level,
      type: speech.type,
      tagIds: speech.tagIds,
      createdAt: speech.createdAt,
    );
  }

  @override
  SpeechModel copyWith({
    String? id,
    String? text,
    String? audioUrl,
    SpeechLevel? level,
    SpeechType? type,
    List<String>? tagIds,
    DateTime? createdAt,
  }) {
    return SpeechModel(
      id: id ?? this.id,
      text: text ?? this.text,
      audioUrl: audioUrl ?? this.audioUrl,
      level: level ?? this.level,
      type: type ?? this.type,
      tagIds: tagIds ?? this.tagIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
