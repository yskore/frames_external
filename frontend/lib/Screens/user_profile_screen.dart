import 'dart:async';
import 'dart:convert';
import 'package:frames_app/Functions/piece_loading.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter/material.dart';
import 'package:frames_app/Functions/profile_page.dart';
import 'package:frames_app/Screens/user_menu.dart';
import 'package:frames_app/Widgets/user_profile_widgets.dart';
import 'package:frames_app/Widgets/piece_preview_popup.dart'; 
import 'package:geolocator/geolocator.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;
  final String? successMessage;  // Add this


  const UserProfileScreen({Key? key, required this.username, this.successMessage,  // Add this
}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _showGallery = true;
  List<Piece> _pieces = [];
  late Future<Map<String, dynamic>> _profileData;
  bool _isLoading = false;
  List<Anchor> _anchors = [];
  Completer<GoogleMapController> _mapController = Completer();
  LatLng? _currentUserLocation;

  @override
  void initState() {
    super.initState();
    _loadPieces();
    _loadAnchors(widget.username); 
    _profileData = _fetchProfileData();
      requestLocationPermission();


    // Show success message if it exists
  if (widget.successMessage != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.successMessage!))
        );
        _refreshProfileData();
      
      }
    });
  }
  
  }

  Future<void> requestLocationPermission() async {
  final permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always) {
    _getCurrentLocation();
  }
}
  
    @override
  void dispose() {
    _disposeMapController();
    super.dispose();
  }

  Future<void> _loadPieces() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _pieces = await getPiecesByOwner(widget.username);
      print('username = ' + widget.username);
      if (_pieces.isNotEmpty) {
        print('Frame used for the first piece: ${_pieces[0].frameName}');
        print('The piece is called: ${_pieces[0].pieceTitle}');
      }
    } catch (e) {
      print('Error loading pieces: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _refreshProfileData() {
  setState(() {
    _profileData = _fetchProfileData(); // This will trigger FutureBuilder to rebuild
  });
}

Future<void> _getCurrentLocation() async {
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
    
    setState(() {
      _currentUserLocation = LatLng(position.latitude, position.longitude);
    });
  } catch (e) {
    print('Error getting current location: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 56), // Space for the back button
                _buildProfileInfoRow(),
                SizedBox(height: 16),
                _buildToggleRow(),
                Expanded(
                  child: _showGallery ? _buildGalleryView() : _buildMapView(),
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              child: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => MenuScreen(username: widget.username,)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow() {
    return Container(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _profileData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final data = snapshot.data!;
            final userProfile = data['userProfileInfo'] as UserProfile;
            return Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 16, left: 16, right: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              // TODO: Implement profile picture change
                            },
                            child: CircleAvatar(
                              radius: 40,
                              backgroundImage: 
                                userProfile.Profile_photo.isNotEmpty
                                  ? NetworkImage(userProfile.Profile_photo)
                                  : const NetworkImage('https://via.placeholder.com/80'),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(userProfile.username, style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(userProfile.bio ?? 'No bio available', textAlign: TextAlign.center),
                        ],
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCountColumn('Followers', data['followers'].toString()),
                            _buildCountColumn('Following', data['following'].toString()),
                            _buildCountColumn('Live Pieces', userProfile.live_pieces.toString()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // TODO: Implement edit functionality
                    },
                  ),
                ),
              ],
            );
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }

  Widget _buildGalleryView() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
      ),
      itemCount: _pieces.length,
      itemBuilder: (context, index) {
        return _buildPieceItem(_pieces[index]);
      },
    );
  }
   
  Widget _buildCountColumn(String label, String count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count, style: TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

Widget _buildToggleRow() {
  return Container(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Gallery'),
        Switch(
          value: !_showGallery,
          onChanged: (value) async {
            bool switchingToMap = value;  // true if switching to map view
            
            setState(() {
              _showGallery = !value;
              _isLoading = switchingToMap;  // Only show loading when switching to map
            });
            
            // Only refresh data when switching to map view
            if (switchingToMap) {
              try {
                await Future.wait([
                  _loadPieces(),
                  _loadAnchors(widget.username),
                ]);
                
                // Only update map if we're still in map view
                if (!_showGallery && _mapController.isCompleted) {
                  final controller = await _mapController.future;
                  
                  Set<Marker> updatedMarkers = _anchors.map((anchor) {
                    Piece? matchingPiece;
                    try {
                      matchingPiece = _pieces.firstWhere(
                        (piece) => piece.pieceid == anchor.pieceId,
                      );
                    } catch (e) {
                      print('No matching piece found for anchor: ${anchor.pieceId}');
                    }

                    return Marker(
                      markerId: MarkerId(anchor.anchorId),
                      position: LatLng(
                        anchor.location.coordinates[1], 
                        anchor.location.coordinates[0]
                      ),
                      infoWindow: InfoWindow(
                        title: matchingPiece?.pieceTitle ?? anchor.frameName,
                        snippet: 'Tap to view details',
                      ),
                      onTap: () {
                        if (matchingPiece != null) {
                          _showPiecePreview(context, matchingPiece);
                        }
                      },
                    );
                  }).toSet();

                  if (updatedMarkers.isNotEmpty) {
                    await _fitBounds(updatedMarkers);
                  }
                }
              } catch (e) {
                print('Error refreshing map data: $e');
                if (mounted) {  // Check if widget is still mounted
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to refresh map data. Please try again.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } finally {
                if (mounted) {  // Check if widget is still mounted
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            } else {
              // When switching back to gallery, dispose of the map controller
              _disposeMapController();
            }
          },
        ),
        const Text('Map'),
      ],
    ),
  );
}

  void _showPiecePreview(BuildContext context, Piece piece) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        print('[TEST] PiecePreviewPopup: Creating fresh piece data for ${piece.pieceTitle}, Frame_name = ${piece.frameName}');
        String freshPieceData = jsonEncode({
        'frameName': piece.frameName,  
        'faceName': 'Face',
        'imageUrl': piece.pieceDisplay,
        'PieceID': piece.pieceid,
      });
         print('[TEST] Fresh piece data being sent to preview: $freshPieceData');

        return PiecePreviewPopup(
          pieceName: piece.pieceTitle,
          pieceData: freshPieceData,
          liveStatus: piece.liveStatus,
          pieceDescription: piece.pieceDescription,
          pieceLikes: piece.pieceLikes,
          pieceForSale: piece.pieceForSale,
          pieceCreationDate: piece.pieceCreationDate,
          piecePrice: piece.piecePrice,
          pieceOwner: piece.pieceOwner,
          onPieceUpdated: () {
            // Reload pieces when a piece is updated
            _loadPieces();
          },
        );
      },
    );
  }
 
  Widget _buildPieceItem(Piece piece) {
  return GestureDetector(
    onTap: () => _showPiecePreview(context, piece),
    child: Container(
      margin: EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image with loading indicator
          Image.network(
            piece.pieceDisplay ?? 'https://via.placeholder.com/150',
            fit: BoxFit.cover,
            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2.0,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(Icons.error_outline, color: Colors.red),
              );
            },
          ),
          // Status overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 4),
              color: Colors.black54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    piece.liveStatus ? 'Live' : 'Draft',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(width: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: piece.liveStatus ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}




Widget _buildMapView() {
  if (_isLoading) {
    return Center(child: CircularProgressIndicator());
  }

  if (_anchors.isEmpty && _currentUserLocation == null) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('No live pieces placed on map'),
          SizedBox(height: 8),
          Text('Total anchors loaded: ${_anchors.length}', 
               style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // Create set of markers including both pieces and user location
  Set<Marker> markers = {};
  
  // Add piece markers
  markers.addAll(_anchors.map((anchor) {
    Piece? matchingPiece;
    try {
      matchingPiece = _pieces.firstWhere(
        (piece) => piece.pieceid == anchor.pieceId,
      );
    } catch (e) {
      print('No matching piece found for anchor: ${anchor.pieceId}');
    }

    return Marker(
      markerId: MarkerId(anchor.anchorId),
      position: LatLng(
        anchor.location.coordinates[1], 
        anchor.location.coordinates[0]
      ),
      infoWindow: InfoWindow(
        title: matchingPiece?.pieceTitle ?? anchor.frameName,
        snippet: 'Tap to view details',
      ),
      onTap: () {
        if (matchingPiece != null) {
          _showPiecePreview(context, matchingPiece);
        }
      },
    );
  }));

  // Add user location marker if available
  if (_currentUserLocation != null) {
    markers.add(
      Marker(
        markerId: MarkerId('user_location'),
        position: _currentUserLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: 'Your Location'),
      ),
    );
  }

  // Determine initial camera position
  LatLng initialPosition = _currentUserLocation ?? 
    LatLng(_anchors.first.location.coordinates[1], 
           _anchors.first.location.coordinates[0]);

  return GoogleMap(
    initialCameraPosition: CameraPosition(
      target: initialPosition,
      zoom: 15,
    ),
    markers: markers,
    myLocationEnabled: true,
    myLocationButtonEnabled: true,
    mapToolbarEnabled: false,
    zoomControlsEnabled: true,
    onMapCreated: (GoogleMapController controller) {
      if (!_mapController.isCompleted) {
        _mapController.complete(controller);
        if (markers.isNotEmpty) {
          _fitBounds(markers);
        }
      }
    },
  );
}
  // Add this helper function to fit all markers in view
  Future<void> _fitBounds(Set<Marker> markers) async {
    if (markers.isEmpty) return;

    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;

    for (final marker in markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng) minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng) maxLng = marker.position.longitude;
    }

    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50, // padding
      ),
    );
  }



