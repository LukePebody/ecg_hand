// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameMessage _$GameMessageFromJson(Map<String, dynamic> json) => GameMessage(
  type: json['type'] as String,
  data: json['data'] as Map<String, dynamic>,
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$GameMessageToJson(GameMessage instance) =>
    <String, dynamic>{
      'type': instance.type,
      'data': instance.data,
      'timestamp': instance.timestamp.toIso8601String(),
    };
