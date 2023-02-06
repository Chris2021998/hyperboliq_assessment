import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hyperboliq_assessment/utils/image_handler.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart' as imgPicker;
import 'package:logger/logger.dart';

final logger = Logger();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isProcessing = false;
  Uint8List? uploadedImage;

  _pickImage() async {
    try {
      // Upload Image
      final image = await imgPicker.ImagePicker().pickImage(source: imgPicker.ImageSource.gallery);
      final imageAsBytes = await image!.readAsBytes();
      setState(() {
        uploadedImage = imageAsBytes;
      });
    } catch (e) {
      logger.e(e.toString());
    }
  }

  _replaceWithTiles() async {
    try {
      setState(() {
        isProcessing = true;
      });

      final imageHandler = ImageHandler();
      // Read and calculate average RGB of all images in assets folder
      final manifestJson = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
      Iterable<String> tilePaths = json.decode(manifestJson).keys.where((String key) => key.startsWith('assets'));
      final assetsAvgRgb = <List<int>>[];
      final tiles = <Uint8List>[];
      for (var tile in tilePaths) {
        final Uint8List inputImg = (await rootBundle.load(tile)).buffer.asUint8List();
        final avg = imageHandler.getAverageRGB(inputImg);
        tiles.add(inputImg);
        assetsAvgRgb.add(avg);
      }

      // Split and calculate average RGB of uploaded image
      final parts = imageHandler.splitImage(uploadedImage!, rows: 20, columns: 20);

      // Calculate closest difference for each part against assets
      final replacements = <List<Uint8List>>[];
      for (var i = 0; i < parts.length; i++) {
        final partRow = parts[i];
        final tileRow = <Uint8List>[];

        for (var j = 0; j < partRow.length; j++) {
          final part = partRow[j];
          final partAvgRgb = imageHandler.getAverageRGB(part);
          final partXyz = imageHandler.convertRgbToXyz(partAvgRgb);
          final partLab = imageHandler.convertXyzToLab(partXyz);

          double closestDifference = 1000000;
          var selectedIndex;
          for (var k = 0; k < assetsAvgRgb.length; k++) {
            final assetRgb = assetsAvgRgb[k];
            final assetXyz = imageHandler.convertRgbToXyz(assetRgb);
            final assetLab = imageHandler.convertXyzToLab(assetXyz);

            final diff = imageHandler.differenceDelteECIE(partLab, assetLab);
            if (diff < closestDifference) {
              closestDifference = diff;
              selectedIndex = k;
            }
          }

          if (selectedIndex != null) tileRow.add(tiles[selectedIndex]);
        }

        replacements.add(tileRow);
      }

      setState(() {
        uploadedImage = imageHandler.replaceWithTiles(uploadedImage!, replacements);
      });
    } catch (e) {
      logger.e(e);
      rethrow;
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (uploadedImage != null) ...[
              SizedBox(
                width: 250,
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: Image.memory(
                    uploadedImage!,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ],
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text("Pick Image"),
            ),
            ElevatedButton(
              onPressed: _replaceWithTiles,
              child: const Text("Replace with tiles"),
            ),
          ],
        ),
        if (isProcessing) ...[
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Container(
              color: Colors.grey.shade200.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
