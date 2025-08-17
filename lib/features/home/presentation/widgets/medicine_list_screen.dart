import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/medicine_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/medicine_model.dart';
import 'medicine_detail_screen.dart';

class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MedicineProvider>(context, listen: false).loadMedicines();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    // Clear search when leaving the screen without reloading
    Provider.of<MedicineProvider>(
      context,
      listen: false,
    ).clearFiltersWithoutReload();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final medicineProvider = Provider.of<MedicineProvider>(
        context,
        listen: false,
      );
      if (medicineProvider.hasMoreData && !medicineProvider.isLoading) {
        medicineProvider.loadMedicines();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Sheba Medicine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: MedicineSearchDelegate());
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              final medicineProvider = Provider.of<MedicineProvider>(
                context,
                listen: false,
              );
              switch (value) {
                case 'name':
                  medicineProvider.setSortBy('name');
                  break;
                case 'price_low':
                  medicineProvider.setSortBy('price');
                  break;
                case 'price_high':
                  medicineProvider.setSortBy('-price');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha),
                    SizedBox(width: 8),
                    Text('Sort by Name'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'price_low',
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward),
                    SizedBox(width: 8),
                    Text('Price: Low to High'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'price_high',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward),
                    SizedBox(width: 8),
                    Text('Price: High to Low'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, medicineProvider, child) {
          if (medicineProvider.isLoading &&
              medicineProvider.medicines.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (medicineProvider.error != null &&
              medicineProvider.medicines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading medicines',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    medicineProvider.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      medicineProvider.clearError();
                      medicineProvider.loadMedicines(refresh: true);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final medicines = medicineProvider.filteredMedicines;

          if (medicines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No medicines found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your search or filters',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (medicineProvider.searchQuery.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        medicineProvider.clearFiltersWithoutReload();
                      },
                      child: const Text('Clear Filters'),
                    ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => medicineProvider.loadMedicines(refresh: true),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  medicines.length + (medicineProvider.hasMoreData ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == medicines.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final medicine = medicines[index];
                return MedicineCard(medicine: medicine);
              },
            ),
          );
        },
      ),
    );
  }
}

class MedicineCard extends StatelessWidget {
  final Medicine medicine;

  const MedicineCard({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MedicineDetailScreen(medicine: medicine),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Medicine Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLightColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: medicine.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          medicine.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.medical_services,
                              size: 40,
                              color: AppTheme.primaryColor,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.medical_services,
                        size: 40,
                        color: AppTheme.primaryColor,
                      ),
              ),
              const SizedBox(width: 16),

              // Medicine Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      medicine.manufacturer,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: medicine.isInStock
                                ? AppTheme.successColor.withOpacity(0.1)
                                : AppTheme.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            medicine.stockStatus,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: medicine.isInStock
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          medicine.formattedPrice,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
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
      ),
    );
  }
}

class MedicineSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          // Clear search in provider
          final medicineProvider = Provider.of<MedicineProvider>(
            context,
            listen: false,
          );
          medicineProvider.clearFiltersWithoutReload();
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        // Clear search when going back
        final medicineProvider = Provider.of<MedicineProvider>(
          context,
          listen: false,
        );
        medicineProvider.clearFiltersWithoutReload();
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final medicineProvider = Provider.of<MedicineProvider>(
      context,
      listen: false,
    );

    if (query.isNotEmpty) {
      try {
        medicineProvider.setSearchQuery(query);
      } catch (e) {
        print('Search error: $e');
        // Clear search on error
        medicineProvider.clearFilters();
      }
    }

    return Consumer<MedicineProvider>(
      builder: (context, provider, child) {
        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
                const SizedBox(height: 16),
                Text(
                  'Search error',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    provider.clearError();
                    provider.clearFiltersWithoutReload();
                  },
                  child: const Text('Clear Search'),
                ),
              ],
            ),
          );
        }

        final medicines = provider.filteredMedicines;

        if (medicines.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No medicines found for "$query"',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: medicines.length,
          itemBuilder: (context, index) {
            return MedicineCard(medicine: medicines[index]);
          },
        );
      },
    );
  }
}
