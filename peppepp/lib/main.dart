import 'dart:ffi';
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

  final List<List<int>> contrast = [
    [1, 4, 7, 4, 1],
    [4, 16, 26, 16, 4],
    [7, 26, 41, 26, 7],
    [4, 16, 26, 16, 4],
    [1, 4, 7, 4, 1],
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
      _path = image.path;
    });
  }

  Future shareImage() async {
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
    print(path);
    File file = File(path! + '/testImage.jpg');
    file.writeAsBytes(_image as List<int>);
    setState(() {
      _path = path + '/testImage.jpeg';
    });
  }

  List<List<int>> filter(List<List<int>> matrix) {
    List<List<int>> newMatrix = List.generate(
        matrix.length, (i) => List.from(matrix[i]),
        growable: false);

    for (int i = 3; i < matrix.length - 3; ++i) {
      for (int j = 3; j < matrix[0].length - 3; ++j) {
        newMatrix[i][j] = ((matrix[i - 2][j - 2] * contrast[0][0] +
                    matrix[i - 2][j - 1] * contrast[0][1] +
                    matrix[i - 2][j] * contrast[0][2] +
                    matrix[i - 2][j + 1] * contrast[0][3] +
                    matrix[i - 2][j + 2] * contrast[0][4] +
                    matrix[i - 1][j - 2] * contrast[1][0] +
                    matrix[i - 1][j - 1] * contrast[1][1] +
                    matrix[i - 1][j] * contrast[1][2] +
                    matrix[i - 1][j + 1] * contrast[1][3] +
                    matrix[i - 1][j + 2] * contrast[1][4] +
                    matrix[i][j - 2] * contrast[2][0] +
                    matrix[i][j - 1] * contrast[2][1] +
                    matrix[i][j] * contrast[2][2] +
                    matrix[i][j + 1] * contrast[2][3] +
                    matrix[i][j + 2] * contrast[2][4] +
                    matrix[i + 1][j - 2] * contrast[3][0] +
                    matrix[i + 1][j - 1] * contrast[3][1] +
                    matrix[i + 1][j] * contrast[3][2] +
                    matrix[i + 1][j + 1] * contrast[3][3] +
                    matrix[i + 1][j + 2] * contrast[3][4] +
                    matrix[i + 2][j - 2] * contrast[4][0] +
                    matrix[i + 2][j - 1] * contrast[4][1] +
                    matrix[i + 2][j] * contrast[4][2] +
                    matrix[i + 2][j + 1] * contrast[4][3] +
                    matrix[i + 2][j + 2] * contrast[4][4]) /
                273)
            .floor();
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

    rMatrix = filter(rMatrix);
    gMatrix = filter(gMatrix);
    bMatrix = filter(bMatrix);
    // aMatrix = filter(aMatrix);

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

  Color primaryColor = Colors.white;
  final _controller = CircleColorPickerController(
    initialColor: Colors.white,
  );

  Widget buildColorPicker() => CircleColorPicker(
        controller: _controller,
        onChanged: (color) {
          setState(() => primaryColor = color);
        },
      );

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
              ? ColorFiltered(
                  colorFilter: ColorFilter.mode(primaryColor, BlendMode.color),
                  child: Image.memory(_image!))
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
                                onPressed: () => Navigator.pop(context),
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
                const Text("Gauss blur")
              ],
            )
          ]),
    );
  }
}
