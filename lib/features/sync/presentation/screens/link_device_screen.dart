import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/supabase_client.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/link_device_how_it_works_card.dart';
import '../widgets/link_device_import_card.dart';
import '../widgets/link_device_this_device_card.dart';

class LinkDeviceScreen extends ConsumerStatefulWidget {
  const LinkDeviceScreen({super.key});

  @override
  ConsumerState<LinkDeviceScreen> createState() => _LinkDeviceScreenState();
}

class _LinkDeviceScreenState extends ConsumerState<LinkDeviceScreen> {
  // Text controller stays local — guideline is to keep controllers in the
  // widget even after lifting business state into a provider.
  final _codeController = TextEditingController();

  String? get _myId => TankSyncClient.client?.auth.currentUser?.id;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.linkDeviceScreenTitle ?? 'Link Device'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LinkDeviceThisDeviceCard(myId: _myId),
          const SizedBox(height: 16),
          LinkDeviceImportCard(codeController: _codeController),
          const SizedBox(height: 16),
          const LinkDeviceHowItWorksCard(),
        ],
      ),
    );
  }
}



