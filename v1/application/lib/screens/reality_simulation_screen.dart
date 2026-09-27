import 'package:flutter/material.dart';

class RealitySimulationScreen extends StatelessWidget {
  const RealitySimulationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'Reality Simulation',
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
            'Construction Comparison',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Compare the planned design with the current construction.',
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 20),

          // SIDE BY SIDE COMPARISON
          Row(
            children: [
              Expanded(
                child: _comparisonCard(
                  'PLANNED',
                  Icons.view_in_ar,
                  Colors.blue,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _comparisonCard(
                  'CURRENT',
                  Icons.construction,
                  Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // SIMULATION
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.home_work,
                    size: 150,
                    color: Colors.blue,
                  ),
                ),

                Positioned(
                  top: 15,
                  left: 15,
                  child: _tag(
                    'REALITY OVERLAY',
                    Colors.blue,
                  ),
                ),

                Positioned(
                  right: 15,
                  top: 15,
                  child: _tag(
                    '62% COMPLETE',
                    Colors.green,
                  ),
                ),

                // Problem marker
                Positioned(
                  left: 95,
                  top: 125,
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.priority_high,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ISSUE
          Card(
            color: const Color(0xFFFFEBEE),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 32,
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mismatch Detected',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),

                        SizedBox(height: 7),

                        Text(
                          'Current wall position does not match the planned window opening.',
                        ),

                        SizedBox(height: 7),

                        Text(
                          'Action recommended: Verify before continuing construction.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Verification Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          _result(
            'Wall Alignment',
            'Matched',
            Icons.check_circle,
            Colors.green,
          ),

          _result(
            'Door Position',
            'Matched',
            Icons.check_circle,
            Colors.green,
          ),

          _result(
            'Window Opening',
            'Mismatch',
            Icons.warning,
            Colors.red,
          ),

          _result(
            'Column Position',
            'Matched',
            Icons.check_circle,
            Colors.green,
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.send),
            label: const Text(
              'Send Report to Homeowner',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _comparisonCard(
    String title,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 38,
            color: color,
          ),

          const SizedBox(height: 8),

          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _tag(
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static Widget _result(
    String title,
    String status,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: Icon(
          icon,
          color: color,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Text(
          status,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}