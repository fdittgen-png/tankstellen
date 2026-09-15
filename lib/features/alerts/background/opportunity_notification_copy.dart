// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Notification copy for an [Opportunity], per kind (#4183).
///
/// Same mechanism as [BackgroundNotificationTemplates] and for the same
/// reason (#2306): the WorkManager isolate has no `BuildContext` and its
/// device locale is not the in-app language the user chose, so the main
/// isolate resolves the ARB templates ahead of time and the isolate only
/// interpolates values it computes locally.
///
/// ## Why the three existing kinds are not here
///
/// `favouriteStation`, `exceptionalLocalPrice` and `localMovement` keep
/// the copy they already had — the per-station price-alert pair, the
/// grouped radius pair and the velocity pair on
/// [BackgroundNotificationTemplates]. #4149 was a migration, not a
/// rewrite: "none of them changes when an alert fires", and changing what
/// an alert SAYS would have been the same kind of unannounced change.
///
/// ## Why a null render is a refusal, not a fallback
///
/// [render] returns null when the opportunity lacks a field its copy
/// needs — in practice a station-shaped kind with no station name. The
/// alternative, substituting the station id, puts `de-9f3a1c` in front of
/// a user; the other alternative, dropping the segment, silently changes
/// what the sentence claims. A null travels to the dispatcher as a named
/// demotion instead, so the opportunity still reaches the feed and the
/// reason is recorded.
library;

import 'package:meta/meta.dart';

import '../domain/opportunity.dart';
import 'notification_templates.dart';

/// Title and body, both already interpolated.
typedef NotificationCopy = ({String title, String body});

/// The ARB templates for the opportunity kinds that did not exist before
/// the engine did.
@immutable
class OpportunityTemplates {
  const OpportunityTemplates({
    required this.bestStopNowTitle,
    required this.bestStopNowBody,
    required this.bestStopOnRouteTitle,
    required this.bestStopOnRouteBody,
    required this.refuelSoonTitle,
    required this.refuelSoonBody,
    required this.personalBaselineTitle,
    required this.personalBaselineBody,
  });

  final String bestStopNowTitle;
  final String bestStopNowBody;
  final String bestStopOnRouteTitle;
  final String bestStopOnRouteBody;
  final String refuelSoonTitle;
  final String refuelSoonBody;
  final String personalBaselineTitle;
  final String personalBaselineBody;

  Map<String, dynamic> toJson() => {
        'bestStopNowTitle': bestStopNowTitle,
        'bestStopNowBody': bestStopNowBody,
        'bestStopOnRouteTitle': bestStopOnRouteTitle,
        'bestStopOnRouteBody': bestStopOnRouteBody,
        'refuelSoonTitle': refuelSoonTitle,
        'refuelSoonBody': refuelSoonBody,
        'personalBaselineTitle': personalBaselineTitle,
        'personalBaselineBody': personalBaselineBody,
      };

  /// Null when any field is missing — including when the whole object is,
  /// which is what a blob written by a build older than #4183 looks like.
  ///
  /// Null propagates to [BackgroundNotificationTemplates.tryDecode], whose
  /// callers already fall back to resolving live. That is the existing
  /// corrupt-blob path, so an upgrade re-resolves once and the main
  /// isolate rewrites the blob on the next launch.
  static OpportunityTemplates? tryDecode(Object? json) {
    if (json is! Map) return null;
    final map = json.cast<String, Object?>();
    String? s(String k) => map[k] is String ? map[k]! as String : null;
    final values = [
      s('bestStopNowTitle'),
      s('bestStopNowBody'),
      s('bestStopOnRouteTitle'),
      s('bestStopOnRouteBody'),
      s('refuelSoonTitle'),
      s('refuelSoonBody'),
      s('personalBaselineTitle'),
      s('personalBaselineBody'),
    ];
    if (values.any((v) => v == null)) return null;
    return OpportunityTemplates(
      bestStopNowTitle: values[0]!,
      bestStopNowBody: values[1]!,
      bestStopOnRouteTitle: values[2]!,
      bestStopOnRouteBody: values[3]!,
      refuelSoonTitle: values[4]!,
      refuelSoonBody: values[5]!,
      personalBaselineTitle: values[6]!,
      personalBaselineBody: values[7]!,
    );
  }
}

/// Renders one [Opportunity] as a notification.
abstract final class OpportunityNotificationCopy {
  /// Copy for [o], or null when the opportunity cannot be stated without
  /// inventing something. See the library doc.
  ///
  /// [priceOf] and [distanceOf] format the two numbers; they are
  /// parameters because a price's decimal convention is per-country and
  /// this runs where there is no locale.
  static NotificationCopy? render(
    Opportunity o,
    BackgroundNotificationTemplates templates, {
    required String Function(double) priceOf,
    required String Function(double) distanceOf,
    String? currency,
  }) {
    final symbol = templates.currencyForCountry(null);
    final money = currency ?? symbol;
    final price = priceOf(o.currentPrice);
    final distance = distanceOf(o.distanceKm);
    final station = o.stationName;
    final fuel = o.fuelType;

    // Every kind below except localMovement is ABOUT a station, and its
    // copy names one. Without a name there is nothing honest to render.
    if (station == null && o.kind != OpportunityKind.localMovement) {
      return null;
    }

    switch (o.kind) {
      case OpportunityKind.favouriteStation:
        // The alert the user set themselves keeps the copy it had: the
        // reference is their own threshold, which is the most checkable
        // one there is.
        final target = o.referencePrice;
        if (target == null) return null;
        return (
          title: templates
              .renderPriceAlertTitle(station: station!, fuelType: fuel),
          body: templates.renderPriceAlertBody(
              price: price, target: priceOf(target), currency: money),
        );

      case OpportunityKind.exceptionalLocalPrice:
        // The radius alert's grouped copy, for the single-station case
        // the dispatcher hands over one at a time.
        final threshold = o.referencePrice;
        if (threshold == null) return null;
        return (
          title: templates.renderRadiusTitle(
              label: station!,
              count: 1,
              threshold: priceOf(threshold),
              currency: money),
          body: '$price $money',
        );

      case OpportunityKind.localMovement:
        // Not about one station: an area moved. `station` is legitimately
        // null here and the copy never names one.
        return (
          title: templates.renderVelocityTitle(fuelLabel: fuel),
          body: templates.renderVelocityBody(count: 1, cents: 0),
        );

      case OpportunityKind.bestStopNow:
        return (
          title: templates.renderOpportunityBestStopNowTitle(fuelType: fuel),
          body: templates.renderOpportunityBestStopNowBody(
              price: price,
              currency: money,
              station: station!,
              distance: distance),
        );

      case OpportunityKind.bestStopOnRoute:
        return (
          title:
              templates.renderOpportunityBestStopOnRouteTitle(fuelType: fuel),
          body: templates.renderOpportunityBestStopOnRouteBody(
              price: price,
              currency: money,
              station: station!,
              distance: distance),
        );

      case OpportunityKind.refuelSoon:
        return (
          title: templates.renderOpportunityRefuelSoonTitle(),
          body: templates.renderOpportunityRefuelSoonBody(
              station: station!,
              distance: distance,
              price: price,
              currency: money),
        );

      case OpportunityKind.personalBaseline:
        return (
          title:
              templates.renderOpportunityPersonalBaselineTitle(fuelType: fuel),
          body: templates.renderOpportunityPersonalBaselineBody(
              price: price, currency: money, station: station!),
        );
    }
  }
}
