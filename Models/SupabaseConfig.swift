import Foundation
import Supabase

class SupabaseConfig {
    static let shared = SupabaseConfig()
    
    private let supabaseURL: URL
    private let supabaseAnonKey: String
    
    lazy var client: SupabaseClient = {
        return SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey
        )
    }()
    
    private init() {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let urlString = plist["SUPABASE_URL"] as? String,
              let url = URL(string: urlString),
              let key = plist["SUPABASE_ANON_KEY"] as? String else {
            fatalError("Failed to load Supabase configuration from Config.plist")
        }
        self.supabaseURL = url
        self.supabaseAnonKey = key
    }
}
