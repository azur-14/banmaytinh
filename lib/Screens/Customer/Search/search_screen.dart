import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:badges/badges.dart' as badges;
import 'package:danentang/widgets/Search/mobile_search_bar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = [];
  final String _recentSearchesKey = 'recent_searches';

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];
    });
  }

  Future<void> _saveSearchTerm(String term) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (term.trim().isEmpty) return;

    _recentSearches.remove(term); // remove duplicates
    _recentSearches.insert(0, term); // add to the top
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10); // keep only 10
    }
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
    setState(() {});
  }

  void _onSearchSubmitted(String term) {
    _saveSearchTerm(term);
    // TODO: Perform search action
    print('Searching for: $term');
  }

  void _clearRecentSearches() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    setState(() {
      _recentSearches = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onSubmitted: _onSearchSubmitted,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_recentSearches.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Searches',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: _clearRecentSearches,
                    child: const Text('Clear All'),
                  )
                ],
              ),
              Wrap(
                spacing: 8,
                children: _recentSearches.map((term) {
                  return ActionChip(
                    label: Text(term),
                    onPressed: () => _onSearchSubmitted(term),
                  );
                }).toList(),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