void _disposeMapController() async {
  if (_mapController.isCompleted) {
    final controller = await _mapController.future;
    controller.dispose();
    _mapController = Completer<GoogleMapController>();
  }
}


Future<void> _loadAnchors(String username) async {
  print("_loadAnchors called with username: $username");
  try {
    final url = Uri.parse('https://x-fabric-419423.uc.r.appspot.com/get_anchors_by_owner');
    final requestBody = jsonEncode({'username': username});
    print("Sending request with body: $requestBody");
    
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: requestBody,
    );
    
    print("Response status code: ${response.statusCode}");
    print("Response body: ${response.body}");
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print("Parsed data length: ${data.length}");
      print("Raw data: $data");
      
      setState(() {
        _anchors = data.map((json) => Anchor.fromJson(json)).toList();
        print('Anchors loaded successfully. Count: ${_anchors.length}');
        if (_anchors.isNotEmpty) {
          print('First anchor details: ${jsonEncode(_anchors.first.toJson())}');
        }
      });
    } else {
      print('Error loading anchors. Status: ${response.statusCode}, Body: ${response.body}');
    }
  } catch (e, stackTrace) {
    print('Error loading anchors: $e');
    print('Stack trace: $stackTrace');
  }
}

  Future<Map<String, dynamic>> _fetchProfileData() async {
    final userProfileInfo = await getUserProfile(widget.username);
    final followers = await getFollowerCount(widget.username);
    final following = await getFollowingCount(widget.username);
    final pieces = await getPieceCount(widget.username);

    return {
      'userProfileInfo': userProfileInfo,
      'followers': followers,
      'following': following,
      'pieces': pieces,
    };
  }
}