import 'package:flutter/material.dart';
import '../../models/lost_found_item.dart';
import '../../services/lost_found_service.dart';
import 'package:intl/intl.dart';
import 'add_lost_found_item.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({Key? key}) : super(key: key);

  @override
  _LostFoundScreenState createState() => _LostFoundScreenState();
}



class _LostFoundScreenState extends State<LostFoundScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LostFoundService _service = LostFoundService();
  ItemStatus? _statusFilter;
  ItemCategory? _categoryFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found Board'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Lost'),
            Tab(text: 'Found'),
          ],
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Category'),
                        selected: _categoryFilter != null,
                        onSelected: (bool selected) {
                          _showCategoryFilterDialog();
                        },
                      ),
                      const SizedBox(width: 8),
                      ...ItemCategory.values.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category.toString().split('.').last),
                            selected: _categoryFilter == category,
                            onSelected: (bool selected) {
                              setState(() {
                                _categoryFilter = selected ? category : null;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItemList(null),
                _buildItemList(ItemStatus.lost),
                _buildItemList(ItemStatus.found),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        label: const Text('Report Item'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildItemList(ItemStatus? status) {
    return StreamBuilder<List<LostFoundItem>>(
      stream: _service.getItems(
        status: status,
        category: _categoryFilter,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!;

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No items found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: item.imageUrl != null
                      ? Image.network(
                          item.imageUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: double.infinity,
                                height: 200,
                                color: Colors.grey[200],
                                child: Icon(Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey[400]),
                              ),
                        )
                      : Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey[200],
                          child: Icon(Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey[400]),
                        ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                            ),
                            if (item.userId == FirebaseAuth.instance.currentUser?.uid)
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                                onSelected: (value) async {
                                  if (value == 'delete') {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Item'),
                                        content: const Text('Are you sure you want to delete this item?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      try {
                                        await _service.deleteItem(item.id);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Item deleted successfully')),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error deleting item: $e')),
                                          );
                                        }
                                      }
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: item.status == ItemStatus.lost
                                    ? Colors.red[50]
                                    : Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.status == ItemStatus.lost
                                        ? Icons.search
                                        : Icons.check_circle,
                                    size: 16,
                                    color: item.status == ItemStatus.lost
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.status.toString().split('.').last.toUpperCase(),
                                    style: TextStyle(
                                      color: item.status == ItemStatus.lost
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('MMM d, y').format(item.date),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.location,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (!item.anonymousContact && item.contactInfo != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.contactInfo!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCategoryFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ItemCategory.values
                .map(
                  (category) => ListTile(
                    title: Text(category.toString().split('.').last),
                    onTap: () {
                      setState(() => _categoryFilter = category);
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _categoryFilter = null);
                Navigator.pop(context);
              },
              child: const Text('Clear Filter'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAddItemDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddLostFoundItem()),
    );
  }

  Future<void> _deleteItem(BuildContext context, LostFoundItem item) async {
    try {
      await _service.deleteItem(item.id);
      if (context.mounted) {
        Navigator.pop(context); // Close the details dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _showItemDetails(BuildContext context, LostFoundItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.imageUrl != null)
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(item.imageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(item.description),
              const SizedBox(height: 8),
              Text('Location:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(item.location),
              const SizedBox(height: 8),
              Text('Category:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(item.category.toString().split('.').last),
              const SizedBox(height: 8),
              Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(DateFormat('MMM d, yyyy').format(item.date)),
              if (!item.anonymousContact && item.contactInfo != null) ...[  
                const SizedBox(height: 8),
                Text('Contact:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(item.contactInfo!),
              ],
            ],
          ),
        ),
        actions: [
          FutureBuilder<bool>(
            future: _service.canDeleteItem(item.id),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return TextButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Item'),
                      content: const Text('Are you sure you want to delete this item?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => _deleteItem(context, item),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
