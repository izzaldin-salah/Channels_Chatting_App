// // lib/pages/notification_channels_page.dart

// import 'package:flutter/material.dart';
// import 'package:my_app/notification_channels_page.dart';
// import 'auth_screen.dart';

// class NotificationChannelsPage extends StatefulWidget {
//   const NotificationChannelsPage({super.key});

//   @override
//   State<NotificationChannelsPage> createState() => _NotificationChannelsPageState();
// }

// class _NotificationChannelsPageState extends State<NotificationChannelsPage> {
//   final _controller = NotificationChannelController();
//   final _channelController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _setupController();
//     _controller.initializeApp();
//   }

//   void _setupController() {
//     _controller.onShowSnackBar = _showSnackBar;
//     _controller.onNavigateToAuth = _navigateToAuth;
//     _controller.onStateChanged = () {
//       setState(() {});
//     };
//   }

//   void _navigateToAuth() {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => const AuthPage()),
//     );
//   }

//   void _showSnackBar(String message, Color backgroundColor) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: backgroundColor,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: _buildAppBar(),
//       body: _buildBody(),
//     );
//   }

//   AppBar _buildAppBar() {
//     return AppBar(
//       elevation: 0,
//       backgroundColor: const Color(0xFF2C3E50),
//       title: const Text(
//         'Notification Channels',
//         style: TextStyle(
//           fontSize: 20,
//           fontWeight: FontWeight.w600,
//           color: Colors.white,
//         ),
//       ),
//       actions: [
//         IconButton(
//           icon: const Icon(Icons.logout, color: Colors.white),
//           onPressed: _controller.signOut,
//         ),
//       ],
//     );
//   }

//   Widget _buildBody() {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             const Color(0xFF2C3E50),
//             Colors.grey[900]!,
//           ],
//         ),
//       ),
//       child: Column(
//         children: [
//           _buildChannelInput(),
//           _buildChannelsList(),
//         ],
//       ),
//     );
//   }

//   Widget _buildChannelInput() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.grey[800],
//           borderRadius: BorderRadius.circular(25),
//         ),
//         child: TextField(
//           controller: _channelController,
//           style: const TextStyle(color: Colors.white),
//           decoration: InputDecoration(
//             hintText: 'Add a new channel',
//             hintStyle: TextStyle(color: Colors.grey[400]),
//             border: InputBorder.none,
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 20,
//               vertical: 15,
//             ),
//             suffixIcon: IconButton(
//               icon: const Icon(Icons.add, color: Colors.blue),
//               onPressed: () {
//                 _controller.addChannel(_channelController.text);
//                 _channelController.clear();
//               },
//             ),
//           ),
//           onSubmitted: (value) {
//             _controller.addChannel(value);
//             _channelController.clear();
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildChannelsList() {
//     return Expanded(
//       child: ListView.builder(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         itemCount: _controller.channels.length,
//         itemBuilder: (context, index) {
//           return _buildChannelItem(index);
//         },
//       ),
//     );
//   }

//   Widget _buildChannelItem(int index) {
//     final channel = _controller.channels[index];
//     final isSubscribed = _controller.subscriptions[channel] ?? false;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.grey[800]!, Colors.grey[900]!],
//         ),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: ListTile(
//         onTap: () => _controller.openChatRoom(channel, context),
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 8,
//         ),
//         leading: _buildChannelAvatar(channel),
//         title: Text(
//           channel,
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.w500,
//             fontSize: 16,
//           ),
//         ),
//         trailing: _buildChannelActions(channel, isSubscribed),
//       ),
//     );
//   }

//   Widget _buildChannelAvatar(String channel) {
//     return CircleAvatar(
//       backgroundColor: Colors.blue[400],
//       child: Text(
//         channel[0].toUpperCase(),
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   Widget _buildChannelActions(String channel, bool isSubscribed) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Switch(
//           value: isSubscribed,
//           onChanged: (value) => _controller.toggleSubscription(channel, value),
//           activeColor: Colors.blue[400],
//         ),
//         IconButton(
//           icon: const Icon(
//             Icons.delete,
//             color: Colors.red,
//           ),
//           onPressed: () => _controller.deleteChannel(channel),
//         ),
//       ],
//     );
//   }

//   @override
//   void dispose() {
//     _channelController.dispose();
//     super.dispose();
//   }
// }