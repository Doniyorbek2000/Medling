import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel? openLiveSocket(Uri uri, String token) =>
    IOWebSocketChannel.connect(
      uri,
      headers: {'authorization': 'Bearer $token'},
      pingInterval: const Duration(seconds: 25),
      connectTimeout: const Duration(seconds: 10),
    );
