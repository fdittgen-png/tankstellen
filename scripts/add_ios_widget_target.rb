# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT

# Wires the TankstellenWidget WidgetKit extension target into
# ios/Runner.xcodeproj (#3166).
#
# The ~405 LOC of SwiftUI widget code under ios/TankstellenWidget/ shipped
# source-tracked but was never part of any Xcode build target — this script
# performs the "Required Xcode work" of docs/guides/ios-widget-extension.md
# reproducibly from the command line via the xcodeproj gem (bundled with the
# fastlane stack):
#
#   1. adds an app-extension PBXNativeTarget "TankstellenWidget"
#      (com.apple.product-type.app-extension, bundle id
#      de.tankstellen.tankstellen.TankstellenWidget),
#   2. compiles the five tracked Swift sources + Assets.xcassets, with the
#      tracked Info.plist / TankstellenWidget.entitlements,
#   3. bases every widget configuration on Flutter/Generated.xcconfig so
#      CFBundleVersion ($(FLUTTER_BUILD_NUMBER)) tracks the host app,
#   4. embeds the .appex in Runner via an "Embed Foundation Extensions"
#      copy-files phase + target dependency,
#   5. points Runner at ios/Runner/Runner.entitlements (the App Group
#      entitlement file existed but was never referenced by
#      CODE_SIGN_ENTITLEMENTS — without it the host app is signed WITHOUT
#      the group and UserDefaults(suiteName:) sharing silently fails),
#   6. mirrors Runner's signing per configuration: Automatic (team
#      C4Y5RDF8P9) for Debug/Profile, Manual + match AppStore profile for
#      Release,
#   7. saves a shared build scheme for the new target.
#
# Idempotent: re-running on a project that already has the target is a no-op.
#
# Usage (from the repo root):
#   ruby scripts/add_ios_widget_target.rb

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../ios/Runner.xcodeproj', __dir__)
WIDGET_NAME = 'TankstellenWidget'.freeze
WIDGET_BUNDLE_ID = 'de.tankstellen.tankstellen.TankstellenWidget'.freeze
TEAM_ID = 'C4Y5RDF8P9'.freeze
DEPLOYMENT_TARGET = '16.6'.freeze # matches the Runner target's setting
SWIFT_SOURCES = %w[
  TankstellenWidget.swift
  NearestStationsProvider.swift
  NearestStationsEntry.swift
  NearestStationsWidgetView.swift
  StationRow.swift
].freeze

project = Xcodeproj::Project.open(PROJECT_PATH)

runner = project.targets.find { |t| t.name == 'Runner' }
abort 'Runner target not found' unless runner

if project.targets.any? { |t| t.name == WIDGET_NAME }
  puts "#{WIDGET_NAME} target already present — nothing to do."
  exit 0
end

generated_xcconfig = project.files.find { |f| f.path == 'Flutter/Generated.xcconfig' }
abort 'Flutter/Generated.xcconfig reference not found' unless generated_xcconfig

# --- 1. The extension target (also creates the .appex product reference and
# one build configuration per project configuration: Debug/Release/Profile).
widget = project.new_target(:app_extension, WIDGET_NAME, :ios, DEPLOYMENT_TARGET)

# --- 2. Group + tracked files.
group = project.main_group.new_group(WIDGET_NAME, WIDGET_NAME)
swift_refs = SWIFT_SOURCES.map { |f| group.new_file(f) }
assets_ref = group.new_file('Assets.xcassets')
group.new_file('Info.plist')
group.new_file("#{WIDGET_NAME}.entitlements")

widget.add_file_references(swift_refs)
widget.resources_build_phase.add_file_reference(assets_ref)

# new_target links Foundation.framework via a file reference pinned to a
# hard-coded SDK directory name that drifts with every Xcode release (and
# does not exist on this machine's SDK). Swift auto-links Foundation /
# SwiftUI / WidgetKit from the imports, so drop the explicit link.
widget.frameworks_build_phase.files.dup.each do |bf|
  ref = bf.file_ref
  widget.frameworks_build_phase.remove_build_file(bf)
  ref.remove_from_project if ref && ref.build_files.empty?
end
# ...and the now-empty "iOS" SDK-frameworks group it created.
frameworks_group = project.main_group['Frameworks']
if frameworks_group
  ios_group = frameworks_group.children.find do |c|
    c.is_a?(Xcodeproj::Project::Object::PBXGroup) &&
      c.display_name == 'iOS' && c.empty?
  end
  ios_group&.remove_from_project
end

