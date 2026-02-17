import 'package:flutter/material.dart';

class FilterChipSection extends StatelessWidget {
  final List<String> genres;
  final String? selectedGenre;
  final String selectedSort;
  final Function(String?) onGenreSelected;
  final Function(String) onSortSelected;
  final VoidCallback onClearFilters;

  const FilterChipSection({
    super.key,
    required this.genres,
    required this.selectedGenre,
    required this.selectedSort,
    required this.onGenreSelected,
    required this.onSortSelected,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters = selectedGenre != null || selectedSort != 'createdAt';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filters',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (hasFilters)
                TextButton(
                  onPressed: onClearFilters,
                  child: Text(
                    'Clear all',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Sort options
                _buildFilterChip(
                  context,
                  label: 'Latest',
                  icon: Icons.access_time,
                  isSelected: selectedSort == 'createdAt',
                  onTap: () => onSortSelected('createdAt'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Most Played',
                  icon: Icons.trending_up,
                  isSelected: selectedSort == 'playCount',
                  onTap: () => onSortSelected('playCount'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Price',
                  icon: Icons.attach_money,
                  isSelected: selectedSort == 'price',
                  onTap: () => onSortSelected('price'),
                ),
                if (genres.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  const SizedBox(width: 16),
                  // Genre filters
                  ...genres.map((genre) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(
                          context,
                          label: genre,
                          icon: Icons.music_note,
                          isSelected: selectedGenre == genre,
                          onTap: () => onGenreSelected(
                            selectedGenre == genre ? null : genre,
                          ),
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : const Color(0xFF1A1F3A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
