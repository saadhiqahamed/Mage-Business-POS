import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/providers/product_provider.dart';
import '../../../core/database/database_provider.dart';
import 'product_barcode_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  bool _isScanning = false;

  void _onBarcodeDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;
    setState(() => _isScanning = false);

    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first.rawValue ?? "Unknown";
      final db = ref.read(databaseProvider);
      final existingProduct = await findProductByBarcode(db, barcode);
      
      if (mounted) {
        if (existingProduct != null) {
          _showUpdateStockDialog(existingProduct.id, existingProduct.name, existingProduct.currentStock);
        } else {
          _showNewProductDialog(customBarcode: barcode);
        }
      }
    }
  }

  void _showUpdateStockDialog(String id, String name, int currentStock) {
    final stockController = TextEditingController(text: currentStock.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Update Stock', style: const TextStyle(color: Color(0xFF1A237E))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: $name', style: const TextStyle(color: Color(0xFFD6A51D), fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: stockController,
              decoration: const InputDecoration(labelText: 'New Stock Level', labelStyle: TextStyle(color: Colors.grey)),
              style: const TextStyle(color: Color(0xFF1A237E)),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD6A51D), foregroundColor: Colors.black),
            onPressed: () {
              final newStock = int.tryParse(stockController.text) ?? currentStock;
              ref.read(productRepositoryProvider).updateStock(id, newStock);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock Updated')));
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showNewProductDialog({String? customBarcode}) {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final buyingController = TextEditingController();
    final sellingController = TextEditingController();
    final stockController = TextEditingController();
    final supNameCtrl = TextEditingController();
    final supContactCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('New Product', style: TextStyle(color: Color(0xFF1A237E))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (customBarcode != null) 
                Text('Scanned Barcode: $customBarcode', style: const TextStyle(color: Color(0xFFD6A51D))),
              _buildField(nameController, 'Product Name'),
              _buildField(categoryController, 'Category (e.g. Drinks, Snacks)'),
              _buildField(buyingController, 'Cost Price (Rs)', isNum: true),
              _buildField(sellingController, 'Selling Price (Rs)', isNum: true),
              _buildField(stockController, 'Initial Stock Level', isNum: true),
              _buildField(supNameCtrl, 'Supplier Name (Optional)'),
              _buildField(supContactCtrl, 'Supplier Contact (Optional)'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD6A51D), foregroundColor: Colors.black),
            onPressed: () async {
              final name = nameController.text;
              final cat = categoryController.text;
              final buying = ((double.tryParse(buyingController.text) ?? 0) * 100).toInt();
              final selling = ((double.tryParse(sellingController.text) ?? 0) * 100).toInt();
              final stock = int.tryParse(stockController.text) ?? 0;

              if (name.isNotEmpty) {
                await ref.read(productRepositoryProvider).addProduct(
                  name: name,
                  categoryId: cat.isEmpty ? null : cat,
                  buyingPrice: buying,
                  sellingPrice: selling,
                  initialStock: stock,
                  customBarcode: customBarcode,
                  supplierName: supNameCtrl.text,
                  supplierContact: supContactCtrl.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product Added')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, {bool isNum = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Color(0xFF1A237E)),
        keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD6A51D))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Stock & Inventory', style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFFD6A51D), size: 28),
            tooltip: 'Add Product Manually',
            onPressed: () => _showNewProductDialog(),
          ).animate().scale(),
        ],
      ),
      body: _isScanning
          ? MobileScanner(onDetect: _onBarcodeDetect).animate().fade()
          : productsAsync.when(
              data: (products) => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Row(
                        children: [
                          Expanded(child: Text(p.name, style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold))),
                          if (p.categoryId != null && p.categoryId!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Color(0xFF1A237E).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(p.categoryId!, style: const TextStyle(fontSize: 10, color: Color(0xFFD6A51D))),
                            ),
                        ],
                      ),
                      subtitle: Text('Stock: ${p.currentStock} | Price: Rs ${(p.sellingPrice / 100).toStringAsFixed(2)}', 
                                     style: const TextStyle(color: Colors.grey)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.qr_code, color: Color(0xFF1A237E).withOpacity(0.7)),
                            onPressed: () {
                              if (p.barcode != null) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ProductBarcodeScreen(
                                  productName: p.name,
                                  barcode: p.barcode!,
                                  sellingPriceCents: p.sellingPrice,
                                )));
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFFD6A51D)),
                            onPressed: () => _showUpdateStockDialog(p.id, p.name, p.currentStock),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade().slideX();
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFD6A51D))),
              error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _isScanning = !_isScanning),
        backgroundColor: _isScanning ? Colors.redAccent : const Color(0xFFD6A51D),
        foregroundColor: Colors.black,
        icon: Icon(_isScanning ? Icons.close : Icons.qr_code_scanner),
        label: Text(_isScanning ? 'Cancel' : 'Scan Barcode', style: const TextStyle(fontWeight: FontWeight.bold)),
      ).animate().scale(),
    );
  }
}
