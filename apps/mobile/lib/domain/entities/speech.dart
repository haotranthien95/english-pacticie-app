import 'package:equatable/equatable.dart';
import '../../core/constants/enums.dart';

/// Speech entity representing a single speech item
/// Domain layer - pure business logic
class Speech extends Equatable {
  final String id;
  final String text;
  final String audioUrl;
  final SpeechLevel level;
  final SpeechType type;
  final List<String> tagIds;
  final DateTime createdAt;

  const Speech({
    required this.id,
    required this.text,
    required this.audioUrl,
    required this.level,
    required this.type,
    required this.tagIds,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        text,
        audioUrl,
        level,
        type,
        tagIds,
        createdAt,
      ];

  @override
  String toString() {
    return 'Speech(id: $id, text: $text, level: $level, type: $type)';
  }

  Speech copyWith({
    String? id,
    String? text,
    String? audioUrl,
    SpeechLevel? level,
    SpeechType? type,
    List<String>? tagIds,
    DateTime? createdAt,
  }) {
    return Speech(
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
