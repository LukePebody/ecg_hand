import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logging/logging.dart';
import 'package:ecg_protocol/ecg_protocol.dart';

final _logger = Logger('ClientNetworkService');

class ClientNetworkService {
  static final ClientNetworkService _instance =
      ClientNetworkService._internal();
  factory ClientNetworkService() => _instance;
  ClientNetworkService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  String? _connectedCode;
  final StreamController<GameMessage> _messageController =
      StreamController<GameMessage>.broadcast();

  Stream<GameMessage> get messages => _messageController.stream;
  bool get isConnected => _isConnected;
  String? get connectedCode => _connectedCode;

  /// Connect to a hosted game using a 6-digit code
  Future<bool> connectToGame(String hostCode, {String? serverHost}) async {
    serverHost ??= 'localhost:8080';

    try {
      _logger.info('Attempting to connect to game with code: $hostCode');

      // First, validate the code with the server
      final response = await http.post(
        Uri.parse('http://$serverHost/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': hostCode}),
      );

      if (response.statusCode != 200) {
        _logger.warning('Failed to join game: ${response.body}');
        return false;
      }

      final responseData = jsonDecode(response.body);
      final websocketPort = responseData['websocket_port'] as int;

      // Connect to WebSocket
      final wsUri = Uri.parse(
        'ws://${serverHost.split(':')[0]}:$websocketPort/connect',
      );
      _channel = WebSocketChannel.connect(wsUri);

      // Listen for messages
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onDone: () {
          _logger.info('WebSocket connection closed');
          _disconnect();
        },
        onError: (error) {
          _logger.warning('WebSocket error: $error');
          _disconnect();
        },
      );

      _isConnected = true;
      _connectedCode = hostCode;
      _logger.info('Successfully connected to game: $hostCode');

      return true;
    } catch (e) {
      _logger.severe('Failed to connect to game: $e');
      return false;
    }
  }

  /// Disconnect from the current game
  void disconnect() {
    _disconnect();
  }

  void _disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _connectedCode = null;
  }

  /// Send a message to the server
  void sendMessage(GameMessage message) {
    if (!_isConnected || _channel == null) {
      _logger.warning('Cannot send message: not connected');
      return;
    }

    final messageJson = jsonEncode(message.toJson());
    _channel!.sink.add(messageJson);
    _logger.info('Sent ${message.type} message to server');
  }

  /// Handle incoming messages from the server
  void _handleMessage(dynamic rawMessage) {
    try {
      final messageData = jsonDecode(rawMessage as String);
      final gameMessage = GameMessage.fromJson(messageData);

      _logger.info('Received ${gameMessage.type} message from server');
      _messageController.add(gameMessage);
    } catch (e) {
      _logger.warning('Failed to parse message: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _disconnect();
    _messageController.close();
  }
}
