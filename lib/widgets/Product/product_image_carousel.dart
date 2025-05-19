import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:danentang/models/product.dart';
import 'dart:convert'; // For base64Decode
import 'dart:typed_data'; // For Uint8List

class ProductImageCarousel extends StatefulWidget {
  final Product product;
  const ProductImageCarousel({super.key, required this.product});

  @override
  _ProductImageCarouselState createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Helper function to check if a string is a valid Base64 string
  bool _isBase64(String str) {
    try {
      base64Decode(str);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Helper function to build image widget
  Widget _buildImage(String imageUrl, double height, double width, bool isDesktop) {
    // Try decoding as Base64
    if (_isBase64(imageUrl)) {
      try {
        final Uint8List imageBytes = base64Decode(imageUrl);
        return Image.memory(
          imageBytes,
          height: height,
          width: width,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[200], // Light gray for error background
            height: height,
            width: width,
            child: const Icon(
              Icons.broken_image,
              size: 50,
              color: Colors.grey, // Gray for error icon
            ),
          ),
        );
      } catch (e) {
        print('Error decoding Base64 image: $e');
      }
    }

    // Fallback to network image if not Base64
    return Image.network(
      imageUrl,
      height: height,
      width: width,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[200], // Light gray for error background
        height: height,
        width: width,
        child: const Icon(
          Icons.broken_image,
          size: 50,
          color: Colors.grey, // Gray for error icon
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    // Define color scheme
    const primaryColor = Color(0xFF1E90FF); // Dodger Blue (used sparingly)
    const lightBlueColor = Color(0xFF87CEEB); // Light Sky Blue (subtle accents)
    const accentColor = Color(0xFF2E2E2E); // Dark gray for emphasis
    const backgroundColor = Colors.white; // White background

    return Container(
      color: backgroundColor, // White background for the carousel
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: isDesktop ? 400 : 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: lightBlueColor.withOpacity(0.3), // Light blue border
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                ),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.product.images.length,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12), // Match container border radius
                      child: _buildImage(
                        widget.product.images[index].url,
                        isDesktop ? 400 : 250,
                        double.infinity,
                        isDesktop,
                      ),
                    );
                  },
                ),
              ),

            ],
          ),
          if (widget.product.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: widget.product.images.length,
                effect: WormEffect(
                  dotHeight: 10,
                  dotWidth: 10,
                  activeDotColor: accentColor, // Dark gray for active dot
                  dotColor: lightBlueColor.withOpacity(0.3), // Light blue for inactive dots
                  spacing: 8,
                ),
              ),
            ),
          if (widget.product.images.length > 1)
            Padding(
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.product.images.asMap().entries.skip(1).map(
                        (entry) {
                      int index = entry.key;
                      ProductImage image = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            _pageController.jumpToPage(index);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: lightBlueColor.withOpacity(0.3), // Light blue border for thumbnails
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildImage(
                                image.url,
                                isDesktop ? 80 : 50,
                                80,
                                isDesktop,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}