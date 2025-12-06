import Foundation
import Supabase

/// Singleton client for Supabase connection
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://gxmssvosvlznfbunnjxi.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd4bXNzdm9zdmx6bmZidW5uanhpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ5OTA3MTEsImV4cCI6MjA4MDU2NjcxMX0.vjF9vJ_ceCtWwYUbaiw3_lnmWIfIe36cQTOAiyzjhYk"
        )
    }
}
