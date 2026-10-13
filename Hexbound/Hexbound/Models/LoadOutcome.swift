import Foundation

/// Result of a cache-first list load.
///
/// The screens in this app show warm cache first and refresh in the background.
/// That pattern has one dangerous failure mode, and every list screen had it:
/// the service caught its network error, returned `[]`, and the view model
/// assigned and CACHED that empty array. A single offline refresh therefore
///
///   1. wiped good data off the screen,
///   2. persisted the emptiness, so it survived a relaunch, and
///   3. looked identical to "you own nothing" — the `ErrorStateView` on those
///      screens was unreachable because `errorMessage` was never assigned.
///
/// Distinguishing "loaded, and it is empty" from "could not load" is the whole
/// point of this type. Use `apply(...)` so the three rules stay in one place
/// instead of being re-derived per screen.
enum LoadOutcome<Value> {
    /// The server answered. The value is authoritative, empty or not.
    case loaded(Value)

    /// The load never ran — no character selected yet, for instance. Nothing
    /// is known, so nothing is assigned and nothing is cached. This is NOT an
    /// error the player should see.
    case skipped

    /// The load failed. Whatever is already on screen stays there.
    case failed(Error)

    /// The loaded value, or nil when the load failed or was skipped.
    var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    var isFailure: Bool {
        if case .failed = self { return true }
        return false
    }

    /// Short, player-facing reason, or nil when there is nothing to show.
    ///
    /// Nil for a 401: `APIError.isUnauthorized` is handled globally by the
    /// session-expired modal, and a local error page would render behind it.
    /// `APIError.userMessage` is used rather than `errorDescription` because
    /// the latter is the raw string and can carry decode/SQL detail.
    var userMessage: String? {
        guard case .failed(let error) = self else { return nil }
        if let apiError = error as? APIError {
            if apiError.isUnauthorized { return nil }
            return apiError.userMessage
        }
        return "Couldn't load. Check your connection and try again."
    }

    /// Apply the outcome to a screen's state.
    ///
    /// On success: assign, cache, clear the error.
    /// On skip: do nothing at all.
    /// On failure: set the error and **leave the previous value and cache
    /// untouched** — a stale list the player can still read beats an empty one.
    ///
    /// Setting an error does not by itself make the screen an error page: a
    /// screen with warm data keeps showing it. See `showsErrorState` on the
    /// view models.
    @MainActor
    func apply(
        assign: (Value) -> Void,
        cache: (Value) -> Void = { _ in },
        setError: (String?) -> Void
    ) {
        switch self {
        case .loaded(let value):
            assign(value)
            cache(value)
            setError(nil)
        case .skipped:
            break
        case .failed:
            setError(userMessage)
        }
    }
}
