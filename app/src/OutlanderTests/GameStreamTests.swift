//
//  GameStreamTests.swift
//  Outlander
//
//  Created by Joseph McBride on 7/29/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

@testable import Outlander
import XCTest

class GameStreamTests: XCTestCase {
    func streamCommands(_ lines: [String], context: GameContext = GameContext(), monsterIgnoreList: String = "") -> [StreamCommand] {
        var commands: [StreamCommand] = []
        let context = context

        let stream = GameStream(context: context) { cmd in
            commands.append(cmd)
        }
        stream.monsterCountIgnoreList = monsterIgnoreList

        stream.reset(true)

        for line in lines {
            stream.stream(line)
        }

        return commands
    }

    func testBasics() {
        let context = GameContext()
        let stream = GameStream(context: context) { _ in }
        stream.stream("Please wait for connection to game server.\r\n")
    }

    func testCombinedTags() {
        let commands = streamCommands([
            "Please wait for connection to game server.\r\n",
            "<prompt time=\"1576081991\">&gt;</prompt>\r\n",
        ])

        XCTAssertEqual(commands.count, 3)

        switch commands[2] {
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

    func test_stream_hand_ids() {
        let context = GameContext()
        let commands = streamCommands([
            "<left exist=\"21668354\" noun=\"scissors\">serrated scissors</left><right exist=\"22336507\" noun=\"belt\">survival belt</right>",
        ], context: context)

        XCTAssertEqual(commands.count, 3)

        XCTAssertEqual(context.globalVars["lefthandid"], "21668354")
        XCTAssertEqual(context.globalVars["righthandid"], "22336507")
    }
}

class GameStreamTokenizerTests: XCTestCase {
    var reader = GameStreamTokenizer()

    override func setUp() {}

    override func tearDown() {}

    func testHandlesText() {
        let tokens = reader.read("Copyright 2019 Simutronics Corp.\n")
        XCTAssertEqual(tokens.count, 1)
        let token = tokens[0]
        XCTAssertEqual(token.name(), "text")

        let tokens2 = reader.read("Copyright 2019 Simutronics Corp.\n")
        XCTAssertEqual(tokens2[0].name(), "text")
    }

    func testReadsSelfClosingTag() {
        let tokens = reader.read("<popStream/>\n")
        XCTAssertEqual(tokens.count, 2)
        let token = tokens[0]
        XCTAssertEqual(token.name(), "popstream")
    }

    func testReadsSelfClosingTagWithAttribute() {
        let tokens = reader.read("<popStream id=\"combat\"/>\n")
        XCTAssertEqual(tokens.count, 2)
        let token = tokens[0]
        XCTAssertEqual(token.name(), "popstream")
        XCTAssertEqual(token.attr("id"), "combat")
    }

    func testReadsCombatPopStreamSelfClosingTagWithAnotherTag() {
        let tokens = reader.read("<popStream id=\"combat\"/><prompt time=\"1563328849\">s&gt;</prompt>\n")
        XCTAssertEqual(tokens.count, 3)
        var token = tokens[0]
        XCTAssertEqual(token.name(), "popstream")
        XCTAssertEqual(token.attr("id"), "combat")

        token = tokens[1]
        XCTAssertEqual(token.name(), "prompt")
        XCTAssertEqual(token.attr("time"), "1563328849")
    }

    func testReadsCombatPopStreamTagWithAttribute() {
        let tokens = reader.read("<popStream id=\"combat\">\n")
        XCTAssertEqual(tokens.count, 2)
        let token = tokens[0]
        XCTAssertEqual(token.name(), "popstream")
        XCTAssertEqual(token.attr("id"), "combat")
    }

    func testReadsCombatPopStreamTagWithAnotherTag() {
        let tokens = reader.read("<popStream id=\"combat\"><prompt time=\"1563328849\">s&gt;</prompt>\n")
        XCTAssertEqual(tokens.count, 3)
        var token = tokens[0]
        XCTAssertEqual(token.name(), "popstream")
        XCTAssertEqual(token.attr("id"), "combat")

        token = tokens[1]
        XCTAssertEqual(token.name(), "prompt")
        XCTAssertEqual(token.attr("time"), "1563328849")
    }

    func testReadsEmptyTagWithClosingTag() {
        let tokens = reader.read("<spell></spell>\n")
        XCTAssertEqual(tokens.count, 2)
        let token = tokens[0]
        XCTAssertEqual(token.name(), "spell")
    }

    func testReadsTagWithChildText() {
        let tokens = reader.read("<spell>None</spell>\n")
        XCTAssertEqual(tokens.count, 2)
        let token = tokens[0]
        XCTAssertEqual(token.name(), "spell")
        XCTAssertEqual(token.value(), "None")
    }

    func testReadsTagWithChildTags() {
        let tokens = reader.read("<dialogData><skin>one</skin><skin>two</skin></dialogData>\n")
        XCTAssertEqual(tokens.count, 2)
        let token = tokens[0]
        XCTAssertEqual(token.name(), "dialogdata")
        XCTAssertEqual(token.value(), "one,two")
    }

    func testReadsSelfClosingTagAttributes() {
        let tokens = reader.read("<clearStream id=\"percWindow\"/>\n")
        XCTAssertEqual(tokens.count, 2)
        let token = tokens[0]
        XCTAssertEqual(token.name(), "clearstream")
        XCTAssertTrue(token.hasAttr("id"))
        XCTAssertEqual(token.attr("id"), "percWindow")
    }

    func testReadsTagAttributes() {
        let tokens = reader.read("<prompt time=\"1563328849\">s&gt;</prompt>\n")
        XCTAssertEqual(tokens.count, 2)
        let token = tokens[0]
        XCTAssertEqual(token.name(), "prompt")
        XCTAssertEqual(token.value(), "s&gt;")
        XCTAssertTrue(token.hasAttr("time"))
        XCTAssertEqual(token.attr("time"), "1563328849")
    }

    func testReadsTagMultipleAttributes() {
        let tokens = reader.read("<app char=\"Arneson\" game=\"DR\" title=\"[DR: Arneson] StormFront\"/>\n")
        XCTAssertEqual(tokens.count, 2)
        let token = tokens[0]
        XCTAssertEqual(token.name(), "app")

        XCTAssertTrue(token.hasAttr("char"))
        XCTAssertEqual(token.attr("char"), "Arneson")

        XCTAssertTrue(token.hasAttr("game"))
        XCTAssertEqual(token.attr("game"), "DR")

        XCTAssertTrue(token.hasAttr("title"))
        XCTAssertEqual(token.attr("title"), "[DR: Arneson] StormFront")
    }

    func testReadsTagTicQuotes() {
        let tokens = reader.read("<roundTime value='1563329043'/>\n")
        XCTAssertEqual(tokens.count, 2)
        let token = tokens[0]
        XCTAssertEqual(token.name(), "roundtime")

        XCTAssertTrue(token.hasAttr("value"))
        XCTAssertEqual(token.attr("value"), "1563329043")
    }

    func testReadsTagTicQuotesWithQuote() {
        let tokens = reader.read("<test value='some \"message\"'/>\n")
        XCTAssertEqual(tokens.count, 2)
        let token = tokens[0]
        XCTAssertEqual(token.name(), "test")

        XCTAssertTrue(token.hasAttr("value"))
        XCTAssertEqual(token.attr("value"), "some \"message\"")
    }

    func testReadsAttributesWithTics() {
        let tokens = reader.read("<test value=\"some 'message'\"/>\n")
        XCTAssertEqual(tokens.count, 2)
        let token = tokens[0]
        XCTAssertEqual(token.name(), "test")

        XCTAssertTrue(token.hasAttr("value"))
        XCTAssertEqual(token.attr("value"), "some 'message'")
    }

    func testReadsAttributesWithEscapedCharacters() {
        let tokens = reader.read("<test value=\"some \\\"message\\\"\"/>\n")
        XCTAssertEqual(tokens.count, 2)
        let token = tokens[0]
        XCTAssertEqual(token.name(), "test")

        XCTAssertTrue(token.hasAttr("value"))
        XCTAssertEqual(token.attr("value"), "some \"message\"")
    }

    func testReadsThoughts() {
        let tokens = reader.read("<pushStream id=\"thoughts\"/><preset id='thought'>[General][Someone] </preset>\"something to say\"\n")
        XCTAssertEqual(tokens.count, 3)

        let token = tokens[0]
        XCTAssertEqual(token.name(), "pushstream")

        XCTAssertTrue(token.hasAttr("id"))
        XCTAssertEqual(token.attr("id"), "thoughts")

        let preset = tokens[1]
        XCTAssertEqual(preset.name(), "preset")

        XCTAssertTrue(preset.hasAttr("id"))
        XCTAssertEqual(preset.attr("id"), "thought")
        XCTAssertEqual(preset.value(), "[General][Someone] ")

        let text = tokens[2]
        XCTAssertEqual(text.value(), "\"something to say\"\n")
    }

    func testParsesStreamWindowSubtitleWithInvalidQuotes() {
        // the subtitle has an invalid xml attribute
        let tokens = reader.read("<streamWindow id='room' title='Room' subtitle=\" - [\"Kertigen's Honor\"]\" location='center' target='drop' ifClosed='' resident='true'/>\n")
        XCTAssertEqual(tokens.count, 2)

        let token = tokens[0]
        XCTAssertEqual(token.name(), "streamwindow")

        XCTAssertTrue(token.hasAttr("subtitle"))
        XCTAssertEqual(token.attr("subtitle"), " - [\"Kertigen's Honor\"]")
    }

    func testParsesRoomExits() {
        let tokens = reader.read(
            "<component id='room exits'>Obvious paths: <d>northeast</d>, <d>south</d>, <d>northwest</d>.<compass></compass></component>\n"
        )

        XCTAssertEqual(tokens.count, 2)

        let token = tokens[0]
        XCTAssertEqual(token.name(), "component")
        XCTAssertEqual(token.children().count, 8)
    }

    func test_room_objs() {
        let tokens = reader.read(
            "<component id='room objs'>You also see <pushBold/>a juvenile wyvern<popBold/>, <pushBold/>a juvenile wyvern<popBold/>, a rocky path, <pushBold/>a juvenile wyvern<popBold/> and some junk.</component>\n"
        )

        XCTAssertEqual(tokens.count, 2)

        let token = tokens[0]
        XCTAssertEqual(token.name(), "component")
        XCTAssertEqual(token.children().count, 13)
    }

    func test_experience() {
        let tokens = reader.read("<component id='exp First Aid'><preset id='whisper'>       First Aid:  565 87% cogitating   </preset></component>")

        XCTAssertEqual(tokens.count, 1)

        let token = tokens[0]
        XCTAssertEqual(token.children().count, 1)
    }
}
