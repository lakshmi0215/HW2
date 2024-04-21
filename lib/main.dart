import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
          brightness: themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Image Picker'),
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadFromPrefs();
  }

  toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkModeEnabled') ?? false;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkModeEnabled', _isDarkMode);
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? image;

  Future pickImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      if (pickedImage == null) return;
      final imageTemp = File(pickedImage.path);
      setState(() => image = imageTemp);
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Storage"),
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            MaterialButton(
              color: Colors.brown,
              child: Text(
                "Pick from Gallery",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold
                ),
              ),
              onPressed: () => pickImage(ImageSource.gallery),
            ),
            SizedBox(height: 20),
            image != null
                ? SizedBox(
              height: 150,
              width: 150,
              child: Image.file(image!),
            )
                : Text("No image selected"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: image == null ? null : () {
                color: Colors.brown;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DownloadPage(imagePath: image!.path)),
                );
              },
              child: Text("Download Page"),
            ),
          ],
        ),
      ),
    );
  }
}

class DownloadPage extends StatelessWidget {
  final String imagePath;

  DownloadPage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Download Page"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.file(File(imagePath), height: 150, width: 150),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _downloadImage(context, imagePath),
              child: Text("Download Image"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadImage(BuildContext context, String path) async {
    try {
      final File originalFile = File(path);
      final Uint8List bytes = await originalFile.readAsBytes();
      final directory = await getApplicationDocumentsDirectory();
      final File newFile = File('${directory.path}/${path.split('/').last}');
      await newFile.writeAsBytes(bytes);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${path.split('/').last} Downloaded Successfully'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to download image: $e'),
      ));
    }
  }
}
