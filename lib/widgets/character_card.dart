import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/character.dart';
import '../providers/character_provider.dart';

class CharacterCard extends StatelessWidget {
  final Character character;
  final Function onFavoriteToggle;
  final bool isFavorite;

  const CharacterCard({
    super.key,
    required this.character,
    required this.onFavoriteToggle,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                // Character image
                Hero(
                  tag: 'character-${character.id}',
                  child: CachedNetworkImage(
                    imageUrl: character.image,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error),
                    ),
                  ),
                ),
                
                // Status indicator
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(character.status),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      character.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Favorite button
                Positioned(
                  top: 8,
                  right: 8,
                  child: FavoriteButton(
                    characterId: character.id,
                    onPressed: () => onFavoriteToggle(),
                    isForcedFavorite: isFavorite,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    character.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Species and Gender
                  _buildInfoRow(
                    Icons.category,
                    'Species: ${character.species}',
                  ),
                  const SizedBox(height: 4),
                  
                  _buildInfoRow(
                    Icons.person,
                    'Gender: ${character.gender}',
                  ),
                  const SizedBox(height: 4),
                  
                  // Origin
                  _buildInfoRow(
                    Icons.public,
                    'Origin: ${character.origin.name}',
                  ),
                  const SizedBox(height: 4),
                  
                  // Location
                  _buildInfoRow(
                    Icons.location_on,
                    'Location: ${character.location.name}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'alive':
        return Colors.green;
      case 'dead':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class FavoriteButton extends StatelessWidget {
  final int characterId;
  final VoidCallback onPressed;
  final bool isForcedFavorite;

  const FavoriteButton({
    super.key,
    required this.characterId,
    required this.onPressed,
    this.isForcedFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    // Если известно, что персонаж в избранном (например, на экране Favorites)
    if (isForcedFavorite) {
      return _buildButton(true);
    }

    return Consumer<CharacterProvider>(
      builder: (context, provider, _) {
        // Используем синхронный метод isFavorite, который теперь работает с кэшем
        final isFavorite = provider.isFavorite(characterId);
        return _buildButton(isFavorite);
      },
    );
  }

  Widget _buildButton(bool isFavorite) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isFavorite ? Icons.star : Icons.star_border,
            color: isFavorite ? Colors.amber : Colors.grey,
            size: 24,
          ),
        ),
      ),
    );
  }
}