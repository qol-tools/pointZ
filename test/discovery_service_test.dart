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

    group('ipv4BroadcastAddress', () {
      test('returns /24 broadcast for 10.44.214.201 (hotspot)', () {
        // Arrange & Act
        final broadcast = discovery.ipv4BroadcastAddress('10.44.214.201');

        // Assert
        expect(broadcast, '10.44.214.255');
      });

      test('returns /24 broadcast for 172.20.10.1 (iOS hotspot)', () {
        // Arrange & Act
        final broadcast = discovery.ipv4BroadcastAddress('172.20.10.1');

        // Assert
        expect(broadcast, '172.20.10.255');
      });

      test('returns /24 broadcast for 192.168.1.100', () {
        // Arrange & Act
        final broadcast = discovery.ipv4BroadcastAddress('192.168.1.100');

        // Assert
        expect(broadcast, '192.168.1.255');
      });

      test('returns /24 broadcast for 192.168.43.1 (Android hotspot)', () {
        // Arrange & Act
        final broadcast = discovery.ipv4BroadcastAddress('192.168.43.1');

        // Assert
        expect(broadcast, '192.168.43.255');
      });

      test('returns null for invalid IP with wrong octet count', () {
        // Arrange & Act
        final broadcast = discovery.ipv4BroadcastAddress('192.168.1');

        // Assert
        expect(broadcast, null);
      });

      test('returns null for invalid IP with non-numeric octets', () {
        // Arrange & Act
        final broadcast = discovery.ipv4BroadcastAddress('192.168.1.abc');

        // Assert
        expect(broadcast, null);
      });

      test('returns null for empty string', () {
        // Arrange & Act
        final broadcast = discovery.ipv4BroadcastAddress('');

        // Assert
        expect(broadcast, null);
      });

      test('returns null for IPv6 address', () {
        // Arrange & Act
        final broadcast = discovery.ipv4BroadcastAddress('::1');

        // Assert
        expect(broadcast, null);
      });
    });
  });
}
