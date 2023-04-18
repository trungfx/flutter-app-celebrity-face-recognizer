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
      title: 'Nhận diện mèo',
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
  List<dynamic>? _topCategories;
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

  Future identifyImage() async {
    setState(() {
      _isLoading = true;
    });
    String apiUrl = "https://python-webapp-01.cleverapps.io/image";
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.files.add(await http.MultipartFile.fromPath('file', _image!.path));
    var response = await request.send();
    if (response.statusCode == 200) {
      var jsonResponse = json.decode(await response.stream.bytesToString());
      print(jsonResponse);
      setState(() {
        _topCategories = jsonResponse['top_categories'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _topCategories = null; // thêm dòng này để khắc phục lỗi
      });
      print('Error: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nhận diện mèo'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
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
              onPressed: _image == null ? null : identifyImage,
              child: Text('Nhận diện ngay'),
            ),
            SizedBox(height: 16.0),
            _isLoading
                ? SpinKitRing(
                    color: Colors.blue,
                    size: 50.0,
                  )
                : _topCategories == null
                    ? Container()
                    : Column(
                        children: [
                          Text(
                            'Kết quả nhận diện:',
                            style: TextStyle(fontSize: 20.0),
                          ),
                          SizedBox(height: 16.0),
                          Text(
                            _topCategories![0][0],
                            style: TextStyle(fontSize: 18.0),
                          ),
                          SizedBox(height: 16.0),
                          Text(
                            'Độ chính xác: ${_topCategories![0][1]}',
                            style: TextStyle(fontSize: 18.0),
                          ),
                        ],
                      ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Khởi tạo giá trị mặc định của url
    _urlController.text = "https://python-webapp-01.cleverapps.io";
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
        title: Text("Cài đặt"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "URL nhận diện:",
              style: TextStyle(fontSize: 18.0),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: "Nhập URL nhận diện",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Lưu url vào bộ nhớ
                String apiUrl = _urlController.text;
                // TODO: Lưu url vào bộ nhớ ở đây
                Navigator.of(context).pop();
              },
              child: Text("Lưu"),
            ),
          ],
        ),
      ),
    );
  }
}
