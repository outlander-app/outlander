//
//  VariablesLoaderTests.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

extension Date {
    init(_ dateString: String) {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale
        let date = dateStringFormatter.date(from: dateString)!
        self.init(timeInterval: 0, since: date)
    }
}

class TestClock: IClock {
    var now: Date {
        Date("2021-11-10")
//        Date(timeIntervalSince1970: 1636502400)
    }
}

class VariablesLoaderTests: XCTestCase {
    let fileSystem = InMemoryFileSystem()
    var loader: VariablesLoader?
    let context = GameContext()
    let clock: IClock = TestClock()

    override func setUp() {
        loader = VariablesLoader(fileSystem)
        context.globalVars = GlobalVariables(events: context.events, settings: context.applicationSettings, clock: clock)
    }

    func test_load() {
        fileSystem.contentToLoad = "#var {Alchemy.LearningRate} {0}\n#var {Alchemy.LearningRateName} {clear}\n"

        loader!.load(context.applicationSettings, context: context)

        XCTAssertEqual(context.globalVars.count, 12)
        XCTAssertEqual(context.globalVars["Alchemy.LearningRate"], "0")
        XCTAssertEqual(context.globalVars["Alchemy.LearningRateName"], "clear")
    }

    func test_save() {
        fileSystem.contentToLoad = "#var {Alchemy.LearningRate} {0}\n#var {Alchemy.LearningRateName} {clear}\n"

        loader!.load(context.applicationSettings, context: context)
        loader!.save(context.applicationSettings, variables: context.globalVars)
        
        let unixTime = clock.now.timeIntervalSince1970.formattedNumber

        XCTAssertEqual(fileSystem.savedContent ?? "",
                       """
                       #var {Alchemy.LearningRate} {0}
                       #var {Alchemy.LearningRateName} {clear}
                       #var {date} {2021-11-10}
                       #var {datetime} {2021-11-10 12:00:00 AM}
                       #var {lefthand} {Empty}
                       #var {preparedspell} {None}
                       #var {prompt} {>}
                       #var {righthand} {Empty}
                       #var {roundtime} {0}
                       #var {tdp} {0}
                       #var {time} {12:00:00 AM}
                       #var {unixtime} {\(unixTime)}

                       """)
    }
}
