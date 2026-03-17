import Foundation
import GoogleSignIn

/// Wrapper around Google Sign-In SDK for easy integration.
@MainActor
enum GoogleSignInHelper {

    struct GoogleSignInResult {
        let idToken: String
        let accessToken: String
        let email: String?
        let fullName: String?
    }

    /// Triggers the Google Sign-In flow and returns the ID token + access token.
    static func signIn() async throws -> GoogleSignInResult {
        // Configure with iOS Client ID
        let config = GIDConfiguration(clientID: AppConstants.googleClientID)
        GIDSignIn.sharedInstance.configuration = config

        // Get the top-most view controller for presenting
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            throw GoogleSignInError.noRootViewController
        }

        // Find the top presented VC
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)

        guard let idToken = result.user.idToken?.tokenString else {
            throw GoogleSignInError.noIDToken
        }

        let accessToken = result.user.accessToken.tokenString
        let email = result.user.profile?.email
        let fullName = result.user.profile?.name

        return GoogleSignInResult(
            idToken: idToken,
            accessToken: accessToken,
            email: email,
            fullName: fullName
        )
    }

    /// Handle the URL callback from Google Sign-In.
    static func handle(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

enum GoogleSignInError: LocalizedError {
    case noRootViewController
    case noIDToken

    var errorDescription: String? {
        switch self {
        case .noRootViewController:
            return "Could not find root view controller"
        case .noIDToken:
            return "Google Sign In did not return an ID token"
        }
    }
}
