import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/song_provider.dart';
import '../widgets/song_card.dart';
import '../widgets/filter_chip_section.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(songListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged() {
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == ref.read(searchQueryProvider)) return;
      ref.read(searchQueryProvider.notifier).state = _searchController.text;
      ref.read(songListProvider.notifier).applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songListProvider);
    final genresAsync = ref.watch(genresProvider);
    final selectedGenre = ref.watch(selectedGenreProvider);
    final selectedSort = ref.watch(selectedSortProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E27),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Discover Music',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search songs, artists...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.7)),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                          ref.read(songListProvider.notifier).applyFilters();
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1A1F3A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Filters
          genresAsync.when(
            data: (genres) => FilterChipSection(
              genres: genres,
              selectedGenre: selectedGenre,
              selectedSort: selectedSort,
              onGenreSelected: (genre) {
                ref.read(selectedGenreProvider.notifier).state = genre;
                ref.read(songListProvider.notifier).applyFilters();
              },
              onSortSelected: (sort) {
                ref.read(selectedSortProvider.notifier).state = sort;
                ref.read(songListProvider.notifier).applyFilters();
              },
              onClearFilters: () {
                ref.read(selectedGenreProvider.notifier).state = null;
                ref.read(selectedSortProvider.notifier).state = 'createdAt';
                ref.read(songListProvider.notifier).applyFilters();
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Song list
          Expanded(
            child: songsAsync.when(
              data: (songs) {
                if (songs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_note,
                          size: 80,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No songs found',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            ref.read(selectedGenreProvider.notifier).state = null;
                            ref.read(searchQueryProvider.notifier).state = '';
                            ref.read(songListProvider.notifier).applyFilters();
                          },
                          child: const Text('Clear filters'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  backgroundColor: const Color(0xFF1A1F3A),
                  color: Theme.of(context).colorScheme.primary,
                  onRefresh: () async {
                    await ref.read(songListProvider.notifier).fetchSongs(refresh: true);
                  },
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.67,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      return SongCard(song: songs[index]);
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load songs',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        ref.read(songListProvider.notifier).fetchSongs(refresh: true);
                      },
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
