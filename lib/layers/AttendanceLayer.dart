import 'package:flutter/material.dart';

class AttendanceLayer extends StatefulWidget {
  final Future<String> Function() onCheckIn;
  final Future<String> Function() onCheckOut;
  final bool isFakeLocation;
  final bool isNearCheckIn;
  final bool isNearCheckOut;
  final bool doneCheckIn;
  final bool doneCheckOut;

  const AttendanceLayer({
    super.key,
    required this.onCheckIn,
    required this.onCheckOut,
    required this.isFakeLocation,
    required this.isNearCheckIn,
    required this.isNearCheckOut,
    required this.doneCheckIn,
    required this.doneCheckOut,
  });

  @override
  State<AttendanceLayer> createState() => _AttendanceLayerState();
}

class _AttendanceLayerState extends State<AttendanceLayer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal:30, vertical:20),
      padding: const EdgeInsets.all(50),
      decoration: BoxDecoration(
        border: Border.all(color:Colors.white, width:2),
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors:[Colors.blue,Colors.purple],
          begin:Alignment.topLeft,
          end:Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Giriş
          GestureDetector(
            onTap: () async {
              String result = await widget.onCheckIn();
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result))
              );
            },
            child: Container(
              height:50,
              decoration: BoxDecoration(
                color: widget.isFakeLocation
                    ? Colors.grey
                    : Colors.blue.shade900,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  'Giriş Yap',
                  style: TextStyle(
                      color:Colors.white,
                      fontSize:18,
                      fontWeight:FontWeight.w500
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height:30),

          // Çıkış
          GestureDetector(
            onTap: () async {
              String result = await widget.onCheckOut();
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result))
              );
            },
            child: Container(
              height:50,
              decoration: BoxDecoration(
                color: widget.isFakeLocation
                    ? Colors.grey
                    : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'Çıkış Yap',
                  style: TextStyle(
                      color:Colors.white,
                      fontSize:18,
                      fontWeight:FontWeight.w500
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


