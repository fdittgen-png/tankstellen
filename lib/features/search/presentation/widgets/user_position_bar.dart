import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/location/user_position_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Shows the user's known position and allows updating it.
class UserPositionBar extends ConsumerWidget {
  final VoidCallback onUpdatePosition;

  const UserPositionBar({super.key, required this.onUpdatePosition});

  String _formatAge(DateTime updatedAt) {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inMinutes < 1) return '< 1 min';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPos = ref.watch(userPositionProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final posLabel = l10n?.yourPosition ?? 'Your position';
    final unknownLabel = l10n?.positionUnknown ?? 'Position unknown';
    final distFromSearchLabel =
        l10n?.distancesFromCenter ?? 'Distances from search center';

    if (userPos != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        child: Row(
          children: [
            Icon(Icons.my_location,
                size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$posLabel: ${userPos.source} (${_formatAge(userPos.updatedAt)})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              onTap: onUpdatePosition,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Icon(Icons.refresh,
                    size: 18, color: theme.colorScheme.primary),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Row(
        children: [
          Icon(Icons.location_off,
              size: 16, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$unknownLabel \u2014 $distFromSearchLabel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: onUpdatePosition,
            icon: Icon(Icons.my_location,
                size: 14, color: theme.colorScheme.primary),
            label: Text('GPS',
                style:
                    TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
