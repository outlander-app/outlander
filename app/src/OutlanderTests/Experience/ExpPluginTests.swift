//
//  ExpPluginTests.swift
//  OutlanderTests
//
//  Created by Joe McBride on 11/5/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import XCTest

class ExpPluginTests: XCTestCase {
    func test_xml_parse() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        _ = plugin.parse(xml: "<component id='exp First Aid'>       First Aid:  565 87% cogitating </component>")

        XCTAssertEqual(host.variables["First_Aid.Ranks"], "565.87")
        XCTAssertEqual(host.variables["First_Aid.LearningRate"], "24")
        XCTAssertEqual(host.variables["First_Aid.LearningRateName"], "cogitating")
    }

    func test_xml_parse_whisper() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        _ = plugin.parse(xml: "<component id='exp Sorcery'><preset id='whisper'>          Sorcery:  694 85% mind lock     </preset></component>")

        XCTAssertEqual(host.variables["Sorcery.Ranks"], "694.85")
        XCTAssertEqual(host.variables["Sorcery.LearningRate"], "34")
        XCTAssertEqual(host.variables["Sorcery.LearningRateName"], "mind lock")
    }

    func test_xml_parse_empty() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        _ = plugin.parse(xml: "<component id='exp Sorcery'></component>")

        XCTAssertEqual(host.variables["Sorcery.Ranks"], "0.0")
        XCTAssertEqual(host.variables["Sorcery.LearningRate"], "0")
        XCTAssertEqual(host.variables["Sorcery.LearningRateName"], "clear")
    }

    func test_xml_parse_multi_tag() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        _ = plugin.parse(xml: "<roundTime value='1634753994'/><component id='exp Arcana'><preset id='whisper'>          Arcana:  1644 35% dabbling     </preset></component>")

        XCTAssertEqual(host.variables["Arcana.Ranks"], "1644.35")
        XCTAssertEqual(host.variables["Arcana.LearningRate"], "1")
        XCTAssertEqual(host.variables["Arcana.LearningRateName"], "dabbling")
    }

    func test_update_exp_window_sends_clear_exp_window() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        _ = plugin.parse(xml: "<component id='exp Sorcery'></component>")
        _ = plugin.parse(xml: "<prompt time=\"1634753924\">&gt;</prompt>")

        XCTAssertEqual(host.sendHistory.first, "#echo >experience @suspend@")
        XCTAssertEqual(host.sendHistory.last, "#echo >experience @resume@")
    }

    func test_update_exp_window_sends_exp() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        _ = plugin.parse(xml: "<component id='exp Sorcery'><preset id='whisper'>          Sorcery:  694 85% mind lock     </preset></component>")
        _ = plugin.parse(xml: "<prompt time=\"1634753924\">&gt;</prompt>")

        XCTAssertEqual(host.sendHistory[1], "#echo >experience          Sorcery:  694 85%  (34/34)  0.00")
    }

    func test_to_orderby() {
        var name: ExpTracker.OrderBy? = "name".toOrderBy()
        XCTAssertEqual(name, .name)

        name = " name ".toOrderBy()
        XCTAssertEqual(name, .name)
    }

    func test_lowest_skill_mindstate() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        _ = plugin.parse(xml: "<component id='exp Sorcery'><preset id='whisper'>          Sorcery:  700 00% dabbling    </preset></component>")
        _ = plugin.parse(xml: "<component id='exp First Aid'><preset id='whisper'>          First Aid:  700 00% perusing    </preset></component>")

        _ = plugin.parse(input: "/tracker lowest Sorcery|First_Aid")

        XCTAssertEqual(host.sendHistory[0], "#parse EXPTRACKER Sorcery 0")
    }

    func test_lowest_skill_ranks() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        _ = plugin.parse(xml: "<component id='exp Sorcery'><preset id='whisper'>          Sorcery:  700 00% dabbling    </preset></component>")
        _ = plugin.parse(xml: "<component id='exp First Aid'><preset id='whisper'>          First Aid:  701 00% dabbling    </preset></component>")

        _ = plugin.parse(input: "/tracker lowest Sorcery|First_Aid")

        XCTAssertEqual(host.sendHistory[0], "#parse EXPTRACKER Sorcery 0")
    }

    func test_lowest_skill_ranks_no_mindstate() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        _ = plugin.parse(xml: "<component id='exp Forging'><preset id='whisper'>          Forging:   1661 87% clear   </preset></component>")
        _ = plugin.parse(xml: "<component id='exp Engineering'><preset id='whisper'>          Engineering:   1356 88% clear    </preset></component>")
        _ = plugin.parse(xml: "<component id='exp Outfitting'><preset id='whisper'>          Outfitting:   1629 64% clear    </preset></component>")
        _ = plugin.parse(xml: "<component id='exp Alchemy'><preset id='whisper'>          Alchemy:   1127 01% clear    </preset></component>")
        _ = plugin.parse(xml: "<component id='exp Enchanting'><preset id='whisper'>          Enchanting:    966 60% clear    </preset></component>")
        _ = plugin.parse(xml: "<component id='exp Scholarship'><preset id='whisper'>          Scholarship:   1515 59% clear    </preset></component>")
        _ = plugin.parse(xml: "<component id='exp Performance'><preset id='whisper'>          Performance:   1334 56% clear   </preset></component>")
        _ = plugin.parse(xml: "<component id='exp Tactics'><preset id='whisper'>          Tactics:   1626 67% clear    </preset></component>")

        _ = plugin.parse(input: "/tracker lowest Alchemy|Performance|Enchanting|Engineering|Outfitting|Forging")

        XCTAssertEqual(host.sendHistory[0], "#parse EXPTRACKER Enchanting 2")
    }

    func test_lowest_skill_mindstate_() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        _ = plugin.parse(xml: "<component id='exp Forging'><preset id='whisper'>          Forging:   1661 87% clear   </preset></component>")
        _ = plugin.parse(xml: "<component id='exp Engineering'><preset id='whisper'>          Engineering:   1356 88% clear    </preset></component>")
        _ = plugin.parse(xml: "<component id='exp Outfitting'><preset id='whisper'>          Outfitting:   1629 64% clear    </preset></component>")
        _ = plugin.parse(xml: "<component id='exp Alchemy'><preset id='whisper'>          Alchemy:   1127 01% clear    </preset></component>")
        _ = plugin.parse(xml: "<component id='exp Enchanting'><preset id='whisper'>          Enchanting:    966 60% dabbling    </preset></component>")
        _ = plugin.parse(xml: "<component id='exp Scholarship'><preset id='whisper'>          Scholarship:   1515 59% clear    </preset></component>")
        _ = plugin.parse(xml: "<component id='exp Performance'><preset id='whisper'>          Performance:   1334 56% clear   </preset></component>")
        _ = plugin.parse(xml: "<component id='exp Tactics'><preset id='whisper'>          Tactics:   1626 67% clear    </preset></component>")

        _ = plugin.parse(input: "/tracker lowest Alchemy|Performance|Engineering|Outfitting|Forging|Enchanting")

        XCTAssertEqual(host.sendHistory[0], "#parse EXPTRACKER Alchemy 0")
    }

    func test_highest_skill_mindstate() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        _ = plugin.parse(xml: "<component id='exp Sorcery'><preset id='whisper'>          Sorcery:  700 00% dabbling    </preset></component>")
        _ = plugin.parse(xml: "<component id='exp First Aid'><preset id='whisper'>          First Aid:  700 00% perusing    </preset></component>")

        _ = plugin.parse(input: "/tracker highest Sorcery|First_Aid")

        XCTAssertEqual(host.sendHistory[0], "#parse EXPTRACKER First_Aid 1")
    }

    func test_highest_skill_ranks() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        _ = plugin.parse(xml: "<component id='exp Sorcery'><preset id='whisper'>          Sorcery:  700 00% dabbling    </preset></component>")
        _ = plugin.parse(xml: "<component id='exp First Aid'><preset id='whisper'>          First Aid:  701 00% dabbling    </preset></component>")

        _ = plugin.parse(input: "/tracker highest Sorcery|First_Aid")

        XCTAssertEqual(host.sendHistory[0], "#parse EXPTRACKER First_Aid 1")
    }

    func test_handles_exp_brief() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        _ = plugin.parse(xml: "<component id='exp Shield Usage'><d cmd='skill Shield Usage'>  Shield</d>:   71 33% [33/34]</component>")

        XCTAssertEqual(host.variables["Shield_Usage.Ranks"], "71.33")
        XCTAssertEqual(host.variables["Shield_Usage.LearningRate"], "33")
        XCTAssertEqual(host.variables["Shield_Usage.LearningRateName"], "nearly locked")
    }

    func test_handles_exp_brief_whisper() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        _ = plugin.parse(xml: "<component id='exp Scholarship'><preset id='whisper'><d cmd='skill Scholarship'> Scholar</d>:  552 30%  [ 3/34]</preset></component>")

        XCTAssertEqual(host.variables["Scholarship.Ranks"], "552.30")
        XCTAssertEqual(host.variables["Scholarship.LearningRate"], "3")
        XCTAssertEqual(host.variables["Scholarship.LearningRateName"], "learning")
    }

    func test_rexp_parse() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        _ = plugin.parse(xml: "<component id='exp rexp'>Rested EXP Stored: 5:59 hours  Usable This Cycle: 5:53 hours  Cycle Refreshes: 22:32 hours</component>")

        XCTAssertEqual(host.variables["rexp"], "Rested EXP Stored: 5:59 hours  Usable This Cycle: 5:53 hours  Cycle Refreshes: 22:32 hours")
    }

    func test_rexp_empty_parse() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        _ = plugin.parse(xml: "<component id='exp rexp'></component>")

        XCTAssertEqual(host.variables["rexp"], "")
    }

    func test_sleep_parse() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        _ = plugin.parse(xml: "<component id='exp sleep'><b>You are relaxed and your mind has entered a state of rest.  To wake up and start learning again, type: AWAKEN</b></component>")

        XCTAssertEqual(host.variables["sleep"], "You are relaxed and your mind has entered a state of rest.  To wake up and start learning again, type: AWAKEN")
    }

    func test_sleep_empty_parse() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        _ = plugin.parse(xml: "<component id='exp sleep'></component>")

        XCTAssertEqual(host.variables["sleep"], "")
    }

    func test_tdp_parse() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        _ = plugin.parse(xml: "<component id='exp tdp'>            TDPs:  926</component>")

        XCTAssertEqual(host.variables["tdp"], "926")
    }

    func test_favor_parse() {
        let host = TestHost()
        let plugin = ExpPlugin()
        plugin.initialize(host: host)

        _ = plugin.parse(xml: "<component id='exp favor'>          Favors:  12</component>")

        XCTAssertEqual(host.variables["favor"], "12")
    }
}
