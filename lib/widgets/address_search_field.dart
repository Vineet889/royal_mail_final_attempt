import 'package:flutter/material.dart';
import '../services/address_js_interface.dart';

class AddressSearchField extends StatefulWidget {
  final Function(AddressDetails) onAddressSelected;

  const AddressSearchField({
    Key? key,
    required this.onAddressSelected,
  }) : super(key: key);

  @override
  State<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  final _searchController = TextEditingController();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  
  List<AddressSuggestion> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAddressNow();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _initializeAddressNow() async {
    try {
      await AddressJSInterface.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize address search: $e')),
        );
      }
    }
  }

  void _onSearchChanged() async {
    final query = _searchController.text;
    if (query.length < 3) {
      _hideSuggestions();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final suggestions = await AddressJSInterface.findAddresses(query);
      if (mounted) {
        _showSuggestions(suggestions);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching addresses: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search address...',
          suffixIcon: _isLoading 
            ? const CircularProgressIndicator.adaptive() 
            : const Icon(Icons.search),
        ),
      ),
    );
  }

  void _showSuggestions(List<AddressSuggestion> suggestions) {
    _suggestions = suggestions;
    _overlayEntry?.remove();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    _suggestions = [];
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 5),
          child: Material(
            elevation: 4,
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_suggestions[index].text),
                  onTap: () async {
                    final details = await AddressJSInterface.retrieveAddress(_suggestions[index].id);
                    widget.onAddressSelected(details);
                    _hideSuggestions();
                    _searchController.text = _suggestions[index].text;
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ... rest of the widget implementation remains the same ...
} 