//
//  BookmarkHelper.swift
//  Outlander
//
//  Created by Joseph McBride on 12/13/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Cocoa
import Foundation

class Preferences {
    static var workingDirectoryBookmark: Data? {
        get {
            UserDefaults.standard.data(forKey: "workingDirectoryBookmark")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "workingDirectoryBookmark")
        }
    }
}

// https://benscheirman.com/2019/10/troubleshooting-appkit-file-permissions/
class BookmarkHelper {
    func promptOrRestore() -> URL? {
        guard let bookmark = Preferences.workingDirectoryBookmark else {
            if let url = promptForWorkingDirectoryPermission() {
                saveBookmarkData(for: url)
                if let bookmark2 = Preferences.workingDirectoryBookmark {
                    return restoreFileAccess(with: bookmark2)
                }
                return nil
            } else {
                return nil
            }
        }

        return restoreFileAccess(with: bookmark)
    }

    private func promptForWorkingDirectoryPermission() -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.message = "Choose your Outlander settings directory"
        openPanel.prompt = "Choose"
        openPanel.allowedFileTypes = ["none"]
        openPanel.allowsOtherFileTypes = false
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents").appendingPathComponent("Outlander2")

        _ = openPanel.runModal()
        print(openPanel.urls) // this contains the chosen folder
        return openPanel.urls.first
    }

    private func saveBookmarkData(for workDir: URL) {
        do {
            let bookmarkData = try workDir.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)

            // save in UserDefaults
            Preferences.workingDirectoryBookmark = bookmarkData
        } catch {
            print("Failed to save bookmark data for \(workDir)", error)
        }
    }

    private func restoreFileAccess(with bookmarkData: Data) -> URL? {
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale {
                // bookmarks could become stale as the OS changes
                print("Bookmark is stale, need to save a new one... ")
                saveBookmarkData(for: url)
            }
            return url
        } catch {
            print("Error resolving bookmark:", error)
            return nil
        }
    }
}
