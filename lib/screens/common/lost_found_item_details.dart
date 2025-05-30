import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/lost_found_item.dart';
import '../../services/lost_found_service.dart';

class LostFoundItemDetails extends StatelessWidget {
  final LostFoundItem item;
  final LostFoundService _service = LostFoundService();

  LostFoundItemDetails({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
        actions: [
          if (!item.isResolved)
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'resolve':
                    await _showResolveDialog(context);
                    break;
                  case 'delete':
                    await _showDeleteDialog(context);
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'resolve',
                  child: Text('Mark as Resolved'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item.imageUrl != null)
              Image.network(
                item.imageUrl!,
                height: 250,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          item.status.toString().split('.').last.toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: item.status == ItemStatus.lost
                            ? Colors.red
                            : item.status == ItemStatus.found
                                ? Colors.green
                                : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          item.category.toString().split('.').last,
                        ),
                      ),
                      if (item.isResolved) ...[
                        const SizedBox(width: 8),
                        const Chip(
                          label: Text('RESOLVED'),
                          backgroundColor: Colors.blue,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoSection('Location', item.location),
                  _buildInfoSection(
                    'Date',
                    DateFormat('MMMM d, yyyy').format(item.date),
                  ),
                  _buildInfoSection('Description', item.description),
                  if (!item.anonymousContact && item.contactInfo != null)
                    _buildInfoSection('Contact', item.contactInfo!),
                  const SizedBox(height: 24),
                  if (!item.isResolved)
                    ElevatedButton(
                      onPressed: () => _showClaimDialog(context),
                      child: const Text('Claim This Item'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _showClaimDialog(BuildContext context) async {
    final TextEditingController proofController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Claim Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please provide proof of ownership or identification to claim this item:',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: proofController,
                decoration: const InputDecoration(
                  labelText: 'Proof of Ownership',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement claim functionality
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Claim request sent to the item owner'),
                  ),
                );
              },
              child: const Text('Submit Claim'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showResolveDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mark as Resolved'),
          content: const Text(
            'Are you sure you want to mark this item as resolved?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _service.markAsResolved(item.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Item marked as resolved'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: const Text(
            'Are you sure you want to delete this item? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _service.deleteItem(item.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Item deleted successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
