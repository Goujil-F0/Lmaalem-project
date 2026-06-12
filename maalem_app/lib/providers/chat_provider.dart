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
  // 1. Démarrer le chat (Historique HTTP + Connexion Socket)
  void initChat(int bookingId) async {
    _isLoading = true;
    _messages.clear();
    // On met à jour l'interface pour afficher le chargement
    Future.microtask(() => notifyListeners());

    // A. On charge l'historique de la BDD via HTTP
    try {
      final url = Uri.parse('${ApiEndpoints.messages}/$bookingId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> data = decoded['data'];
        _messages = data.map((m) => Message.fromJson(m)).toList();
      } else {
        print("⚠️ Erreur API Messages: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Erreur de connexion au serveur pour l'historique: $e");
    } finally {
      // --- CETTE PARTIE EST CRUCIALE ---
      // Le bloc "finally" s'exécute TOUJOURS, même si le backend a planté.
      // Ça garantit que l'écran ne restera jamais bloqué sur un chargement infini !
      _isLoading = false;
      notifyListeners();
    }

    // B. On se connecte au Socket en temps réel (en arrière-plan)
    // B. On se connecte au Socket en temps réel (en arrière-plan)
    try {
      // 1. On déconnecte l'ancien socket s'il existe
      if (_socket != null) {
        _socket!.disconnect();
        _socket!
            .clearListeners(); // 🧹 LA LIGNE MAGIQUE QUI TUE LE BUG DE L'ÉCHO !
      }

      // 2. On crée la nouvelle connexion
      _socket = socket_io.io(
          ApiEndpoints.socketUrl,
          socket_io.OptionBuilder()
              .setTransports(['websocket'])
              .enableAutoConnect()
              .build());

      // 3. On remet NOS oreilles toutes neuves (une seule fois)
      _socket!.onConnect((_) {
        print("🔌 Connecté au serveur Socket !");
        _socket!.emit('join_chat', bookingId);
      });

      _socket!.on('receive_message', (data) {
        final newMessage = Message.fromJson(data);
        _messages.add(newMessage);
        notifyListeners(); // Met à jour l'écran
      });
    } catch (e) {
      print("Erreur d'initialisation du Socket: $e");
    }
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

  Future<void> markMessagesAsRead(int bookingId, int userId) async {
    try {
      final url = Uri.parse('${ApiEndpoints.messages}/read/$bookingId/$userId');
      await http.patch(url); // On dit au backend "C'est bon, j'ai tout lu !"
    } catch (e) {
      print("Erreur markAsRead: $e");
    }
  }
}
