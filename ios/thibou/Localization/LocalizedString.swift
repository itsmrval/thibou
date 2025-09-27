import SwiftUI

enum LocalizedKey: String, CaseIterable {
    case ok = "Common.ok"
    case cancel = "Common.cancel"
    case back = "Common.back"
    case next = "Common.next"
    case done = "Common.done"
    case save = "Common.save"
    case delete = "Common.delete"
    case edit = "Common.edit"
    case loading = "Common.loading"
    case error = "Common.error"
    case success = "Common.success"
    case retry = "Common.retry"
    case search = "Common.search"
    case searchPlaceholder = "Common.search_placeholder"
    case suggested = "Common.suggested"
    case searching = "Common.searching"
    case noResultsFound = "Common.no_results_found"
    case noResultsDescription = "Common.no_results_description"
    case notSpecified = "Common.not_specified"
    case yes = "Common.yes"
    case no = "Common.no"
    case version = "Common.version"
    case unexpectedError = "Common.unexpected_error"
    case home = "Common.navigation.home"
    case library = "Common.navigation.library"
    case tools = "Common.navigation.tools"
    case settings = "Common.navigation.settings"
    case myIsland = "Common.navigation.my_island"
    case villagers = "Components/Library.villagers"
    case fish = "Components/Library.fish"
    case bugs = "Components/Library.bugs"
    case fossils = "Components/Library.fossils"
    case clothing = "Components/Library.clothing"
    case objects = "Components/Library.objects"
    case navigation = "Components/Library.navigation"
    case loadingVillagers = "Components/Library.loading_villagers"
    case errorOccurred = "Components/Library.error_occurred"
    case noVillagersFound = "Components/Library.no_villagers_found"
    case noFishFound = "Components/Library.no_fish_found"
    case noBugsFound = "Components/Library.no_bugs_found"
    case noFossilsFound = "Components/Library.no_fossils_found"
    case noClothingFound = "Components/Library.no_clothing_found"
    case noObjectsFound = "Components/Library.no_objects_found"
    case sharingTextTodo = "Components/Library.sharing_text_todo"
    case basicInformation = "Villager.basic_information"
    case species = "Villager.species"
    case gender = "Villager.gender"
    case personality = "Villager.personality"
    case birthday = "Villager.birthday"
    case gameInformation = "Villager.game_information"
    case astrologicalSign = "Villager.astrological_sign"
    case firstAppearance = "Villager.first_appearance"
    case islander = "Villager.islander"
    case favoriteQuote = "Villager.favorite_quote"
    case house = "Villager.house.title"
    case translations = "Villager.translations"
    case exterior = "Villager.house.exterior"
    case interior = "Villager.house.interior"
    case exteriorDescription = "Villager.house.exterior_description"
    case interiorDescription = "Villager.house.interior_description"
    case roof = "Villager.house.roof"
    case siding = "Villager.house.siding"
    case door = "Villager.house.door"
    case shape = "Villager.house.shape"
    case shapeDescription = "Villager.house.shape_description"
    case english = "Villager.languages.english"
    case french = "Villager.languages.french"
    case spanish = "Villager.languages.spanish"
    case german = "Villager.languages.german"
    case italian = "Villager.languages.italian"
    case japanese = "Villager.languages.japanese"
    case korean = "Villager.languages.korean"
    case chinese = "Villager.languages.chinese"
    case dutch = "Villager.languages.dutch"
    case russian = "Villager.languages.russian"
    case shortcuts = "Components/Home.shortcuts"
    case myInhabitants = "Components/Home.my_inhabitants"
    case analyzeArtwork = "Components/Home.analyze_artwork"
    case viewPatterns = "Components/Home.view_patterns"
    case viewMoreDetails = "Components/Home.view_more_details"
    case toolsTitle = "Components/Tools.tools"
    case wikiToolsComingSoon = "Components/Tools.wiki_tools_coming_soon"
    case myIslandTitle = "Components/Island.my_island"
    case comingSoon = "Components/Island.coming_soon"
    case loginRequired = "Components/Island.login_required"
    case loginDescription = "Components/Island.login_description"
    case signIn = "Components/Island.sign_in"
    case parameters = "Components/Auth.parameters"
    case general = "Components/Auth.general"
    case language = "Components/Auth.language"
    case account = "Components/Auth.account"
    case myAccount = "Components/Auth.my_account"
    case signOut = "Components/Auth.sign_out"
    case signInWithApple = "Components/Auth.sign_in_with_apple"
    case signInWithEmail = "Components/Auth.sign_in_with_email"
    case changeEmail = "Components/Auth.change_email"
    case changePassword = "Components/Auth.change_password"
    case linkAppleAccount = "Components/Auth.link_apple_account"
    case unlinkAppleAccount = "Components/Auth.unlink_apple_account"
    case chooseLangauge = "Components/Auth.choose_language"
    case createAccount = "Components/Auth.create_account"
    case signInAuth = "Components/Auth.sign_in"
    case username = "Components/Auth.username"
    case emailAddress = "Components/Auth.email_address"
    case newEmailAddress = "Components/Auth.new_email_address"
    case password = "Components/Auth.password"
    case newPassword = "Components/Auth.new_password"
    case currentPassword = "Components/Auth.current_password"
    case confirmPassword = "Components/Auth.confirm_password"
    case accountConnected = "Components/Auth.account_connected"
    case alreadyHaveAccount = "Components/Auth.already_have_account"
    case dontHaveAccount = "Components/Auth.dont_have_account"
    case waitingForApple = "Components/Auth.waiting_for_apple"
    case linkAppleDescription = "Components/Auth.link_apple_description"
    case unlinkAppleDescription = "Components/Auth.unlink_apple_description"
    case changePasswordTitle = "Components/Auth.change_password_title"
    case changeEmailTitle = "Components/Auth.change_email_title"
    case currentPasswordPlaceholder = "Components/Auth.current_password_placeholder"
    case newPasswordPlaceholder = "Components/Auth.new_password_placeholder"
    case confirmNewPassword = "Components/Auth.confirm_new_password"
    case newEmailPlaceholder = "Components/Auth.new_email_placeholder"
    case location = "Fish.location"
    case rarity = "Fish.rarity"
    case shopPrice = "Fish.shop_price"
    case cjPrice = "Fish.cj_price"
    case availability = "Fish.availability"
    case northernHemisphere = "Fish.northern_hemisphere"
    case southernHemisphere = "Fish.southern_hemisphere"
    case notAvailable = "Fish.not_available"
    case january = "Fish.months.january"
    case february = "Fish.months.february"
    case march = "Fish.months.march"
    case april = "Fish.months.april"
    case may = "Fish.months.may"
    case june = "Fish.months.june"
    case july = "Fish.months.july"
    case august = "Fish.months.august"
    case september = "Fish.months.september"
    case october = "Fish.months.october"
    case november = "Fish.months.november"
    case december = "Fish.months.december"
    case fishBasicInformation = "Fish.basic_information"
    case fishTranslations = "Fish.translations"

