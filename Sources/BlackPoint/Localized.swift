import Foundation

enum L10n {
    private static var language: AppLanguage = .system

    static func configure(language: AppLanguage) {
        self.language = language
    }

    static func text(_ key: String) -> String {
        if let bundle = localizedBundle {
            let localized = bundle.localizedString(forKey: key, value: nil, table: nil)
            if localized != key {
                return localized
            }
        }

        let appLocalized = Bundle.main.localizedString(forKey: key, value: nil, table: nil)
        if appLocalized != key {
            return appLocalized
        }

        let moduleLocalized = Bundle.module.localizedString(forKey: key, value: nil, table: nil)
        if moduleLocalized != key {
            return moduleLocalized
        }

        return key
    }

    private static var localizedBundle: Bundle? {
        guard let identifier = language.localizationIdentifier else {
            return nil
        }

        if let path = Bundle.main.path(forResource: identifier, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }

        if let path = Bundle.module.path(forResource: identifier, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }

        return nil
    }
}
