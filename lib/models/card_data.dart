import 'package:json_annotation/json_annotation.dart';

part 'card_data.g.dart';

@JsonSerializable()
class CardData {
  final String id;
  final String name;
  final String? faceImageUrl; // Network URL for card face
  final String? backImageUrl; // Network URL for card back
  final bool isFaceUp;
  final int ranking;

  const CardData({
    required this.id,
    required this.name,
    this.faceImageUrl,
    this.backImageUrl,
    required this.isFaceUp,
    required this.ranking,
  });

  factory CardData.fromJson(Map<String, dynamic> json) =>
      _$CardDataFromJson(json);
  Map<String, dynamic> toJson() => _$CardDataToJson(this);

  CardData copyWith({
    String? id,
    String? name,
    String? faceImageUrl,
    String? backImageUrl,
    bool? isFaceUp,
    int? ranking,
  }) {
    return CardData(
      id: id ?? this.id,
      name: name ?? this.name,
      faceImageUrl: faceImageUrl ?? this.faceImageUrl,
      backImageUrl: backImageUrl ?? this.backImageUrl,
      isFaceUp: isFaceUp ?? this.isFaceUp,
      ranking: ranking ?? this.ranking,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CardData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CardData(id: $id, name: $name, isFaceUp: $isFaceUp)';
  }
}