    static func speciesName(_ species: String) -> String {
        return LocalizationManager.shared.localizedString(for: "species_names.\(species)", component: "Villager", fallback: species.capitalized)
    }

    static func fishLocation(_ location: String) -> String {
        return LocalizationManager.shared.localizedString(for: "fish_locations.\(location)", component: "Components/Library", fallback: location.capitalized)
    }

    static func genderName(_ gender: String) -> String {
        return LocalizationManager.shared.localizedString(for: "genders.\(gender)", component: "Villager", fallback: gender.capitalized)
    }

    static func personalityName(_ personality: String) -> String {
        return LocalizationManager.shared.localizedString(for: "personalities.\(personality)", component: "Villager", fallback: personality.capitalized)
    }

    static func astrologicalSignName(_ sign: String) -> String {
        return LocalizationManager.shared.localizedString(for: "astrological_signs.\(sign)", component: "Villager", fallback: sign.capitalized)
    }

    static func gameAppearanceName(_ gameCode: String) -> String {
        return LocalizationManager.shared.localizedString(for: "game_appearances.\(gameCode)", component: "Villager", fallback: gameCode)
    }

    static func fishRarity(_ rarity: String) -> String {
        return LocalizationManager.shared.localizedString(for: "fish_rarities.\(rarity)", component: "Components/Library", fallback: rarity.capitalized)
    }

    static func fishLocationDescription(_ location: String) -> String {
        return LocalizationManager.shared.localizedString(for: "fish_location_descriptions.\(location)", component: "Fish", fallback: "Available in \(location)")
    }

    static func fishLanguageName(_ languageKey: String) -> String {
        return LocalizationManager.shared.localizedString(for: "languages.\(languageKey)", component: "Fish", fallback: languageKey.capitalized)
    }

    var localized: String {
        let components = rawValue.split(separator: ".").map(String.init)
        if components.count >= 2 {
            let component = components[0]
            let key = components.dropFirst().joined(separator: ".")
            return LocalizationManager.shared.localizedString(for: key, component: component)
        }
        return LocalizationManager.shared.localizedString(for: rawValue)
    }
}

extension Text {
    init(_ key: LocalizedKey) {
        self.init(key.localized)
    }
}
