import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BakeryCard extends StatelessWidget {
  final String name;
  final String description;
  final String rating;
  final String time;
  final String fee;
  final String imageUrl;
  final bool isDark;
  final Color cardColor;
  final bool isClosed;

  const BakeryCard({
    super.key,
    required this.name,
    required this.description,
    required this.rating,
    required this.time,
    required this.fee,
    required this.imageUrl,
    required this.isDark,
    required this.cardColor,
    this.isClosed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Opacity(
        opacity: isClosed ? 0.6 : 1.0,
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF7D2D35),
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: isClosed ? Colors.red : Colors.grey,
                          fontWeight: isClosed
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (fee.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.delivery_dining,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fee,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
