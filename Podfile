IOS_VERSION = '10.0'

platform :ios, IOS_VERSION

use_modular_headers!

def pod_protobuf
  pod 'Protobuf', '~> 3.5.0', :inhibit_warnings => true
end

target 'ScienceJournal' do
  pod_protobuf
  # Pods for ScienceJournal
  ## Drive
  pod 'GoogleAPIClientForREST/Drive', '~> 1.2.1', :inhibit_warnings => true
  ## MDC
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
  ## ZipArchive
  pod 'SSZipArchive', '2.1.1'

  target 'ScienceJournalTests' do
    inherit! :search_paths
  end

  target 'ScienceJournalUITests' do
    inherit! :search_paths
  end
end

target 'ScienceJournalProtos' do
  pod_protobuf
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if installer.config.verbose?
        puts "Setting deployment target #{deployment_target} for #{config.name} on #{target.name}"
      end
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = IOS_VERSION
    end
  end
end
