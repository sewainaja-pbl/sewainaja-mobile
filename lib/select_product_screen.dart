import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'data/repositories/item_repository.dart';
import 'data/models/item_model.dart';
import 'models/product.dart';
import 'widgets/custom_app_bar.dart';
import 'widgets/product_card.dart';

class SelectProductScreen extends StatefulWidget {
  final String partnerId;

  const SelectProductScreen({super.key, required this.partnerId});

  @override
  State<SelectProductScreen> createState() => _SelectProductScreenState();
}

class _SelectProductScreenState extends State<SelectProductScreen> {
  late Stream<List<ItemModel>> _itemsStream;
  final ItemRepository _itemRepo = ItemRepository();

  @override
  void initState() {
    super.initState();
    // Mengambil produk milik lawan bicara (bisa disesuaikan jika ingin produk sendiri)
    _itemsStream = _itemRepo.watchItemsByOwner(widget.partnerId);
  }

  void _sendProduct(ItemModel item) {
    // Return a map that represents the item card JSON
    final itemMap = {
      'id': item.id,
      'name': item.name,
      'price': 'Rp${(item.pricePerHour * 24).toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}/hari',
      'image': item.photos.isNotEmpty ? item.photos.first : '',
      'status': item.status,
    };
    final jsonString = json.encode(itemMap);
    Navigator.pop(context, jsonString);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: const CustomAppBar(
        title: 'Pilih Produk',
      ),
      body: StreamBuilder<List<ItemModel>>(
        stream: _itemsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF012D1D)));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada produk yang dapat dipilih.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xFF717973),
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.65, // Adjust this ratio depending on ProductCard height + Kirim button
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final product = items[index];
              return Column(
                children: [
                  Expanded(
                    child: ProductCard(
                      product: ProductData(
                        id: product.id,
                        name: product.name,
                        price: 'Rp${(product.pricePerHour * 24).toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}',
                        rating: product.ownerRating,
                        image: product.photos.isNotEmpty ? product.photos.first : '',
                        originalItem: product,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _sendProduct(product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF012D1D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Kirim',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
