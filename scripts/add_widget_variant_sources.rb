# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT

# Wires the widget-variant Swift sources (#3171 — favorites + predictive
# widgets, shared list view, AppIntent refresh) into ios/Runner.xcodeproj,
# following the reproducible pbxproj-wiring pattern established by
# scripts/add_ios_widget_target.rb (#3166) and
# scripts/add_live_activity_sources.rb (#3170).
#
# All four files are SwiftUI / AppIntents surfaces rendered inside the
# widget process, so they are compiled into the TankstellenWidget
# extension target ONLY:
#   1. TankstellenWidget/StationListWidgetView.swift — shared list body
#      (header w/ iOS-17 refresh button, rows, predictive line).
#   2. TankstellenWidget/FavoriteStationsWidget.swift — favorites variant.
#   3. TankstellenWidget/PredictiveStationsWidget.swift — predictive variant.
#   4. TankstellenWidget/WidgetRefreshIntent.swift — iOS-17 AppIntent that
#      nudges the Dart side through the shared App-Group store.
#
# Idempotent: files already referenced / already in the target's sources
# are skipped, so re-running is a no-op.
#
# Usage (from the repo root):
#   ruby scripts/add_widget_variant_sources.rb

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../ios/Runner.xcodeproj', __dir__)

project = Xcodeproj::Project.open(PROJECT_PATH)

widget = project.targets.find { |t| t.name == 'TankstellenWidget' }
abort 'TankstellenWidget target not found — run scripts/add_ios_widget_target.rb first' unless widget

widget_group = project.main_group.children.find do |c|
  c.is_a?(Xcodeproj::Project::Object::PBXGroup) && c.name == 'TankstellenWidget'
end
abort 'TankstellenWidget group not found' unless widget_group

# Find-or-create a file reference for +path+ inside +group+.
def file_ref(group, path)
  group.files.find { |f| f.path == path } || group.new_file(path)
end

# Add +ref+ to +target+'s compile sources unless already present.
def compile(target, ref)
  already = target.source_build_phase.files_references.include?(ref)
  target.source_build_phase.add_file_reference(ref, true) unless already
  puts "#{target.name}: #{ref.path} #{already ? 'already compiled' : 'added'}"
end

%w[
  StationListWidgetView.swift
  FavoriteStationsWidget.swift
  PredictiveStationsWidget.swift
  WidgetRefreshIntent.swift
].each do |source|
  compile(widget, file_ref(widget_group, source))
end

project.save
puts "Saved #{PROJECT_PATH}"
