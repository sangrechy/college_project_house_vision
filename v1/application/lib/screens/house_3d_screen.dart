import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class House3DScreen extends StatelessWidget {
  const House3DScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          '3D House View',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Dream Home',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Interactive 3D visualization',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 20),

          Container(
            height: 420,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF1FF),
              borderRadius: BorderRadius.circular(22),
            ),
            clipBehavior: Clip.antiAlias,
            child: const ModelViewer(
              src: 'assets/models/house.glb',
              alt: '3D model of the house',
              autoRotate: true,
              cameraControls: true,
              ar: false,
              backgroundColor: Colors.transparent,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Interactive Controls',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _controlCard(
                  Icons.touch_app,
                  'Drag',
                  'Rotate',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _controlCard(
                  Icons.zoom_in,
                  'Pinch',
                  'Zoom',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _controlCard(
                  Icons.threed_rotation,
                  'Auto',
                  'Rotate',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Card(
            color: Colors.white,
            child: const ListTile(
              leading: Icon(
                Icons.view_in_ar,
                color: Colors.blue,
              ),
              title: Text(
                '3D Model Ready',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Drag to rotate and pinch to zoom the house.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _controlCard(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 6,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.blue,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}