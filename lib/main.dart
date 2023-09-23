import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image/image.dart' as IMG;

late List<CameraDescription> cameras;

Future<void> main() async {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // Khoá màn hình ngang
    DeviceOrientation.portraitDown,
  ]);
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
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
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool isCheckSaveImage = false;
  late CameraController controller;

  Future<XFile?> capturePhoto() async {
    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }
    try {
      await controller.setFlashMode(FlashMode.off); //optional
      XFile file = await controller.takePicture();
      return file;
    } on CameraException catch (e) {
      debugPrint('Error occured while taking picture: $e');
      return null;
    }
  }

  void _onTakePhotoPressed() async {
    setState(() {
      isCheckSaveImage = true;
    });
    final xFile = await capturePhoto();
    if (xFile != null) {
      if (xFile.path.isNotEmpty) {
        cropSquare(xFile.path);
      }
    }
  }

  Future cropSquare(
    String srcFilePath,
  ) async {
    var bytes = await File(srcFilePath).readAsBytes();
    IMG.Image? src = IMG.decodeImage(bytes);

    IMG.Image destImage =
        IMG.copyCrop(src!, x: 100, y: 200, width: 300, height: 300);

    IMG.adjustColor(destImage, brightness: 50, contrast: 20,);

    var jpg = IMG.encodeJpg(destImage, quality: 100);

    final file = File(srcFilePath);
    await file.writeAsBytes(jpg);
    saveImageToGallery(file);
  }

  Future<void> saveImageToGallery(File xFile) async {
    try {
      await GallerySaver.saveImage(xFile.path);
      print('Tệp ảnh đã được lưu vào thư viện ảnh.');
      _incrementCounter();
    } catch (e) {
      print('Lỗi khi lưu tệp ảnh vào thư viện ảnh: $e');
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
      isCheckSaveImage = false;
    });
  }

  @override
  void initState() {
    super.initState();

    // Khởi tạo máy ảnh với máy ảnh mặc định
    controller = CameraController(cameras[0], ResolutionPreset.medium);

    // Khởi động máy ảnh
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Save Image: $_counter"),
        centerTitle: true,
      ),
      body: Container(
        margin: const EdgeInsets.only(bottom: 90),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller),
            cameraOverlay(),
          ],
        ),
      ),
      bottomSheet: Container(
        height: 90,
        width: MediaQuery.of(context).size.width,
        color: Colors.black,
        child: Center(
          child: GestureDetector(
            onTap: () {
              if (!isCheckSaveImage) {
                _onTakePhotoPressed();
              }
            },
            child: Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget cameraOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
