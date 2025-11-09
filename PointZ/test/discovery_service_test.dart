import 'package:flutter_test/flutter_test.dart';
import 'package:pointz/services/discovery_service.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  group('DiscoveredServer', () {
    test('equality is based on address only', () {
      // Arrange
      final server1 = DiscoveredServer(
        address: InternetAddress('192.168.1.1'),
        hostname: 'host1',
      );
      final server2 = DiscoveredServer(
        address: InternetAddress('192.168.1.1'),
        hostname: 'host2',
      );
      final server3 = DiscoveredServer(
        address: InternetAddress('192.168.1.2'),
        hostname: 'host1',
      );

      // Act
      final equals1and2 = server1 == server2;
      final equals1and3 = server1 == server3;
      final hashEquals = server1.hashCode == server2.hashCode;

      // Assert
      expect(equals1and2, true);
      expect(equals1and3, false);
      expect(hashEquals, true);
    });
  });

  group('ServerDiscovery', () {
    late ServerDiscovery discovery;

    setUp(() async {
      discovery = await ServerDiscovery.start();
    });

    tearDown(() {
      discovery.dispose();
    });

    test('parseJsonHostname extracts hostname from valid JSON', () {
      // Arrange
      final json = jsonEncode({'hostname': 'test-host'});

      // Act
      final hostname = discovery.parseJsonHostname(json);

      // Assert
      expect(hostname, 'test-host');
    });

    test('parseJsonHostname returns unknown for missing hostname', () {
      // Arrange
      final json = jsonEncode({});

      // Act
      final hostname = discovery.parseJsonHostname(json);

      // Assert
      expect(hostname, ServerDiscovery.unknownHostname);
    });

    test('parseJsonHostname returns null for invalid JSON', () {
      // Arrange
      const invalidJson = 'invalid json';

      // Act
      final hostname = discovery.parseJsonHostname(invalidJson);

      // Assert
      expect(hostname, null);
    });

    test('parseLegacyHostname returns address for legacy response', () {
      // Arrange
      final address = InternetAddress('192.168.1.1');
      const legacyMessage = ServerDiscovery.legacyResponse;

      // Act
      final hostname = discovery.parseLegacyHostname(legacyMessage, address);

      // Assert
      expect(hostname, '192.168.1.1');
    });

    test('parseLegacyHostname returns null for non-legacy response', () {
      // Arrange
      final address = InternetAddress('192.168.1.1');
      const nonLegacyMessage = 'OTHER_MESSAGE';

      // Act
      final hostname = discovery.parseLegacyHostname(nonLegacyMessage, address);

      // Assert
      expect(hostname, null);
    });

    test('parseLegacyHostname handles whitespace', () {
      // Arrange
      final address = InternetAddress('192.168.1.1');
      const messageWithWhitespace = '  ${ServerDiscovery.legacyResponse}  ';

      // Act
      final hostname =
          discovery.parseLegacyHostname(messageWithWhitespace, address);

      // Assert
      expect(hostname, '192.168.1.1');
    });

    test('extractHostname prefers JSON over legacy format', () {
      // Arrange
      final address = InternetAddress('192.168.1.1');
      final jsonData = utf8.encode(jsonEncode({'hostname': 'json-host'}));
      final datagram = Datagram(jsonData, address, 0);

      // Act
      final hostname = discovery.extractHostname(datagram);

      // Assert
      expect(hostname, 'json-host');
    });

    test('extractHostname falls back to legacy format', () {
      // Arrange
      final address = InternetAddress('192.168.1.1');
      final legacyData = utf8.encode(ServerDiscovery.legacyResponse);
      final datagram = Datagram(legacyData, address, 0);

      // Act
      final hostname = discovery.extractHostname(datagram);

      // Assert
      expect(hostname, '192.168.1.1');
    });

    test('extractHostname returns null for unknown format', () {
      // Arrange
      final address = InternetAddress('192.168.1.1');
      final unknownData = utf8.encode('UNKNOWN_FORMAT');
      final datagram = Datagram(unknownData, address, 0);

      // Act
      final hostname = discovery.extractHostname(datagram);

      // Assert
      expect(hostname, null);
    });
  });
}
