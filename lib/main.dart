import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fetch the available cameras before initializing the app.
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CCTV Camera App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: CameraSelectionPage(cameras: cameras),
    );
  }
}

class CameraSelectionPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraSelectionPage({super.key, required this.cameras});

  @override
  _CameraSelectionPageState createState() => _CameraSelectionPageState();
}

class _CameraSelectionPageState extends State<CameraSelectionPage> {
  List<CameraDescription> selectedCameras = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Cameras'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView.builder(
        itemCount: widget.cameras.length,
        itemBuilder: (context, index) {
          final camera = widget.cameras[index];
          return CheckboxListTile(
            title: Text(camera.name),
            subtitle: Text(camera.lensDirection.toString()),
            value: selectedCameras.contains(camera),
            onChanged: (bool? selected) {
              setState(() {
                if (selected == true) {
                  selectedCameras.add(camera);
                } else {
                  selectedCameras.remove(camera);
                }
              });
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (selectedCameras.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CameraFeedPage(selectedCameras: selectedCameras),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Please select at least one camera')),
            );
          }
        },
        tooltip: 'Next',
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}

class CameraFeedPage extends StatefulWidget {
  final List<CameraDescription> selectedCameras;

  const CameraFeedPage({super.key, required this.selectedCameras});

  @override
  _CameraFeedPageState createState() => _CameraFeedPageState();
}

class _CameraFeedPageState extends State<CameraFeedPage> {
  List<CameraController> controllers = [];

  @override
  void initState() {
    super.initState();
    for (var camera in widget.selectedCameras) {
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
      );
      controllers.add(controller);
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {}); // Refresh the UI after initializing
      });
    }
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Feeds'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Display two camera feeds per row
        ),
        itemCount: controllers.length,
        itemBuilder: (context, index) {
          if (controllers[index].value.isInitialized) {
            return AspectRatio(
              aspectRatio: controllers[index].value.aspectRatio,
              child: CameraPreview(controllers[index]),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
