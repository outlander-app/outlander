//
//  PresetLoaderTests.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/15/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

class PresetLoaderTests: XCTestCase {
    let fileSystem = InMemoryFileSystem()
    var loader: PresetLoader?
    let context = GameContext()

    override func setUp() {
        loader = PresetLoader(fileSystem)
    }

    func test_load() {
        fileSystem.contentToLoad = "#preset {automapper} {#99FFFF}\n#preset {chatter} {#99FFFF}"

        loader!.load(context.applicationSettings, context: context)

        XCTAssertEqual(context.presets.count, 22)
        XCTAssertEqual(context.presets["automapper"]?.color, "#99ffff")
    }

    func test_load_class() {
        fileSystem.contentToLoad = "#preset {automapper} {#42FFFF} {my_class}\n#preset {chatter} {#99FFFF}"

        loader!.load(context.applicationSettings, context: context)

        XCTAssertEqual(context.presets["automapper"]?.color, "#42ffff")
        XCTAssertEqual(context.presets["automapper"]?.presetClass, "my_class")
    }

    func test_save() {
        fileSystem.contentToLoad = "#preset {automapper} {#99FFFF}\n#preset {chatter} {#42FFFF} {my_class}"

        loader!.load(context.applicationSettings, context: context)
        loader!.save(context.applicationSettings, presets: context.presets)

        XCTAssertEqual(fileSystem.savedContent ?? "",
                       """
                       #preset {automapper} {#99ffff}
                       #preset {chatter} {#42ffff} {my_class}
                       #preset {commandinput} {#f5f5f5,#1e1e1e}
                       #preset {concentration} {#f5f5f5,#009999}
                       #preset {creatures} {#ffff00}
                       #preset {exptracker} {#66ffff}
                       #preset {health} {#f5f5f5,#cc0000}
                       #preset {mana} {#f5f5f5,#00004b}
                       #preset {roomdesc} {#cccccc}
                       #preset {roomname} {#0000ff}
                       #preset {roundtime} {#f5f5f5,#003366}
                       #preset {scriptecho} {#66ffff}
                       #preset {scripterror} {#efefef,#ff3300}
                       #preset {scriptinfo} {#0066cc}
                       #preset {scriptinput} {#acff2f}
                       #preset {sendinput} {#acff2f}
                       #preset {speech} {#66ffff}
                       #preset {spirit} {#f5f5f5,#400040}
                       #preset {stamina} {#f5f5f5,#004000}
                       #preset {statusbartext} {#f5f5f5}
                       #preset {thought} {#66ffff}
                       #preset {whisper} {#66ffff}

                       """)
    }
}
