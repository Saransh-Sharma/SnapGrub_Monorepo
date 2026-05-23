import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

Future<String> recognizeLabelText(String imagePath) async {
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final recognized =
        await recognizer.processImage(InputImage.fromFilePath(imagePath));
    return recognized.text;
  } finally {
    await recognizer.close();
  }
}
