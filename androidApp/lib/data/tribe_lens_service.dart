import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Identifies a tribe (Adi, Singpho or Khamti) from a photo of traditional
/// attire with TribeLens (https://tribelens-pmv7.vercel.app).
///
/// How TribeLens works: the page reads `#img=<base64>` from its own URL in
/// the browser, runs a TensorFlow.js model on the photo (no backend API;
/// the fragment never leaves the device) and then replaces the page with a
/// single `<pre id="tribe">` holding the plain-text label (`Adi`,
/// `Singpho` or `Khamti`), also set as `document.title`. On failure the
/// text starts with `Error:`. So the app loads that URL in a tiny WebView
/// and reads the text back.
class TribeLensService {
  TribeLensService({TribeLensClient Function()? clientFactory})
    : _clientFactory = clientFactory ?? WebViewTribeLensClient.new;

  final TribeLensClient Function() _clientFactory;

  static const baseUrl = 'https://tribelens-pmv7.vercel.app/';

  /// Upper limit for the photo sent to TribeLens: 1.5 MB (1,500,000 bytes,
  /// a little under 1.5 MiB). Its base64 form (~2,000,000 chars) then stays
  /// under the ~2 MB (2,097,152 chars) URL limit of Chromium / WebView.
  static const maxImageBytes = 1500000;

  /// How long to wait for the page to answer.
  static const timeout = Duration(seconds: 30);

  /// Tribe names (as in `MockData.tribes`) for each TribeLens answer.
  static const _aliases = {
    'singpho': 'Singpho',
    'adi': 'Adi',
    'khampti': 'Khamti',
    'khamti': 'Khamti',
  };

  /// Creates the client that talks to the page. The caller should keep its
  /// [TribeLensClient.buildHost] widget on screen while [identify] runs.
  TribeLensClient createClient() => _clientFactory();

  /// Compresses [photo], sends it to TribeLens through [client] and returns
  /// the tribe name (`Adi`, `Singpho` or `Khamti`), or null when the photo
  /// was not recognised, the page timed out or there is no internet.
  Future<String?> identify(TribeLensClient client, Uint8List photo) async {
    try {
      final small = await compressPhoto(photo);
      final raw = await client.fetchResult(urlFor(base64Encode(small)));
      final tribe = parseTribe(raw);
      if (tribe == null) debugPrint('TribeLens: unrecognised answer "$raw"');
      return tribe;
    } catch (e) {
      debugPrint('TribeLens failed: $e');
      return null;
    }
  }

  /// TribeLens URL with the base64 photo after `#img=`, as the page expects.
  /// Plain base64 is used as is: the page turns any `+` that became a space
  /// back into `+`, and `/` and `=` are fine in a URL fragment.
  static String urlFor(String base64Photo) => '$baseUrl#img=$base64Photo';

  /// Maps the page's plain-text answer to a tribe name in the app, or null.
  /// Case-insensitive and trimmed; accepts `khampti` and `khamti`.
  static String? parseTribe(String? raw) {
    if (raw == null) return null;
    return _aliases[raw.trim().toLowerCase()];
  }

  /// Unwraps a value from `runJavaScriptReturningResult`: Android returns
  /// strings JSON-encoded (`"Adi"`), iOS returns them as is.
  static String unwrapJsString(Object? value) {
    if (value == null) return '';
    final s = value.toString().trim();
    if (s == 'null') return '';
    if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
      try {
        return (jsonDecode(s) as String).trim();
      } catch (_) {
        return s.substring(1, s.length - 1).trim();
      }
    }
    return s;
  }

  /// Returns a JPEG of [bytes] under [maxBytes]. A JPEG that is already
  /// small enough is returned as is. Otherwise it is re-encoded with
  /// [encoder] (native JPEG compression by default), first lowering the
  /// quality, then scaling it down (short side [maxSide], then 25% smaller
  /// each round) until it fits.
  static Future<Uint8List> compressPhoto(
    Uint8List bytes, {
    int maxBytes = maxImageBytes,
    int maxSide = 1280,
    JpegEncoder encoder = nativeJpegEncoder,
  }) async {
    final isJpeg = bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;
    if (isJpeg && bytes.length < maxBytes) return bytes;
    var side = maxSide;
    while (true) {
      for (final quality in const [85, 75, 65, 55]) {
        final out = await encoder(bytes, side: side, quality: quality);
        if (out.isEmpty) throw const FormatException('Could not encode photo');
        if (out.length < maxBytes) return out;
      }
      if (side <= 160) {
        return encoder(bytes, side: side, quality: 40);
      }
      side = (side * 0.75).round();
    }
  }

  /// [JpegEncoder] using the platform's JPEG encoder (Android Bitmap /
  /// iOS UIImage): scales the photo so its short side is at most [side]
  /// and applies the EXIF rotation.
  static Future<Uint8List> nativeJpegEncoder(
    Uint8List bytes, {
    required int side,
    required int quality,
  }) => FlutterImageCompress.compressWithList(
    bytes,
    minWidth: side,
    minHeight: side,
    quality: quality,
    format: CompressFormat.jpeg,
  );
}

/// Re-encodes a photo as JPEG at [quality] (0–100), scaled down so its
/// short side is at most [side] pixels.
typedef JpegEncoder =
    Future<Uint8List> Function(
      Uint8List bytes, {
      required int side,
      required int quality,
    });

/// Loads a TribeLens URL and returns the plain text the page shows.
abstract class TribeLensClient {
  /// Loads [url] and waits for the answer text (or throws on timeout or a
  /// network error).
  Future<String> fetchResult(String url);

  /// Widget that must stay mounted while [fetchResult] runs (the WebView
  /// needs a window to run its scripts reliably).
  Widget buildHost();
}

/// [TribeLensClient] that runs the page in a 1×1 WebView and polls the DOM.
class WebViewTribeLensClient implements TribeLensClient {
  WebViewTribeLensClient() : _controller = WebViewController();

  final WebViewController _controller;

  static const _readAnswer =
      "(function(){var e=document.getElementById('tribe');"
      "return e?e.textContent:'';})()";

  @override
  Future<String> fetchResult(String url) async {
    String? loadError;
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.setNavigationDelegate(
      NavigationDelegate(
        onWebResourceError: (e) {
          if (e.isForMainFrame ?? true) loadError = e.description;
        },
        onHttpError: (e) {
          if (e.request?.uri.path == '/') {
            loadError = 'HTTP ${e.response?.statusCode}';
          }
        },
      ),
    );
    await _controller.loadRequest(Uri.parse(url));
    final deadline = DateTime.now().add(TribeLensService.timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (loadError != null) throw Exception('Page failed: $loadError');
      try {
        final text = TribeLensService.unwrapJsString(
          await _controller.runJavaScriptReturningResult(_readAnswer),
        );
        if (text.isNotEmpty) return text;
      } catch (_) {
        // The page is still loading; try again.
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    throw TimeoutException('TribeLens did not answer', TribeLensService.timeout);
  }

  @override
  Widget buildHost() => SizedBox(
    width: 1,
    height: 1,
    child: WebViewWidget(controller: _controller),
  );
}
