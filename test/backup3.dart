import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Nhận diện người nổi tiếng',
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class Celebrity {
  final String id;
  final String name;
  final String description;
  final String wikiUrl;
  final String article;

  Celebrity({
    required this.id,
    required this.name,
    required this.description,
    required this.wikiUrl,
    required this.article,
  });

  factory Celebrity.fromJson(Map<String, dynamic> json) {
    return Celebrity(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      wikiUrl: json['wiki_url'],
      article: json['article'],
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  List<Celebrity>? _celebrities;
  bool _isLoading = false;
  bool _imageSelected = false;
  // thêm biến này để kiểm tra ảnh đã được chọn hay chưa

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
    });
  }

  Future identifyImage() async {
    setState(() {
      _isLoading = true;
    });
    String apiUrl = "http://10.0.2.2:5000/image";
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.files.add(await http.MultipartFile.fromPath('file', _image!.path));
    var response = await request.send();
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
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_imageSelected)
              Expanded(
                child: Image.file(_image!),
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
            else if (_celebrities != null)
              Expanded(
                child: ListView.builder(
                  itemCount: _celebrities!.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      // leading: Image.network(_celebrities![index].wikiUrl),
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
                                    // Image.network(_celebrities![index].wikiUrl),
                                    const SizedBox(height: 10),
                                    Text(
                                      _celebrities![index].article,
                                      textAlign: TextAlign.justify,
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

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Khởi tạo giá trị mặc định của url
    _urlController.text = "https://python-app-01.cleverapps.io/";
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cài đặt"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "URL nhận diện:",
              style: TextStyle(fontSize: 18.0),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: "Nhập URL nhận diện",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Lưu url vào bộ nhớ
                String apiUrl = _urlController.text;
                // TODO: Lưu url vào bộ nhớ ở đây
                Navigator.of(context).pop();
              },
              child: const Text("Lưu"),
            ),
          ],
        ),
      ),
    );
  }
}
