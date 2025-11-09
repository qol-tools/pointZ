import 'dart:async';
import 'dart:io';
import 'dart:convert';

class DiscoveredServer {
  final InternetAddress address;
  final String hostname;

  const DiscoveredServer({
    required this.address,
    required this.hostname,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredServer &&
          runtimeType == other.runtimeType &&
          address == other.address;

  @override
  int get hashCode => address.hashCode;
}

class ServerDiscovery {
  static const int discoveryPort = 45454;
  static const String discoverMessage = 'DISCOVER';
  static const String legacyResponse = 'POINTZ_SERVER';
  static const String hostnameKey = 'hostname';
  static const String unknownHostname = 'Unknown';
  static const String broadcastAddress = '255.255.255.255';

  final RawDatagramSocket _socket;
  final StreamController<DiscoveredServer> _serverController =
      StreamController<DiscoveredServer>.broadcast();

  ServerDiscovery._(this._socket) {
    _socket.listen(_handleSocketEvent);
  }

  void _handleSocketEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;

    final datagram = _socket.receive();
    if (datagram == null) return;

    _parseAndEmitServer(datagram);
  }

  void _parseAndEmitServer(Datagram datagram) {
    final hostname = extractHostname(datagram);
    if (hostname == null) return;

    _serverController.add(DiscoveredServer(
      address: datagram.address,
      hostname: hostname,
    ));
  }

  String? extractHostname(Datagram datagram) {
    final message = utf8.decode(datagram.data);

    return parseJsonHostname(message) ??
        parseLegacyHostname(message, datagram.address);
  }

  String? parseJsonHostname(String message) {
    try {
      final json = jsonDecode(message) as Map<String, dynamic>;
      return json[hostnameKey] as String? ?? unknownHostname;
    } catch (_) {
      return null;
    }
  }

  String? parseLegacyHostname(String message, InternetAddress address) {
    if (message.trim() != legacyResponse) {
      return null;
    }
    return address.address;
  }

  static Future<ServerDiscovery> start() async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;
    return ServerDiscovery._(socket);
  }

  Stream<DiscoveredServer> get discoveredServers => _serverController.stream;

  void discover() {
    final data = utf8.encode(discoverMessage);
    _socket.send(data, InternetAddress(broadcastAddress), discoveryPort);
  }

  void dispose() {
    _socket.close();
    _serverController.close();
  }
}
