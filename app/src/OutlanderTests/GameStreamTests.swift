//
//  GameStreamTests.swift
//  Outlander
//
//  Created by Joseph McBride on 7/29/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import XCTest

class TestStreamHandler: StreamHandler {
    var dataList: [String] = []
    
    func stream(_ data: String, with context: GameContext) {
        guard !data.isEmpty else {
            return
        }

        dataList.append(data)
    }

    func reset() {
        dataList.removeAll()
    }
}

class GameStreamTests: XCTestCase {
    var testStreamHandler: TestStreamHandler = TestStreamHandler()

    func streamCommands(_ lines: [String], context: GameContext = GameContext(), monsterIgnoreList: String = "") -> [StreamCommand] {
        var commands: [StreamCommand] = []
        let context = context

        let stream = GameStream(context: context, pluginManager: InMemoryPluginManager()) { cmd in
            commands.append(cmd)
        }
        stream.monsterCountIgnoreList = monsterIgnoreList

        stream.reset(true)
        testStreamHandler.reset()

        stream.addHandler(testStreamHandler)

        for line in lines {
            stream.stream(line)
        }

        return commands
    }

    func testBasics() {
        let context = GameContext()
        let stream = GameStream(context: context, pluginManager: InMemoryPluginManager()) { _ in }
        stream.stream("Please wait for connection to game server.\r\n")
    }

    func testCombinedTags() {
        let commands = streamCommands([
            "Please wait for connection to game server.\r\n",
            "<prompt time=\"1576081991\">&gt;</prompt>\r\n",
        ])

        XCTAssertEqual(commands.count, 4)

        switch commands[3] {
        case let .text(tags):
            XCTAssertEqual(tags.count, 2)
        default:
            XCTFail()
        }
    }

    func testStreamRoomObjTags() {
        let context = GameContext()
        let commands = streamCommands([
            "<component id='room objs'>You also see a stick.</component>\r\n",
        ], context: context)

        XCTAssertEqual(commands.count, 2)

        switch commands[1] {
        case .room:
            XCTAssertEqual(context.globalVars["roomobjs"], "You also see a stick.")
        default:
            XCTFail()
        }
    }

    func testStreamRoomExitsTags() {
        let context = GameContext()
        let commands = streamCommands([
            "<component id='room exits'>Obvious paths: <d>north</d>, <d>south</d>.<compass></compass></component>\r\n",
        ], context: context)

        XCTAssertEqual(commands.count, 2)

        switch commands[1] {
        case .room:
            XCTAssertEqual(context.globalVars["roomexits"], "Obvious paths: north, south.")
        default:
            XCTFail()
        }
    }

    func test_stream_room_exit_multi_tags() {
        let context = GameContext()
        let commands = streamCommands([
            "<component id='room exits'>Obvious paths: clockwise, widdershins.\r\n",
            "\r\n",
            "<compass></compass></component>\r\n",
        ], context: context)

        XCTAssertEqual(commands.count, 4)

        switch commands[1] {
        case .room:
            XCTAssertEqual(context.globalVars["roomexits"], "Obvious paths: clockwise, widdershins.")
        default:
            XCTFail()
        }
    }

    func testStreamRoomDescTags() {
        let context = GameContext()
        let commands = streamCommands([
            "<component id='room desc'>The stone road, once the pinnacle of craftsmanship, is cracked and worn.</component>\r\n",
        ], context: context)

        XCTAssertEqual(commands.count, 2)

        switch commands[1] {
        case .room:
            XCTAssertEqual(context.globalVars["roomdesc"], "The stone road, once the pinnacle of craftsmanship, is cracked and worn.")
        default:
            XCTFail()
        }
    }

    func testStreamCompass() {
        let context = GameContext()
        let commands = streamCommands([
            "<compass><dir value=\"sw\"/><dir value=\"nw\"/></compass>",
        ], context: context)

        XCTAssertEqual(commands.count, 2)

        switch commands[1] {
        case .compass:
            XCTAssertEqual(context.globalVars["north"], "0")
            XCTAssertEqual(context.globalVars["south"], "0")
            XCTAssertEqual(context.globalVars["east"], "0")
            XCTAssertEqual(context.globalVars["west"], "0")
            XCTAssertEqual(context.globalVars["southwest"], "1")
            XCTAssertEqual(context.globalVars["southeast"], "0")
            XCTAssertEqual(context.globalVars["northwest"], "1")
            XCTAssertEqual(context.globalVars["northeast"], "0")
            XCTAssertEqual(context.globalVars["out"], "0")
            XCTAssertEqual(context.globalVars["down"], "0")
        default:
            XCTFail()
        }
    }

    func test_stream_room_objs_with_monsters() {
        let context = GameContext()
        let commands = streamCommands([
            "<component id='room objs'>You also see <pushBold/>a juvenile wyvern<popBold/>, <pushBold/>a juvenile wyvern<popBold/>, a rocky path, <pushBold/>a juvenile wyvern<popBold/> and some junk.</component>\n",
        ], context: context)

        XCTAssertEqual(commands.count, 2)

        switch commands[1] {
        case .room:
            XCTAssertEqual(context.globalVars["roomobjs"], "You also see a juvenile wyvern, a juvenile wyvern, a rocky path, a juvenile wyvern and some junk.")
        default:
            XCTFail()
        }

        XCTAssertEqual(context.globalVars["monstercount"], "3")
        XCTAssertEqual(context.globalVars["monsterlist"], "a juvenile wyvern|a juvenile wyvern|a juvenile wyvern")
    }

