import 'package:http/http.dart' as http;
import 'dart:convert';

/// A service that handles communication with the web server API
class ApiService {
  /// The base URL for the Flask API server
  final String serverUrl = 'http://localhost:5000';
  
  /// Sends inhaler usage data to the web server
  /// 
  /// Returns true if the data was successfully sent
  Future<bool> sendUsageData(int count, String notes) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/updateData'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'inhalerUseCount': count,
          'notes': notes,
        }),
      );
      
      print('Server response: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending data to server: $e');
      return false;
    }
  }
} 