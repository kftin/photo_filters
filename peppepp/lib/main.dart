import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'color_filters.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Uint8List? _image;
  Uint8List? srcImage;

  final List<List<int>> contrast = [
    [0, -1, 0],
    [-1, 5, -1],
    [0, -1, 0]
  ];

  final imagePicker = ImagePicker();

  Future getImageCamera() async {
    final image = await imagePicker.pickImage(source: ImageSource.camera);
    final bytes = await File(image!.path).readAsBytes();

    setState(() {
      srcImage = bytes;
      _image = srcImage;
    });
  }

  Future getImageGallery() async {
    final image = await imagePicker.pickImage(source: ImageSource.gallery);
    final bytes = await File(image!.path).readAsBytes();

    setState(() {
      srcImage = bytes;
      _image = srcImage;
    });
  }

  List<List<int>> filter(List<List<int>> matrix) {
    List<List<int>> newMatrix = List.generate(
        matrix.length, (i) => List.from(matrix[i]),
        growable: false);

    // print(matrix);
    // print("___");
    // print(newMatrix);

    for (int i = 1; i < matrix.length - 1; ++i) {
      for (int j = 1; j < matrix[0].length - 1; ++j) {
        newMatrix[i][j] = matrix[i - 1][j - 1] * contrast[0][0] +
            matrix[i - 1][j] * contrast[0][1] +
            matrix[i - 1][j + 1] * contrast[0][2] +
            matrix[i][j - 1] * contrast[1][0] +
            matrix[i][j] * contrast[1][1] +
            matrix[i][j + 1] * contrast[1][2] +
            matrix[i + 1][j - 1] * contrast[2][0] +
            matrix[i + 1][j] * contrast[2][1] +
            matrix[i + 1][j + 1] * contrast[2][2];
      }
    }
    return newMatrix;
  }

  Future convFilter() async {
    final im = img.decodeImage(srcImage!);
    final pixels = im!.getBytes(format: img.Format.rgba);

    var rMatrix = List.generate(
        im.height,
        (int i) => List.generate(
            im.width, (int j) => pixels[i * 4 * im.width + j * 4],
            growable: false),
        growable: false);
    var gMatrix = List.generate(
        im.height,
        (int i) => List.generate(
            im.width, (int j) => pixels[i * 4 * im.width + j * 4 + 1],
            growable: false),
        growable: false);
    var bMatrix = List.generate(
        im.height,
        (int i) => List.generate(
            im.width, (int j) => pixels[i * 4 * im.width + j * 4 + 2],
            growable: false),
        growable: false);
    var aMatrix = List.generate(
        im.height,
        (int i) => List.generate(
            im.width, (int j) => pixels[i * 4 * im.width + j * 4 + 3],
            growable: false),
        growable: false);

    // Filter
    // print(rMatrix);
    rMatrix = filter(rMatrix);
    // print("____");
    // print(rMatrix);
    gMatrix = filter(gMatrix);
    bMatrix = filter(bMatrix);
    aMatrix = filter(aMatrix);

    for (int i = 0; i < im.height; ++i) {
      for (int j = 0; j < im.width; ++j) {
        pixels[i * im.width * 4 + j * 4] = rMatrix[i][j];
        pixels[i * im.width * 4 + j * 4 + 1] = gMatrix[i][j];
        pixels[i * im.width * 4 + j * 4 + 2] = bMatrix[i][j];
        pixels[i * im.width * 4 + j * 4 + 3] = aMatrix[i][j];
      }
    }

    setState(() {
      _image = img.encodeJpg(im) as Uint8List?;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Row(
        children: <Widget>[
          IconButton(
              onPressed: getImageCamera, icon: const Icon(Icons.camera_alt)),
          IconButton(
              onPressed: getImageGallery, icon: const Icon(Icons.folder)),
          const Spacer(),
          IconButton(
              onPressed: getImageGallery, icon: const Icon(Icons.save_alt)),
          IconButton(onPressed: getImageGallery, icon: const Icon(Icons.share)),
        ],
      )),
      body: Center(
          child: _image != null
              ? Image.memory(_image!)
              : const Text("No img yet...")),
      floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                    onPressed: convFilter, icon: const Icon(Icons.color_lens_sharp)),
                const Text("Color filter")
              ],
            ),
            // const Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                    onPressed: convFilter, icon: const Icon(Icons.blur_circular)),
                const Text("Gauss blur")
              ],
            )
          ]
          // children: <Widget> [
          //   IconButton(onPressed: convFilter, icon: const Icon(Icons.filter),
          //   ),
          // ],
          ),
    );
  }
}
