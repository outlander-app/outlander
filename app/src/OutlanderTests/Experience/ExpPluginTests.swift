//
//  ExpPluginTests.swift
//  OutlanderTests
//
//  Created by Joe McBride on 11/5/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

@testable import Outlander
import XCTest

class TestHost: IHost {
    var variables: [String: String] = [:]
    var sendHistory: [String] = []

    func send(text: String) {
        sendHistory.append(text)
    }

    func get(variable: String) -> String {
        variables[variable] ?? ""
    }

    func set(variable: String, value: String) {
        variables[variable] = value
    }
}

class ExpPluginTests: XCTestCase {
    func test_xml_parse() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        plugin.parse(xml: "<component id='exp First Aid'>       First Aid:  565 87% cogitating </component>")

        XCTAssertEqual(host.variables["First_Aid.Ranks"], "565.87")
        XCTAssertEqual(host.variables["First_Aid.LearningRate"], "24")
        XCTAssertEqual(host.variables["First_Aid.LearningRateName"], "cogitating")
    }

    func test_xml_parse_whisper() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        plugin.parse(xml: "<component id='exp Sorcery'><preset id='whisper'>          Sorcery:  694 85% mind lock     </preset></component>")

        XCTAssertEqual(host.variables["Sorcery.Ranks"], "694.85")
        XCTAssertEqual(host.variables["Sorcery.LearningRate"], "34")
        XCTAssertEqual(host.variables["Sorcery.LearningRateName"], "mind lock")
    }

    func test_xml_parse_empty() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        plugin.parse(xml: "<component id='exp Sorcery'></component>")

        XCTAssertEqual(host.variables["Sorcery.Ranks"], "0.0")
        XCTAssertEqual(host.variables["Sorcery.LearningRate"], "0")
        XCTAssertEqual(host.variables["Sorcery.LearningRateName"], "clear")
    }

    func test_xml_parse_multi_tag() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        plugin.parse(xml: "<roundTime value='1634753994'/><component id='exp Arcana'><preset id='whisper'>          Arcana:  1644 35% dabbling     </preset></component>")

        XCTAssertEqual(host.variables["Arcana.Ranks"], "1644.35")
        XCTAssertEqual(host.variables["Arcana.LearningRate"], "1")
        XCTAssertEqual(host.variables["Arcana.LearningRateName"], "dabbling")
    }

    func test_update_exp_window_sends_clear_exp_window() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        plugin.parse(xml: "<component id='exp Sorcery'></component>")
        plugin.parse(xml: "<prompt time=\"1634753924\">&gt;</prompt>")

        XCTAssertEqual(host.sendHistory.first, "#echo >experience @suspend@")
        XCTAssertEqual(host.sendHistory.last, "#echo >experience @resume@")
    }

    func test_update_exp_window_sends_exp() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        plugin.parse(xml: "<component id='exp Sorcery'><preset id='whisper'>          Sorcery:  694 85% mind lock     </preset></component>")
        plugin.parse(xml: "<prompt time=\"1634753924\">&gt;</prompt>")

        XCTAssertEqual(host.sendHistory[1], "#echo >experience          Sorcery:  694 85%  (34/34)  0.00")
    }

    func test_to_orderby() {
        var name: ExpTracker.OrderBy? = "name".toOrderBy()
        XCTAssertEqual(name, .name)

        name = " name ".toOrderBy()
        XCTAssertEqual(name, .name)
    }
}
