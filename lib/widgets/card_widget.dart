import 'package:flutter/material.dart';
import '../models/card_data.dart';

class CardWidget extends StatelessWidget {
  final CardData card;
  final VoidCallback? onTap;
  final bool isSelected;
  final double width;
  final double height;

  const CardWidget({
    super.key,
    required this.card,
    this.onTap,
    this.isSelected = false,
    this.width = 80,
    this.height = 112,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..translate(0.0, isSelected ? -10.0 : 0.0),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade400,
              width: isSelected ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: card.isFaceUp ? _buildCardFace() : _buildCardBack(),
          ),
        ),
      ),
    );
  }

  Widget _buildCardFace() {
    // Try to load the actual card image from network, fall back to placeholder
    if (card.faceImageUrl != null) {
      return Image.network(
        card.faceImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildCardPlaceholder(true);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    } else {
      return _buildCardPlaceholder(true);
    }
  }

  Widget _buildCardBack() {
    // Try to load the card back image from network, fall back to placeholder
    if (card.backImageUrl != null) {
      return Image.network(
        card.backImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildCardPlaceholder(false);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    } else {
      return _buildCardPlaceholder(false);
    }
  }

  Widget _buildCardPlaceholder(bool showFace) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              showFace
                  ? [Colors.white, Colors.grey.shade100]
                  : [Colors.blue.shade800, Colors.blue.shade600],
        ),
      ),
      child: Center(
        child:
            showFace
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.style, color: Colors.grey.shade600, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      card.name,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
                : Icon(
                  Icons.style,
                  color: Colors.white.withOpacity(0.7),
                  size: 32,
                ),
      ),
    );
  }
}
