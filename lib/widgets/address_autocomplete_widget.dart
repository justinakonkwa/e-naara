import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ecommerce/services/places_autocomplete_service.dart';
import 'package:ecommerce/services/geo_restriction_service.dart';

class AddressAutocompleteWidget extends StatefulWidget {
  final Function(String address, LatLng position) onAddressSelected;
  final String? initialValue;
  final String hintText;

  const AddressAutocompleteWidget({
    super.key,
    required this.onAddressSelected,
    this.initialValue,
    this.hintText = 'Entrez votre adresse de livraison',
  });

  @override
  State<AddressAutocompleteWidget> createState() => _AddressAutocompleteWidgetState();
}

class _AddressAutocompleteWidgetState extends State<AddressAutocompleteWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  List<PlacePrediction> _predictions = [];
  List<String> _localSuggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue ?? '';
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _controller.text.isNotEmpty) {
      _searchAddresses(_controller.text);
    } else {
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  Future<void> _searchAddresses(String input) async {
    if (input.length < 2) {
      setState(() {
        _predictions = [];
        _localSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showSuggestions = true;
    });

    try {
      // Recherche Google Places API
      final predictions = await PlacesAutocompleteService.getPlacePredictions(input);
      
      // Recherche locale
      final localSuggestions = PlacesAutocompleteService.getLocalSuggestions(input);

      setState(() {
        _predictions = predictions;
        _localSuggestions = localSuggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onPredictionSelected(PlacePrediction prediction) async {
    setState(() {
      _isLoading = true;
      _showSuggestions = false;
    });

    try {
      final details = await PlacesAutocompleteService.getPlaceDetails(prediction.placeId);
      
      if (details != null && details.latitude != null && details.longitude != null) {
        final position = LatLng(details.latitude!, details.longitude!);
        
        // Validation intelligente de l'adresse
        final isValidAddress = GeoRestrictionService.validateKinshasaAddress(
          details.formattedAddress, 
          position
        );
        
        if (!isValidAddress) {
          final errorMessage = GeoRestrictionService.getAddressValidationMessage(
            details.formattedAddress, 
            position
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        _controller.text = details.formattedAddress;
        widget.onAddressSelected(details.formattedAddress, position);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la récupération de l\'adresse'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _onLocalSuggestionSelected(String suggestion) {
    _controller.text = suggestion;
    setState(() {
      _showSuggestions = false;
    });
    
    // Pour les suggestions locales, on utilise le centre de Kinshasa
    // L'utilisateur pourra ajuster la position sur la carte
    final position = GeoRestrictionService.getKinshasaCenter();
    widget.onAddressSelected(suggestion, position);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Champ de saisie avec autocomplétion
        Container(
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
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.location_on),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _predictions = [];
                          _localSuggestions = [];
                          _showSuggestions = false;
                        });
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              _searchAddresses(value);
            },
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                final position = GeoRestrictionService.getKinshasaCenter();
                widget.onAddressSelected(value, position);
              }
            },
          ),
        ),

        // Suggestions d'adresses
        if (_showSuggestions && (_predictions.isNotEmpty || _localSuggestions.isNotEmpty))
          Container(
            margin: const EdgeInsets.only(top: 8),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Suggestions Google Places
                if (_predictions.isNotEmpty) ...[
                  _buildSectionHeader('Suggestions Google', Icons.search),
                  ..._predictions.map((prediction) => _buildPredictionTile(prediction)),
                ],

                // Suggestions locales
                if (_localSuggestions.isNotEmpty) ...[
                  if (_predictions.isNotEmpty) const Divider(height: 1),
                  _buildSectionHeader('Adresses populaires', Icons.star),
                  ..._localSuggestions.map((suggestion) => _buildLocalSuggestionTile(suggestion)),
                ],
              ],
            ),
          ),

        // Indicateur de zone de service
        if (_controller.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: GeoRestrictionService.isAddressInKinshasa(_controller.text)
                  ? Colors.green.withValues(alpha: 0.1)
                  : theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: GeoRestrictionService.isAddressInKinshasa(_controller.text)
                    ? Colors.green
                    : theme.colorScheme.primary,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  GeoRestrictionService.isAddressInKinshasa(_controller.text)
                      ? Icons.check_circle
                      : Icons.info_outline,
                  size: 16,
                  color: GeoRestrictionService.isAddressInKinshasa(_controller.text)
                      ? Colors.green
                      : theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    GeoRestrictionService.isAddressInKinshasa(_controller.text)
                        ? '✅ Adresse acceptée - Zone de livraison Kinshasa'
                        : 'Service disponible uniquement à Kinshasa',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: GeoRestrictionService.isAddressInKinshasa(_controller.text)
                          ? Colors.green
                          : theme.colorScheme.onPrimaryContainer,
                      fontWeight: GeoRestrictionService.isAddressInKinshasa(_controller.text)
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionTile(PlacePrediction prediction) {
    final theme = Theme.of(context);
    
    return ListTile(
      dense: true,
      leading: const Icon(Icons.location_on, size: 20),
      title: Text(
        prediction.mainText,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        prediction.secondaryText,
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _onPredictionSelected(prediction),
    );
  }

  Widget _buildLocalSuggestionTile(String suggestion) {
    final theme = Theme.of(context);
    
    return ListTile(
      dense: true,
      leading: const Icon(Icons.star, size: 20, color: Colors.amber),
      title: Text(
        suggestion,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: const Text('Adresse populaire'),
      onTap: () => _onLocalSuggestionSelected(suggestion),
    );
  }
}
