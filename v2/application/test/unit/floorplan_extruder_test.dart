import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_vision/data/services/floorplan_3d_extruder.dart';

void main() {
  group('Floorplan3dExtruder Unit Tests', () {
    test('fromRelativeRects correctly computes metric dimensions and offsets', () {
      final roomDefs = [
        {
          'name': 'Living Room',
          'areaSqFt': 250,
          'left': 0.1,
          'top': 0.1,
          'width': 0.5,
          'length': 0.4,
        },
        {
          'name': 'Bed Room',
          'areaSqFt': 180,
          'left': 0.6,
          'top': 0.1,
          'width': 0.35,
          'length': 0.4,
        },
      ];

      final rooms = Floorplan3dExtruder.fromRelativeRects(
        roomDefs: roomDefs,
        totalWidthMeters: 10.0,
        totalLengthMeters: 8.0,
      );

      expect(rooms.length, equals(2));
      expect(rooms[0].name, equals('Living Room'));
      expect(rooms[0].x, closeTo(1.0, 0.001));
      expect(rooms[0].y, closeTo(0.8, 0.001));
      expect(rooms[0].width, closeTo(5.0, 0.001));
      expect(rooms[0].length, closeTo(3.2, 0.001));
    });

    test('generateGlb produces valid glTF 2.0 Binary Header and Chunks', () {
      const rooms = [
        DetectedRoom(name: 'Main Hall', x: 0, y: 0, width: 6.0, length: 5.0, areaSqFt: 320),
        DetectedRoom(name: 'Kitchen', x: 6.2, y: 0, width: 3.5, length: 3.5, areaSqFt: 130),
      ];

      final glbBytes = Floorplan3dExtruder.generateGlb(
        rooms: rooms,
        wallHeight: 3.2,
        wallMaterial: 'Scandinavian Timber',
      );

      expect(glbBytes, isNotNull);
      expect(glbBytes.length, greaterThan(100));

      // 1. Magic 'glTF'
      expect(glbBytes[0], equals(0x67)); // 'g'
      expect(glbBytes[1], equals(0x6C)); // 'l'
      expect(glbBytes[2], equals(0x54)); // 'T'
      expect(glbBytes[3], equals(0x46)); // 'F'

      // 2. Version 2
      final byteData = glbBytes.buffer.asByteData();
      final version = byteData.getUint32(4, Endian.little);
      expect(version, equals(2));

      // 3. Length matches total buffer length
      final fileLength = byteData.getUint32(8, Endian.little);
      expect(fileLength, equals(glbBytes.length));

      // 4. JSON Chunk
      final jsonChunkLen = byteData.getUint32(12, Endian.little);
      final jsonChunkType = byteData.getUint32(16, Endian.little);
      expect(jsonChunkType, equals(0x4E4F534A)); // 'JSON'

      // Extract JSON and verify fields
      final jsonBytes = glbBytes.sublist(20, 20 + jsonChunkLen);
      final jsonString = utf8.decode(jsonBytes).trim();
      final gltf = json.decode(jsonString) as Map<String, dynamic>;

      expect(gltf['asset']['version'], equals('2.0'));
      expect(gltf['meshes'], isNotEmpty);
      expect(gltf['materials'], isNotEmpty);
      expect(gltf['bufferViews'].length, equals(4));

      // 5. Binary Chunk
      final binChunkOffset = 20 + jsonChunkLen;
      final binChunkType = byteData.getUint32(binChunkOffset + 4, Endian.little);
      expect(binChunkType, equals(0x004E4942)); // 'BIN\0'
    });

    test('generateGlb supports different wall finishes and parametric heights', () {
      const rooms = [
        DetectedRoom(name: 'Room A', x: 0, y: 0, width: 4.0, length: 4.0, areaSqFt: 170),
      ];

      for (final material in ['Exposed Red Brick', 'Cast Concrete', 'Architectural Stucco']) {
        final glb = Floorplan3dExtruder.generateGlb(
          rooms: rooms,
          wallHeight: 3.5,
          wallMaterial: material,
        );
        expect(glb.length, greaterThan(500));
      }
    });
  });
}
