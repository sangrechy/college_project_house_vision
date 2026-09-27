import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class CustomizeModelScreen extends StatefulWidget {
  const CustomizeModelScreen({super.key});

  @override
  State<CustomizeModelScreen> createState() =>
      _CustomizeModelScreenState();
}

class _CustomizeModelScreenState
    extends State<CustomizeModelScreen> {
  int selectedComponent = 0;

  final List<String> components = [
    'Window',
    'Door',
    'Wall',
    'Room',
  ];

  final List<IconData> componentIcons = [
    Icons.window,
    Icons.door_front_door,
    Icons.view_agenda,
    Icons.room,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Customize House',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          // =====================================================
          // 3D MODEL
          // =====================================================

          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: const ModelViewer(
                src: 'assets/models/house_ar.glb',

                // Allow user to rotate the house
                cameraControls: true,

                // Auto rotate
                autoRotate: false,

                // Transparent background
                backgroundColor: Colors.white,

                // Start camera position
                cameraOrbit: '45deg 65deg 4m',

                // Allow zoom
                disableZoom: false,
              ),
            ),
          ),

          // =====================================================
          // COMPONENT TITLE
          // =====================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              18,
              16,
              18,
              8,
            ),
            color: Colors.white,
            child: const Text(
              'Add Component',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // =====================================================
          // COMPONENT BUTTONS
          // =====================================================

          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(
              14,
              8,
              14,
              14,
            ),
            child: Row(
              children: List.generate(
                components.length,
                (index) {
                  final selected =
                      selectedComponent == index;

                  return Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 4,
                      ),
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(14),
                        onTap: () {
                          setState(() {
                            selectedComponent = index;
                          });

                          _showComingSoon(
                            components[index],
                          );
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 4,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFE8F1FF)
                                : const Color(0xFFF5F7FB),
                            borderRadius:
                                BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? Colors.blue
                                  : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                componentIcons[index],
                                color: selected
                                    ? Colors.blue
                                    : Colors.grey,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                components[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w600,
                                  color: selected
                                      ? Colors.blue
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // =====================================================
          // SAVE DESIGN
          // =====================================================

          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(
              18,
              8,
              18,
              20,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saveDesign,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Save Design',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // COMPONENT ACTION
  // ===========================================================

  void _showComingSoon(String component) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$component customization will be added next.',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ===========================================================
  // SAVE
  // ===========================================================

  void _saveDesign() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Design saved successfully.',
        ),
      ),
    );
  }
}