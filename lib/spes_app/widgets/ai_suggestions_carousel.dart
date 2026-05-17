import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/prediction_engine.dart';
import '../constants/app_strings.dart';

class AiSuggestionsCarousel extends StatefulWidget {
  final Function(Product) onAdd;
  final String? storeId;

  const AiSuggestionsCarousel({
    super.key,
    required this.onAdd,
    this.storeId,
  });

  @override
  State<AiSuggestionsCarousel> createState() => _AiSuggestionsCarouselState();
}

class _AiSuggestionsCarouselState extends State<AiSuggestionsCarousel> {
  late Future<List<Product>> _suggestionsFuture;

  @override
  void initState() {
    super.initState();
    _refreshSuggestions();
  }

  void _refreshSuggestions() {
    setState(() {
      _suggestionsFuture = PredictionEngine.instance.getReplenishmentSuggestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _suggestionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Center(child: CircularProgressIndicator(color: Colors.indigo)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Nessun suggerimento da mostrare
        }

        final suggestions = snapshot.data!;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.indigo.shade50.withOpacity(0.8),
                Colors.deepPurple.shade50.withOpacity(0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.indigo.shade100, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology, color: Colors.indigo, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppStrings.aiSuggestionsTitle,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        Text(
                          AppStrings.aiSuggestionsSubtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final product = suggestions[index];
                    return _buildSuggestionCard(context, product);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuggestionCard(BuildContext context, Product product) {
    final hasLocalImage = product.imageUrl != null &&
        product.imageUrl!.isNotEmpty &&
        !product.imageUrl!.startsWith('http');

    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade100.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  // Immagine Prodotto
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? (hasLocalImage
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(product.imageUrl!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.fastfood_rounded,
                                      color: Colors.indigo,
                                      size: 24),
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  product.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.fastfood_rounded,
                                      color: Colors.indigo,
                                      size: 24),
                                ),
                              ))
                        : const Icon(Icons.shopping_bag_outlined,
                            color: Colors.indigo, size: 24),
                  ),
                  const SizedBox(width: 10),
                  // Testo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (product.brand != null && product.brand!.isNotEmpty)
                          Text(
                            product.brand!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        const SizedBox(height: 4),
                        // Categoria/Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (product.category ?? 'Generico').replaceFirst('it:', '').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bottone Inserimento Rapido
            Positioned(
              right: 6,
              bottom: 6,
              child: Material(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    widget.onAdd(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${AppStrings.addedSuccess} ${product.name}'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.indigo,
                      ),
                    );
                    _refreshSuggestions(); // Ricarica lo stato
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
