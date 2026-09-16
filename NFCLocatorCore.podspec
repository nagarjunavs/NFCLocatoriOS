Pod::Spec.new do |s|
  s.name             = 'NFCLocatorCore'
  s.version          = '0.1.0'
  s.summary          = 'Shows users exactly where to tap their phone against an NFC reader.'
  s.description      = <<-DESC
    NFCLocatorCore is an on-device Swift library that tells a user exactly where to hold their
    phone against an NFC reader, tag, or smart lock. It resolves a per-device antenna location
    through a three-layer chain (host-supplied remote catalog, bundled offline seed catalog,
    generic form-factor heuristic) and ships ready-to-use SwiftUI components
    (AntennaLocatorScreen, AntennaSilhouette, GuidedSweepAnimation) alongside the underlying
    resolver so integrators can use either the full screen or just the resolver logic.
  DESC

  s.homepage         = 'https://github.com/nagarjunavs/NFCLocatoriOS'
  s.license          = { type: 'MIT', file: 'LICENSE' }
  s.author           = 'Nagarjuna Vutkuri Swamy'

  # The `tag:` below must exactly match an actual git tag pushed to the repository before
  # `pod trunk push` — CocoaPods resolves `source_files` from that tag, not from HEAD.
  s.source           = { git: 'https://github.com/nagarjunavs/NFCLocatoriOS.git', tag: s.version.to_s }

  s.swift_version    = '5.10'
  s.ios.deployment_target = '17.0'

  s.source_files     = 'NFCLocatorCore/Sources/NFCLocatorCore/**/*.swift'

  # SwiftPM synthesizes `Bundle.module` for resource access at build time; CocoaPods has no
  # equivalent, so resources are packaged into a named resource bundle instead. The library's
  # `Bundle.nfcLocatorCoreResources` accessor (Support/Bundle+NFCLocatorCore.swift) resolves a
  # bundle named exactly "NFCLocatorCore" under CocoaPods — this name must match.
  s.resource_bundles = {
    'NFCLocatorCore' => ['NFCLocatorCore/Sources/NFCLocatorCore/Resources/*']
  }

  s.frameworks       = 'SwiftUI', 'SwiftData'

  # No third-party dependencies today — kept intentionally empty. If a dependency is ever added,
  # pin it to a tested version range here and record why in CHANGELOG.md.
  # s.dependency 'SomePackage', '~> 1.0'
end