    func test_stream_room_objs_with_monsters_with_ignore_list() {
        let context = GameContext()
        let commands = streamCommands([
            "<component id='room objs'>You also see <pushBold/>a juvenile wyvern<popBold/>, <pushBold/>a juvenile wyvern<popBold/>, a rocky path, <pushBold/>a juvenile wyvern<popBold/> and <pushBold/>a great horned owl<popBold/>.</component>\n",
        ], context: context, monsterIgnoreList: "great horned owl")

        XCTAssertEqual(commands.count, 2)

        switch commands[1] {
        case .room:
            XCTAssertEqual(context.globalVars["roomobjs"], "You also see a juvenile wyvern, a juvenile wyvern, a rocky path, a juvenile wyvern and a great horned owl.")
        default:
            XCTFail()
        }

        XCTAssertEqual(context.globalVars["monstercount"], "3")
        XCTAssertEqual(context.globalVars["monsterlist"], "a juvenile wyvern|a juvenile wyvern|a juvenile wyvern")
    }

    func test_stream_preset() {
        let context = GameContext()
        let commands = streamCommands([
            "<preset id='roomDesc'>Fragrant smoke drifts from censers to carry periodic ripples of sound from the rooms beyond.</preset>  You also see an iron-bound oak door set in the far wall.\r\n",
            "<prompt time=\"1725664159\">&gt;</prompt>",
        ], context: context)

        XCTAssertEqual(commands.count, 4)

        switch commands[3] {
        case let .text(tags):
            XCTAssertEqual(tags[0].text, "Fragrant smoke drifts from censers to carry periodic ripples of sound from the rooms beyond.\nYou also see an iron-bound oak door set in the far wall.\n")
            XCTAssertEqual(tags[0].preset, "roomdesc")
            XCTAssertEqual(tags[1].text, ">")
            XCTAssertEqual(tags[1].isPrompt, true)
        default:
            XCTFail()
        }
    }

    func test_stream_hand_ids() {
        let context = GameContext()
        let commands = streamCommands([
            "<left exist=\"21668354\" noun=\"scissors\">serrated scissors</left><right exist=\"22336507\" noun=\"belt\">survival belt</right>",
        ], context: context)

        XCTAssertEqual(commands.count, 3)

        XCTAssertEqual(context.globalVars["lefthandid"], "21668354")
        XCTAssertEqual(context.globalVars["righthandid"], "22336507")
    }

    func test_combat_stream() {
        let context = GameContext()
        let commands = streamCommands([
            "<pushStream id=\"combat\" />&lt; Moving like a striking snake, you slice a damascened haralun sterak axe with a dragonwood haft bound in Imperial weave at a juvenile wyvern.  A juvenile wyvern attempts to dodge, mainly avoiding the blow.  <pushBold/>The axe lands a heavy strike to the wyvern's right arm.<popBold/>\n",
            "[You're bruised, winded, nimbly balanced and in very strong position.]\n",
            "[Roundtime 4 sec.]\n",
            "<popStream id=\"combat\" /><prompt time=\"1637690082\">R&gt;</prompt>\n",
        ], context: context)

        XCTAssertEqual(commands.count, 6)

        switch commands[5] {
        case let .text(tags):
            XCTAssertEqual(tags[2].text, "\n[You're bruised, winded, nimbly balanced and in very strong position.]\n[Roundtime 4 sec.]\n")
        default:
            XCTFail()
        }
    }

    func test_multi_tag_death_stream() {
        let context = GameContext()
        let commands = streamCommands([
            "<pushStream id=\"death\"/> * Krohhnos was just struck down!\n",
            "<popStream/><pushStream id=\"death\"/> * Krohhnos just disintegrated!\n",
            "<popStream/><prompt time=\"1639032361\">H&gt;</prompt>\n",
        ], context: context)

        XCTAssertEqual(commands.count, 5)

        switch commands[4] {
        case let .text(tags):
            XCTAssertEqual(tags[0].text, "* Krohhnos was just struck down!\n* Krohhnos just disintegrated!\n")
        default:
            XCTFail()
        }
    }

