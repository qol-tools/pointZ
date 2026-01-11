import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;

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
  static const String globalBroadcast = '255.255.255.255';

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

  Future<void> discover() async {
    final data = utf8.encode(discoverMessage);

    _socket.send(data, InternetAddress(globalBroadcast), discoveryPort);

    await _discoverOnAllInterfaces(data);
  }


  Future<void> _discoverOnAllInterfaces(List<int> data) async {
    final interfaces = await NetworkInterface.list().catchError((_) => <NetworkInterface>[]);
    final subnetBroadcasts = interfaces
        .expand((interface) => interface.addresses)
        .where((address) => address.type == InternetAddressType.IPv4)
        .map((address) => ipv4BroadcastAddress(address.address))
        .whereType<String>()
        .where((broadcastAddress) => broadcastAddress != globalBroadcast)
        .toSet();

    for (final broadcastAddress in subnetBroadcasts) {
      _socket.send(data, InternetAddress(broadcastAddress), discoveryPort);
    }
  }

  @visibleForTesting
  String? ipv4BroadcastAddress(String ipAddress) {
    final octets = ipAddress.split('.').map(int.tryParse).toList();
    if (octets.length != 4 || octets.any((octet) => octet == null)) return null;

    return '${octets[0]}.${octets[1]}.${octets[2]}.255';
  }

  void dispose() {
    _socket.close();
    _serverController.close();
  }
}
