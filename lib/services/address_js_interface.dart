import 'dart:async';
import 'package:flutter/services.dart';

class AddressJSInterface {
  static const platform = MethodChannel('address_now_channel');
  static bool _isInitialized = false;
  static Completer<void>? _initializer;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initializer != null) return _initializer!.future;

    _initializer = Completer<void>();
    try {
      await platform.invokeMethod('initializeAddressNow', {
        'apiKey': 'tx12-yy85-mb16-yu94'
      });
      _isInitialized = true;
      _initializer!.complete();
    } catch (e) {
      _initializer!.completeError(e);
      _initializer = null;
      throw Exception('Failed to initialize AddressNow: $e');
    }
  }

  static Future<List<AddressSuggestion>> findAddresses(String search) async {
    await initialize();
    try {
      final result = await platform.invokeMethod('findAddresses', {
        'search': search
      });
      
      return (result as List)
          .map((item) => AddressSuggestion.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw Exception('Error searching addresses: $e');
    }
  }

  static Future<AddressDetails> retrieveAddress(String id) async {
    await initialize();
    try {
      final result = await platform.invokeMethod('retrieveAddress', {
        'id': id
      });
      
      return AddressDetails.fromJson(Map<String, dynamic>.from(result));
    } catch (e) {
      throw Exception('Error retrieving address: $e');
    }
  }
}

class AddressSuggestion {
  final String id;
  final String text;

  AddressSuggestion({
    required this.id,
    required this.text,
  });

  factory AddressSuggestion.fromJson(Map<String, dynamic> json) {
    return AddressSuggestion(
      id: json['id'],
      text: json['text'],
    );
  }
}

class AddressDetails {
  final String line1;
  final String line2;
  final String city;
  final String postcode;

  AddressDetails({
    required this.line1,
    required this.line2,
    required this.city,
    required this.postcode,
  });

  factory AddressDetails.fromJson(Map<String, dynamic> json) {
    return AddressDetails(
      line1: json['line1'] ?? '',
      line2: json['line2'] ?? '',
      city: json['city'] ?? '',
      postcode: json['postcode'] ?? '',
    );
  }
} 