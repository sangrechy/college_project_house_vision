import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'reality_simulation_screen.dart';
import 'ar_house_screen.dart';
import 'customize_model_screen.dart';

class ConstructorDashboard extends StatelessWidget {
  const ConstructorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'House Vision',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_outlined,
            ),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Welcome, Constructor 👷',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Manage and verify the current construction.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 20),

          // =====================================================
          // FIREBASE DESIGN UPDATE
          // =====================================================

          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('projects')
                .doc('dream_home')
                .snapshots(),

            builder: (context, snapshot) {
              if (!snapshot.hasData ||
                  !snapshot.data!.exists) {
                return _noUpdateCard();
              }

              final data =
                  snapshot.data!.data()
                      as Map<String, dynamic>;

              final component =
                  data['selectedComponent'] ?? 'None';

              final position =
                  ((data['position'] ?? 0.5) * 100)
                      .round();

              return Card(
                color: const Color(0xFFE8F1FF),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.notifications_active,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'New Design Update',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      Text(
                        'Homeowner changed the '
                        '$component position.',
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Position: $position%',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const RealitySimulationScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.view_in_ar,
                          ),
                          label: const Text(
                            'View Updated Model',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // =====================================================
          // PROJECT
          // =====================================================

          Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.home_work,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Project: Dream Home',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Location: Coimbatore, Tamil Nadu',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'Construction Progress',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  LinearProgressIndicator(
                    value: 0.62,
                    minHeight: 8,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    '62% completed',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Construction Tools',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // =====================================================
          // FIRST ROW
          // =====================================================

          Row(
            children: [
              Expanded(
                child: _toolCard(
                  Icons.map_outlined,
                  'Floor Plan',
                  Colors.blue,
                  () {},
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _toolCard(
                  Icons.view_in_ar,
                  'AR Preview',
                  Colors.purple,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ARHouseScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // =====================================================
          // SECOND ROW
          // =====================================================

          Row(
            children: [
              Expanded(
                child: _toolCard(
                  Icons.camera_alt_outlined,
                  'Verify Work',
                  Colors.orange,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const RealitySimulationScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _toolCard(
                  Icons.edit_road,
                  'Customize',
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const CustomizeModelScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // =====================================================
          // CONSTRUCTION ALERT
          // =====================================================

          Card(
            color: const Color(0xFFFFF4E5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 30,
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Construction Check',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        SizedBox(height: 5),

                        Text(
                          'Verify wall and window positions '
                          'against the planned model.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // =====================================================
          // FIREBASE STATUS
          // =====================================================

          Card(
            color: Colors.white,
            child: const ListTile(
              leading: Icon(
                Icons.cloud_done,
                color: Colors.green,
              ),
              title: Text(
                'Firebase Connected',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Homeowner and constructor data '
                'are synchronized.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // NO UPDATE CARD
  // ===========================================================

  static Widget _noUpdateCard() {
    return Card(
      color: Colors.white,
      child: const ListTile(
        leading: Icon(
          Icons.check_circle,
          color: Colors.green,
        ),
        title: Text(
          'No New Design Changes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'The current design is synchronized.',
        ),
      ),
    );
  }

  // ===========================================================
  // TOOL CARD
  // ===========================================================

  static Widget _toolCard(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 8,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 34,
                color: color,
              ),

              const SizedBox(height: 10),

              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}