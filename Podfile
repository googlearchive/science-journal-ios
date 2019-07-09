MINIMUM_IOS_VERSION = '12.0'

platform :ios, MINIMUM_IOS_VERSION

def shared_test_pods
  pod 'Protobuf', '~> 3.5.0', :inhibit_warnings => true
  pod 'SwiftLint'
end

target 'ScienceJournal' do
  use_frameworks!

  # Pods for ScienceJournal
  ## Drive
  pod 'GoogleAPIClientForREST/Drive', '~> 1.2.1', :inhibit_warnings => true
  ## MDC
  pod 'MaterialComponents/ActionSheet'
  pod 'MaterialComponents/ActivityIndicator'
  pod 'MaterialComponents/AnimationTiming'
  pod 'MaterialComponents/AppBar'
  pod 'MaterialComponents/BottomSheet'
  pod 'MaterialComponents/ButtonBar'
  pod 'MaterialComponents/Buttons'
  pod 'MaterialComponents/CollectionCells'
  pod 'MaterialComponents/CollectionLayoutAttributes'
  pod 'MaterialComponents/Collections'
  pod 'MaterialComponents/Dialogs'
  pod 'MaterialComponents/Dialogs+ColorThemer'
  pod 'MaterialComponents/FeatureHighlight'
  pod 'MaterialComponents/FeatureHighlight+ColorThemer'
  pod 'MaterialComponents/FlexibleHeader'
  pod 'MaterialComponents/HeaderStackView'
  pod 'MaterialComponents/Ink'
  pod 'MaterialComponents/NavigationBar'
  pod 'MaterialComponents/OverlayWindow'
  pod 'MaterialComponents/PageControl'
  pod 'MaterialComponents/Palettes'
  pod 'MaterialComponents/private/KeyboardWatcher'
  pod 'MaterialComponents/private/Overlay'
  pod 'MaterialComponents/ProgressView'
  pod 'MaterialComponents/ShadowElevations'
  pod 'MaterialComponents/ShadowLayer'
  pod 'MaterialComponents/Snackbar'
  pod 'MaterialComponents/Tabs'
  pod 'MaterialComponents/TextFields', :inhibit_warnings => true
  pod 'MaterialComponents/Themes'
  pod 'MaterialComponents/Typography'
  ## Protobuf
  pod 'Protobuf', '~> 3.5.0', :inhibit_warnings => true
  ## ZipArchive
  pod 'SSZipArchive', '2.1.1'
  ## SnapKit
  pod 'SnapKit', '~> 5.0.0'

  target 'ScienceJournalTests' do
    inherit! :search_paths
    shared_test_pods
  end
end

target 'ScienceJournalUITests' do
  inherit! :search_paths
  shared_test_pods
end

post_install do |installer|
  deployment_target = MINIMUM_IOS_VERSION
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if installer.config.verbose?
        puts "Setting deployment target #{deployment_target} for #{config.name} on #{target.name}..."
      end
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = deployment_target
      upgrade_to_recommended_settings! config
    end
  end
  puts "Generating Science Journal protos..."
  system("cd Protos && ./generate.sh")
  puts "Updating version numbers and generating plist..."
  system("cd Scripts && ./update_version_numbers.sh")
  puts "Removing unfixable warnings..."
  remove_unfixable_warnings! installer
end

def upgrade_to_recommended_settings! config
  if Pod::VERSION == '1.7.3'
    # Having this set triggers Xcode's "Upgrade to recommended settings"
    config.build_settings.delete('ARCHS')
  end
end

def remove_unfixable_warnings! installer
  installer.pod_targets.each do |target|
    if target.name == 'MaterialComponents' && target.version == '85.0.0'
      # The *ColorThemer types currently emit deprecation warnings,
      # but the new versions aren't available yet.
      installer.pods_project.files.map(&:path).grep(/MDC\w+ColorThemer.h/).each do |file|
        path = "Pods/MaterialComponents/#{file}"
        content = IO.read(path).gsub(/__deprecated_msg\([^)]*\)/, '')
        File.chmod(0644, path)
        IO.write(path, content)
        File.chmod(0444, path)
      end
    end
  end
end
