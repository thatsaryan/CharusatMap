import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  runApp(const MyApp());
}

class PanoramaScene {
  final String id;
  final String imageUrl;
  final String nextSceneId;

  const PanoramaScene({
    required this.id,
    required this.imageUrl,
    required this.nextSceneId,
  });
}

enum PanoramaStatus { initial, loading, loaded, error }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Panorama Viewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Map<String, PanoramaScene> _scenes = {
    'scene1': const PanoramaScene(
      id: 'scene1',
      imageUrl:
          'https://raw.githubusercontent.com/thatsaryan/CharusatPhotos/main/Main_In_1.jpg',
      nextSceneId: 'scene2',
    ),
    'scene2': const PanoramaScene(
      id: 'scene2',
      imageUrl:
          'https://raw.githubusercontent.com/aryanmaheta848/CharusatPhotos/main/Main_In_2.jpg',
      nextSceneId: 'scene1',
    ),
  };

  late PanoramaScene _currentScene;
  PanoramaStatus _status = PanoramaStatus.initial;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentScene = _scenes['scene1']!;
    _loadScene(_currentScene);
  }

  Future<void> _loadScene(PanoramaScene scene) async {
    setState(() {
      _status = PanoramaStatus.loading;
      _errorMessage = null;
    });

    try {
      await precacheImage(CachedNetworkImageProvider(scene.imageUrl), context);

      if (mounted) {
        setState(() {
          _currentScene = scene;
          _status = PanoramaStatus.loaded;
        });
      }

      final nextScene = _scenes[scene.nextSceneId]!;
      precacheImage(CachedNetworkImageProvider(nextScene.imageUrl), context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load panorama: ${scene.imageUrl}';
          _status = PanoramaStatus.error;
        });
      }
    }
  }

  void _transitionToNextScene() {
    final nextScene = _scenes[_currentScene.nextSceneId];
    if (nextScene == null) return;

    setState(() {
      _currentScene = nextScene;
    });

    final sceneAfterNext = _scenes[nextScene.nextSceneId]!;
    precacheImage(CachedNetworkImageProvider(sceneAfterNext.imageUrl), context);
  }

  Widget _buildBody() {
    switch (_status) {
      case PanoramaStatus.initial:
      case PanoramaStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case PanoramaStatus.error:
        return _buildErrorWidget();
      case PanoramaStatus.loaded:
        return _buildPanoramaViewer();
    }
  }

  Widget _buildPanoramaViewer() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 1200),
      transitionBuilder: (child, animation) {
        final scale = Tween<double>(begin: 1.02, end: 1.0).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: PanoramaViewer(
        key: ValueKey(_currentScene.id),
        sensitivity: 1.5,
        zoom: 0.7,
        hotspots: [
          Hotspot(
            latitude: 0,
            longitude: 0,
            width: 90,
            height: 90,
            widget: _buildHotspot(),
          ),
        ],
        child: Image(
          image: CachedNetworkImageProvider(_currentScene.imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildHotspot() {
    return GestureDetector(
      onTap: _transitionToNextScene,
      child: Tooltip(
        message: 'Go forward',
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.8),
              width: 2.5,
            ),
          ),
          child: const Icon(
            Icons.keyboard_arrow_up,
            color: Colors.white,
            size: 45,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An unknown error occurred.',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadScene(_currentScene),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Stack(children: [_buildBody()]));
  }
}