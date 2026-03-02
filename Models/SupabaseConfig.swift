import Foundation
import Supabase

class SupabaseConfig {
    static let shared = SupabaseConfig()
    
    let supabaseURL: URL
    let supabaseAnonKey: String
    
    lazy var client: SupabaseClient = {
        return SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey
        )
    }()

    var functionsBaseURL: URL {
        guard let host = supabaseURL.host else {
            return supabaseURL
        }

        let projectRef = host.replacingOccurrences(of: ".supabase.co", with: "")
        return URL(string: "https://\(projectRef).functions.supabase.co") ?? supabaseURL
    }
    
    private init() {
        // Prefer Info.plist (values injected from .xcconfig), fallback to bundled Config.plist.
        if let infoPlist = Bundle.main.infoDictionary,
           let urlString = infoPlist["SupabaseURL"] as? String,
           let url = URL(string: urlString),
           let key = infoPlist["SupabaseAnonKey"] as? String {
            self.supabaseURL = url
            self.supabaseAnonKey = key
            return
        }

        if let configURL = Bundle.main.url(forResource: "Config", withExtension: "plist"),
           let data = try? Data(contentsOf: configURL),
           let config = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
           let urlString = config["SUPABASE_URL"] as? String,
           let url = URL(string: urlString),
           let key = config["SUPABASE_ANON_KEY"] as? String {
            self.supabaseURL = url
            self.supabaseAnonKey = key
            return
        }

        fatalError("Failed to load Supabase configuration. Ensure Info.plist or Config.plist includes SupabaseURL/SupabaseAnonKey or SUPABASE_URL/SUPABASE_ANON_KEY.")
    }
}
