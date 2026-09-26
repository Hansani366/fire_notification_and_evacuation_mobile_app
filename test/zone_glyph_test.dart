import 'package:firewatch/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the tile draws for a glyph this build has never heard of.
///
/// `zones_seed.py` on the backend owns the glyph names and this app owns the
/// drawings, so the two can drift: a zone added there with a new glyph reaches a
/// phone that does not know it. Everything unrecognised used to become a fabric
/// roll, silently, which put a bolt of cloth in a bedroom and reported nothing.
void main() {
  group('ZoneGlyph.fromWire', () {
    test('a glyph this build knows round-trips', () {
      for (final g in ZoneGlyph.values) {
        expect(ZoneGlyph.fromWire(g.wire), g, reason: g.name);
      }
    });

    test('an unrecognised name becomes unknown, not a fabric roll', () {
      expect(ZoneGlyph.fromWire('garage'), ZoneGlyph.unknown);
      expect(ZoneGlyph.fromWire('FabricRoll'), ZoneGlyph.unknown);
    });

    test('a missing glyph becomes unknown too', () {
      expect(ZoneGlyph.fromWire(null), ZoneGlyph.unknown);
      expect(ZoneGlyph.fromWire(''), ZoneGlyph.unknown);
    });
  });
}
