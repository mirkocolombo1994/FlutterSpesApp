import 'package:flutter/material.dart';
import 'dart:io';
import '../models/product.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Header
            if (product.imageUrl != null && File(product.imageUrl!).existsSync())
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(product.imageUrl!)),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.blueGrey.shade50,
                child: const Icon(Icons.inventory, size: 100, color: Colors.blueGrey),
              ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey.shade900,
                              ),
                        ),
                      ),
                      if (product.category != null)
                        Chip(
                          label: Text(product.category!),
                          backgroundColor: Colors.blueGrey.shade100,
                          labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  if (product.brand != null && product.brand!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        product.brand!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.blueGrey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  
                  // Product Info Section
                  _buildInfoSection(context, 'Dettagli Prodotto'),
                  
                  _buildInfoRow(context, Icons.qr_code_scanner, 'Barcode', product.barcode),
                  
                  if (product.weight != null)
                    _buildInfoRow(
                      context,
                      Icons.scale,
                      'Formato',
                      '${product.weight} ${product.weightUnit ?? ""}',
                    ),
                  
                  if (product.pricePerKg != null && product.pricePerKg! > 0)
                    _buildInfoRow(
                      context,
                      Icons.euro,
                      'Prezzo di Riferimento',
                      '${product.pricePerKg!.toStringAsFixed(2)} €/unità',
                    ),
                  
                  if (product.description != null && product.description!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildInfoSection(context, 'Descrizione'),
                    const SizedBox(height: 8),
                    Text(
                      product.description!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.blueGrey.shade800,
                            height: 1.5,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey.shade400,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.blueGrey.shade700),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey.shade500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
