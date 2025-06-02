import 'package:flutter/material.dart';

/// Documentation Guide for AetherBloom Project
/// 
/// This file provides examples of properly documented code for the
/// AetherBloom project. It demonstrates best practices for documenting
/// classes, methods, and properties in Flutter/Dart.

/// Class-level documentation should describe the purpose and responsibility of the class.
/// Include information about:
/// - What the class represents or does
/// - How it integrates with other components
/// - Any important implementation details
class ExampleService {
  // Constants should have a brief comment explaining their purpose or value
  static const String _storageKey = 'example_key'; // Key for shared preferences storage
  
  // Singleton pattern implementation
  static final ExampleService _instance = ExampleService._();
  
  /// Factory constructor for accessing the singleton instance
  /// Use triple-slash comments for public API documentation
  factory ExampleService() => _instance;
  
  // Private variables should have comments explaining their purpose
  final List<String> _items = []; // Cached list of items
  bool _isInitialized = false; // Tracks initialization state
  
  /// Private constructor for singleton pattern
  ExampleService._();
  
  /// Initializes the service by loading data from storage
  /// 
  /// Method documentation should explain:
  /// - What the method does
  /// - Parameters and return values
  /// - Side effects or exceptions that might occur
  /// 
  /// For async methods, mention if they must be awaited
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Load data from persistent storage
    await _loadData();
    _isInitialized = true;
  }
  
  /// Loads previously stored data from shared preferences
  /// 
  /// Private methods should also be documented, especially
  /// if they contain complex logic or important operations
  Future<void> _loadData() async {
    // Implementation details...
  }
  
  /// Adds a new item to the collection
  /// 
  /// @param item The item to add
  /// @return True if the item was added, false if it already existed
  Future<bool> addItem(String item) async {
    if (_items.contains(item)) {
      return false;
    }
    
    _items.add(item);
    await _saveData();
    return true;
  }
  
  /// Saves current data to persistent storage
  Future<void> _saveData() async {
    // Implementation details...
  }
  
  /// Returns a read-only list of all items
  /// 
  /// Getter documentation should explain what is returned
  /// and any relevant details about the returned data
  List<String> get items => List.unmodifiable(_items);
}

/// Model classes should document their properties and purpose
/// 
/// Include information about:
/// - What the model represents
/// - How it's used in the application
/// - Special behaviors or validations
class ExampleModel {
  final String id;       // Unique identifier
  final String name;     // Display name
  final int quantity;    // Current inventory count
  final bool isActive;   // Whether this item is currently active
  
  /// Creates a new example model with the required properties
  /// 
  /// Constructor documentation should explain required and
  /// optional parameters, as well as any validation logic
  const ExampleModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.isActive,
  });
  
  /// Creates a copy of this model with updated properties
  /// 
  /// Any parameter not provided will keep its original value
  ExampleModel copyWith({
    String? id,
    String? name,
    int? quantity,
    bool? isActive,
  }) {
    return ExampleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      isActive: isActive ?? this.isActive,
    );
  }
  
  /// Converts the model to a JSON-serializable map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'isActive': isActive,
    };
  }
  
  /// Creates a model instance from JSON data
  factory ExampleModel.fromJson(Map<String, dynamic> json) {
    return ExampleModel(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      isActive: json['isActive'] as bool,
    );
  }
  
  /// Computed property that determines if inventory is low
  /// 
  /// Documentation for getters should explain the calculation
  /// or logic used and what the return value represents
  bool get isLowQuantity => quantity < 10;
  
  /// Returns a formatted string representation of the model
  @override
  String toString() => '$name (Qty: $quantity)';
}

/// Screen widgets should document their purpose and functionality
/// 
/// Include information about:
/// - What the screen displays
/// - User interactions it supports
/// - Data it consumes or produces
class ExampleScreen extends StatefulWidget {
  final String title; // Screen title to display
  
  /// Creates a new example screen
  const ExampleScreen({
    Key? key,
    required this.title,
  }) : super(key: key);
  
  @override
  _ExampleScreenState createState() => _ExampleScreenState();
}

/// State class for the example screen
/// 
/// Documents the internal state and lifecycle behavior
class _ExampleScreenState extends State<ExampleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  
  bool _isLoading = false; // Tracks data loading state
  
  /// Initializes the screen state
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  /// Loads initial data for the screen
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    // Load data from services...
    
    setState(() {
      _isLoading = false;
    });
  }
  
  /// Cleans up resources when the screen is disposed
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
  
  /// Submits the form data
  /// 
  /// Validates input and processes the submission
  void _onSubmit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    // Process the submitted data...
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }
  
  /// Builds the form widget
  /// 
  /// Helper methods for building UI components should
  /// be documented to explain what they construct
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Input',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          ElevatedButton(
            onPressed: _onSubmit,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

/// Enum values should have documentation explaining each option
enum ExampleStatus {
  /// Item is active and available
  active,
  
  /// Item is temporarily unavailable
  inactive,
  
  /// Item has been permanently removed
  deleted,
}

/// Extension methods should document what functionality they add
extension ExampleStatusExtension on ExampleStatus {
  /// Returns a user-friendly string representation of the status
  String get displayName {
    switch (this) {
      case ExampleStatus.active:
        return 'Active';
      case ExampleStatus.inactive:
        return 'Inactive';
      case ExampleStatus.deleted:
        return 'Deleted';
    }
  }
  
  /// Returns the color associated with this status
  Color get color {
    switch (this) {
      case ExampleStatus.active:
        return Colors.green;
      case ExampleStatus.inactive:
        return Colors.orange;
      case ExampleStatus.deleted:
        return Colors.red;
    }
  }
} 