import 'package:flutter/material.dart';

import 'package:ar_flutter_plugin_plus/ar_flutter_plugin_plus.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';

import 'package:vector_math/vector_math_64.dart' as vector;

class ARHouseScreen extends StatefulWidget {
  const ARHouseScreen({super.key});

  @override
  State<ARHouseScreen> createState() => _ARHouseScreenState();
}

class _ARHouseScreenState extends State<ARHouseScreen> {
  ARSessionManager? sessionManager;
  ARObjectManager? objectManager;

  ARNode? houseNode;

  bool housePlaced = false;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'AR House Preview',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // AR CAMERA
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontal,
          ),

          // INSTRUCTION
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                housePlaced
                    ? '🏠 House placed in AR'
                    : 'Move your phone slowly and point it at the floor, then tap.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // LOADING
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.white,
                      ),
                      SizedBox(height: 15),
                      Text(
                        'Loading house model...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // RESET
          if (housePlaced)
            Positioned(
              bottom: 25,
              left: 20,
              right: 20,
              child: ElevatedButton.icon(
                onPressed: resetHouse,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset House'),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // AR VIEW CREATED
  // ============================================================

  void onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    this.sessionManager = sessionManager;
    this.objectManager = objectManager;

    debugPrint('AR: View created');

    // Start AR session
    sessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
      handlePans: true,
      handleRotation: true,
    );

    debugPrint('AR: Session initialized');

    // Start object manager
    objectManager.onInitialize();

    debugPrint('AR: Object manager initialized');

    // Listen for floor taps
    sessionManager.onPlaneOrPointTap = onPlaneTapped;

    // Track ARCore state
    sessionManager.onTrackingStateChanged = (
      String state,
      String reason,
    ) {
      debugPrint(
        'AR TRACKING: $state | $reason',
      );
    };
  }

  // ============================================================
  // FLOOR TAP
  // ============================================================

  Future<void> onPlaneTapped(
    List<ARHitTestResult> hitTestResults,
  ) async {
    debugPrint(
      'AR TAP RECEIVED: ${hitTestResults.length}',
    );

    if (housePlaced) {
      debugPrint('AR: House already placed');
      return;
    }

    if (isLoading) {
      debugPrint('AR: Model is already loading');
      return;
    }

    if (hitTestResults.isEmpty) {
      debugPrint('AR: No valid plane found');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final hit = hitTestResults.first;

      final translation =
          hit.worldTransform.getTranslation();

      debugPrint(
        'AR: Tap position = '
        '${translation.x}, '
        '${translation.y}, '
        '${translation.z}',
      );

      // ========================================================
      // CREATE HOUSE NODE
      // ========================================================

      debugPrint('AR: Creating house node...');

      final node = ARNode(
        type: NodeType.webGLB,

        // IMPORTANT:
        // This file must physically exist here:
        //
        // assets/models/house_ar.glb
        //
        uri: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',

        name: 'DreamHome',

        // Start small.
        // We can increase this later.
        scale: vector.Vector3(
          0.2,
          0.2,
          0.2,
        ),

        position: vector.Vector3(
          translation.x,
          translation.y,
          translation.z,
        ),

        rotation: vector.Vector4(
          0,
          0,
          0,
          0,
        ),
      );

      debugPrint(
        'AR: House node created',
      );

      // ========================================================
      // ADD MODEL
      // ========================================================

      debugPrint(
        'AR: Starting addNode...',
      );

      final added =
          await objectManager?.addNode(node);

      debugPrint(
        'AR: addNode result = $added',
      );

      // ========================================================
      // SUCCESS
      // ========================================================

      if (added == true) {
        houseNode = node;

        debugPrint(
          'AR: HOUSE SUCCESSFULLY ADDED',
        );

        if (mounted) {
          setState(() {
            housePlaced = true;
          });
        }
      }

      // ========================================================
      // FAILURE
      // ========================================================

      else {
        debugPrint(
          'AR: addNode returned FALSE',
        );

        if (mounted) {
          showMessage(
            'Could not place the house model.',
          );
        }
      }
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    catch (e, stackTrace) {
      debugPrint(
        'AR HOUSE ERROR: $e',
      );

      debugPrint(
        'AR HOUSE STACK TRACE: $stackTrace',
      );

      if (mounted) {
        showMessage(
          'Error loading house model.',
        );
      }
    }

    // ==========================================================
    // FINISH LOADING
    // ==========================================================

    finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      debugPrint(
        'AR: Loading finished',
      );
    }
  }

  // ============================================================
  // RESET HOUSE
  // ============================================================

  Future<void> resetHouse() async {
    debugPrint(
      'AR: Resetting house',
    );

    if (houseNode != null) {
      await objectManager?.removeNode(
        houseNode!,
      );
    }

    houseNode = null;

    if (mounted) {
      setState(() {
        housePlaced = false;
      });
    }

    debugPrint(
      'AR: House reset complete',
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    sessionManager?.dispose();
    super.dispose();
  }
}