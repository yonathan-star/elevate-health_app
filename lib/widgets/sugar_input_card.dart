import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sugar_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SugarInputCard extends StatefulWidget {
  const SugarInputCard({super.key});

  @override
  State<SugarInputCard> createState() => _SugarInputCardState();
}

class _SugarInputCardState extends State<SugarInputCard> {
  final _sugarController = TextEditingController();
  String _selectedCategory = 'Added Sugar';

  final List<String> _categories = [
    'Added Sugar',
    'Natural Sugar',
    'Hidden Sugar',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<SugarProvider>(
      builder: (context, sugarProvider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Add Sugar Intake',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F5132),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sugarController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Sugar (grams)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2F5132),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.qr_code_scanner,
                      color: Color(0xFF2F5132),
                    ),
                    onPressed: () async {
                      final code = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const _BarcodeScannerScreen(),
                        ),
                      );
                      if (code != null && code is String) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Barcode Scanned'),
                            content: Text(
                              'Barcode: $code\nEnter sugar value manually.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2F5132),
                      width: 2,
                    ),
                  ),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final sugar = double.tryParse(_sugarController.text);
                    if (sugar != null && sugar > 0) {
                      await sugarProvider.addSugarEntry(
                        sugar,
                        _selectedCategory,
                      );
                      _sugarController.clear();
                      FocusScope.of(context).unfocus();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sugar intake logged successfully!'),
                          backgroundColor: Color(0xFF6ABF69),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid sugar amount'),
                          backgroundColor: Color(0xFFF2A93B),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F5132),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Entry',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BarcodeScannerScreen extends StatelessWidget {
  const _BarcodeScannerScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F5132),
        title: const Text(
          'Scan Barcode',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          if (barcode.rawValue != null) {
            Navigator.pop(context, barcode.rawValue);
          }
        },
      ),
    );
  }
}
