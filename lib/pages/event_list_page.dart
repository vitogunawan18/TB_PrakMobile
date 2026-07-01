import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'event_detail_page.dart';
import '../theme/app_theme.dart';

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
  final LayerLink _cityDropdownLink = LayerLink();
  OverlayEntry? _cityDropdownEntry;
  bool get _isCityDropdownOpen => _cityDropdownEntry != null;
  final TextEditingController _citySearchController = TextEditingController();
  bool _isCitySearchFocused = false;

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
    setState(() {});
  }

  void _onCityChanged() {
    setState(() {});
    _savePreferences();
  }

  List<String> get _availableCities {
    final cities = <String>{};
    for (final event in _events) {
      final city = (event['city'] as String? ?? event['venue']?['city'] as String? ?? '').trim();
      if (city.isNotEmpty) {
        cities.add(city);
      }
    }
    final list = cities.toList()..sort();
    final current = _cityController.text.trim();
    if (current.isNotEmpty && !list.contains(current)) {
      list.add(current);
      list.sort();
    }
    return list;
  }

  void _toggleCityDropdown() {
    if (_isCityDropdownOpen) {
      _closeCityDropdown();
    } else {
      _openCityDropdown();
    }
  }

  void _openCityDropdown() {
    _citySearchController.clear();
    _isCitySearchFocused = false;
    _cityDropdownEntry = _createCityDropdownEntry();
    Overlay.of(context).insert(_cityDropdownEntry!);
    setState(() {});
  }

  void _closeCityDropdown() {
    if (_cityDropdownEntry != null) {
      _cityDropdownEntry!.remove();
      _cityDropdownEntry = null;
      setState(() {});
    }
  }

  OverlayEntry _createCityDropdownEntry() {
    RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    var size = renderBox?.size ?? Size.zero;

    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _closeCityDropdown,
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.transparent,
              ),
            ),
            Positioned(
              width: 220,
              child: CompositedTransformFollower(
                link: _cityDropdownLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomRight,
                followerAnchor: Alignment.topRight,
                offset: const Offset(0, 8),
                child: Material(
                  color: Colors.transparent,
                  child: StatefulBuilder(
                    builder: (context, setModalState) {
                      final query = _citySearchController.text.toLowerCase().trim();
                      final allCities = _availableCities;
                      final filteredCities = allCities.where((city) => city.toLowerCase().contains(query)).toList();

                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.accentSecondary.withOpacity(0.2), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                              child: Focus(
                                onFocusChange: (hasFocus) {
                                  setModalState(() {
                                    _isCitySearchFocused = hasFocus;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgPrimary.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _isCitySearchFocused
                                          ? AppTheme.accentPrimary
                                          : AppTheme.accentSecondary.withOpacity(0.15),
                                      width: _isCitySearchFocused ? 1.5 : 1.0,
                                    ),
                                    boxShadow: _isCitySearchFocused
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.accentPrimary.withOpacity(0.15),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: TextField(
                                    controller: _citySearchController,
                                    textAlignVertical: TextAlignVertical.center,
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    onChanged: (_) {
                                      setModalState(() {});
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Cari kota...',
                                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                                      prefixIcon: const Icon(Icons.search, color: AppTheme.accentPrimary, size: 16),
                                      suffixIcon: _citySearchController.text.isNotEmpty
                                          ? GestureDetector(
                                              onTap: () {
                                                _citySearchController.clear();
                                                setModalState(() {});
                                              },
                                              child: const Icon(Icons.clear, color: AppTheme.textSecondary, size: 14),
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Divider(color: Colors.white.withOpacity(0.06), height: 1),
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                              ),
                              child: ListView(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                shrinkWrap: true,
                                children: [
                                  if (query.isEmpty) ...[
                                    ListTile(
                                      visualDensity: VisualDensity.compact,
                                      title: const Text(
                                        'Semua Kota',
                                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                      ),
                                      selected: _cityController.text.isEmpty,
                                      selectedTileColor: AppTheme.accentSecondary.withOpacity(0.15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      onTap: () {
                                        _cityController.text = '';
                                        _closeCityDropdown();
                                      },
                                    ),
                                    Divider(color: Colors.white.withOpacity(0.04), height: 8),
                                  ],
                                  if (filteredCities.isEmpty && query.isNotEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: Center(
                                        child: Text(
                                          'Tidak ditemukan',
                                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                        ),
                                      ),
                                    )
                                  else
                                    ...filteredCities.map((city) {
                                      final isSelected = _cityController.text == city;
                                      return ListTile(
                                        visualDensity: VisualDensity.compact,
                                        title: Text(
                                          city,
                                          style: TextStyle(
                                            color: isSelected ? AppTheme.accentPrimary : Colors.white,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            fontSize: 13,
                                          ),
                                        ),
                                        selected: isSelected,
                                        selectedTileColor: AppTheme.accentSecondary.withOpacity(0.15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        trailing: isSelected
                                            ? const Icon(Icons.check, color: AppTheme.accentPrimary, size: 16)
                                            : null,
                                        onTap: () {
                                          _cityController.text = city;
                                          _closeCityDropdown();
                                        },
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  List<dynamic> get _filteredEvents {
    final queryText = _searchController.text.toLowerCase().trim();
    final cityText = _cityController.text.toLowerCase().trim();
    return _events.where((event) {
      final title = (event['title'] as String? ?? '').toLowerCase();
      final city = (event['city'] as String? ?? event['venue']?['city'] as String? ?? '').toLowerCase();
      final category = (event['category']?['name'] as String? ?? '').toLowerCase();
      
      bool matchesQuery = true;
      if (queryText.isNotEmpty) {
        final tokens = queryText.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
        matchesQuery = tokens.every((token) {
          if (token == 'edufair') {
            return title.contains('edu') || title.contains('fair') || category.contains('edu');
          }
          return title.contains(token) || city.contains(token) || category.contains(token);
        });
      }
      
      bool matchesCity = true;
      if (cityText.isNotEmpty) {
        final tokens = cityText.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
        matchesCity = tokens.every((token) {
          return city.contains(token);
        });
      }
      
      return matchesQuery && matchesCity;
    }).toList();
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
        perPage: 100,
        categoryId: _selectedCategoryId,
      );
      if (page == 1) {
        setState(() {
          _events = events;
          _page = 1;
          _hasMore = events.length >= 100;
        });
      } else {
        setState(() {
          _events.addAll(events);
          _hasMore = events.length >= 100;
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

  String _formatDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, AppTheme.textSecondary],
          ).createShader(bounds),
          child: const Text(
            'Temukan Event',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _page = 1;
          _hasMore = true;
          await _loadEvents(page: 1);
        },
        child: Column(
          children: [
            // Glassmorphic Search and City filter bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentSecondary.withOpacity(0.1), width: 1.2),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.search, color: AppTheme.accentPrimary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Cari event...',
                        hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.white.withOpacity(0.12),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.location_on, color: AppTheme.accentPrimary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: CompositedTransformTarget(
                      link: _cityDropdownLink,
                      child: GestureDetector(
                        onTap: _toggleCityDropdown,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _cityController.text.trim().isEmpty ? 'Semua' : _cityController.text.trim(),
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            
            // Category Chips Slider
            if (_categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_categories.length + 1, (i) {
                      final bool isAllChip = i == 0;
                      final bool selected = isAllChip
                          ? _selectedCategoryId == null
                          : (_categories[i - 1]['id'] != null && _categories[i - 1]['id'] == _selectedCategoryId);
                      final String name = isAllChip ? 'Semua' : (_categories[i - 1]['name'] ?? 'Kategori');

                      return GestureDetector(
                        onTap: () {
                          if (isAllChip) {
                            if (_selectedCategoryId == null) return; // already selected
                            setState(() {
                              _selectedCategoryId = null;
                              _page = 1;
                              _hasMore = true;
                            });
                          } else {
                            final id = _categories[i - 1]['id'] as int?;
                            if (id == _selectedCategoryId) return; // already selected
                            setState(() {
                              _selectedCategoryId = id;
                              _page = 1;
                              _hasMore = true;
                            });
                          }
                          _savePreferences();
                          _loadEvents(page: 1);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: selected
                              ? AppTheme.gradientButtonDecoration()
                              : BoxDecoration(
                                  color: AppTheme.cardSurface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                                ),
                          child: Text(
                            name,
                            style: TextStyle(
                              color: selected ? Colors.white : AppTheme.textSecondary,
                              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            
            // Events Card List View
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? ListView(children: [Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.textSecondary))))])
                      : _filteredEvents.isEmpty
                          ? const Center(child: Text('Tidak ada event yang ditemukan', style: TextStyle(color: AppTheme.textSecondary)))
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), // extra padding at bottom to clear floating nav
                              itemCount: _filteredEvents.length + (_isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= _filteredEvents.length) return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
                                final event = _filteredEvents[index] as Map<String, dynamic>;
                                return GestureDetector(
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
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardSurface.withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppTheme.accentSecondary.withOpacity(0.1), width: 1.2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Poster Image (16:9)
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            topRight: Radius.circular(20),
                                          ),
                                          child: AspectRatio(
                                            aspectRatio: 16 / 9,
                                            child: (event['poster_url'] as String?) != null
                                                ? CachedNetworkImage(
                                                    imageUrl: AppTheme.getDirectImageUrl(event['poster_url'] as String?),
                                                    fit: BoxFit.cover,
                                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                                    errorWidget: (context, url, error) => CachedNetworkImage(
                                                      imageUrl: AppTheme.getEventPlaceholder(event['title'] as String?, event['category']?['name'] as String?),
                                                      fit: BoxFit.cover,
                                                      placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                                      errorWidget: (context, url, err) => Container(
                                                        color: AppTheme.cardSurface,
                                                        child: const Icon(Icons.image, size: 40, color: AppTheme.textSecondary),
                                                      ),
                                                    ),
                                                  )
                                                : Container(
                                                    color: AppTheme.cardSurface,
                                                    child: const Icon(Icons.image, size: 40, color: AppTheme.textSecondary),
                                                  ),
                                          ),
                                        ),
                                        
                                        // Card Details Body
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Category Badge
                                              if (event['category']?['name'] != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.accentSecondary.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    event['category']['name'] as String,
                                                    style: const TextStyle(
                                                      color: AppTheme.accentPrimary,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              if (event['category']?['name'] != null) const SizedBox(height: 8),

                                              // Event Title
                                              Text(
                                                event['title'] ?? 'Tidak ada judul',
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),

                                              // Location Row
                                              Row(
                                                children: [
                                                  const Icon(Icons.location_on, size: 14, color: AppTheme.accentPrimary),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      event['city'] ?? event['venue']?['city'] ?? 'Kota tidak tersedia',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: AppTheme.textSecondary,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              
                                              // Divider separator
                                              Divider(color: Colors.white.withOpacity(0.05), height: 1),
                                              const SizedBox(height: 12),
                                              
                                              // Bottom Row: Date & Ticket Price
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    event['event_at'] != null 
                                                        ? _formatDate(event['event_at'] as String)
                                                        : 'Tanggal tidak tersedia',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: AppTheme.textSecondary.withOpacity(0.7),
                                                    ),
                                                  ),
                                                  Text(
                                                    event['min_price'] != null 
                                                        ? 'Mulai Rp ${event['min_price']}'
                                                        : 'Tiket tersedia',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.accentPrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
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
    _cityController.removeListener(_onCityChanged);
    _cityController.dispose();
    _citySearchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _closeCityDropdown();
    super.dispose();
  }
}
