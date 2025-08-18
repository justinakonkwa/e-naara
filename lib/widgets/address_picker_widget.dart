import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ecommerce/services/geocoding_service.dart';
import 'package:ecommerce/services/geo_restriction_service.dart';

class AddressPickerWidget extends StatefulWidget {
  final String? initialAddress;
  final Function(String address, LatLng position) onAddressSelected;

  const AddressPickerWidget({
    super.key,
    this.initialAddress,
    required this.onAddressSelected,
  });

  @override
  State<AddressPickerWidget> createState() => _AddressPickerWidgetState();
}

class _AddressPickerWidgetState extends State<AddressPickerWidget> {
  GoogleMapController? _mapController;
  LatLng _selectedPosition = GeoRestrictionService.getKinshasaCenter(); // Kinshasa par défaut
  String _selectedAddress = '';
  bool _isLoading = true;
  Set<Marker> _markers = {};
  Set<Polygon> _serviceAreas = {};

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Essayer de récupérer la position actuelle
      final position = await _getCurrentLocation();
      if (position != null) {
        setState(() {
          _selectedPosition = position;
        });
        
        // Géocoder la position pour obtenir l'adresse
        final address = await GeocodingService.reverseGeocode(position);
        if (address != null) {
          setState(() {
            _selectedAddress = address;
          });
        }
      } else if (widget.initialAddress != null) {
        // Géocoder l'adresse initiale
        final position = await GeocodingService.geocodeAddress(widget.initialAddress!);
        if (position != null) {
          setState(() {
            _selectedPosition = position;
            _selectedAddress = widget.initialAddress!;
          });
        }
      }
    } catch (e) {
      print('❌ [ADDRESS_PICKER] Erreur initialisation: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      _updateMarkers();
    }
  }

  Future<LatLng?> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('❌ [ADDRESS_PICKER] Erreur position actuelle: $e');
      return null;
    }
  }

  void _updateMarkers() {
    // Créer les zones de service
    final serviceAreas = GeoRestrictionService.getServiceAreas();
    
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: _selectedPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Adresse sélectionnée',
            snippet: _selectedAddress.isNotEmpty ? _selectedAddress : 'Appuyez pour sélectionner',
          ),
        ),
      };

      _serviceAreas = {
        Polygon(
          polygonId: const PolygonId('kinshasa_zone'),
          points: serviceAreas['Kinshasa']!,
          fillColor: Colors.green.withValues(alpha: 0.2),
          strokeColor: Colors.green,
          strokeWidth: 2,
        ),
        Polygon(
          polygonId: const PolygonId('rdc_boundary'),
          points: serviceAreas['RDC']!,
          fillColor: Colors.blue.withValues(alpha: 0.1),
          strokeColor: Colors.blue,
          strokeWidth: 1,
        ),
      };
    });
  }

  Future<void> _onMapTap(LatLng position) async {
    // Vérifier si la position est dans la zone de service
    if (!GeoRestrictionService.isInDeliveryZone(position)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(GeoRestrictionService.getOutOfServiceMessage(position)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _selectedPosition = position;
    });

    // Géocoder la nouvelle position
    final address = await GeocodingService.reverseGeocode(position);
    if (address != null) {
      setState(() {
        _selectedAddress = address;
      });
    }

    _updateMarkers();
  }

  void _confirmSelection() {
    if (_selectedAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une adresse sur la carte'),
        ),
      );
      return;
    }

    // Vérifier si l'adresse est dans la zone de service
    if (!GeoRestrictionService.isInDeliveryZone(_selectedPosition)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(GeoRestrictionService.getOutOfServiceMessage(_selectedPosition)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    widget.onAddressSelected(_selectedAddress, _selectedPosition);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner l\'adresse'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () async {
              final position = await _getCurrentLocation();
              if (position != null && _mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(position, 15),
                );
                _onMapTap(position);
              }
            },
            tooltip: 'Ma position actuelle',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Carte
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                                              child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _selectedPosition,
                            zoom: 10,
                          ),
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                          onTap: _onMapTap,
                          markers: _markers,
                          polygons: _serviceAreas,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                        ),
                    ),
                  ),
                ),

                // Informations et boutons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adresse sélectionnée:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedAddress.isNotEmpty 
                                    ? _selectedAddress 
                                    : 'Appuyez sur la carte pour sélectionner une adresse',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Légende des zones
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Zones de service :',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    border: Border.all(color: Colors.green),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Zone de livraison (Kinshasa)',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    border: Border.all(color: Colors.blue),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'RDC (service limité)',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Annuler'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _selectedAddress.isNotEmpty ? _confirmSelection : null,
                              child: const Text('Confirmer'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
