// lib/pages/conventions/convention_map_page.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as location_package;
import 'package:geocoding/geocoding.dart';

import 'package:kipik_v5/locator.dart';
import 'package:kipik_v5/models/convention.dart';
import 'package:kipik_v5/services/convention/firebase_convention_service.dart';
import 'package:kipik_v5/widgets/common/app_bars/custom_app_bar_kipik.dart';
import 'package:kipik_v5/widgets/common/drawers/drawer_factory.dart';
import 'package:kipik_v5/widgets/common/buttons/tattoo_assistant_button.dart';
import 'package:kipik_v5/theme/kipik_theme.dart';

class ConventionMapPage extends StatefulWidget {
  const ConventionMapPage({Key? key}) : super(key: key);

  @override
  State<ConventionMapPage> createState() => _ConventionMapPageState();
}

class _ConventionMapPageState extends State<ConventionMapPage> {
  final FirebaseConventionService _service = locator<FirebaseConventionService>();
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  
  // Utiliser un alias pour éviter les conflits avec d'autres classes Location
  late location_package.Location _locationService;
  
  List<Convention> _conventions = [];
  final Set<Marker> _markers = {};
  final Map<String, LatLng> _locationCache = {};
  
  // Fond d'écran
  final String _backgroundImage = 'assets/background_charbon.png';

  bool _serviceEnabled = false;
  location_package.PermissionStatus _permissionStatus = location_package.PermissionStatus.denied;
  bool _isLoading = true;
  String? _centerId;

  @override
  void initState() {
    super.initState();
    // Initialiser le service de localisation dans initState
    _locationService = location_package.Location();
    _initLocation();
    _loadConventions();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic> && args.containsKey('centerId')) {
      _centerId = args['centerId'] as String;
    }
  }

  Future<void> _initLocation() async {
    _serviceEnabled = await _locationService.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationService.requestService();
      if (!_serviceEnabled) return;
    }

    _permissionStatus = await _locationService.hasPermission();
    if (_permissionStatus == location_package.PermissionStatus.denied) {
      _permissionStatus = await _locationService.requestPermission();
      if (_permissionStatus != location_package.PermissionStatus.granted) return;
    }

    setState(() {});
  }

  Future<LatLng?> _getCoordinatesFromAddress(String address) async {
    if (_locationCache.containsKey(address)) {
      return _locationCache[address];
    }
    
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);
        
        _locationCache[address] = latLng;
        
        return latLng;
      }
    } catch (e) {
      print('Erreur de géocodage pour $address: $e');
    }
    
    return null;
  }

  Future<void> _loadConventions() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final list = await _service.fetchConventions();
      
      final markers = <Marker>{};
      
      for (final convention in list) {
        LatLng? position;
        
        if (convention.latitude != null && convention.longitude != null) {
          position = LatLng(convention.latitude!, convention.longitude!);
        } else {
          position = await _getCoordinatesFromAddress(convention.location);
        }
        
        if (position != null) {
          final marker = Marker(
            markerId: MarkerId(convention.id),
            position: position,
            infoWindow: InfoWindow(
              title: convention.title,
              snippet: _formatDateRange(convention.start, convention.end),
              onTap: () {
                _showConventionDetails(convention);
              },
            ),
            icon: convention.isPremium
                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose)
                : BitmapDescriptor.defaultMarker,
          );
          
          markers.add(marker);
        }
      }
      
      setState(() {
        _conventions = list;
        _markers.clear();
        _markers.addAll(markers);
        _isLoading = false;
      });
      
      if (_centerId != null) {
        _centerOnConvention(_centerId!);
      }
      
    } catch (e) {
      print('Erreur lors du chargement des conventions: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des conventions. Veuillez réessayer.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _centerOnConvention(String conventionId) async {
    Convention? conventionToCenter;
    
    try {
      conventionToCenter = _conventions.firstWhere(
        (c) => c.id == conventionId,
      );
    } catch (e) {
      if (_conventions.isNotEmpty) {
        conventionToCenter = _conventions.first;
      } else {
        return;
      }
    }
    
    if (conventionToCenter == null) return;
    
    LatLng? position;
    if (conventionToCenter.latitude != null && conventionToCenter.longitude != null) {
      position = LatLng(conventionToCenter.latitude!, conventionToCenter.longitude!);
    } else {
      position = await _getCoordinatesFromAddress(conventionToCenter.location);
    }
    
    if (position != null) {
      final controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(position, 10.0));
    }
  }
  
  String _formatDateRange(DateTime start, DateTime end) {
    final startFormat = '${start.day}/${start.month}/${start.year}';
    final endFormat = '${end.day}/${end.month}/${end.year}';
    return '$startFormat → $endFormat';
  }
  
  void _showConventionDetails(Convention convention) {
    Navigator.pushNamed(
      context,
      '/conventions',
      arguments: {'selectedConventionId': convention.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: DrawerFactory.of(context),
      appBar: const CustomAppBarKipik(
        title: 'Carte des Conventions',
        showBackButton: true,
        showBurger: true,
        showNotificationIcon: false,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'refreshBtn',
            onPressed: _loadConventions,
            backgroundColor: KipikTheme.rouge,
            mini: true,
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
          const SizedBox(height: 10),
          TattooAssistantButton(
            allowImageGeneration: false,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(_backgroundImage, fit: BoxFit.cover),
          
          SafeArea(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: KipikTheme.rouge),
                  )
                : GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(46.5, 2.5), // centre approximatif France
                      zoom: 5.2,
                    ),
                    markers: _markers,
                    onMapCreated: (controller) => _controller.complete(controller),
                    myLocationEnabled: _permissionStatus == location_package.PermissionStatus.granted,
                    myLocationButtonEnabled: _permissionStatus == location_package.PermissionStatus.granted,
                    mapType: MapType.normal,
                  ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: KipikTheme.rouge),
                    const SizedBox(height: 16),
                    const Text(
                      'Chargement des conventions...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}