# --- 3. Build settings. Replace the xcodeproj template defaults wholesale so
# the result matches what Xcode's own widget-extension template would write,
# adapted to this project's conventions (versions pinned to the host via
# Generated.xcconfig's FLUTTER_BUILD_NUMBER, signing mirroring Runner).
widget.build_configurations.each do |config|
  # Generated.xcconfig provides FLUTTER_BUILD_NUMBER / FLUTTER_ROOT. Do NOT
  # use Flutter/Debug|Release.xcconfig here — those #include the Pods-Runner
  # xcconfigs, which would inject the host app's pod link flags into the
  # extension.
  config.base_configuration_reference = generated_xcconfig

  bs = config.build_settings
  bs.clear
  bs['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  bs['ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME'] = 'WidgetBackground'
  bs['CLANG_ENABLE_MODULES'] = 'YES'
  bs['CODE_SIGN_ENTITLEMENTS'] = "#{WIDGET_NAME}/#{WIDGET_NAME}.entitlements"
  bs['CURRENT_PROJECT_VERSION'] = '$(FLUTTER_BUILD_NUMBER)'
  bs['DEVELOPMENT_TEAM'] = TEAM_ID
  bs['INFOPLIST_FILE'] = "#{WIDGET_NAME}/Info.plist"
  bs['INFOPLIST_KEY_CFBundleDisplayName'] = 'Sparkilo'
  bs['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  bs['LD_RUNPATH_SEARCH_PATHS'] = [
    '$(inherited)',
    '@executable_path/Frameworks',
    '@executable_path/../../Frameworks',
  ]
  # Track the host app exactly: Runner/Info.plist uses $(FLUTTER_BUILD_NAME)
  # / $(FLUTTER_BUILD_NUMBER) and App Store validation requires the
  # extension's CFBundleShortVersionString to match the containing app's.
  bs['MARKETING_VERSION'] = '$(FLUTTER_BUILD_NAME)'
  bs['PRODUCT_BUNDLE_IDENTIFIER'] = WIDGET_BUNDLE_ID
  bs['PRODUCT_NAME'] = '$(TARGET_NAME)'
  bs['SKIP_INSTALL'] = 'YES'
  bs['SUPPORTED_PLATFORMS'] = 'iphoneos iphonesimulator'
  bs['SUPPORTS_MACCATALYST'] = 'NO'
  bs['SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD'] = 'NO'
  bs['SWIFT_VERSION'] = '5.0'
  bs['TARGETED_DEVICE_FAMILY'] = '1'
  bs['VERSIONING_SYSTEM'] = 'apple-generic'

  case config.name
  when 'Debug'
    bs['CODE_SIGN_IDENTITY'] = 'Apple Development'
    bs['CODE_SIGN_STYLE'] = 'Automatic'
    bs['PROVISIONING_PROFILE_SPECIFIER'] = ''
    bs['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'DEBUG'
    bs['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
  when 'Release'
    # Mirrors Runner's Release config: manual signing against the fastlane
    # match distribution profile. The profile does not exist until the
    # widget App ID + App Group are registered in the Apple Developer
    # Portal and `match appstore --force` is re-run (see
    # docs/guides/ios-widget-extension.md, "Required Apple Developer
    # Portal work").
    bs['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = 'Apple Distribution'
    bs['CODE_SIGN_STYLE'] = 'Manual'
    bs['PROVISIONING_PROFILE_SPECIFIER'] = "match AppStore #{WIDGET_BUNDLE_ID}"
    bs['SWIFT_COMPILATION_MODE'] = 'wholemodule'
    bs['SWIFT_OPTIMIZATION_LEVEL'] = '-O'
  when 'Profile'
    bs['CODE_SIGN_IDENTITY'] = 'Apple Development'
    bs['CODE_SIGN_STYLE'] = 'Automatic'
    bs['PROVISIONING_PROFILE_SPECIFIER'] = ''
    bs['SWIFT_COMPILATION_MODE'] = 'wholemodule'
    bs['SWIFT_OPTIMIZATION_LEVEL'] = '-O'
  end
end

# --- 4. Embed the .appex in Runner + build-order dependency.
#
# The phase MUST come before Flutter's "Thin Binary" script phase (per the
# Flutter app-extension docs): Thin Binary rewrites the whole .app bundle,
# so an appex copy scheduled after it forms a dependency cycle that Xcode's
# build system rejects ("Cycle inside Runner").
embed = runner.copy_files_build_phases.find { |p| p.name == 'Embed Foundation Extensions' }
unless embed
  embed = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
  embed.name = 'Embed Foundation Extensions'
  embed.symbol_dst_subfolder_spec = :plug_ins
  embed.dst_path = ''
  thin_binary = runner.build_phases.find { |p| p.display_name == 'Thin Binary' }
  insert_at = thin_binary ? runner.build_phases.index(thin_binary) : runner.build_phases.length
  runner.build_phases.insert(insert_at, embed)
end
build_file = embed.add_file_reference(widget.product_reference)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
runner.add_dependency(widget)

# --- 5. Wire the (pre-existing but never referenced) Runner entitlements so
# the host app is actually signed with the App Group.
runner_group = project.main_group['Runner']
unless runner_group.files.any? { |f| f.path == 'Runner.entitlements' }
  runner_group.new_file('Runner.entitlements')
end
runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] ||= 'Runner/Runner.entitlements'
end

project.save

# --- 6. Shared scheme so `xcodebuild -list` / CI can address the target.
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(widget)
scheme.save_as(PROJECT_PATH, WIDGET_NAME, true)

puts "Added #{WIDGET_NAME} target (#{WIDGET_BUNDLE_ID}) to #{PROJECT_PATH}"
