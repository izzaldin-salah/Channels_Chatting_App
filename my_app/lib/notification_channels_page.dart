import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'chat_room_page.dart';
import 'package:my_app/screens/auth_screen.dart';

class NotificationChannelsPage extends StatefulWidget {
  const NotificationChannelsPage({super.key});

  @override
  State<NotificationChannelsPage> createState() => _NotificationChannelsPageState();
}

class _NotificationChannelsPageState extends State<NotificationChannelsPage> {
  // Firebase instances
  final _firestore = FirebaseFirestore.instance;
  final _analytics = FirebaseAnalytics.instance;
  final _messaging = FirebaseMessaging.instance;
  final _auth = FirebaseAuth.instance;
  
  // Controllers
  final _channelController = TextEditingController();
  
  // State variables
  final List<String> _channels = [];
  final Map<String, bool> _subscriptions = {};

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() {
    _checkAuth();
    _loadChannelsAndSubscriptions();
    _setupMessageListener();
  }

  void _setupMessageListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? 'No message body',
        );
      }
    });
  }

  void _checkAuth() {
    if (_auth.currentUser == null) {
      _navigateToAuth();
    }
  }

  void _navigateToAuth() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthPage()),
    );
  }

  Future<void> _loadChannelsAndSubscriptions() async {
    try {
      final userId = _auth.currentUser!.uid;
      final channelsSnapshot = await _firestore.collection('channels').get();

      setState(() {
        _channels
          ..clear()
          ..addAll(channelsSnapshot.docs.map((doc) => doc.id));
      });

      for (var channel in _channels) {
        final subscriptionSnapshot = await _firestore
            .collection('channels')
            .doc(channel)
            .collection('subscriptions')
            .doc(userId)
            .get();

        setState(() {
          _subscriptions[channel] = subscriptionSnapshot.exists;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load channels: $e');
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    _analytics.logEvent(
      name: 'sign_out',
      parameters: {'timestamp': DateTime.now().toIso8601String()},
    );
    _navigateToAuth();
  }

  Future<void> _addChannel(String channel) async {
    if (channel.isEmpty) return;

    try {
      final existingChannel = await _firestore.collection('channels').doc(channel).get();
      if (existingChannel.exists) {
        _showErrorSnackBar('Channel $channel already exists');
        return;
      }

      await _firestore.collection('channels').doc(channel).set({'subscriptions': []});
      setState(() {
        _channels.add(channel);
        _subscriptions[channel] = false;
      });
      _channelController.clear();
    } catch (e) {
      _showErrorSnackBar('Failed to add channel: $e');
    }
  }

  Future<void> _deleteChannel(String channel) async {
    if (!await _confirmDelete(channel)) return;

    try {
      await _performChannelDeletion(channel);
      _updateStateAfterDeletion(channel);
      _showSuccessSnackBar('Channel $channel deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to delete channel: $e');
    }
  }

  Future<bool> _confirmDelete(String channel) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete Channel'),
        content: Text('Are you sure you want to delete the channel "$channel"?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _performChannelDeletion(String channel) async {
    // Delete channel from Firestore
    await _firestore.collection('channels').doc(channel).delete();

    // Delete related messages
    final messagesSnapshot = await _firestore
        .collection('messages')
        .where('channelId', isEqualTo: channel)
        .get();

    for (var doc in messagesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete from Realtime Database
    await FirebaseDatabase.instance.ref('channels/$channel/messages').remove();
  }

  void _updateStateAfterDeletion(String channel) {
    setState(() {
      _channels.remove(channel);
      _subscriptions.remove(channel);
    });
  }

  Future<void> _toggleSubscription(String channel, bool value) async {
    if (value) {
      await _subscribeToChannel(channel);
    } else {
      await _unsubscribeFromChannel(channel);
    }
  }

  Future<void> _subscribeToChannel(String channel) async {
    final token = await _messaging.getToken();
    final userId = _auth.currentUser!.uid;

    if (token == null) {
      _showErrorSnackBar('Failed to get FCM token');
      return;
    }

    try {
      await _firestore
          .collection('channels')
          .doc(channel)
          .collection('subscriptions')
          .doc(userId)
          .set({'token': token});

      await _messaging.subscribeToTopic(channel);
      _analytics.logEvent(
        name: 'channel_subscribe',
        parameters: {'channel': channel, 'userId': userId},
      );

      setState(() => _subscriptions[channel] = true);
      _showSuccessSnackBar('Subscribed to $channel');
    } catch (e) {
      _showErrorSnackBar('Failed to subscribe: $e');
    }
  }

  Future<void> _unsubscribeFromChannel(String channel) async {
    final userId = _auth.currentUser!.uid;

    try {
      await _firestore
          .collection('channels')
          .doc(channel)
          .collection('subscriptions')
          .doc(userId)
          .delete();

      await _messaging.unsubscribeFromTopic(channel);
      _analytics.logEvent(
        name: 'channel_unsubscribe',
        parameters: {'channel': channel, 'userId': userId},
      );

      setState(() => _subscriptions[channel] = false);
      _showSuccessSnackBar('Unsubscribed from $channel');
    } catch (e) {
      _showErrorSnackBar('Failed to unsubscribe: $e');
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidNotificationDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await FlutterLocalNotificationsPlugin().show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  void _showErrorSnackBar(String message) {
    _showSnackBar(message, Colors.red);
  }

  void _showSuccessSnackBar(String message) {
    _showSnackBar(message, Colors.green);
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  void _openChatRoom(String channel) async {
    final userId = _auth.currentUser!.uid;

    try {
      final subscriptionSnapshot = await _firestore
          .collection('channels')
          .doc(channel)
          .collection('subscriptions')
          .doc(userId)
          .get();

      if (subscriptionSnapshot.exists) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatRoomPage(channel: channel)),
        );
      } else {
        _showErrorSnackBar(
          'You must subscribe to this channel to access the chat room.',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to verify subscription status: $e');
    }
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF2C3E50),
      title: const Text(
        'Notification Channels',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: _signOut,
        ),
      ],
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _channelController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add a new channel',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add, color: Colors.blue),
                    onPressed: () => _addChannel(_channelController.text),
                  ),
                ),
                onSubmitted: _addChannel,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _channels.length,
              itemBuilder: (context, index) {
                final channel = _channels[index];
                final isSubscribed = _subscriptions[channel] ?? false;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey[800]!, Colors.grey[900]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    onTap: () => _openChatRoom(channel),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[400],
                      child: Text(
                        channel[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      channel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: isSubscribed,
                          onChanged: (value) => _toggleSubscription(channel, value),
                          activeColor: Colors.blue[400],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () => _deleteChannel(channel),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}




}