    func test_assess_stream() {
        let commands = streamCommands([
            "<pushStream id=\"assess\"/><clearStream id=\"assess\"/>You assess your combat situation...\n",
            "\n",
            "\n",
            "\n",
            "<popStream/><pushStream id=\"assess\"/>You (solidly balanced) are facing <d cmd='look #60060590'>a juvenile wyvern</d> (1) at melee range.\n",
            "<popStream/><pushStream id=\"assess\"/><d cmd='look #60060590'>A juvenile wyvern</d> (1: somewhat off balance) is facing you at melee range.  | <d cmd='face #60060590'>F</d>\n",
            "<popStream/><pushStream id=\"assess\"/><d cmd='look #60057929'>A juvenile wyvern</d> (2: somewhat off balance) is behind you at melee range.  | <d cmd='face #60057929'>F</d>\n",
            "<popStream/><pushStream id=\"assess\"/><d cmd='look #60057925'>A juvenile wyvern</d> (3: nimbly balanced) is behind you at melee range.  | <d cmd='face #60057925'>F</d>\n",
            "<popStream/><pushStream id=\"assess\"/><d cmd='look #60060598'>A juvenile wyvern</d> (4: slightly off balance) is flanking you at melee range.  | <d cmd='face #60060598'>F</d>\n",
            "<popStream/><prompt time=\"1637690082\">R&gt;</prompt>\n",
        ])

        XCTAssertEqual(commands.count, 13)

        switch commands[12] {
        case let .text(tags):
            XCTAssertEqual(tags.count, 20)
        default:
            XCTFail()
        }
    }

    func test_combines_concise_thoughts_stream() {
        let commands = streamCommands([
            "<pushStream id=\"thoughts\"/><preset id='thought'>[General][Someone] </preset>\"something to say\"\n",
            "<popStream/><prompt time=\"1638240815\">R&gt;</prompt>"
        ])
        XCTAssertEqual(commands.count, 4)

        XCTAssertEqual(testStreamHandler.dataList.count, 2)
        XCTAssertEqual(testStreamHandler.dataList[0], "[General][Someone] \"something to say\"")
        XCTAssertEqual(testStreamHandler.dataList[1], "R>")

        switch commands[3] {
        case let .text(tags):
            XCTAssertEqual(tags.count, 2)
            XCTAssertEqual(tags[0].text, "[General][Someone] \"something to say\"\n")
        default:
            XCTFail()
        }
    }
    
    func test_combines_thoughts_stream() {
        let commands = streamCommands([
            "<pushStream id=\"thoughts\"/><preset id='thought'>[General] Your mind hears Someone thinking, </preset>\"Yup, it works!\"\n",
            "<popStream/><prompt time=\"1766284988\">&gt;</prompt>"
        ])
        XCTAssertEqual(commands.count, 4)

        switch commands[3] {
        case let .text(tags):
            XCTAssertEqual(tags.count, 2)
            XCTAssertEqual(tags[0].text, "[General] Your mind hears Someone thinking, \"Yup, it works!\"\n")
        default:
            XCTFail()
        }
    }

    func test_combines_personal_recieve_concise_thoughts_stream() {
        let commands = streamCommands([
            "<pushStream id=\"thoughts\"/><preset id='thought'>[Personal][Someone] </preset>\"&lt;to you&gt;\"  \"test thought\"\n",
            "<popStream/><prompt time=\"1766284988\">&gt;</prompt>"
        ])
        XCTAssertEqual(commands.count, 4)

        switch commands[3] {
        case let .text(tags):
            XCTAssertEqual(tags.count, 2)
            XCTAssertEqual(tags[0].text, "[Personal][Someone] \"<to you>\"  \"test thought\"\n")
        default:
            XCTFail()
        }
    }

    func test_combines_personal_recieve_thoughts_stream() {
        let commands = streamCommands([
            "<pushStream id=\"thoughts\"/><preset id='thought'>[Personal] Your mind hears Someone thinking, </preset>\"&lt;to you&gt;\"  \"test thought\"\n",
            "<popStream/><prompt time=\"1766284988\">&gt;</prompt>"
        ])
        XCTAssertEqual(commands.count, 4)

        switch commands[3] {
        case let .text(tags):
            XCTAssertEqual(tags.count, 2)
            XCTAssertEqual(tags[0].text, "[Personal] Your mind hears Someone thinking, \"<to you>\"  \"test thought\"\n")
        default:
            XCTFail()
        }
    }

    func test_combines_send_thoughts_stream() {
        let commands = streamCommands([
            "<pushStream id=\"thoughts\"/><preset id='thought'>You to Saracus,</preset> \"Yup, it works!\"\n",
            "<popStream/>You project your thoughts to Saracus.",
            "<prompt time=\"1766284988\">&gt;</prompt>"
        ])
        XCTAssertEqual(commands.count, 5)

        switch commands[4] {
        case let .text(tags):
            XCTAssertEqual(tags.count, 3)
            XCTAssertEqual(tags[0].text, "You to Saracus, \"Yup, it works!\"\n")
        default:
            XCTFail()
        }
    }

//    func test_urchin_stream() {
//        let commands = streamCommands([
//            "Raven's Point         <d cmd='urchin guide Raven's Point, Town Square'>Raven's Point, Town Square</d>\n",
//            "Vela'Tohr Valley      <d cmd='urchin guide Cleric Guild'>Cleric Guild</d> (*)"
//        ])
//
//        XCTAssertEqual(commands.count, 3)
//
//        switch commands[2] {
//        case let .text(tags):
//            XCTAssertEqual(tags.count, 20)
//        default:
//            XCTFail()
//        }
//    }
}
