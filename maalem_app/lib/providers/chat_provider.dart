// lib/providers/chat_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../data/models/message_model.dart';
import '../core/constants/api_endpoints.dart';

class ChatProvider with ChangeNotifier {
  List<Message> _messages = [];
  bool _isLoading = false;
  socket_io.Socket? _socket;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;

  // 1. Démarrer le chat (Historique HTTP + Connexion Socket)
  void initChat(int bookingId) async {
    _isLoading = true;
    _messages.clear();
    notifyListeners();

    // A. On charge l'historique de la BDD
    try {
      final url = Uri.parse('${ApiEndpoints.messages}/$bookingId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> data = decoded['data'];
        _messages = data.map((m) => Message.fromJson(m)).toList();
      }
    } catch (e) {
      debugPrint("Erreur historique chat: $e");
    }

    // B. On se connecte au Socket en temps réel
    _socket = socket_io.io(
        ApiEndpoints.socketUrl,
        socket_io.OptionBuilder()
            .setTransports(['websocket']) // Obligatoire pour Flutter
            .enableAutoConnect()
            .build());

    _socket!.onConnect((_) {
      debugPrint("Socket connecte au serveur.");
      // On rejoint la "Room" de cette réservation
      _socket!.emit('join_chat', bookingId);

      _isLoading = false;
      notifyListeners();
    });

    // C. Quand on reçoit un message en temps réel
    _socket!.on('receive_message', (data) {
      final newMessage = Message.fromJson(data);
      _messages.add(newMessage);
      notifyListeners(); // 🔄 Met à jour l'écran instantanément !
    });
  }

  // 2. Envoyer un message
  void sendMessage(int bookingId, int senderId, String content) {
    if (content.trim().isEmpty) return;

    final data = {
      'bookingId': bookingId,
      'senderId': senderId,
      'content': content.trim(),
    };

    // On l'envoie au serveur Node.js
    _socket?.emit('send_message', data);
  }

  // 3. Déconnexion (quand on quitte l'écran)
  void disconnectChat() {
    _socket?.disconnect();
    _socket?.dispose();
  }
}
