import 'dart:async';
import 'dart:io';
import 'dart:convert';

class ServerDiscovery {
  static const int discoveryPort = 45454;
  static const String discoverMessage = 'DISCOVER';
  static const String serverResponse = 'POINTZ_SERVER';
  
  final RawDatagramSocket _socket;
  final StreamController<InternetAddress> _serverController = StreamController<InternetAddress>.broadcast();
  
  ServerDiscovery._(this._socket) {
    _socket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket.receive();
        if (datagram != null) {
          final message = utf8.decode(datagram.data);
          if (message.trim() == serverResponse) {
            _serverController.add(datagram.address);
          }
        }
      }
    });
  }
  
  static Future<ServerDiscovery> start() async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;
    return ServerDiscovery._(socket);
  }
  
  Stream<InternetAddress> get discoveredServers => _serverController.stream;
  
  void discover() {
    final data = utf8.encode(discoverMessage);
    _socket.send(data, InternetAddress('255.255.255.255'), discoveryPort);
  }
  
  void dispose() {
    _socket.close();
    _serverController.close();
  }
}

