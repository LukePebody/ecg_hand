// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardData _$CardDataFromJson(Map<String, dynamic> json) => CardData(
  id: json['id'] as String,
  name: json['name'] as String,
  faceImageUrl: json['faceImageUrl'] as String?,
  backImageUrl: json['backImageUrl'] as String?,
  isFaceUp: json['isFaceUp'] as bool,
  ranking: (json['ranking'] as num).toInt(),
);

Map<String, dynamic> _$CardDataToJson(CardData instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'faceImageUrl': instance.faceImageUrl,
  'backImageUrl': instance.backImageUrl,
  'isFaceUp': instance.isFaceUp,
  'ranking': instance.ranking,
};
