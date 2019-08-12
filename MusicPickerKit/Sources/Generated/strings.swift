// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
internal enum L10n {

  internal enum General {
    /// Add Music
    internal static let addMusic = L10n.tr("Localizable", "general.addMusic")
    /// End
    internal static let end = L10n.tr("Localizable", "general.end")
    /// Yikes! An error occurred.
    internal static let error = L10n.tr("Localizable", "general.error")
    /// Music
    internal static let music = L10n.tr("Localizable", "general.music")
    /// Ok
    internal static let ok = L10n.tr("Localizable", "general.ok")
    /// Start
    internal static let start = L10n.tr("Localizable", "general.start")
    /// Videos
    internal static let videos = L10n.tr("Localizable", "general.videos")
  }

  internal enum Music {
    /// Open Music app
    internal static let appOpen = L10n.tr("Localizable", "music.app_open")
    internal enum Download {
      /// The song you selected is not available on your device. In order to use it you must first download it to your device from your Music App
      internal static let description = L10n.tr("Localizable", "music.download.description")
      /// Download from iCloud
      internal static let title = L10n.tr("Localizable", "music.download.title")
    }
    internal enum Photos {
      /// Import from photos
      internal static let `import` = L10n.tr("Localizable", "music.photos.import")
    }
    internal enum SongUnavailable {
      /// The song you selected cannot be used since it's protected by DRM
      internal static let description = L10n.tr("Localizable", "music.song_unavailable.description")
      /// Song Unavailable
      internal static let title = L10n.tr("Localizable", "music.song_unavailable.title")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    // swiftlint:disable:next nslocalizedstring_key
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {}
