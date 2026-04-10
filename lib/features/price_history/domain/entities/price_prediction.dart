/// Domain entity re-export for PricePrediction and its supporting value types.
///
/// Presentation and cross-feature consumers must import this path instead of
/// reaching into `data/models/`. PricePrediction is a pure computed result
/// with no persistence concerns, so it is a first-class domain entity.
library;

export '../../data/models/price_prediction.dart';
