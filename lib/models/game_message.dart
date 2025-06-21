import 'package:json_annotation/json_annotation.dart';

part 'game_message.g.dart';

@JsonSerializable()
class GameMessage {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const GameMessage({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  factory GameMessage.fromJson(Map<String, dynamic> json) =>
      _$GameMessageFromJson(json);
  Map<String, dynamic> toJson() => _$GameMessageToJson(this);

  // Factory constructors for common message types
  factory GameMessage.join(String playerName) {
    return GameMessage(
      type: 'join',
      data: {'player_name': playerName},
      timestamp: DateTime.now(),
    );
  }

  factory GameMessage.playCard(String cardId) {
    return GameMessage(
      type: 'play_card',
      data: {'card_id': cardId},
      timestamp: DateTime.now(),
    );
  }

  factory GameMessage.chat(String playerName, String message) {
    return GameMessage(
      type: 'chat',
      data: {'player_name': playerName, 'message': message},
      timestamp: DateTime.now(),
    );
  }

  factory GameMessage.dealCards(List<Map<String, dynamic>> cards) {
    return GameMessage(
      type: 'deal_cards',
      data: {'cards': cards},
      timestamp: DateTime.now(),
    );
  }

  factory GameMessage.removeCards(List<String> cardIds) {
    return GameMessage(
      type: 'remove_cards',
      data: {'card_ids': cardIds},
      timestamp: DateTime.now(),
    );
  }

  factory GameMessage.gameState(Map<String, dynamic> state) {
    return GameMessage(
      type: 'game_state',
      data: state,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'GameMessage(type: $type, data: $data, timestamp: $timestamp)';
  }
}
