import 'dart:convert';
import 'dart:typed_data';

import 'package:explore_arunachal/data/mock_data.dart';
import 'package:explore_arunachal/data/tribe_lens_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

class _FakeClient implements TribeLensClient {
  _FakeClient(this.answer);
  final Future<String> Function(String url) answer;
  String? url;

  @override
  Future<String> fetchResult(String url) {
    this.url = url;
    return answer(url);
  }

  @override
  Widget buildHost() => const SizedBox.shrink();
}

void main() {
  group('TribeLensService.parseTribe', () {
    test('maps the three answers to app tribe names', () {
      expect(TribeLensService.parseTribe('singpho'), 'Singpho');
      expect(TribeLensService.parseTribe('Adi'), 'Adi');
      expect(TribeLensService.parseTribe('KHAMPTI'), 'Khamti');
      expect(TribeLensService.parseTribe('khamti'), 'Khamti');
      expect(TribeLensService.parseTribe('Khamti'), 'Khamti');
    });

    test('trims whitespace and newlines', () {
      expect(TribeLensService.parseTribe('  Singpho \n'), 'Singpho');
      expect(TribeLensService.parseTribe('\tadi\r\n'), 'Adi');
    });

    test('returns null for unknown or error answers', () {
      expect(TribeLensService.parseTribe(null), isNull);
      expect(TribeLensService.parseTribe(''), isNull);
      expect(TribeLensService.parseTribe('Monpa'), isNull);
      expect(TribeLensService.parseTribe('Error: invalid image data'), isNull);
      expect(TribeLensService.parseTribe('adi tribe'), isNull);
    });

    test('every answer is a tribe in MockData', () {
      final names = MockData.tribes.map((t) => t.name).toSet();
      for (final a in ['singpho', 'adi', 'khampti', 'khamti']) {
        expect(names, contains(TribeLensService.parseTribe(a)));
      }
    });
  });

  test('unwrapJsString handles Android JSON strings and iOS raw strings', () {
    expect(TribeLensService.unwrapJsString('"Adi"'), 'Adi');
    expect(TribeLensService.unwrapJsString('Singpho'), 'Singpho');
    expect(TribeLensService.unwrapJsString('""'), '');
    expect(TribeLensService.unwrapJsString(null), '');
    expect(TribeLensService.unwrapJsString('null'), '');
  });

  test('urlFor puts the base64 after #img=', () {
    expect(
      TribeLensService.urlFor('/9j/4A+B=='),
      'https://tribelens-pmv7.vercel.app/#img=/9j/4A+B==',
    );
  });

  group('compressPhoto', () {
    // Stand-in for the native encoder in unit tests (same contract: JPEG,
    // short side at most [side]), using package:image.
    final calls = <(int, int)>[];
    Future<Uint8List> dartEncoder(
      Uint8List bytes, {
      required int side,
      required int quality,
    }) async {
      calls.add((side, quality));
      var im = img.decodeImage(bytes);
      if (im == null) return Uint8List(0);
      final short = im.width < im.height ? im.width : im.height;
      if (short > side) {
        im = im.width < im.height
            ? img.copyResize(im, width: side)
            : img.copyResize(im, height: side);
      }
      return img.encodeJpg(im, quality: quality);
    }

    img.Image noise(int w, int h, int seed) {
      final src = img.Image(width: w, height: h);
      for (final p in src) {
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        p
          ..r = seed & 0xff
          ..g = (seed >> 8) & 0xff
          ..b = (seed >> 16) & 0xff;
      }
      return src;
    }

    setUp(calls.clear);

    test('a large photo comes out as a JPEG under 1.5 MB', () async {
      // Noisy 3000×2250 image: ~20 MB as PNG, hard to compress.
      final png = img.encodePng(noise(3000, 2250, 7), level: 1);
      expect(png.length, greaterThan(TribeLensService.maxImageBytes));
      final out = await TribeLensService.compressPhoto(
        png,
        encoder: dartEncoder,
      );
      expect(out.length, lessThan(TribeLensService.maxImageBytes));
      expect(out.length, lessThan(1.5 * 1024 * 1024));
      expect(out[0], 0xFF);
      expect(out[1], 0xD8);
      // Quality is lowered before the size is.
      expect(calls.first, (1280, 85));
      // Base64 of the result fits a WebView URL (< 2,097,152 chars).
      final url = TribeLensService.urlFor(base64Encode(out));
      expect(url.length, lessThan(2097152));
    });

    test('a big JPEG over the limit is squeezed too', () async {
      final jpg = img.encodeJpg(noise(2000, 2000, 3), quality: 95);
      final out = await TribeLensService.compressPhoto(
        jpg,
        maxBytes: 100000,
        encoder: dartEncoder,
      );
      expect(out.length, lessThan(100000));
      expect(calls.last.$1, lessThan(1280));
    });

    test('a small JPEG is sent unchanged', () async {
      final jpg = img.encodeJpg(img.Image(width: 64, height: 64));
      final out = await TribeLensService.compressPhoto(
        jpg,
        encoder: dartEncoder,
      );
      expect(identical(out, jpg), isTrue);
      expect(calls, isEmpty);
    });

    test('rejects data that cannot be encoded', () {
      expect(
        TribeLensService.compressPhoto(
          Uint8List.fromList(utf8.encode('not an image')),
          encoder: dartEncoder,
        ),
        throwsFormatException,
      );
    });
  });

  group('identify', () {
    final photo = img.encodeJpg(img.Image(width: 32, height: 32));

    test('sends base64 in the URL and returns the tribe', () async {
      final client = _FakeClient((_) async => ' KHAMPTI\n');
      final tribe = await TribeLensService().identify(client, photo);
      expect(tribe, 'Khamti');
      expect(
        client.url,
        'https://tribelens-pmv7.vercel.app/#img=${base64Encode(photo)}',
      );
    });

    test('returns null on unknown answers and errors', () async {
      final service = TribeLensService();
      expect(
        await service.identify(_FakeClient((_) async => 'Error: x'), photo),
        isNull,
      );
      expect(
        await service.identify(
          _FakeClient((_) => Future.error(Exception('offline'))),
          photo,
        ),
        isNull,
      );
    });
  });
}
