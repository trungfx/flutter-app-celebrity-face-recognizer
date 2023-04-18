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
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Nhận diện người nổi tiếng',
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
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  List<Celebrity>? _celebrities;
  bool _isLoading = false;
  bool _imageSelected = false;

  Future<void> getImageFromGallery() async {
    final imagePicker = ImagePicker();
    final pickedImage =
        await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedImage == null) {
      return;
    }
    setState(() {
      _imageSelected = true;
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
      _image = File(pickedImage.path);
      _celebrities = null;
    });
  }

  Future identifyImage() async {
    setState(() {
      _isLoading = true;
    });
    String apiUrl = "https://python-app-0.cleverapps.io/image";
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.files.add(await http.MultipartFile.fromPath('file', _image!.path));
    var response = await request.send();
    if (response.statusCode == 200) {
      var jsonResponse = json.decode(await response.stream.bytesToString());
      List<dynamic> celebrityJson = jsonResponse['celebrities'];
      List<Celebrity> celebrities =
          celebrityJson.map((json) => Celebrity.fromJson(json)).toList();
      setState(() {
        _isLoading = false;
        _celebrities = celebrities;
      });
    } else {
      setState(() {
        _isLoading = false;
        _celebrities = null;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhận diện người nổi tiếng'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_imageSelected)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(),
                  ),
                  child: Image.file(_image!),
                ),
              ),
            if (_isLoading)
              const SpinKitWave(
                color: Colors.blue,
                size: 50.0,
              )
            else if (_celebrities != null)
              Expanded(
                child: ListView.builder(
                  itemCount: _celebrities!.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      leading: Image.network(_celebrities![index].wikiUrl),
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
                                    Image.network(celebrities![index].wikiUrl),
                                    const SizedBox(height: 10),
                                    Text(celebrities![index].article),
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return SafeArea(
                  child: Container(
                    child: Wrap(
                      children: <Widget>[
                        ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Thư viện ảnh'),
                            onTap: () {
                              getImageFromGallery()
                                  .then(() => Navigator.pop(context));
                            }),
                        ListTile(
                          leading: const Icon(Icons.photo_camera),
                          title: const Text('Máy ảnh'),
                          onTap: () {
                            getImageFromCamera()
                                .then(() => Navigator.pop(context));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              });
        },
        tooltip: 'Chọn ảnh',
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
