import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';

import 'setting.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nhận diện người nổi tiếng',
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class FacialArea {
  final int x;
  final int y;
  final int w;
  final int h;

  FacialArea(
      {required this.x, required this.y, required this.w, required this.h});

  factory FacialArea.fromJson(Map<String, dynamic> json) {
    return FacialArea(
      x: json['x'],
      y: json['y'],
      w: json['w'],
      h: json['h'],
    );
  }
}

class Celebrity {
  final String id;
  final String name;
  final String description;
  final String wikiUrl;
  final String article;
  final FacialArea facialArea;

  Celebrity({
    required this.id,
    required this.name,
    required this.description,
    required this.wikiUrl,
    required this.article,
    required this.facialArea,
  });

  factory Celebrity.fromJson(Map<String, dynamic> json) {
    return Celebrity(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      wikiUrl: json['wiki_url'],
      article: json['article'],
      facialArea: FacialArea.fromJson(json['facial_area']),
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final Rect rect;

  BoundingBoxPainter(this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class HomePage extends StatefulWidget {
  // const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentUrl = '';
  File? _image;
  int? _imageWidth = 0;
  int? _imageHeight = 0;
  List<Celebrity>? _celebrities;
  bool _isLoading = false;
  bool _imageSelected = false;
  // thêm biến này để kiểm tra ảnh đã được chọn hay chưa
  final GlobalKey imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  Future<void> getImageFromGallery() async {
    final imagePicker = ImagePicker();
    final pickedImage =
        await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedImage == null) {
      return;
    }
    setState(() {
      _imageSelected = true;
      // cập nhật biến _imageSelected khi ảnh đã được chọn
      _image = File(pickedImage.path);
      _celebrities = null;

      // Lấy kích thước ảnh
      img.Image? image = img.decodeImage(_image!.readAsBytesSync());
      _imageWidth = image?.width;
      _imageHeight = image?.height;
    });
  }

  Future<void> getImageFromCamera() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: ImageSource.camera);
    if (pickedImage == null) {
      return;
    }
    setState(() {
      _imageSelected = true;
      // cập nhật biến _imageSelected khi ảnh đã được chọn
      _image = File(pickedImage.path);
      _celebrities = null;

      // Lấy kích thước ảnh
      img.Image? image = img.decodeImage(_image!.readAsBytesSync());
      _imageWidth = image?.width;
      _imageHeight = image?.height;
    });
  }

  Future updateUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String apiUrl =
        prefs.getString('currentUrl') ?? 'http://10.0.2.2:5000/image';

    setState(() {
      _currentUrl = apiUrl;
    });
    return apiUrl;
  }

