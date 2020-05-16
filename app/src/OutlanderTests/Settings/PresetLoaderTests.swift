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
        self.loader = PresetLoader(fileSystem)
    }
    
    func test_load() {
        self.fileSystem.contentToLoad = "#preset {automapper} {#99FFFF}\n#preset {chatter} {#99FFFF}"

        loader!.load(context.applicationSettings, context: context)

        XCTAssertEqual(context.presets.count, 14)
        XCTAssertEqual(context.presets["automapper"]?.color, "#99ffff")
    }
    
    func test_load_class() {
        self.fileSystem.contentToLoad = "#preset {automapper} {#42FFFF} {my_class}\n#preset {chatter} {#99FFFF}"
        
        loader!.load(context.applicationSettings, context: context)
        
        XCTAssertEqual(context.presets["automapper"]?.color, "#42ffff")
        XCTAssertEqual(context.presets["automapper"]?.presetClass, "my_class")
    }
    
    func test_save() {
        self.fileSystem.contentToLoad = "#preset {automapper} {#99FFFF}\n#preset {chatter} {#42FFFF} {my_class}"

        loader!.load(context.applicationSettings, context: context)
        loader!.save(context.applicationSettings, presets: context.presets)

        XCTAssertEqual(self.fileSystem.savedContent ?? "",
                       """
#preset {automapper} {#99ffff}
#preset {chatter} {#42ffff} {my_class}
#preset {creatures} {#ffff00}
#preset {exptracker} {#66ffff}
#preset {roomdesc} {#cccccc}
#preset {roomname} {#0000ff}
#preset {scriptecho} {#66ffff}
#preset {scripterror} {#efefef,#ff3300}
#preset {scriptinfo} {#0066cc}
#preset {scriptinput} {#acff2f}
#preset {sendinput} {#acff2f}
#preset {speech} {#66ffff}
#preset {thought} {#66ffff}
#preset {whisper} {#66ffff}

""")
    }
}
