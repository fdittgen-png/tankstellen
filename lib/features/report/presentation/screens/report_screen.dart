import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/feedback/github_issue_reporter/error_reporter.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/report_type.dart';
import '../../providers/report_form_provider.dart';
import '../widgets/no_backend_banner.dart';
import '../widgets/report_input_section.dart';
import '../widgets/report_type_list.dart';
import 'report_backend_availability.dart';
import 'report_submit_handler.dart';

export '../../domain/entities/report_type.dart';

/// Screen for submitting a community report about a station. Form state
/// (selected type, submission progress) lives in [reportFormControllerProvider];
/// the price text controller is owned locally for lifecycle reasons.
class ReportScreen extends ConsumerStatefulWidget {
  final String stationId;

  /// Reporter used for GitHub-routed report types (see #508). Defaults
  /// to a real [ErrorReporter] that launches the browser after the
  /// user confirms the consent dialog. Tests inject a fake.
  final ErrorReporter? reporter;

  const ReportScreen({
    super.key,
    required this.stationId,
    this.reporter,
  });

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _priceController = TextEditingController();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Rebuild submit-button enablement as the user types into
    // _priceController / _textController (the disabled-state depends
    // on whether the relevant field has content).
    _priceController.addListener(_onInputChanged);
    _textController.addListener(_onInputChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(reportFormControllerProvider.notifier).selectType(null);
    });
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  bool _hasRequiredInput(ReportType type) {
    if (type.needsPrice) return _priceController.text.trim().isNotEmpty;
    if (type.needsText) return _textController.text.trim().isNotEmpty;
    return true;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() {
    return ReportSubmitHandler(
      context: context,
      ref: ref,
      stationId: widget.stationId,
      priceController: _priceController,
      textController: _textController,
      reporter: widget.reporter,
    ).submit();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final form = ref.watch(reportFormControllerProvider);
    final selectedType = form.selectedType;
    final backends = ReportBackendAvailability.watch(ref);

    // #484 — was "Signaler un prix" but two of the existing options
    // (open/closed status) are not about prices and the rework will
    // add metadata-only report types. Generic "Report a problem"
    // matches the actual scope.
    return PageScaffold(
      title: l10n?.reportIssueTitle ?? 'Report a problem',
      bodyPadding: EdgeInsets.zero,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l10n?.tooltipBack ?? 'Back',
        onPressed: () => context.pop(),
      ),
      // RadioGroup sits OUTSIDE the ListView so every lazy-built
      // RadioListTile can look up the ancestor at any scroll position
      // (#710). Selection + change propagation flow through the group's
      // onChanged into the Riverpod controller.
      body: RadioGroup<ReportType>(
        groupValue: selectedType,
        onChanged: (v) =>
            ref.read(reportFormControllerProvider.notifier).selectType(v),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!backends.hasAnyBackend && !backends.allVisibleRouteToGitHub)
              ...[
                const NoBackendBanner(),
                const SizedBox(height: 16),
              ],
            ...buildReportTypeList(
              context,
              ref,
              visibleTypes: backends.visibleTypes,
              hasAnyBackend: backends.hasAnyBackend,
            ),
            ReportInputSection(
              selectedType: selectedType,
              priceController: _priceController,
              textController: _textController,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: selectedType != null &&
                      !form.isSubmitting &&
                      _hasRequiredInput(selectedType) &&
                      (backends.selectedIsGitHubRouted(selectedType) ||
                          backends.hasAnyBackend)
                  ? _submit
                  : null,
              child: form.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n?.sendReport ?? 'Send report'),
            ),
          ],
        ),
      ),
    );
  }
}
