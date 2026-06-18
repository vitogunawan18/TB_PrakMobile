import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'event_detail_page.dart';
import 'tickets_page.dart';
import 'orders_page.dart';
import 'profile_page.dart';

class EventListPage extends StatefulWidget {
  final ApiService apiService;
  final dynamic authManager;

  const EventListPage({super.key, required this.apiService, this.authManager});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _events = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  Timer? _searchDebounce;
  final ScrollController _scrollController = ScrollController();
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<dynamic> _categories = [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _initPreferences().then((_) {
      _loadCategories();
      _loadEvents();
    });
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _cityController.addListener(_onCityChanged);
  }

  Future<void> _initPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _cityController.text = prefs.getString('filter_city') ?? '';
        _selectedCategoryId = prefs.getInt('filter_category_id');
      });
    } catch (_) {}
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('filter_city', _cityController.text.trim());
      if (_selectedCategoryId != null) {
        await prefs.setInt('filter_category_id', _selectedCategoryId!);
      } else {
        await prefs.remove('filter_category_id');
      }
    } catch (_) {}
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _savePreferences();
      _page = 1;
      _hasMore = true;
      _loadEvents();
    });
  }

  void _onCityChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _savePreferences();
      _page = 1;
      _hasMore = true;
      _loadEvents();
    });
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadEvents({int page = 1}) async {
    if (page == 1) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final events = await widget.apiService.fetchEvents(
        page: page,
        perPage: 10,
        query: _searchController.text.trim(),
        categoryId: _selectedCategoryId,
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      );
      if (page == 1) {
        setState(() {
          _events = events;
          _page = 1;
          _hasMore = events.length >= 10;
        });
      } else {
        setState(() {
          _events.addAll(events);
          _hasMore = events.length >= 10;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore) return;
    _page++;
    await _loadEvents(page: _page);
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await widget.apiService.fetchCategories();
      setState(() => _categories = cats);
    } catch (_) {
      // ignore categories load errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrdersPage(apiService: widget.apiService),
                ),
              );
            },
            tooltip: 'Pesanan',
          ),
          IconButton(
            icon: const Icon(Icons.confirmation_num),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TicketsPage(apiService: widget.apiService),
                ),
              );
            },
            tooltip: 'Tiket Saya',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfilePage(apiService: widget.apiService, authManager: widget.authManager),
                ),
              );
            },
            tooltip: 'Profil',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _page = 1;
          _hasMore = true;
          await _loadEvents(page: 1);
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Cari event...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_on),
                        hintText: 'Kota...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_categories.isNotEmpty)
              SizedBox(
                height: 56,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length,
                  itemBuilder: (context, i) {
                    final c = _categories[i] as Map<String, dynamic>;
                    final id = c['id'] as int?;
                    final name = c['name'] ?? 'Kategori';
                    final selected = id != null && id == _selectedCategoryId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(name),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            _selectedCategoryId = v ? id : null;
                            _page = 1;
                            _hasMore = true;
                          });
                          _savePreferences();
                          _loadEvents(page: 1);
                        },
                      ),
                    );
                  },
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? ListView(children: [Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_errorMessage!)))])
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _events.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _events.length) return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
                            final event = _events[index] as Map<String, dynamic>;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: (event['poster_url'] as String?) != null
                                    ? SizedBox(
                                        width: 56,
                                        height: 56,
                                        child: CachedNetworkImage(
                                          imageUrl: event['poster_url'] as String,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                          errorWidget: (context, url, error) => const Icon(Icons.image_not_supported),
                                        ),
                                      )
                                    : null,
                                title: Text(event['title'] ?? 'Tidak ada judul'),
                                subtitle: Text(event['city'] ?? 'Kota tidak tersedia'),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => EventDetailPage(
                                        apiService: widget.apiService,
                                        eventId: event['id'] as int,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
}
