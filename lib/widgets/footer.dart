import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF171F32), // Darker background tone
      padding: EdgeInsets.symmetric(vertical: 30, horizontal: 32), // Increased vertical padding for better spacing
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Evenly distribute columns
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("HoaLaHe", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 15),
                  _buildFooterLink("About Us"),
                  _buildFooterLink("Contact"),
                  _buildFooterLink("Careers"),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Customer Service", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 15),
                  _buildFooterLink("Help Center"),
                  _buildFooterLink("Returns"),
                  _buildFooterLink("Shipping Info"),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Follow Us", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 15),
                  _buildFooterLinkWithIcon(Icons.facebook, "Facebook"),
                ],
              ),
            ],
          ),
          SizedBox(height: 30), // Increased spacing before copyright
          Text(
            "© 2025 HoaLaHe. All Rights Reserved.",
            style: TextStyle(color: Colors.grey[300], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }

  Widget _buildFooterLinkWithIcon(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}