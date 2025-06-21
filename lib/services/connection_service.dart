import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import '../models/card_data.dart';
import '../models/game_message.dart';

final _logger = Logger('ConnectionService');

enum ConnectionStatus { disconnected, connecting, connected, error }

class ConnectionService extends ChangeNotifier {
  ConnectionStatus _status = ConnectionStatus.disconnected;
  WebSocketChannel? _channel;
  String? _gameCode;
  String? _playerName;
  List<CardData> _hand = [];
  String? _errorMessage;

  final StreamController<GameMessage> _messageController =
      StreamController<GameMessage>.broadcast();

  // Getters
  ConnectionStatus get status => _status;
  String? get gameCode => _gameCode;
  String? get playerName => _playerName;
  List<CardData> get hand => List.unmodifiable(_hand);
  String? get errorMessage => _errorMessage;
  Stream<GameMessage> get messages => _messageController.stream;

  /// Connect to a game using a 6-digit code
  Future<void> connectToGame(String code, String name) async {
    if (_status == ConnectionStatus.connecting) return;

    _updateStatus(ConnectionStatus.connecting);
    _gameCode = code;
    _playerName = name;
    _errorMessage = null;

    try {
      _logger.info('Attempting to connect to game: $code as $name');

      // Try to find the game host by scanning local network
      // For now, we'll try localhost with common ports
      final possiblePorts = [8080, 3000, 8000, 8888, 9000];
      String? hostUrl;

      for (final port in possiblePorts) {
        try {
          final response = await http
              .post(
                Uri.parse('http://localhost:$port/join'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'code': code}),
              )
              .timeout(const Duration(seconds: 2));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['status'] == 'success') {
              hostUrl = 'localhost:$port';
              break;
            }
          }
        } catch (e) {
          // Try next port
          continue;
        }
      }

      if (hostUrl == null) {
        throw Exception('Game not found with code: $code');
      }

      // Connect via WebSocket
      final wsUrl = 'ws://$hostUrl/connect';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen for messages
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          _logger.severe('WebSocket error: $error');
          _errorMessage = 'Connection error: $error';
          _updateStatus(ConnectionStatus.error);
        },
        onDone: () {
          _logger.info('WebSocket connection closed');
          _updateStatus(ConnectionStatus.disconnected);
        },
      );

      _updateStatus(ConnectionStatus.connected);
      _logger.info('Connected to game successfully');

      // Send join message
      _sendMessage(GameMessage.join(_playerName!));
    } catch (e) {
      _logger.severe('Failed to connect to game: $e');
      _errorMessage = 'Failed to connect: $e';
      _updateStatus(ConnectionStatus.error);
    }
  }

  /// Disconnect from the current game
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _hand.clear();
    _gameCode = null;
    _playerName = null;
    _errorMessage = null;
    _updateStatus(ConnectionStatus.disconnected);
    _logger.info('Disconnected from game');
  }

  /// Send a message to the game host
  void _sendMessage(GameMessage message) {
    if (_status != ConnectionStatus.connected) return;

    try {
      final json = jsonEncode(message.toJson());
      _channel?.sink.add(json);
      _logger.info('Sent message: ${message.type}');
    } catch (e) {
      _logger.warning('Failed to send message: $e');
    }
  }

  /// Handle incoming messages from the game host
  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String);

      // Handle direct card_data messages from ECG_Table
      if (json['type'] == 'card_data') {
        _handleRawCardData(json);
        return;
      }

      // Handle GameMessage format
      final message = GameMessage.fromJson(json);

      switch (message.type) {
        case 'deal_cards':
          _handleDealCards(message);
          break;
        case 'remove_cards':
          _handleRemoveCards(message);
          break;
        case 'card_data':
          _handleCardData(message);
          break;
        case 'game_state':
          _handleGameState(message);
          break;
        default:
          _logger.info('Received message: ${message.type}');
      }

      _messageController.add(message);
    } catch (e) {
      _logger.warning('Failed to handle message: $e');
    }
  }

  /// Handle raw card data from ECG_Table
  void _handleRawCardData(Map<String, dynamic> json) {
    final cards =
        (json['cards'] as List?)
            ?.map((cardJson) => CardData.fromJson(cardJson))
            .toList() ??
        [];

    _hand.clear();
    _hand.addAll(cards);
    notifyListeners();
    _logger.info('Received raw card data, hand size: ${_hand.length}');
  }

  /// Handle cards being dealt to the player
  void _handleDealCards(GameMessage message) {
    final cards =
        (message.data['cards'] as List?)
            ?.map((cardJson) => CardData.fromJson(cardJson))
            .toList() ??
        [];

    _hand.addAll(cards);
    notifyListeners();
    _logger.info('Received ${cards.length} cards, hand size: ${_hand.length}');
  }

  /// Handle card data sent from ECG_Table
  void _handleCardData(GameMessage message) {
    final cards =
        (message.data['cards'] as List?)
            ?.map((cardJson) => CardData.fromJson(cardJson))
            .toList() ??
        [];

    _hand.clear();
    _hand.addAll(cards);
    notifyListeners();
    _logger.info('Received card data, hand size: ${_hand.length}');
  }

  /// Handle cards being removed from the player's hand
  void _handleRemoveCards(GameMessage message) {
    final cardIds = (message.data['card_ids'] as List?)?.cast<String>() ?? [];

    for (final cardId in cardIds) {
      _hand.removeWhere((card) => card.id == cardId);
    }

    notifyListeners();
    _logger.info('Removed ${cardIds.length} cards, hand size: ${_hand.length}');
  }

  /// Handle general game state updates
  void _handleGameState(GameMessage message) {
    _logger.info('Game state updated: ${message.data}');
    // Handle game state changes here
  }

  /// Play a card from the hand
  void playCard(CardData card) {
    if (_status != ConnectionStatus.connected) return;

    _sendMessage(GameMessage.playCard(card.id));
    _hand.remove(card);
    notifyListeners();
    _logger.info('Played card: ${card.name}');
  }

  /// Send a chat message
  void sendChatMessage(String text) {
    if (_status != ConnectionStatus.connected) return;

    _sendMessage(GameMessage.chat(_playerName!, text));
  }

  void _updateStatus(ConnectionStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _messageController.close();
    super.dispose();
  }
}
