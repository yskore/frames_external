import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/ui/Widgets/map_view_widget.dart';
import 'package:frames_app/ui/Screens/home_screen.dart';

class MapExploreScreen extends ConsumerStatefulWidget {
  const MapExploreScreen({super.key});

  @override
  ConsumerState<MapExploreScreen> createState() => _MapExploreScreenState();
}

class _MapExploreScreenState extends ConsumerState<MapExploreScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Explore Live Pieces'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Reset the map providers to trigger a refresh
                ref.read(mapAnchorsProvider('explore_map').notifier).state = [];
                ref.read(mapErrorProvider('explore_map').notifier).state = null;
                ref.read(selectedMarkerProvider('explore_map').notifier).state = null;
                ref.read(markerPieceDetailsProvider('explore_map').notifier).state = null;
                
                // Trigger a rebuild that will reload the anchors
                setState(() {});
              },
            ),
          ],
        ),
        body: const MapViewWidget(
          mode: MapMode.explore,
          mapKey: 'explore_map',
        ),
      ),
    );
  }
}