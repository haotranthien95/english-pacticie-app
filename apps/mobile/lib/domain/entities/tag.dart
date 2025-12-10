import 'package:equatable/equatable.dart';

/// Tag entity for categorizing speeches
/// Domain layer - pure business logic
class Tag extends Equatable {
  final String id;
  final String name;
  final String? description;

  const Tag({
    required this.id,
    required this.name,
    this.description,
  });

  @override
  List<Object?> get props => [id, name, description];

  @override
  String toString() {
    return 'Tag(id: $id, name: $name, description: $description)';
  }

  Tag copyWith({
    String? id,
    String? name,
    String? description,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
}
