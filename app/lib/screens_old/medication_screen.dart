// ... existing code ...
                final medication = Medication(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  description: descriptionController.text,
                  dosesPerContainer: int.tryParse(dosesController.text) ?? 0,
                  remainingDoses: int.tryParse(dosesController.text) ?? 0,
                  refillThreshold: int.tryParse(thresholdController.text) ?? 5,
                  unit: unitController.text,
                  dosageAmount: int.tryParse(dosageController.text) ?? 1,
                  refillLeadTime: const Duration(days: 7),
                  usageHistory: [],
                  color: Colors.blue,
                );
// ... existing code ...