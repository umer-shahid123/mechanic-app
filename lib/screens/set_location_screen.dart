import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:mechanic_app/screens/offers_screen.dart';
import 'package:mechanic_app/theme/app_theme.dart';

class SetLocationScreen extends StatefulWidget {
  const SetLocationScreen({super.key});

  @override
  State<SetLocationScreen> createState() => _SetLocationScreenState();
}

class _SetLocationScreenState extends State<SetLocationScreen> {
  gmaps.LatLng _selectedPos = const gmaps.LatLng(31.4697, 74.2728); // Lahore

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Set Location', 
          style: TextStyle(
            fontWeight: FontWeight.w800, 
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          gmaps.GoogleMap(
            initialCameraPosition: gmaps.CameraPosition(target: _selectedPos, zoom: 15),
            onCameraMove: (pos) => _selectedPos = pos.target,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 35),
              child: Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 45),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                boxShadow: isDark ? [] : [const BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: isDark ? AppColors.neonGreen : AppColors.primary),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Johar Town, Lahore', 
                                style: TextStyle(
                                  fontWeight: FontWeight.w800, 
                                  fontSize: 16,
                                  color: isDark ? Colors.white : AppColors.textDark,
                                ),
                              ),
                              Text(
                                'Punjab, Pakistan', 
                                style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {}, 
                          child: Text(
                            'Change', 
                            style: TextStyle(
                              color: isDark ? AppColors.neonGreen : Colors.blue, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const OffersScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.neonGreen : AppColors.primary,
                      ),
                      child: Text(
                        'Confirm Location', 
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
