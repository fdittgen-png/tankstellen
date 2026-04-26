import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/location_search_service.dart';

/// Reusable text field with debounced city autocomplete suggestions.
///
/// Queries [LocationSearchService.searchCities] as the user types (800ms debounce)
/// and shows a dropdown of matching cities. Selecting a city fills the field
/// and calls [onCitySelected] with the resolved coordinates.
class CityAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final LocationSearchService searchService;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final Widget? suffixWidget;
  final void Function(ResolvedLocation city) onCitySelected;
  final VoidCallback onTextChanged;

  const CityAutocompleteField({
    super.key,
    required this.controller,
    required this.searchService,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.suffixWidget,
    required this.onCitySelected,
    required this.onTextChanged,
  });

  @override
  State<CityAutocompleteField> createState() => _CityAutocompleteFieldState();
}

class _CityAutocompleteFieldState extends State<CityAutocompleteField> {
  Timer? _debounce;
  List<ResolvedLocation> _suggestions = [];
  bool _showSuggestions = false;
  bool _isLoading = false;
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _onTextChanged(String value) {
    widget.onTextChanged();
    _debounce?.cancel();

    if (value.trim().length < 2) {
      _removeOverlay();
      return;
    }

    // Only search if it looks like a city name (not digits = postal code)
    if (RegExp(r'^\d+$').hasMatch(value.trim())) {
      _removeOverlay();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 800), () async {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final results = await widget.searchService.searchCities(value.trim());
        if (mounted) {
          _suggestions = results.take(5).toList();
          _showSuggestions = _suggestions.isNotEmpty;
          _isLoading = false;
          if (_showSuggestions && _focusNode.hasFocus) {
            _showOverlay();
          } else {
            _removeOverlay();
          }
        }
      } catch (e, st) {
        debugPrint('Route autocomplete failed: $e\n$st');
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  void _selectCity(ResolvedLocation city) {
    widget.controller.text = city.name;
    widget.onCitySelected(city);
    _removeOverlay();
    _focusNode.unfocus();
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 2),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final city = _suggestions[index];
                  return ListTile(
                    key: ValueKey('city-${city.lat}-${city.lng}-${city.name}'),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: const Icon(Icons.place, size: 16),
                    title:
                        Text(city.name, style: const TextStyle(fontSize: 13)),
                    onTap: () => _selectCity(city),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _showSuggestions = false;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: Icon(widget.prefixIcon, size: 18),
          suffixIcon: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : widget.suffixWidget,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onChanged: _onTextChanged,
        textInputAction: TextInputAction.next,
      ),
    );
  }
}
