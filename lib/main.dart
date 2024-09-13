import 'dart:io'; // Import to check IP connectivity
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import for HTTP requests
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
      title: 'Detectify',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple,
          elevation: 4,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.deepPurple,
        ),
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
  List<String> externalCameras = []; // To store external camera IPs

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Cameras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Implement notifications functionality
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          AnimationLimiter(
            child: ListView.builder(
              itemCount: widget.cameras.length,
              itemBuilder: (context, index) {
                final camera = widget.cameras[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    horizontalOffset: 50.0,
                    child: FadeInAnimation(
                      child: CheckboxListTile(
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
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                onPressed: () => _showAddExternalCameraDialog(),
                tooltip: 'Add Camera',
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (selectedCameras.isNotEmpty || externalCameras.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CameraFeedPage(
                  selectedCameras: selectedCameras,
                  externalCameras: externalCameras,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Please select or add at least one camera')),
            );
          }
        },
        tooltip: 'Next',
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(Icons.arrow_forward, key: UniqueKey()),
        ),
      ),
    );
  }

  // Function to show a dialog to add an external camera
  void _showAddExternalCameraDialog() {
    final TextEditingController _ipController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add External Camera'),
          content: TextField(
            controller: _ipController,
            decoration: const InputDecoration(hintText: 'Enter Camera IP Address'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                final ip = _ipController.text.trim();
                if (await _isIPReachable(ip)) {
                  setState(() {
                    externalCameras.add(ip);
                  });
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('IP Address not reachable')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Function to check if the entered IP is reachable
  Future<bool> _isIPReachable(String ip) async {
    try {
      final response = await http.get(Uri.parse('http://$ip'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

class CameraFeedPage extends StatefulWidget {
  final List<CameraDescription> selectedCameras;
  final List<String> externalCameras;

  const CameraFeedPage({super.key, required this.selectedCameras, required this.externalCameras});

  @override
  _CameraFeedPageState createState() => _CameraFeedPageState();
}

class _CameraFeedPageState extends State<CameraFeedPage> {
  List<CameraController> controllers = [];
  List<String> externalCamerasFeeds = []; // Mock for external camera feeds

  @override
  void initState() {
    super.initState();

    // Initialize local cameras
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
        setState(() {});
      });
    }

    // Mock the external camera feeds, assuming they are reachable
    for (var ip in widget.externalCameras) {
      externalCamerasFeeds.add('External camera feed from IP: $ip');
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Implement refresh functionality
            },
          ),
        ],
      ),
      body: AnimationLimiter(
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Display two camera feeds per row
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: controllers.length + externalCamerasFeeds.length,
          itemBuilder: (context, index) {
            if (index < controllers.length) {
              // Show local camera feed
              if (controllers[index].value.isInitialized) {
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  columnCount: 2,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: AspectRatio(
                          aspectRatio: controllers[index].value.aspectRatio,
                          child: CameraPreview(controllers[index]),
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            } else {
              // Show external camera feed
              final externalFeed = externalCamerasFeeds[index - controllers.length];
              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: const Duration(milliseconds: 375),
                columnCount: 2,
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(child: Text(externalFeed)),
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
