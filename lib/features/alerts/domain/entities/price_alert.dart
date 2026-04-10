/// Domain entity re-export for PriceAlert.
///
/// Presentation and cross-feature consumers must import this path instead of
/// reaching into `data/models/`. The underlying class lives in the data layer
/// because it is persisted via Hive/Supabase, but its shape is a pure domain
/// concept and is safe to expose as an entity.
library;

export '../../data/models/price_alert.dart';
