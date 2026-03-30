import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/supabase_client.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../../alerts/providers/alert_provider.dart';
import '../../../alerts/data/models/price_alert.dart';

class LinkDeviceScreen extends ConsumerStatefulWidget {
  const LinkDeviceScreen({super.key});

  @override
  ConsumerState<LinkDeviceScreen> createState() => _LinkDeviceScreenState();
}

class _LinkDeviceScreenState extends ConsumerState<LinkDeviceScreen> {
  final _codeController = TextEditingController();
  bool _isLinking = false;
  String? _result;

  String? get _myId => TankSyncClient.client?.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _linkDevice() async {
    final otherUserId = _codeController.text.trim();
    if (otherUserId.isEmpty || otherUserId.length < 10) {
      setState(() => _result = 'Please enter a valid device code');
      return;
    }

    setState(() {
      _isLinking = true;
      _result = null;
    });

    try {
      final client = TankSyncClient.client;
      if (client == null) {
        setState(() => _result = 'Not connected to TankSync');
        return;
      }

      // 1. Fetch the other device's favorites
      final otherFavorites = await client
          .from('favorites')
          .select('station_id')
          .eq('user_id', otherUserId);

      final importedFavIds = (otherFavorites as List)
          .map((r) => r['station_id'] as String)
          .toList();

      // 2. Fetch the other device's alerts
      final otherAlerts = await client
          .from('alerts')
          .select()
          .eq('user_id', otherUserId);

      // 3. Merge favorites locally
      int addedFavorites = 0;
      final currentFavs = ref.read(favoritesProvider);
      for (final stationId in importedFavIds) {
        if (!currentFavs.contains(stationId)) {
          await ref.read(favoritesProvider.notifier).add(stationId);
          addedFavorites++;
        }
      }

      // 4. Merge alerts locally
      int addedAlerts = 0;
      final currentAlerts = ref.read(alertProvider);
      final currentAlertIds = currentAlerts.map((a) => a.id).toSet();
      for (final row in otherAlerts as List) {
        if (!currentAlertIds.contains(row['id'])) {
          try {
            final alert = PriceAlert.fromJson({
              'id': row['id'],
              'stationId': row['station_id'],
              'stationName': row['station_name'] ?? '',
              'fuelType': row['fuel_type'] ?? 'e10',
              'targetPrice': (row['target_price'] as num).toDouble(),
              'isActive': row['is_active'] ?? true,
              'createdAt': row['created_at'] ?? DateTime.now().toIso8601String(),
            });
            await ref.read(alertProvider.notifier).addAlert(alert);
            addedAlerts++;
          } catch (_) {}
        }
      }

      // 5. Sync merged data back to our server account
      await SyncService.syncFavorites(ref.read(favoritesProvider));
      await SyncService.syncAlerts(ref.read(alertProvider));

      setState(() {
        _result =
            'Linked! Imported $addedFavorites favorites and $addedAlerts alerts.';
      });
    } catch (e) {
      setState(() {
        _result = 'Link failed: $e';
      });
    } finally {
      setState(() => _isLinking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Link Device'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // My device code
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.smartphone, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'This device',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Share this code with your other device:',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            _myId ?? 'Not connected',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontFamily: 'monospace'),
                          ),
                        ),
                        if (_myId != null)
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            tooltip: 'Copy code',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _myId!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Device code copied')),
                              );
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Link another device
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.link, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Import from another device',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the device code from your other device to import its favorites and alerts.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Device code',
                      hintText: 'Paste the UUID from other device',
                      prefixIcon: Icon(Icons.key, size: 18),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: (_codeController.text.isNotEmpty && !_isLinking)
                        ? _linkDevice
                        : null,
                    icon: _isLinking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.sync),
                    label: const Text('Import data'),
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _result!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _result!.startsWith('Link failed')
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // How it works explanation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'How it works',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. On Device A: copy the device code above\n'
                    '2. On Device B: paste it in the "Device code" field\n'
                    '3. Tap "Import data" to merge favorites and alerts\n'
                    '4. Both devices will have all combined data\n\n'
                    'Each device keeps its own anonymous identity. '
                    'Data is merged, not moved.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
