//
//  GameStreamTokenizerTests.swift
//  
//
//  Created by Joe McBride on 12/20/25.
//


import XCTest

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

    func test_combat() {
        let tokens = reader.read("""
        <pushStream id="combat" />&lt; Moving like a striking snake, you slice a damascened haralun sterak axe with a dragonwood haft bound in Imperial weave at a juvenile wyvern.  A juvenile wyvern attempts to dodge, mainly avoiding the blow.  <pushBold/>The axe lands a heavy strike to the wyvern's right arm.<popBold/>
        [You're bruised, winded, nimbly balanced and in very strong position.]
        [Roundtime 4 sec.]
        <popStream id="combat" />
        """)

        XCTAssertEqual(tokens.count, 7)

        let token = tokens[5]
        XCTAssertEqual(token.value(), "\n[You're bruised, winded, nimbly balanced and in very strong position.]\n[Roundtime 4 sec.]\n")
    }

    func test_multi_tag_death_stream() {
        let tokens = reader.read("""
            <pushStream id="death"/> * Krohhnos was just struck down!
            <popStream/><pushStream id="death"/> * Krohhnos just disintegrated!
            <popStream/><prompt time="1639032361">H&gt;</prompt>
            """
        )

        XCTAssertEqual(tokens.count, 7)
    }

    func test_combat_measure() {
        measure {
            _ = reader.read("""
            <pushStream id="combat" />&lt; Moving like a striking snake, you slice a damascened haralun sterak axe with a dragonwood haft bound in Imperial weave at a juvenile wyvern.  A juvenile wyvern attempts to dodge, mainly avoiding the blow.  <pushBold/>The axe lands a heavy strike to the wyvern's right arm.<popBold/>
            [You're bruised, winded, nimbly balanced and in very strong position.]
            [Roundtime 4 sec.]
            <popStream id="combat" />
            """)
        }
    }

    func test_resync_feversion__invalid_xml_stream() {
        let tokens = reader.read("""
            <FEVersion ="0" character="Saracus" /><FEStart name="DragonRealms" time="1644525207" />
            """
        )

        XCTAssertEqual(tokens.count, 2)
    }

    func test_invalid_xml_stream_attribue_name_with_no_value() {
        let tokens = reader.read("""
            <FEVersion something= character="Saracus" />
            """
        )

        XCTAssertEqual(tokens.count, 1)

        let token = tokens[0]
        XCTAssertEqual(token.name(), "feversion")

        XCTAssertTrue(token.hasAttr("something"))
        XCTAssertEqual(token.attr("something"), "")

        XCTAssertTrue(token.hasAttr("character"))
        XCTAssertEqual(token.attr("character"), "Saracus")
    }

    func test_invalid_xml_stream_attribue_with_spaces() {
        let tokens = reader.read("""
            <FEVersion character = "Saracus" />
            """
        )

        XCTAssertEqual(tokens.count, 1)

        let token = tokens[0]
        XCTAssertEqual(token.name(), "feversion")

        XCTAssertTrue(token.hasAttr("character"))
        XCTAssertEqual(token.attr("character"), "Saracus")
    }

    func test_d_tag_stream() {
        let tokens = reader.read("""
            Raven's Point         <d cmd='urchin guide Raven's Point, Town Square'>Raven's Point, Town Square</d>
        """)

        XCTAssertEqual(tokens.count, 2)

        let token = tokens[1]
        XCTAssertEqual(token.name(), "d")
        XCTAssertTrue(token.hasAttr("cmd"))
        XCTAssertEqual(token.attr("cmd"), "urchin guide Raven's Point, Town Square")
    }

    func test_d_tag_stream_2() {
        let tokens = reader.read("""
            Raven's Point         <d cmd="urchin guide Raven's Point, Town Square">Raven's Point, Town Square</d>
        """)

        XCTAssertEqual(tokens.count, 2)

        let token = tokens[1]
        XCTAssertEqual(token.name(), "d")
        XCTAssertTrue(token.hasAttr("cmd"))
        XCTAssertEqual(token.attr("cmd"), "urchin guide Raven's Point, Town Square")
    }

    func test_invalid_component() {
        let tokens = reader.read("<component id='room exits'>Obvious paths: clockwise, widdershins.\n")

        XCTAssertEqual(tokens.count, 1)

        let token = tokens[0]
        XCTAssertEqual(token.children().count, 1)
    }

    func test_preset() {
        let tokens = reader.read("<preset id='automapper'>Mapped exits: go oak door, go clockwise, go widdershins</preset>")

        XCTAssertEqual(tokens.count, 1)

        let token = tokens[0]
        XCTAssertEqual(token.children().count, 1)
    }
}
