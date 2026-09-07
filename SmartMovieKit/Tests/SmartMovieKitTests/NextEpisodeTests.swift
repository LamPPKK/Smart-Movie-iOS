import XCTest
@testable import SmartMovieKit

final class NextEpisodeTests: XCTestCase {
    func testNextUnwatchedEpisodeUsesSeasonAndEpisodeOrder() {
        let episodes = [
            EpisodeSummary(id: 3, seriesID: 1, seasonNumber: 2, episodeNumber: 1, name: "S2E1"),
            EpisodeSummary(id: 1, seriesID: 1, seasonNumber: 1, episodeNumber: 1, name: "S1E1"),
            EpisodeSummary(id: 2, seriesID: 1, seasonNumber: 1, episodeNumber: 2, name: "S1E2"),
        ]
        XCTAssertEqual(episodes.nextUnwatchedEpisode(watchedEpisodeNumbers: [1])?.name, "S1E2")
    }

    func testReturnsNilWhenAllEpisodesAreWatched() {
        let episode = EpisodeSummary(id: 1, seriesID: 1, seasonNumber: 1, episodeNumber: 1, name: "S1E1")
        XCTAssertNil([episode].nextUnwatchedEpisode(watchedEpisodeNumbers: [1]))
    }
}
