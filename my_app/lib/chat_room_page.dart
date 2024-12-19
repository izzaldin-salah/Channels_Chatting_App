import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';



class ChatRoomPage extends StatefulWidget {
  final String channel;

  const ChatRoomPage({required this.channel, super.key});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  late final DatabaseReference _messagesRef;
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _messagesRef = FirebaseDatabase.instance.ref('channels/${widget.channel}/messages');

    // Log chat room entry event
    FirebaseAnalytics.instance.logEvent(
      name: 'enter_chat_room',
      parameters: {'channel': widget.channel},
    );
  }


  Future<void> _sendPushNotification(List<String> tokens, {required String title, required String body}) async {
    const String serverKey = 'BEXwx5qmx-4NMnVAqi1jJTudUvcgTRIpjT0-dSju1tTh5Yb7x8uQ6hac37asVHb2qbbDs75h3rwNPHNHiga08BI'; 

    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'registration_ids': tokens,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'channelId': widget.channel,
          },
        }),
      );

      if (response.statusCode == 200) {
        log('Push notification sent successfully');
      } else {
        log('Failed to send push notification: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('Error sending push notification: $e');
    }
  }

  void _sendMessage(String message) async {
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message cannot be empty')),
      );
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      String? senderToken = await FirebaseMessaging.instance.getToken();
      if (senderToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to retrieve sender token')),
        );
        return;
      }

      // Extract sender info (phone number or email)
      final String senderInfo = user.phoneNumber ?? user.email ?? 'Anonymous';

      final messageData = {
        'message': message,
        'channelId': widget.channel,
        'timestamp': DateTime.now().toIso8601String(),
        'senderId': user.uid, // Store the userId instead of token
        'senderInfo': senderInfo, // Use "phone number", "email", or "Anonymous"
      };

      await FirebaseFirestore.instance.collection('messages').add(messageData);
      await _messagesRef.push().set(messageData);

      FirebaseAnalytics.instance.logEvent(
        name: 'message_sent',
        parameters: {
          'channel': widget.channel,
          'sender': senderInfo,
          'message_length': message.length,
        },
      );

      // Get tokens of all subscribers for this channel
      final subscriptionsSnapshot = await FirebaseFirestore.instance
          .collection('channels')
          .doc(widget.channel)
          .collection('subscriptions')
          .get();

      List<String> tokensToNotify = [];
      for (var doc in subscriptionsSnapshot.docs) {
        final data = doc.data();
        final token = data['token'];
        final userId = doc.id;

        // Exclude the sender's token
        if (userId != user.uid && token != null && token != senderToken) {
          tokensToNotify.add(token);
        }
      }

      if (tokensToNotify.isNotEmpty) {
        await _sendPushNotification(
          tokensToNotify,
          title: 'New message in ${widget.channel}',
          body: message,
        );
        log(message);
      }

      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
      print('Error sending message: $e');
    }
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2C3E50),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue[200],
                child: Text(
                  widget.channel[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.channel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Active now',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2C3E50),
              Colors.grey[900]!,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _messagesRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final messages = snapshot.data!.snapshot.children.toList();
                    messages.sort((a, b) {
                      return a
                          .child('timestamp')
                          .value
                          .toString()
                          .compareTo(b.child('timestamp').value.toString());
                    });
                    String formatMessageTime(String timestamp) {
                      final DateTime messageTime = DateTime.parse(timestamp);
                      
                      // Convert to 12-hour format
                      int hour = messageTime.hour;
                      String period = 'AM';
                      
                      if (hour >= 12) {
                        period = 'PM';
                        if (hour > 12) {
                          hour -= 12;
                        }
                      }
                      if (hour == 0) {
                        hour = 12;
                      }
                      
                      // Format minutes with leading zero if needed
                      String minute = messageTime.minute.toString().padLeft(2, '0');
                      
                      return '$hour:$minute $period';
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final text = msg.child('message').value.toString();
                        final senderInfo = msg.child('senderInfo').value.toString();
                        final senderId = msg.child('senderId').value.toString();
                        final isMe = senderId == _auth.currentUser?.uid;
                        final formattedTime = formatMessageTime(msg.child('timestamp').value.toString());

                        return ChatBubble(
                          message: text,
                          senderInfo: senderInfo,
                          isMe: isMe,
                          timestamp: formattedTime,
                        );
                      },
                    );
                  }
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
              color: const Color(0xFF2C3E50),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[700]!],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send),
                      color: Colors.white,
                      onPressed: () => _sendMessage(_messageController.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final String senderInfo;
  final bool isMe;
  final String timestamp;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.senderInfo,
    required this.isMe,
    required this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(
                senderInfo,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ),
          Container(
            margin: EdgeInsets.only(
              left: isMe ? 50 : 16,
              right: isMe ? 16 : 50,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isMe
                    ? [Colors.blue[400]!, Colors.blue[700]!]
                    : [Colors.grey[800]!, Colors.grey[900]!],
              ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timestamp,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}