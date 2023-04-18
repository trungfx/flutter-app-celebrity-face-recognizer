import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nhận diện người nổi tiếng',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  String? _name;
  String? _probability;
  String? _wikiLink;
  bool _isLoading = false;

  Future<void> getImageFromGallery() async {
    final imagePicker = ImagePicker();
    final pickedImage =
        await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedImage == null) {
      return;
    }
    setState(() {
      _image = File(pickedImage.path);
    });
  }

  Future<void> getImageFromCamera() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: ImageSource.camera);
    if (pickedImage == null) {
      return;
    }
    setState(() {
      _image = File(pickedImage.path);
    });
  }

  Future identifyCelebrity() async {
    setState(() {
      _isLoading = true;
    });
    String apiUrl = "https://python-webapp-01.cleverapps.io/image";
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
    var response = await request.send();
    if (response.statusCode == 200) {
      var jsonResponse = json.decode(await response.stream.bytesToString());
      setState(() {
        _name = jsonResponse['name'];
        _probability = jsonResponse['probability'];
        _wikiLink = jsonResponse['wiki_link'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      print('Error: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nhận diện người nổi tiếng'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Do something when the settings icon is pressed
            },
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image == null
                ? Container()
                : Image.file(
                    _image!,
                    height: 200.0,
                  ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: getImageFromGallery,
                  child: Text('Chọn ảnh từ thư viện'),
                ),
                ElevatedButton(
                  onPressed: getImageFromCamera,
                  child: Text('Chụp ảnh ngay từ camera'),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _image == null ? null : identifyCelebrity,
              child: Text('Nhận diện ngay'),
            ),
            SizedBox(height: 16.0),
            _isLoading
                ? SpinKitRing(
                    color: Colors.blue,
                    size: 50.0,
                  )
                : _name == null
                    ? Container()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tên: $_name'),
                          Text('Xác suất: $_probability'),
                          Text('Link wiki: $_wikiLink'),
                        ],
                      ),
          ],
        ),
      ),
    );
  }
}
