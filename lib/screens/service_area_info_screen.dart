import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ecommerce/services/geo_restriction_service.dart';

class ServiceAreaInfoScreen extends StatefulWidget {
  const ServiceAreaInfoScreen({super.key});

  @override
  State<ServiceAreaInfoScreen> createState() => _ServiceAreaInfoScreenState();
}

class _ServiceAreaInfoScreenState extends State<ServiceAreaInfoScreen> {
  GoogleMapController? _mapController;
  Set<Polygon> _serviceAreas = {};

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    final serviceAreas = GeoRestrictionService.getServiceAreas();
    
    setState(() {
      _serviceAreas = {
        Polygon(
          polygonId: const PolygonId('kinshasa_zone'),
          points: serviceAreas['Kinshasa']!,
          fillColor: Colors.green.withValues(alpha: 0.3),
          strokeColor: Colors.green,
          strokeWidth: 3,
        ),
        Polygon(
          polygonId: const PolygonId('rdc_boundary'),
          points: serviceAreas['RDC']!,
          fillColor: Colors.blue.withValues(alpha: 0.1),
          strokeColor: Colors.blue,
          strokeWidth: 2,
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zones de service'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Carte
          Expanded(
            flex: 2,
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
                    target: GeoRestrictionService.getKinshasaCenter(),
                    zoom: 8,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  polygons: _serviceAreas,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
          ),

          // Informations
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Zones de couverture',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Zone de livraison
                    _buildZoneInfo(
                      'Zone de livraison (Kinshasa)',
                      'Service complet disponible',
                      Colors.green,
                      Icons.check_circle,
                      [
                        'Livraison à domicile',
                        'Suivi en temps réel',
                        'Support client',
                        'Paiement sécurisé',
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Zone RDC
                    _buildZoneInfo(
                      'République Démocratique du Congo',
                      'Service limité',
                      Colors.blue,
                      Icons.info,
                      [
                        'Service en développement',
                        'Bientôt disponible',
                        'Contactez-nous pour plus d\'infos',
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Zone hors service
                    _buildZoneInfo(
                      'Autres pays',
                      'Service non disponible',
                      Colors.red,
                      Icons.cancel,
                      [
                        'Service non disponible',
                        'Nous travaillons à l\'expansion',
                        'Restez connectés pour les mises à jour',
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Informations supplémentaires
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informations importantes :',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Distance maximale de livraison : 50 km\n'
                            '• Délai de livraison : 1-3 heures\n'
                            '• Service disponible 7j/7 de 6h à 22h\n'
                            '• Frais de livraison selon la distance',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
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

  Widget _buildZoneInfo(String title, String status, Color color, IconData icon, List<String> features) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      status,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 2),
            child: Row(
              children: [
                Icon(
                  Icons.fiber_manual_record,
                  size: 6,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feature,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}


