import 'dart:ffi';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'color_filters.dart';
import 'package:image/image.dart' as img;
import 'package:share_plus/share_plus.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:easy_folder_picker/DirectoryList.dart';
import 'package:easy_folder_picker/FolderPicker.dart';

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
  Uint8List? _image; // Картинка, которую сохранять
  Uint8List? srcImage;
  String? _path;

  // final List<List<int>> contrast = [
  //   [1, 4, 7, 4, 1],
  //   [4, 16, 26, 16, 4],
  //   [7, 26, 41, 26, 7],
  //   [4, 16, 26, 16, 4],
  //   [1, 4, 7, 4, 1],
  // ];

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
      _path = image.path;
    });
  }

  Future shareImage() async {
    await saveImage();
    List<String> ls = [_path!];
    Share.shareFiles(ls);
  }

  Future saveImage() async {
    String? path = await FilesystemPicker.open(
      title: 'Save to folder',
      context: context,
      fsType: FilesystemType.folder,
      pickText: 'Save file to this folder',
      rootDirectory: Directory('/storage/emulated/0/Download/'),
    );
    // print(path);
    File file = File(path! + '/testImage.jpg');
    file.writeAsBytes(_image as List<int>);
    setState(() {
      _path = path + '/testImage.jpg';
    });
  }

  bool isPixel(int i, int j, int h, int w) {
    if (i >= 0 && i < h && j >= 0 && j < w) {
      return true;
    }
    return false;
  }

  List<List<int>> filter(List<List<int>> matrix, int r) {
    List<List<int>> newMatrix = List.generate(
        matrix.length, (i) => List.from(matrix[i]),
        growable: false);

    for (int i = 0; i < matrix.length; ++i) {
      for (int j = 0; j < matrix[0].length; ++j) {
        newMatrix[i][j] = 0;
        for (int k = -r; k <= r; ++k) {
          for (int f = -r; f <= r; ++f) {
            if (isPixel(i + k, j + f, matrix.length, matrix[0].length)) {
              newMatrix[i][j] += matrix[i + k][j + f];
            } else {
              newMatrix[i][j] += matrix[i][j];
            }
          }
        }
        newMatrix[i][j] =
            (newMatrix[i][j] / ((2 * r + 1) * (2 * r + 1))).floor();
      }
    }
    return newMatrix;
  }

  Future convFilter() async {
    int rad = 3;
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

    rMatrix = filter(rMatrix, rad);
    gMatrix = filter(gMatrix, rad);
    bMatrix = filter(bMatrix, rad);

    for (int i = 0; i < im.height; ++i) {
      for (int j = 0; j < im.width; ++j) {
        pixels[i * im.width * 4 + j * 4] = rMatrix[i][j];
        pixels[i * im.width * 4 + j * 4 + 1] = gMatrix[i][j];
        pixels[i * im.width * 4 + j * 4 + 2] = bMatrix[i][j];
      }
    }

    setState(() {
      _image = img.encodeJpg(im) as Uint8List?;
    });
  }

  Color primaryColor = Colors.white;
  final _controller = CircleColorPickerController(
    initialColor: Colors.white,
  );

  Future colorFilter() async {
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
    int dr = (primaryColor.red / 2).floor();
    int dg = (primaryColor.green / 2).floor();
    int db = (primaryColor.blue / 2).floor();
    print(dr);
    print(dg);
    print(db);

    for (int i = 0; i < im.height; ++i) {
      for (int j = 0; j < im.width; ++j) {
        rMatrix[i][j] = min(rMatrix[i][j] + dr, 255);
        gMatrix[i][j] = min(gMatrix[i][j] + dg, 255);
        bMatrix[i][j] = min(bMatrix[i][j] + db, 255);
      }
    }

    for (int i = 0; i < im.height; ++i) {
      for (int j = 0; j < im.width; ++j) {
        pixels[i * im.width * 4 + j * 4] = rMatrix[i][j];
        pixels[i * im.width * 4 + j * 4 + 1] = gMatrix[i][j];
        pixels[i * im.width * 4 + j * 4 + 2] = bMatrix[i][j];
      }
    }

    setState(() {
      _image = img.encodeJpg(im) as Uint8List?;
    });
  }

  Future contrastFilter() async {
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
    // int dr = (primaryColor.red / 2).floor();
    // int dg = (primaryColor.green / 2).floor();
    // int db = (primaryColor.blue / 2).floor();
    // print(dr);
    // print(dg);
    // print(db);

    for (int i = 0; i < im.height; ++i) {
      for (int j = 0; j < im.width; ++j) {
        rMatrix[i][j] = min((rMatrix[i][j] * 1.2).floor(), 255);
        gMatrix[i][j] = min((gMatrix[i][j] * 1.2).floor(), 255);
        bMatrix[i][j] = min((bMatrix[i][j] * 1.2).floor(), 255);
      }
    }

    for (int i = 0; i < im.height; ++i) {
      for (int j = 0; j < im.width; ++j) {
        pixels[i * im.width * 4 + j * 4] = rMatrix[i][j];
        pixels[i * im.width * 4 + j * 4 + 1] = gMatrix[i][j];
        pixels[i * im.width * 4 + j * 4 + 2] = bMatrix[i][j];
      }
    }

    setState(() {
      _image = img.encodeJpg(im) as Uint8List?;
    });
  }

  Widget buildColorPicker() => CircleColorPicker(
        controller: _controller,
        onChanged: (color) {
          setState(() => primaryColor = color);
        },
      );

  int blurRadius = 1;
  double _currentSliderValue = 20;
  Widget getSlider() {
    return Slider(
        value: _currentSliderValue,
        max: 100,
        divisions: 5,
        label: _currentSliderValue.round().toString(),
        onChanged: (double value) {
          setState(() {
            _currentSliderValue = value;
            blurRadius = value.toInt();
          });
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
          IconButton(onPressed: saveImage, icon: const Icon(Icons.save_alt)),
          IconButton(onPressed: shareImage, icon: const Icon(Icons.share)),
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
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Chose color"),
                          content: buildColorPicker(),
                          actions: [
                            TextButton(
                                onPressed: () => {
                                      colorFilter(),
                                      Navigator.pop(context),
                                    },
                                child: const Text("OK")),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.color_lens_sharp)),
                const Text("Color filter")
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                    onPressed: convFilter,
                    icon: const Icon(Icons.blur_circular)),
                const Text("Blur")
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                    onPressed: contrastFilter,
                    icon: const Icon(Icons.contrast_outlined)),
                const Text("Blur")
              ],
            )
          ]),
    );
  }
}
