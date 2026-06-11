# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT

# Wires the Live Activity Swift sources (#3170) into ios/Runner.xcodeproj,
# following the reproducible pbxproj-wiring pattern established by
# scripts/add_ios_widget_target.rb (#3166 / PR #3217).
#
#   1. TankstellenWidget/TripActivityAttributes.swift — compiled into BOTH
#      the Runner target and the TankstellenWidget extension target.
#      ActivityKit matches the host process and the rendering extension on
#      this shared ActivityAttributes type, so the single source file must
#      be in both targets' compile sources.
#   2. TankstellenWidget/TripRecordingLiveActivity.swift — the SwiftUI
#      lock-screen + Dynamic Island views; extension target only.
#   3. Runner/LiveActivityBridge.swift — the `tankstellen/live_activity`
#      MethodChannel host; Runner target only.
#
# Idempotent: files already referenced / already in a target's sources are
# skipped, so re-running is a no-op.
#
# Usage (from the repo root):
#   ruby scripts/add_live_activity_sources.rb

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../ios/Runner.xcodeproj', __dir__)

project = Xcodeproj::Project.open(PROJECT_PATH)

runner = project.targets.find { |t| t.name == 'Runner' }
abort 'Runner target not found' unless runner
widget = project.targets.find { |t| t.name == 'TankstellenWidget' }
abort 'TankstellenWidget target not found — run scripts/add_ios_widget_target.rb first' unless widget

# Locate the groups the existing sources live in.
widget_group = project.main_group.children.find do |c|
  c.is_a?(Xcodeproj::Project::Object::PBXGroup) && c.name == 'TankstellenWidget'
end
abort 'TankstellenWidget group not found' unless widget_group
runner_group = project.main_group.children.find do |c|
  c.is_a?(Xcodeproj::Project::Object::PBXGroup) &&
    (c.name == 'Runner' || c.path == 'Runner')
end
abort 'Runner group not found' unless runner_group

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

attributes_ref = file_ref(widget_group, 'TripActivityAttributes.swift')
activity_ref   = file_ref(widget_group, 'TripRecordingLiveActivity.swift')
bridge_ref     = file_ref(runner_group, 'LiveActivityBridge.swift')

compile(runner, attributes_ref)   # shared ActivityAttributes — host side
compile(widget, attributes_ref)   # shared ActivityAttributes — render side
compile(widget, activity_ref)     # views: extension only
compile(runner, bridge_ref)       # channel host: Runner only

project.save
puts "Saved #{PROJECT_PATH}"
