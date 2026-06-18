import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../data/models/message_model.dart';
import '../core/constants/api_endpoints.dart';

class ChatProvider with ChangeNotifier {
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isConnected = false;
  socket_io.Socket? _socket;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;

  // 1. Démarrer le chat (Historique HTTP + Connexion Socket)
  // 1. Démarrer le chat (Historique HTTP + Connexion Socket)
  void initChat(int bookingId) async {
    _isLoading = true;
    _messages.clear();
    // On met à jour l'interface pour afficher le chargement
    Future.microtask(() => notifyListeners());

    // A. Charger l'historique via HTTP
    try {
      final url = Uri.parse('${ApiEndpoints.messages}/$bookingId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> data = decoded['data'];
        _messages = data.map((m) => Message.fromJson(m)).toList();
      }
    } catch (e) {
      debugPrint("❌ Erreur historique messages: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // B. Connexion Socket
    try {
      if (_socket != null) {
        try {
          _socket!.disconnect();
        } catch (_) {}
        _socket!.clearListeners();
        _socket = null;
      }

      _socket = socket_io.io(
          ApiEndpoints.socketUrl,
          socket_io.OptionBuilder()
              .setTransports(['websocket'])
              .enableAutoConnect()
              .build());

      _socket!.onConnect((_) {
        _isConnected = true;
        notifyListeners();
        _socket!.emit('join_chat', bookingId);
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        notifyListeners();
      });

      _socket!.onConnectError((_) {
        _isConnected = false;
        notifyListeners();
      });

      _socket!.on('receive_message', (data) {
        final serverMsg = Message.fromJson(data);
        final existingIndex = _messages.indexWhere(
          (m) =>
              m.id < 0 &&
              m.senderId == serverMsg.senderId &&
              m.content == serverMsg.content &&
              m.timestamp.isAfter(DateTime.now().subtract(
                const Duration(seconds: 10),
              )),
        );
        if (existingIndex >= 0) {
          _messages[existingIndex] = serverMsg;
        } else {
          _messages.add(serverMsg);
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint("❌ Erreur initialisation Socket: $e");
    }
  }

  void sendMessage(int bookingId, int senderId, String content) {
    if (content.trim().isEmpty) return;

    final trimmed = content.trim();

    // Ajout optimiste : le message apparaît immédiatement
    final localMessage = Message(
      id: -DateTime.now().microsecondsSinceEpoch,
      bookingId: bookingId,
      senderId: senderId,
      content: trimmed,
      timestamp: DateTime.now(),
    );
    _messages.add(localMessage);
    notifyListeners();

    if (_socket != null && _isConnected) {
      _socket!.emitWithAck('send_message', {
        'bookingId': bookingId,
        'senderId': senderId,
        'content': trimmed,
      }, ack: (ack) {
        if (ack != null && ack['success'] == true) {
          final serverMsg = Message.fromJson(ack['message']);
          final idx = _messages.indexWhere((m) => m.id == localMessage.id);
          if (idx >= 0) {
            _messages[idx] = serverMsg;
            notifyListeners();
          }
        } else {
          _sendViaHttp(bookingId, senderId, trimmed, localMessage);
        }
      });
    } else {
      _sendViaHttp(bookingId, senderId, trimmed, localMessage);
    }
  }

  Future<void> _sendViaHttp(
    int bookingId,
    int senderId,
    String content,
    Message localMessage,
  ) async {
    try {
      final url = Uri.parse(ApiEndpoints.messages);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'booking_id': bookingId,
          'sender_id': senderId,
          'content': content,
        }),
      );
      if (response.statusCode == 201) {
        final serverMsg = Message.fromJson(json.decode(response.body)['data']);
        final idx = _messages.indexWhere((m) => m.id == localMessage.id);
        if (idx >= 0) {
          _messages[idx] = serverMsg;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("❌ Erreur envoi HTTP message: $e");
    }
  }

  void disconnectChat() {
    if (_socket != null) {
      try {
        _socket!.disconnect();
        _socket!.dispose();
      } catch (_) {}
      _socket = null;
    }
    _isConnected = false;
  }

  Future<void> markMessagesAsRead(int bookingId, int userId) async {
    try {
      final url = Uri.parse('${ApiEndpoints.messages}/read/$bookingId/$userId');
      await http.patch(url); // On dit au backend "C'est bon, j'ai tout lu !"
    } catch (e) {
      print("Erreur markAsRead: $e");
    }
  }
}
