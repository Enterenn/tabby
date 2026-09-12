import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// OCR d'une capture (Wallet, appli enseigne) pour retrouver le nom visible.
abstract final class LoyaltyScreenshotText {
  static Future<String> read(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      return result.text.trim();
    } catch (_) {
      return '';
    } finally {
      await recognizer.close();
    }
  }
}
