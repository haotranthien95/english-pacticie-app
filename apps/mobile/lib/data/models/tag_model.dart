import '../../domain/entities/tag.dart';

/// Tag model for data layer with JSON serialization
class TagModel extends Tag {
  const TagModel({
    required super.id,
    required super.name,
    super.description,
  });

  /// Create TagModel from JSON response
  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  /// Convert TagModel to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  /// Create TagModel from Tag entity
  factory TagModel.fromEntity(Tag tag) {
    return TagModel(
      id: tag.id,
      name: tag.name,
      description: tag.description,
    );
  }

  @override
  TagModel copyWith({
    String? id,
    String? name,
    String? description,
  }) {
    return TagModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
}
