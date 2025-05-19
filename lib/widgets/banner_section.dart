import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel_slider;

class BannerSection extends StatelessWidget {
  final bool isWeb;
  final double screenWidth;

  const BannerSection({
    Key? key,
    required this.isWeb,
    required this.screenWidth,
  }) : super(key: key);

  static const List<String> slideshowImages = [
    'assets/images/bn1.jpg',
    'assets/images/bn2.jpg',
    'assets/images/bn3.jpg',
  ];

  static const String voucherImage1 = 'assets/images/cd1.jpg';
  static const String voucherImage2 = 'assets/images/cd2.jpg';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
      decoration: BoxDecoration(
        border: const Border(
          top: BorderSide(color: Colors.transparent, width: 0),
          bottom: BorderSide(color: Colors.transparent, width: 0),
          left: BorderSide(color: Colors.transparent, width: 0),
          right: BorderSide(color: Colors.transparent, width: 0),
        ),
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade400.withOpacity(0.9),
            Colors.white.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: isWeb ? _buildWebBanner(context) : _buildMobileBanner(context),
    );
  }

  Widget _buildMobileBanner(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.transparent, width: 0),
        ),
        child: SizedBox(
          height: screenWidth * 0.5, // Adjusted for a more square look
          child: Stack(
            children: [
              carousel_slider.CarouselSlider(
                options: carousel_slider.CarouselOptions(
                  height: screenWidth * 0.5,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 4),
                  autoPlayAnimationDuration: const Duration(milliseconds: 1000),
                  autoPlayCurve: Curves.easeInOutCubic,
                  enlargeCenterPage: true,
                  viewportFraction: 1.0,
                  aspectRatio: 1.0, // Changed to 1:1 for a square appearance
                  enableInfiniteScroll: true,
                  pageSnapping: true,
                ),
                items: slideshowImages.map((imagePath) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.transparent, width: 0),
                      image: DecorationImage(
                        image: AssetImage(imagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }).toList(),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebBanner(BuildContext context) {
    // Calculate a responsive height based on screen width
    final bannerHeight = screenWidth * 0.3; // Adjust multiplier for desired height

    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.transparent, width: 0),
        ),
        child: SizedBox(
          height: bannerHeight, // Use calculated height
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: carousel_slider.CarouselSlider(
                  options: carousel_slider.CarouselOptions(
                    height: bannerHeight,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 4),
                    autoPlayAnimationDuration: const Duration(milliseconds: 1000),
                    autoPlayCurve: Curves.easeInOutCubic,
                    enlargeCenterPage: true,
                    viewportFraction: 1.0,
                    aspectRatio: 4 / 3, // Adjusted for a more square look
                    enableInfiniteScroll: true,
                    pageSnapping: true,
                  ),
                  items: slideshowImages.map((imagePath) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.transparent, width: 0),
                        image: DecorationImage(
                          image: AssetImage(imagePath),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildVoucherBanner(
                      context,
                      voucherImage1,
                      "",
                      "",
                    ),
                    _buildVoucherBanner(
                      context,
                      voucherImage2,
                      "",
                      "",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherBanner(
      BuildContext context,
      String imagePath,
      String title,
      String subtitle,
      ) {
    return Expanded(
      child: GestureDetector(
        child: Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.1),
                BlendMode.darken,
              ),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.015,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Colors.black87,
                        offset: Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: screenWidth * 0.012,
                    color: Colors.white70,
                    shadows: const [
                      Shadow(
                        color: Colors.black87,
                        offset: Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}