  Future identifyImage() async {
    setState(() {
      _isLoading = true;
    });
    String apiUrl = await updateUrl();
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    if (_image != null) {
      request.files
          .add(await http.MultipartFile.fromPath('file', _image!.path));
    }
    http.StreamedResponse response;
    try {
      response = await request.send();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Lỗi'),
            content: const Text('Đã có lỗi xảy ra khi gửi yêu cầu đến server'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }
    if (response.statusCode == 200) {
      var responseString = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseString);

      // ignore: avoid_print
      print(jsonResponse);
      List<dynamic> celebrityJson = jsonResponse;
      List<Celebrity> celebrities =
          celebrityJson.map((json) => Celebrity.fromJson(json)).toList();

      setState(() {
        _isLoading = false;
        _celebrities = celebrities;
      });
    } else {
      setState(() {
        _isLoading = false;
        _celebrities = null; // thêm dòng này để khắc phục lỗi
      });
      // ignore: avoid_print
      // print('Error: ${response.statusCode}');
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Lỗi'),
            content: const Text('Đã có lỗi xảy ra khi nhận diện ảnh'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void cancelIdentifyImage() {
    // hàm để huỷ xử lý nhận diện
    setState(() {
      _isLoading = false;
      _imageSelected = false;
      _image = null;
      _celebrities = null;
      _imageWidth = 0;
      _imageHeight = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhận diện người nổi tiếng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingPage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Text('API URL: $_currentUrl'),
            // const SizedBox(height: 16.0),
            // Expanded(
            //   child: Image.file(_image!, key: imageKey),
            // ),
            if (_imageSelected)
              Expanded(
                child: Stack(
                  children: [
                    Expanded(
                      child: Image.file(_image!, key: imageKey),
                    ),
                    if (_celebrities != null)
                      ..._celebrities
                              ?.asMap()
                              .map((index, celebrity) {
                                return MapEntry(index, LayoutBuilder(
                                  builder: (context, constraints) {
                                    final RenderBox renderBox = imageKey
                                        .currentContext!
                                        .findRenderObject() as RenderBox;
                                    final imageWidth = renderBox.size.width;
                                    final imageHeight = renderBox.size.height;
                                    final scaleX = imageWidth / _imageWidth!;
                                    final scaleY = imageHeight / _imageHeight!;
                                    final x =
                                        celebrity.facialArea.x.toDouble() *
                                            scaleX;
                                    final y =
                                        celebrity.facialArea.y.toDouble() *
                                            scaleY;
                                    final w =
                                        celebrity.facialArea.w.toDouble() *
                                            scaleX;
                                    final h =
                                        celebrity.facialArea.h.toDouble() *
                                            scaleY;
                                    final rect =
                                        Rect.fromLTRB(x, y, x + w, y + h);
                                    return CustomPaint(
                                        painter: BoundingBoxPainter(rect));
                                  },
                                ));
                              })
                              .values
                              .toList() ??
                          [],
                  ],
                ),
              ),
            const SizedBox(height: 16.0),
            if (!_imageSelected)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: getImageFromGallery,
                    highlightColor: Colors.transparent, // tắt hiệu ứng khi nhấn
                    splashColor: Colors.transparent, // tắt hiệu ứng khi splash
                    child: Column(
                      children: [
                        Container(
                          width: 100.0,
                          height: 100.0,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: const Icon(Icons.photo_library, size: 50.0),
                        ),
                        const SizedBox(height: 8.0),
                        const Text('Chọn từ thư viện',
                            style: TextStyle(fontSize: 16.0)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: getImageFromCamera,
                    highlightColor: Colors.transparent, // tắt hiệu ứng khi nhấn
                    splashColor: Colors.transparent, // tắt hiệu ứng khi splash
                    child: Column(
                      children: [
                        Container(
                          width: 100.0,
                          height: 100.0,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: const Icon(Icons.camera_alt, size: 50.0),
                        ),
                        const SizedBox(height: 8.0),
                        const Text('Chụp ảnh',
                            style: TextStyle(fontSize: 16.0)),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16.0),
            if (_imageSelected && !_isLoading && _celebrities == null)
              // hiển thị ảnh đã chọn và nút nhận diện
              ElevatedButton(
                onPressed: _image == null ? null : identifyImage,
                child: const Text('Nhận diện ngay'),
              ),
            const SizedBox(height: 16.0),
            if (_isLoading) // hiển thị tiêu đề "Đang nhận diện" khi đang xử lý
              const SpinKitRing(
                color: Colors.blue,
                size: 50.0,
              )
            else if (_celebrities != null && _celebrities!.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _celebrities!.length,
                  itemBuilder: (BuildContext context, int index) {
                    double x = _celebrities![index].facialArea.x.toDouble();
                    double y = _celebrities![index].facialArea.y.toDouble();
                    double w = _celebrities![index].facialArea.w.toDouble();
                    double h = _celebrities![index].facialArea.h.toDouble();

                    img.Image? originalImage =
                        img.decodeImage(_image!.readAsBytesSync()) ??
                            img.Image(0, 0);

                    img.Image? faceCrop = img.copyCrop(originalImage, x.toInt(),
                        y.toInt(), w.toInt(), h.toInt());

                    return ListTile(
                      leading: SizedBox(
                        width: 45,
                        // child: Image.file(_image!),
                        child: Image.memory(
                          Uint8List.fromList(img.encodeJpg(faceCrop)),
                          // encode kết quả cắt khuôn mặt dưới dạng jpg để hiển thị
                          fit: BoxFit.cover,
                          // giữ tỷ lệ hình ảnh và đảm bảo nó đầy đủ trong khung
                        ),
                      ),
                      title: Text(_celebrities![index].name),
                      subtitle: Text(_celebrities![index].description),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(_celebrities![index].name),
                              content: SingleChildScrollView(
                                child: ListBody(
                                  children: <Widget>[
                                    SizedBox(
                                      // width: 150,
                                      height: 200,
                                      // child: Image.file(_image!),
                                      child: Image.memory(
                                        Uint8List.fromList(
                                            img.encodeJpg(faceCrop)),
                                        // encode kết quả cắt khuôn mặt dưới dạng jpg để hiển thị
                                        fit: BoxFit.fitHeight,
                                        // giữ tỷ lệ hình ảnh và đảm bảo nó đầy đủ trong khung
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      _celebrities![index].article,
                                      textAlign: TextAlign.justify,
                                    ),
                                    const SizedBox(height: 20),
                                    InkWell(
                                      onTap: () {
                                        launchUrl(Uri.parse(
                                            _celebrities![index].wikiUrl));
                                      },
                                      child: Text(
                                        Uri.decodeFull(
                                            _celebrities![index].wikiUrl),
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              )
            else if (_celebrities != null && _celebrities!.isEmpty)
              const Expanded(
                child:
                    Center(child: Text("Không có người nổi tiếng trong ảnh.")),
              ),
            const SizedBox(height: 48.0),
            if (_imageSelected || _isLoading && _celebrities == null)
              // hiển thị nút huỷ khi không có kết quả nhận diện
              FloatingActionButton(
                onPressed: cancelIdentifyImage,
                backgroundColor: Colors.red,
                child: const Icon(Icons.close, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
