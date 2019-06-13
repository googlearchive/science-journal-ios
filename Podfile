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
    end
  end
  puts "Generating Science Journal protos..."
  system("cd Protos && ./generate.sh")
  puts "Updating version numbers and generating plist..."
  system("cd Scripts && ./update_version_numbers.sh")
end
