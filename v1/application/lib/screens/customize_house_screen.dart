import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class CustomizeHouseScreen extends StatefulWidget {
  const CustomizeHouseScreen({super.key});

  @override
  State<CustomizeHouseScreen> createState() =>
      _CustomizeHouseScreenState();
}

class _CustomizeHouseScreenState
    extends State<CustomizeHouseScreen> {
  String selectedComponent = 'Window';

  double position = 0.5;
  double size = 0.5;

  Color selectedColor = Colors.blue;

  final List<Color> colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.black,
  ];

  IconData get selectedIcon {
    switch (selectedComponent) {
      case 'Door':
        return Icons.door_front_door;
      case 'Wall':
        return Icons.view_agenda;
      default:
        return Icons.window;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Customize House',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Modify Your House',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Customize your house before construction.',
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 20),

          // =========================
          // 3D MODEL + COMPONENT
          // =========================

          Container(
            height: 380,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF1FF),
              borderRadius: BorderRadius.circular(22),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                const ModelViewer(
                  src: 'assets/models/house.glb',
                  alt: '3D House Model',
                  autoRotate: true,
                  cameraControls: true,
                  disableZoom: false,
                  backgroundColor: Colors.transparent,
                ),

                // Live badge
                Positioned(
                  top: 15,
                  left: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'LIVE 3D MODEL',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),

                // =========================
                // SELECTED COMPONENT
                // =========================

                Positioned(
                  left: 25 + (position * 220),
                  top: 145,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        position += details.delta.dx / 220;
                        position =
                            position.clamp(0.0, 1.0);
                      });
                    },
                    child: Container(
                      width: 55 + (size * 35),
                      height: 55 + (size * 35),
                      decoration: BoxDecoration(
                        color:
                            selectedColor.withOpacity(0.20),
                        border: Border.all(
                          color: selectedColor,
                          width: 3,
                        ),
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Icon(
                        selectedIcon,
                        color: selectedColor,
                        size: 32 + (size * 15),
                      ),
                    ),
                  ),
                ),

                // Component label
                Positioned(
                  bottom: 15,
                  left: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selectedIcon,
                          color: selectedColor,
                          size: 20,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '$selectedComponent selected',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // =========================
          // COMPONENT
          // =========================

          const Text(
            'Select Component',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              _componentButton(
                'Window',
                Icons.window,
              ),
              _componentButton(
                'Door',
                Icons.door_front_door,
              ),
              _componentButton(
                'Wall',
                Icons.view_agenda,
              ),
            ],
          ),

          const SizedBox(height: 25),

          // =========================
          // POSITION
          // =========================

          Text(
            '$selectedComponent Position',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          Slider(
            value: position,
            onChanged: (value) {
              setState(() {
                position = value;
              });
            },
          ),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Left',
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                'Right',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // =========================
          // SIZE
          // =========================

          Text(
            '$selectedComponent Size',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          Slider(
            value: size,
            onChanged: (value) {
              setState(() {
                size = value;
              });
            },
          ),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Small',
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                'Large',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // =========================
          // COLOR
          // =========================

          const Text(
            'Choose Color',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
            children: colors.map((color) {
              final isSelected =
                  selectedColor == color;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedColor = color;
                  });
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.black
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 25),

          // =========================
          // SAVE
          // =========================

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      '$selectedComponent design updated',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text(
                'Save Design Changes',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          Card(
            color: Colors.white,
            child: const ListTile(
              leading: Icon(
                Icons.cloud_done,
                color: Colors.green,
              ),
              title: Text(
                'Ready to Synchronize',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Design changes can be shared with the constructor.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _componentButton(
    String name,
    IconData icon,
  ) {
    final active =
        selectedComponent == name;

    return Expanded(
      child: Padding(
        padding:
            const EdgeInsets.only(right: 8),
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              selectedComponent = name;
            });
          },
          style: OutlinedButton.styleFrom(
            backgroundColor:
                active ? Colors.blue : Colors.white,
            foregroundColor:
                active ? Colors.white : Colors.black,
            padding:
                const EdgeInsets.symmetric(
              vertical: 14,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(14),
            ),
          ),
          child: Column(
            children: [
              Icon(icon),
              const SizedBox(height: 5),
              Text(name),
            ],
          ),
        ),
      ),
    );
  }
}