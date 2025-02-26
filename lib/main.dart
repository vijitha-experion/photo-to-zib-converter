import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Home',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.secondaryColor),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Admin Home'),
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
  List<File> _images = []; // Stores all captured images
  File? _zipFile; // Stores the created ZIP file

  Future<void> cameraOpen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path)); // Add new image to the list
      });
    }
  }

  void _deleteImage(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Image"),
        content: const Text("Are you sure you want to delete this image?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _images.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text("Delete",
                style: TextStyle(color: AppColors.primaryColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _convertToZip() async {
    try {
      final archive = Archive();
      for (var image in _images) {
        List<int> imageBytes = await image.readAsBytes();
        archive.addFile(ArchiveFile(
            image.path.split('/').last, imageBytes.length, imageBytes));
      }

      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final zipFilePath = '${directory.path}/images.zip';
      final zipFile = File(zipFilePath);
      await zipFile.writeAsBytes(zipData);

      setState(() {
        _images.clear(); // Remove all images
        _zipFile = zipFile; // Store ZIP file reference
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ZIP file saved at: $zipFilePath")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating ZIP: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: _zipFile != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_zip_rounded,
                      size: 80, color: AppColors.linkColor),
                  const SizedBox(height: 10),
                  Text(
                    "ZIP File: ${_zipFile!.path.split('/').last}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : _images.isNotEmpty
                ? GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onLongPress: () => _deleteImage(index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.file(_images[index],
                                    fit: BoxFit.cover),
                              ),
                              Positioned(
                                right: 4,
                                top: 4,
                                child: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: AppColors.primaryColor),
                                  onPressed: () => _deleteImage(index),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : const Text("No images found"),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: cameraOpen,
              tooltip: 'Open Camera',
              child: const Icon(Icons.camera_alt_rounded),
            ),
            const SizedBox(width: 10),
            if (_images.isNotEmpty)
              FloatingActionButton(
                onPressed: _convertToZip,
                tooltip: 'Convert to ZIP',
                child: const Icon(Icons.folder_zip_rounded),
              ),
          ],
        ),
      ),
    );
  }
}
