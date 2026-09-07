import Foundation
import Observation

@MainActor
@Observable
public final class HomeViewModel {
    public var mediaType: MediaType = .movie
    public private(set) var state: Loadable<HomeFeed> = .idle
    public private(set) var trending: [TitleSummary] = []
    private let catalog: any CatalogRepository
    private var loadTask: Task<Void, Never>?

    public init(catalog: any CatalogRepository) {
        self.catalog = catalog
    }

    public func load(language: String, force: Bool = false) {
        if !force, case .loaded(let feed) = state, feed.mediaType == mediaType { return }
        loadTask?.cancel()
        state = .loading
        let selectedType = mediaType
        loadTask = Task { [weak self, catalog] in
            do {
                let feed = try await catalog.home(mediaType: selectedType, language: language)
                let trending: [TitleSummary] = if let v2 = catalog as? any CatalogV2Repository {
                    (try? await v2.trending(kind: selectedType.rawValue, window: "week", page: 1, language: language, includeAdult: false).results.compactMap {
                        if case .title(let value) = $0 { return value }; return nil
                    }) ?? []
                } else { [] }
                guard !Task.isCancelled, self?.mediaType == selectedType else { return }
                self?.state = .loaded(feed)
                self?.trending = trending
            } catch is CancellationError {
                return
            } catch {
                self?.state = .failed(error.localizedDescription)
            }
        }
    }
}

public enum CatalogLayout: String, CaseIterable, Identifiable {
    case grid
    case list
    public var id: String { rawValue }
}
