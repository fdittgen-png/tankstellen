/// Auto-fills the total-cost field on the Add-Fill-up form (#581)
/// when the screen receives a non-null `preFilledPricePerLiter` from
/// the station context.
///
/// Pulled out of `add_fill_up_screen.dart` (#563 extraction) so the
/// "don't clobber a manually-typed cost" rule has its own unit tests
/// and the calculator owns its `lastAutoCost` instead of leaking the
/// field across the screen state.
///
/// Usage from the screen:
///
///     final calc = FillUpAutoCostCalculator(pricePerLiter: 1.859);
///     // in the liters-controller listener:
///     final next = calc.recompute(
///       litersText: _litersCtrl.text,
///       costText: _costCtrl.text,
///     );
///     if (next != null) _costCtrl.text = next;
class FillUpAutoCostCalculator {
  final double pricePerLiter;
  double? _lastAutoCost;

  FillUpAutoCostCalculator({required this.pricePerLiter});

  /// Recompute the total cost from [litersText]. Returns the new cost
  /// text to write into the cost field, or `null` when:
  ///   * liters parses to a non-positive / unparseable value, OR
  ///   * the user has typed a custom cost (cost field is non-empty
  ///     and does not match the previous auto-fill).
  ///
  /// The caller is responsible for assigning the returned string to
  /// the controller.
  String? recompute({
    required String litersText,
    required String costText,
  }) {
    final liters = double.tryParse(litersText.replaceAll(',', '.'));
    if (liters == null || liters <= 0) return null;
    final current = double.tryParse(costText.replaceAll(',', '.'));
    final autoCost = (liters * pricePerLiter).toStringAsFixed(2);
    // Only overwrite if the user hasn't typed a custom cost. We detect
    // "user-typed" by checking whether the current value matches a
    // prior auto-fill: if the field is empty OR exactly matches the
    // previous auto-computed value, we overwrite.
    if (costText.isEmpty || current == _lastAutoCost) {
      _lastAutoCost = double.tryParse(autoCost);
      return autoCost;
    }
    return null;
  }
}
