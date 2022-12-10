//
//  PathfinderTests.swift
//  OutlanderTests
//
//  Created by Joe McBride on 11/7/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation
import XCTest

private extension CollectionDifference {
    func testDescription(for change: Change) -> String? {
        switch change {
        case .insert(let index, let element, let association):
            if let oldIndex = association {
                return """
                Element moved from index \(oldIndex) to \(index): \(element)
                """
            } else {
                return "Additional element at index \(index): \(element)"
            }
        case .remove(let index, let element, let association):
            // If a removal has an association, it means that
            // it's part of a move, which we're handling above.
            guard association == nil else {
                return nil
            }

            return "Missing element at index \(index): \(element)"
        }
    }
}

private extension CollectionDifference {
    func asTestErrorMessage() -> String {
        let descriptions = compactMap(testDescription)

        guard !descriptions.isEmpty else {
            return ""
        }

        return "- " + descriptions.joined(separator: "\n- ")
    }
}

func assertEqual<T: BidirectionalCollection>(
    _ first: T,
    _ second: T,
    file: StaticString = #file,
    line: UInt = #line
) where T.Element: Hashable {
    let diff = second.difference(from: first).inferringMoves()
    let message = diff.asTestErrorMessage()

    XCTAssert(message.isEmpty, """
    The two collections are not equal. Differences:
    \(message)
    """, file: file, line: line)
}

class PathfinderTests: XCTestCase {
    func test_pathfinding() {
        let finder = Pathfinder()
        let zone = MapZone("1", "Crossing")

        let room1 = MapNode(id: "1", name: "Room 1", descriptions: [], notes: nil, color: nil, position: MapPosition(x: 0, y: 0, z: 0), arcs: [
            MapArc(exit: "south", move: "south", destination: "2", hidden: false),
        ])
        zone.addRoom(room1)

        let room2 = MapNode(id: "2", name: "Room 2", descriptions: [], notes: nil, color: nil, position: MapPosition(x: 0, y: 10, z: 0), arcs: [
            MapArc(exit: "north", move: "north", destination: "1", hidden: false),
        ])
        zone.addRoom(room2)

        let path = finder.findPath(start: "1", target: "2", zone: zone)
        let moves = zone.getMoves(ids: path)

        XCTAssertEqual(moves, ["south"])
    }

    func test_crossing_to_the_bank() {
        LogManager.getLog = { name in
            PrintLogger(name)
        }

        let files = InMemoryFileSystem()
        files.contentToLoad = get_crossing_map()

        let loader = MapLoader(files)
        let mapLoadResult = loader.load(fileUrl: URL(fileURLWithPath: "/load_map"))

        var zone: MapZone? = nil

        switch mapLoadResult {
        case let .Error(e):
            XCTFail("unable to load map data: \(e.description)")
        case let .Success(z):
            zone = z
        }

        let finder = Pathfinder()
        
        let started = Date()

        let path = finder.findPath(start: "68", target: "231", zone: zone!)
        let moves = zone!.getMoves(ids: path)
        
        let diff = Date() - started
        
        print("time: \(diff.formatted)")

        XCTAssertEqual(moves, ["east", "southeast", "northeast", "northeast", "east", "east", "east", "east", "northeast", "go longbow bridge", "northeast", "go provincial bank"])
    }
    
    func test_crossing_to_kalika() {
        LogManager.getLog = { name in
            PrintLogger(name)
        }

        let files = InMemoryFileSystem()
        files.contentToLoad = get_crossing_map()

        let loader = MapLoader(files)
        let mapLoadResult = loader.load(fileUrl: URL(fileURLWithPath: "/load_map"))

        var zone: MapZone? = nil

        switch mapLoadResult {
        case let .Error(e):
            XCTFail("unable to load map data: \(e.description)")
        case let .Success(z):
            zone = z
        }

        let finder = Pathfinder()
        
        let started = Date()

        let path = finder.findPath(start: "68", target: "585", zone: zone!)
        let moves = zone!.getMoves(ids: path)
        
        let diff = Date() - started
        
        print("time: \(diff.formatted)")

        let expected = ["east", "southeast", "north", "northwest", "north", "north", "north", "north", "north", "north", "north", "north", "north", "east", "east", "east", "east", "east", "east", "north", "north", "west", "west", "go path", "north", "go double doors"]
        
        print("moves=\(moves.count) expected=\(expected.count)")
        print(moves)

        assertEqual(moves, expected)
    }

    func get_crossing_map() -> String {
        return """
<?xml version="1.0" encoding="utf-16"?>
<zone name="The Crossing" id="1">
  <node id="1" name="The Crossing, Magen Road">
    <description>The whitewashed building before you is stark and functional.  A sign mounted on it is hand painted and carved with cunning skill.  White-robed figures and all manner of injured and infirm people stream in and out of a double door, leaving thin trails of blood on the spotless pavement.</description>
    <position x="300" y="-408" z="0" />
    <arc exit="east" move="east" destination="2" />
    <arc exit="south" move="south" destination="335" />
    <arc exit="west" move="west" destination="7" />
    <arc exit="go" move="go wide arch" destination="432" />
    <arc exit="go" move="go double door" destination="307" />
  </node>
  <node id="2" name="The Crossing, Magen Road">
    <description>Not far off you spot the town walls, which meet at a right angle in this northeast corner of town.  This road is kept busy by the traffic to and from the popular haunts crowded into this sector - the Barbarians' Guild, the Champions' Arena, the Empaths' Guild, Martyr Saedelthorp's Healing Hospital, and the convivial Gaethrend's Court Inn.  In addition, the Paladins' Guild farther north, and the gate leading out of town to the Warrior Mages' Guild and the wilds all are accessed through this street.</description>
    <position x="330" y="-408" z="0" />
    <arc exit="north" move="north" destination="141" />
    <arc exit="east" move="east" destination="3" />
    <arc exit="west" move="west" destination="1" />
  </node>
  <node id="3" name="The Crossing, Magen Road">
    <description>This bustling junction presents a cross section of the world's inhabitants in various states of health and disrepair.  Bloodied adventurers, impaired healers, overextended spellsingers, and other members of the walking wounded lurch their way towards the Healing Hospital to the west.  Litters, carts and horses carry those too badly hurt to move under their own power.  In striking contrast are the strapping barbarians who swagger by, towards the Arena and Barbarians' Guild southwest.</description>
    <position x="370" y="-408" z="0" />
    <arc exit="north" move="north" destination="144" />
    <arc exit="south" move="south" destination="4" />
    <arc exit="west" move="west" destination="2" />
  </node>
  <node id="4" name="The Crossing, Trothfang Street">
    <description>You stand at the southeast corner of the Champions' Arena, its thick, solid walls and dome rising above you.  You can barely make out on its surface scrawled inscriptions and graffiti with names and titles of barbarians of yore.  Some of the engravings have dates and numbers next to them.  A gust of wind blows the scent of incense offered in the flames on the Temple towers to mix with the odors of sweated bodies.</description>
    <description>You stand at the southeast corner of the Champions' Arena, its thick, solid walls and dome rising high into the night sky.  Scrawled inscriptions and graffiti with names and titles of barbarians of yore are barely visible on the wall's surface.  Some of the engravings have dates and numbers next to them.  Jutting up over the top of the wall in the distance to the east is a thin spire that appears to be shrouded in mist.</description>
    <position x="370" y="-328" z="0" />
    <arc exit="north" move="north" destination="3" />
    <arc exit="east" move="east" destination="149" />
    <arc exit="west" move="west" destination="5" />
  </node>
  <node id="5" name="The Crossing, Trothfang Street">
    <description>The cries of scalpers and touts from the street mix with those from within the thick-walled, domed structure here -- shouts calling for blood and demanding that honor be satisfied, as well as less shrill exhortations to local favorites or up-and-coming gladiators and knights.  Several daunting-looking centurions clad in full ceremonial armor scrutinize you stoically from under the scarlet canopy that shades the entrance to the Champions' Arena.</description>
    <position x="320" y="-328" z="0" />
    <arc exit="east" move="east" destination="4" />
    <arc exit="west" move="west" destination="6" />
  </node>
  <node id="6" name="The Crossing, Trothfang Street">
    <description>Due north you see the square that marks the entrance to the Barbarians' Guild, with its arcade of caryatides and telamones, life-size and lifelike sculptures of former female and male Arena Champions.  The covered entryway to the Arena is dead ahead to the east, while beyond that rise the town walls.</description>
    <position x="300" y="-328" z="0" />
    <arc exit="north" move="north" destination="335" />
    <arc exit="east" move="east" destination="5" />
    <arc exit="go" move="go society building" destination="865" />
  </node>
  <node id="7" name="The Crossing, Flamethorn Way">
    <description>Trellises woven of strips of wicker and cane cover the front of the Herbalist's Shop here.  Vines cling gratefully to the walls, their tendrils seeking ever-tighter grips around the crosspieces of the trellises.  Ivy, morning glory, honeysuckle, jasmine and leafy green creepers all compete in the upward race for light and moisture, making the facade of the shop look more like an ancient ruin than the thriving and busy trade it is.</description>
    <position x="200" y="-408" z="0" />
    <arc exit="north" move="north" destination="136" />
    <arc exit="east" move="east" destination="1" />
    <arc exit="go" move="go shop" destination="219" />
  </node>
  <node id="8" name="The Crossing, Clanthew Boulevard">
    <description>Intimidatingly large passersby crowd around you, and you gulp as you notice most of the men and women here of all races tower above their average counterparts.  They also tend to dress differently - fully equipped, even in the midst of the city - in leathers, hide and armor, weapons drawn or at the ready over shoulders or at their sides.  Carefully you make your way through the throng, since something tells you this would not be a good spot to step on anyone's toes.</description>
    <position x="240" y="-368" z="0" />
    <arc exit="east" move="east" destination="335" />
    <arc exit="south" move="south" destination="9" />
    <arc exit="west" move="west" destination="11" />
    <arc exit="go" move="go meeting hall" destination="975" />
  </node>
  <node id="9" name="The Crossing, Cheopman Lane">
    <description>Large clay urns and willow baskets spill out onto the footpath here, filled with riotous displays of bright flowers in full bloom, sprigs of emerald green foliage, and ornamental reeds, boughs and branches.  A young girl leans nonchalantly against the entrance to the Florist's Shop, watching over the wares.  Smiling shyly, she beckons enticingly to potential customers.</description>
    <position x="240" y="-318" z="0" />
    <arc exit="north" move="north" destination="8" />
    <arc exit="south" move="south" destination="10" />
    <arc exit="go" move="go florist's shop" destination="655" />
  </node>
  <node id="10" name="The Crossing, Cheopman Lane">
    <description>Ragtag merchants and vendors lug heavily-laden sacks and bundles south, while others leave, heading north with empty pushcarts and baskets.  The town's less well-off citizenry stroll by, looking for good deals in the impromptu flea market of Mongers' Bazaar.  Others proudly show off their new purchases and hard-won bargains.</description>
    <position x="240" y="-298" z="0" />
    <arc exit="north" move="north" destination="9" />
    <arc exit="go" move="go bazaar" destination="379" />
  </node>
  <node id="11" name="The Crossing, Clanthew Boulevard" note="Apostle Headquarters|Apostle HQ">
    <description>The cobblestones here are grey and flecked with crystals that sparkle as you move along the boulevard.  High walls over which loom still higher structures with shuttered, mute windows that face the street and baked tile roofs, indicate you are passing through one of the wealthier residential sections of the Crossing.</description>
    <position x="170" y="-368" z="0" />
    <arc exit="east" move="east" destination="8" />
    <arc exit="south" move="south" destination="12" />
    <arc exit="west" move="west" destination="18" />
    <arc exit="go" move="go small hut" destination="899" />
  </node>
  <node id="12" name="The Crossing, Via Iltesh">
    <description>This small lane off of Clanthew Boulevard narrows to the south and grows wider as it leads north into the main road, giving it a shape reminiscent of the blade of a huge greatsword.  Due south you can see the verdant border of the Town Green and the shops of the Weaponsmith and Armorer.  To the northeast is the dome of the Champions' Arena and to the west, the three-story colonnades of the Academy dominate the skyline.</description>
    <position x="170" y="-260" z="0" />
    <arc exit="north" move="north" destination="11" />
    <arc exit="south" move="south" destination="13" />
  </node>
  <node id="13" name="The Crossing, Via Iltesh">
    <description>The lane is quite narrow here, with the sides of the Armorer's and Weaponsmith's shops encroaching on the path itself.  Their huddling structures and the shady hedges and lunats that form this northern boundary of the Town Green cause slippery moss to grow upon the cobblestones and cast a cool, damp pall over this end of the street.</description>
    <position x="170" y="-220" z="0" />
    <arc exit="north" move="north" destination="12" />
    <arc exit="south" move="south" destination="14" />
  </node>
  <node id="14" name="The Crossing, Town Green North" note="Town Green|TGN|Wanted Board">
    <description>A small path of bent grass leads to a narrow stretch of cobblestones between the grass and the privet hedge that stands before Milgrym the Weaponsmith's.  The town's main source of serviceable arms, Milgrym does a good trade and has a solid reputation.  The stream of customers, though steady, seems careful not to disturb the usual tranquility of the facing greensward.</description>
    <position x="170" y="-180" z="0" />
    <arc exit="north" move="north" destination="13" />
    <arc exit="east" move="east" destination="17" />
    <arc exit="southeast" move="southeast" destination="15" />
    <arc exit="south" move="south" destination="16" />
    <arc exit="southwest" move="southwest" destination="23" />
    <arc exit="west" move="west" destination="225" />
    <arc exit="go" move="go weaponsmith's" destination="191" />
    <arc exit="go" move="go green pond" destination="467" />
  </node>
  <node id="15" name="The Crossing, Town Green Southeast" note="TGSE">
    <description>This tranquil corner of the Green has a small bower of entwined modwyn vines, laden with tempting, grape-like clusters.  A limestone bench and some sawed-off sections of trees that serve as rustic stools make up an open-air performance space, where bards, musicians and poets can demonstrate their talents.</description>
    <position x="210" y="-140" z="0" />
    <arc exit="north" move="north" destination="17" />
    <arc exit="west" move="west" destination="16" />
    <arc exit="northwest" move="northwest" destination="14" />
    <arc exit="go" move="go path" destination="371" />
    <arc exit="go" move="go gate" destination="377" />
  </node>
  <node id="16" name="The Crossing, Town Green South" note="TGS">
    <description>A gap in the stand of lunat trees leads south into Lunat Shade Road.  In that general direction lie Berolt's Dry Goods, the Town Hall, the soaring presence of the Temple, the Provincial Bank and other key structures.  A few loafers loll on the grass, watching those entering and leaving the Green.  Sparrows, jays and other birds call to one another from the treetops, flitting back and forth between their nests and roosts in the dense hedges bordering the park.</description>
    <description>A gap in the stand of lunat trees leads south into Lunat Shade Road.  In that general direction the lights shining from Berolt's Dry Goods, the Town Hall, the soaring presence of the Temple, the Provincial Bank and other key structures can be seen.  A few loafers loll on the grass, watching those entering and leaving the green, or laying back to gaze at the night sky.  A lone nightingale serenades from the hedges bordering the park, unaware of its appreciative audience.</description>
    <position x="170" y="-140" z="0" />
    <arc exit="north" move="north" destination="14" />
    <arc exit="northeast" move="northeast" destination="17" />
    <arc exit="east" move="east" destination="15" />
    <arc exit="south" move="south" destination="40" />
    <arc exit="west" move="west" destination="23" />
    <arc exit="northwest" move="northwest" destination="225" />
  </node>
  <node id="17" name="The Crossing, Town Green Northeast" note="TGNE">
    <description>The cool, welcome expanse of the Town Green is a pleasant place to gather and exchange news, gossip and adventuring pointers with all the folk and races of Elanthia who are drawn to town.  A soft, spongy carpet of well-manicured grass underfoot affords a comfortable cushion for sitting or sprawling out to enjoy a rare moment of rest in the warm sun.  An ancient oak tree provides shelter for those so inclined.</description>
    <description>The cool, welcome expanse of the Town Green is a pleasant place to gather and exchange news, gossip and adventuring pointers with all the folk and races of Elanthia who are drawn to town.  A soft, spongy carpet of well-manicured grass underfoot affords a comfortable cushion for sitting or sprawling beneath the star-studded night sky.  An ancient oak tree provides shelter for those so inclined.</description>
    <position x="210" y="-180" z="0" />
    <arc exit="south" move="south" destination="15" />
    <arc exit="southwest" move="southwest" destination="16" />
    <arc exit="west" move="west" destination="14" />
    <arc exit="go" move="go walkway" destination="264" />
    <arc exit="go" move="go path" destination="379" />
    <arc exit="none" move="go shadowed gap" destination="853" />
  </node>
  <node id="18" name="The Crossing, Clanthew Boulevard">
    <description>You pause a moment at one of the busiest crossroads of town.  Through this intersection must pass most of those traveling from the wilderness of the Western Tier into the heart of the Crossing, and those departing as well.  To the east lie the gates to the Eastern Tier, affording access to the Warrior Mages' Guild and the Observatory, and other, more perilous, destinations.</description>
    <position x="60" y="-368" z="0" />
    <arc exit="east" move="east" destination="11" />
    <arc exit="south" move="south" destination="19" />
    <arc exit="west" move="west" destination="31" />
  </node>
  <node id="19" name="The Crossing, S'zella Plaza" note="S'zella Plaza">
    <description>This small piazza stands between the Academy Asemath and the shops and residences clustered around the Town Green to the east.  Its granite pavement has been well-worn, since it forms the north-south connection between the major artery of the Crossing, Clanthew Boulevard, and Lorethew Street.  Several stone benches, roughly hewn out of the same material as the pavement, form a semi-circle around a polychrome plaster statue in a quiet corner of the square.</description>
    <position x="60" y="-282" z="0" />
    <arc exit="north" move="north" destination="18" />
    <arc exit="south" move="south" destination="234" />
  </node>
  <node id="20" name="The Crossing, Asemath Walk">
    <description>You stand before a sign in the shape of a giant lute, painted in red and gilt and inlaid with ivory and jet, with florid script proclaiming the virtues of the True Bard d'Or, the Crossing's finest purveyor of high-quality instruments for
, aesthetes and amateurs alike.  Dashing, gaily-clad figures stream in and out of the shop, lutes slung over shoulders or pipes clasped under arms.  A haunting tune, at once both exhilarating and melancholic, emanates from the doorway.</description>
    <description>You stand before a sign in the shape of a giant lute, painted in red and gilt and inlaid with ivory and jet, with florid script proclaiming the virtues of the True Bard d'Or, the Crossing's finest purveyor of high-quality instruments for bards, aesthetes and amateurs alike.  Dashing, gaily-clad figures stream in and out of the shop, lutes slung over shoulders or pipes clasped under arms.  A haunting tune, at once both exhilarating and melancholic, emanates from the doorway.</description>
    <position x="60" y="-140" z="0" />
    <arc exit="north" move="north" destination="234" />
    <arc exit="east" move="east" destination="22" />
    <arc exit="south" move="south" destination="21" />
    <arc exit="west" move="west" destination="25" />
    <arc exit="go" move="go bards shop" destination="401" />
  </node>
  <node id="21" name="The Crossing, Asemath Walk">
    <description>The crowd here is boisterous, composed of students, teachers, and seekers of all kinds.  Some head south to the famed taproom of the Half Pint Inn, others appear to have already enjoyed the libations there to the dregs and are heading back for study.  The inn to the south and the visitors to the High Temple to the southeast contribute to the brisk flow of people to and from the Academy.</description>
    <description>Small groups of students walk by talking in animated fashion, some excitedly about the night's feature show at the famed taproom of the Half Pint Inn, others laughing themselves wearily home after a too many few rounds of liquid libation.  The well-lit inn to the south as well as the blazing flames on the towers of the High Temple to the southeast add to the cheery street atmosphere.</description>
    <position x="60" y="-100" z="0" />
    <arc exit="north" move="north" destination="20" />
    <arc exit="south" move="south" destination="37" />
  </node>
  <node id="22" name="The Crossing, Manciple Cobble">
    <description>This cobbled street connects the Town Green with the streets leading to Academy Asemath and the shops, inns and eateries that cluster around it.  Old stone residences line the walkway, making it more like a court than a through street.  Your footsteps echo off their unyielding, secretive facades.</description>
    <position x="90" y="-140" z="0" />
    <arc exit="east" move="east" destination="23" />
    <arc exit="west" move="west" destination="20" />
  </node>
  <node id="23" name="The Crossing, Town Green Southwest" note="TGSW|Pillory">
    <description>The hedgerow to the west meets the row of tall lunat trees that separates the Town Green from the commercial traffic on Lunat Shade Road due south.  The growth is especially dense here, with no way to slip past either of the living fences.  The small thorns on the hedges, to keep out stray livestock in search of prime pasture, look daunting in any case.</description>
    <position x="130" y="-140" z="0" />
    <arc exit="north" move="north" destination="225" />
    <arc exit="northeast" move="northeast" destination="14" />
    <arc exit="east" move="east" destination="16" />
    <arc exit="west" move="west" destination="22" />
  </node>
  <node id="24" name="The Crossing, Puddle Path">
    <description>The packed dirt path between bustling Town Green and the quieter confines of Smithy Lane has been worn to a smooth, deep hollow over the years.  A perennial pool of murky brown water now sits obstinately in the center of the path, requiring passers-by to gather up their hems or risk a muddying.  From time to time, small boys have been known to hide in the bushes bordering the path, hoping for a tantalizing glimpse of a lady's ankle.</description>
    <position x="90" y="-220" z="0" />
    <arc exit="southeast" move="southeast" destination="225" />
    <arc exit="go" move="go wooden gate" destination="607" />
  </node>
  <node id="25" name="The Crossing, Trollferry Approach">
    <description>The street here is a bit neglected, as though it once carried constant foot and cart traffic, but now is somewhat forlorn and forgotten.  Little draws your attention, only the red brick back of the bathhouse along the south side of the path, and the clapboard back of the Bards' Shop directly north.  The smells of steam, water, varnish and rosin escape through small windows facing the street, as the path curves northeast to intersect with Asemath Walk.</description>
    <position x="10" y="-140" z="0" />
    <arc exit="east" move="east" destination="20" />
    <arc exit="west" move="west" destination="26" />
  </node>
  <node id="26" name="The Crossing, Trollferry Approach">
    <description>This intersection leads north to Lorethew and Clanthew Streets, which provide access to the river crossing and to the guild headquarters to the north and to the east.  The embankment of the river is built up slightly ahead, providing a small measure of protection against flooding, while also serving as the base for a crumbling, old pier.</description>
    <position x="-40" y="-140" z="0" />
    <arc exit="north" move="north" destination="27" />
    <arc exit="east" move="east" destination="25" />
    <arc exit="west" move="west" destination="32" />
    <arc exit="go" move="go society building" destination="873" />
  </node>
  <node id="27" name="The Crossing, Lorethew Street">
    <description>The path here follows the curves of the Oxenwaithe, bringing you nearer to the swirling, dark currents.  Along the bank, to the southwest, you make out several dinghies bobbing and straining at their moorings, in a doomed dance of freedom they can never win, except at the behest of some greedy ferryman or in the wake of a storm.</description>
    <position x="-40" y="-242" z="0" />
    <arc exit="north" move="north" destination="28" />
    <arc exit="east" move="east" destination="36" />
    <arc exit="south" move="south" destination="26" />
  </node>
  <node id="28" name="The Crossing, Sirenberry Row">
    <description>The daunting, austere structure of Academy Asemath, directly east, blocks out the light, and leaves the humble facade on the other side of the path in intermittent shade.  Scholars and singers, teachers and troubadours, mimes and masters all saunter past, content in their mutual feelings of superiority.  Round the corner, you can just spy a gaudy sign on a shop to the east.</description>
    <position x="-40" y="-282" z="0" />
    <arc exit="north" move="north" destination="29" />
    <arc exit="south" move="south" destination="27" />
  </node>
  <node id="29" name="The Crossing, Clanthew Boulevard" note="Bard">
    <description>From the west comes the sound of currents rushing through a narrow river bend, while in the distance, just barely evident to the northwest, is a corner of the outer town wall, over which the calls of birds can be heard.  Mingled among the sublime sounds of nature, are the equally sweet sounds reaching your ears from a small, unpretentious building set unobtrusively off to the south side of the road.</description>
    <position x="-40" y="-368" z="0" />
    <arc exit="east" move="east" destination="31" />
    <arc exit="south" move="south" destination="28" />
    <arc exit="west" move="west" destination="30" />
    <arc exit="go" move="go small building" destination="468" />
  </node>
  <node id="30" name="The Crossing, Clanthew Boulevard">
    <description>The meandering course of the River Oxenwaithe lies dead ahead.  Wooden carts, powered by all manner of two- and four-legged beasts, rumble past, headed west towards the broad, well-worn planks of the Oxenwaithe Bridge and east into the heart of the Crossing.  Groups of armed adventurers, mystics, merchants and rogues weave in and out of the wheeled and hoofed mobs.</description>
    <position x="-70" y="-368" z="0" />
    <arc exit="east" move="east" destination="29" />
    <arc exit="go" move="go oxenwaithe bridge" destination="94" />
  </node>
  <node id="31" name="The Crossing, Clanthew Boulevard">
    <description>A side entrance to the Academy, in the form of a low, bronze gate, stands here.  Students and faculty come and go through it, since it provides convenient access to the inns and eateries clustered to the north and east of Elanthia's most renowned seat of learning and research.  Several blocks to the east looms the dome of the Champions' Arena, which also houses the Barbarians' Guild and farther north, both within and without the sheltering walls of town, lie various other Guilds.</description>
    <position x="10" y="-368" z="0" />
    <arc exit="north" move="north" destination="122" />
    <arc exit="east" move="east" destination="18" />
    <arc exit="west" move="west" destination="29" />
    <arc exit="go" move="go low gate" destination="196" />
  </node>
  <node id="32" name="The Crossing, Trollferry Quay">
    <description>A dilapidated wooden pier juts out into the steel-grey waters of the Oxenwaithe River here.  Several battered dinghies bounce up and down in time to the currents.  In olden days this was a major ferry crossing, presided over by a loathsome and capricious troll.  Now it is naught but a rotting ruin, as is no doubt the corpse of its former owner.</description>
    <position x="-60" y="-140" z="0" />
    <arc exit="east" move="east" destination="26" />
    <arc exit="south" move="south" destination="33" />
    <arc exit="none" move="go rotting ruin" destination="855" />
  </node>
  <node id="33" name="The Crossing, Embankment">
    <description>Dark, swirling currents of the river rush by, headed southward toward ultimate merger with the mighty Segoltha River.  Still darker, shadowy and inexplicably sinister figures hustle by you, noiselessly, passing in and out of a black, recessed doorway set almost invisibly into a nondescript wall along the curb.</description>
    <position x="-60" y="-100" z="0" />
    <arc exit="north" move="north" destination="32" />
    <arc exit="south" move="south" destination="34" />
    <arc exit="go" move="go black doorway" destination="218" />
  </node>
  <node id="34" name="The Crossing, Embankment">
    <description>The embankment here is high and crude, just a mound of packed mud, earth and marl that seems unlikely to be capable of doing more than providing the neighborhood residents with a false sense of security.  Still, there are a few houses and shops along the riverbank.  Those establishments that have been built hard by the river must take great pains to propitiate the elemental gods since the structures still remain standing.</description>
    <position x="-60" y="-60" z="0" />
    <arc exit="north" move="north" destination="33" />
    <arc exit="south" move="south" destination="35" />
  </node>
  <node id="35" name="The Crossing, Full Moons Crescent">
    <description>The street curves here to match a bend in the river.  A freshly whitewashed house, two stories high, stands just off the path.  Craning your neck, you see the second floor is actually some sort of glass-enclosed solarium, the light streaming through its panes and refracted into a halo of prismatic auras.</description>
    <position x="-60" y="-20" z="0" />
    <arc exit="north" move="north" destination="34" />
    <arc exit="east" move="east" destination="95" />
    <arc exit="go" move="go seeress' house" destination="657" />
  </node>
  <node id="36" name="The Crossing, Lorethew Street">
    <description>This narrow road runs east-west between the Academy and many of the town's shops.  To the east you can see the low shops and hedges that surround the Town Green, while west looms the tributary river, flowing on its winding course south into the mighty Segoltha River.</description>
    <position x="10" y="-242" z="0" />
    <arc exit="east" move="east" destination="234" />
    <arc exit="west" move="west" destination="27" />
  </node>
  <node id="37" name="The Crossing, Asemath Walk">
    <description>Clerics, academics and carousers all are apparent here, headed throughout town on different courses.  The windows and terraces from the back of the two-storied Half Pint Inn face the street from the south, while to the east is the side of the cleric's shop.  Smooth paving stones, pale grey with dark grey borders, have been laid to coordinate with the approaches to the High Temple.</description>
    <description>Normally filled with bustling Clerics, academics and carousers of all types and ages, this area is peaceful as most people have retired for the night, excepting the occasional joyous song that escapes an open window from the back of the two-storied Half Pint Inn to the south.  The side of the Cleric's shop is to the east, bordering the smooth paving stones that have been laid to coordinate with the approaches of the High Temple.</description>
    <position x="60" y="-20" z="0" />
    <arc exit="north" move="north" destination="21" />
    <arc exit="east" move="east" destination="38" />
    <arc exit="west" move="west" destination="96" />
  </node>
  <node id="38" name="The Crossing, Alamhif Trace">
    <description>A constant stream of townsfolk and outlanders file past you but the mix is not your usual pastiche of rag-tag traders, bare-chested barbarians, indolent bards and assorted laborers.  Here most people speak in serene tones or peer at you benevolently from behind cowls of the cleric's calling.  Many cluster around Brother Durantine's Cleric Shop, which hugs the north side of the road.  A monk pauses in the shadows cast by the High Temple tower to the southwest before continuing his journey.</description>
    <description>This normally sedate area is nearly still in the night hours, the occasional late-night shopper heading to or from Brother Durantine's Cleric Shop, which hugs the north side of the road.  A hooded monk exits the shop into the shadows and fingers his prayer beads with unconscious familiarity as he glances up at the bright flame on the High Temple tower to the southwest, pausing a moment before continuing his journey.</description>
    <position x="130" y="-20" z="0" />
    <arc exit="east" move="east" destination="39" />
    <arc exit="south" move="south" destination="44" />
    <arc exit="west" move="west" destination="37" />
    <arc exit="go" move="go cleric shop" destination="407" />
  </node>
  <node id="39" name="The Crossing, Alamhif Trace">
    <description>This pivotal junction connects many of the Crossing's key locations.  Proudly located to the south you see the translucent dome of the Temple flanked by its three guard towers, while the Town Green and the Town Hall can be seen off toward the north and northeast.  The babble of many languages, of clan and guild and folk, fill the air here.  Travelers dressed in all manner of costume, garb and battle gear amble past, admiring the view of the buildings here, or looking about to get their bearings.</description>
    <description>This pivotal junction connects many of the Crossing's key locations.  Blazing to the south in the night sky are the flames on the Temple's three towers, while the lights of Town Green and Town Hall can be seen off towards the north and northeast.  The babble of many languages, clan and guild and folk fill the air here, busy at every hour.  Travelers dressed in all manner of costume, garb and battle gear amble past, admiring the darkened outlines of the buildings, or looking about to get their bearings.</description>
    <position x="170" y="-20" z="0" />
    <arc exit="north" move="north" destination="40" />
    <arc exit="southeast" move="southeast" destination="42" />
    <arc exit="west" move="west" destination="38" />
    <arc exit="go" move="go carousel square" destination="184" />
  </node>
  <node id="40" name="The Crossing, Lunat Shade Road">
    <description>Majestic lunat trees line this byway, donated by the town's prosperous traders, a reminder of how their Guild delights in improving the quality of life for beings all over Elanthia.  One such wealthy merchant, though not as ostentatious as most, is Berolt, the dry goods dealer.  His venerable general store here outfits adventurers with all the basic necessities.  The row of trees on the north side of the street also serves to shade the south half of Town Green.</description>
    <position x="170" y="-100" z="0" />
    <arc exit="north" move="north" destination="16" />
    <arc exit="east" move="east" destination="41" />
    <arc exit="south" move="south" destination="39" />
    <arc exit="go" move="go general store" destination="189" />
  </node>
  <node id="41" name="The Crossing, Lunat Shade Road">
    <description>A modest two-story building with a slate roof and large windows dominates this section of town.  This is the Town Hall, the place to pay fines and taxes, obtain permits and licenses, and attend the occasional town meeting.  On the other side of this tree-lined street is the Plaza.  Looking east from here you can barely make out the ramparts of the Eastern Wall over the low roofs of the houses and shops.</description>
    <position x="210" y="-100" z="0" />
    <arc exit="east" move="east" destination="155" />
    <arc exit="west" move="west" destination="40" />
    <arc exit="go" move="go town hall" destination="311" />
  </node>
  <node id="42" name="The Crossing, Hodierna Way" note="Kraelyst start point|travel start point" color="#808000">
    <description>The hustle of crowds making their way between the secular and religious centers of town that converge here carries you along with its momentum.  The granite and marble facade of the First Provincial Bank catches your eye, standing before you as solid as its name.  A Gor'Tog guard armed with pike and crossbow is posted at the door, while a few well-dressed merchants congregate outside.</description>
    <position x="210" y="20" z="0" />
    <arc exit="east" move="east" destination="160" />
    <arc exit="southwest" move="southwest" destination="43" />
    <arc exit="northwest" move="northwest" destination="39" />
    <arc exit="go" move="go provincial bank" destination="231" />
  </node>
  <node id="43" name="The Crossing, Immortals' Approach" note="almsbox|tithe">
    <description>This stretch of road is wide and paved with smooth stone blocks.  Cherry trees in carved stone planters border the sweeping approach while softening the exterior walls surrounding the Temple grounds.  Flames flicker from the tops of three tall towers standing guard over the orb of the Main Temple.  Fragile walkways lash the towers to each other high above the orb.</description>
    <description>This stretch of road is wide and paved with smooth stone blocks.  Cherry trees in carved stone planters border the sweeping approach while softening the exterior walls surrounding the Temple grounds.  Flames brightly visible in the dark flare from the tops of three tall towers standing guard over the orb of the Main Temple.  Fragile walkways lash the towers to each other high above the orb.</description>
    <position x="170" y="60" z="0" />
    <arc exit="northeast" move="northeast" destination="42" />
    <arc exit="northwest" move="northwest" destination="44" />
    <arc exit="go" move="go longbow bridge" destination="46" />
    <arc exit="go" move="go mahogany gate" destination="440" />
  </node>
  <node id="44" name="The Crossing, Immortals' Approach">
    <description>This cobblestone walk is heavily trafficked with guests leaving the Half Pint Inn to the west and monks and pilgrims traveling to and from the temple to the southeast.  Next to this path looms one of the walls of the High Temple enclosing the fire topped towers and walkways soaring far above.  Although life bustles on around you, you pause to contemplate deeper issues for a brief moment.  Emerging from your reverie, you resume your journey.</description>
    <description>The night hours bring revelers traveling to and from the many amusements to be found in the Half Pint Inn to the west, with the occasional monk or pilgrim making a quiet trek to the Temple to the southeast.  A wall enclosing the fire-topped towers of the High Temple looms closely to the path, the soaring walkways connecting one tower to another looming as shadows high above.</description>
    <position x="130" y="20" z="0" />
    <arc exit="north" move="north" destination="38" />
    <arc exit="southeast" move="southeast" destination="43" />
    <arc exit="west" move="west" destination="45" />
    <arc exit="go" move="go hedged archway" destination="967" />
  </node>
  <node id="45" name="The Crossing, Werfnen's Strole" note="Werfnen's Strole">
    <description>Werfnen's Strole, the Path of Dreamers, leads from the glories of the High Temple to the renowned hospitality of Skalliweg Barrelthumper's Half Pint Inn.  The jocular Halfling is known throughout all Elanthia as the consummate innkeeper.  Mouthwatering aromas and heart-gladdening songs waft out of the inn, while the soothing gurgling of the tributary to the south creates a poignant counterpoint to the uproar within.</description>
    <description>Werfnen's Strole, the Path of Dreamers, leads from the glories of the High Temple to the renowned hospitality of Skalliweg Barrelthumper's Half Pint Inn, brightly lit to welcome any late traveler.  The jocular Halfling is known throughout all Elanthia as the consummate innkeeper.  Mouthwatering aromas and heart-gladdening songs waft out of the inn, while the soothing gurgling of the tributary to the south creates a poignant counterpoint to the uproar within.</description>
    <position x="90" y="20" z="0" />
    <arc exit="east" move="east" destination="44" />
    <arc exit="go" move="go half inn" destination="659" />
    <arc exit="none" move="go alley" destination="860" />
  </node>
  <node id="46" name="The Crossing, Chieftain Walk">
    <description>This busy threeway is a vital link.  The Longbow Bridge feeds into it from the northeast, and the warehouse and dock district which stand to the south and west bustle with activity.  The commercial district to the northwest, and the pleasant and populous beach resort are to the southeast, just at the mouth of the River Oxenwaithe, where it empties into the Segoltha.</description>
    <position x="90" y="140" z="0" />
    <arc exit="north" move="north" destination="47" />
    <arc exit="southeast" move="southeast" destination="49" />
    <arc exit="southwest" move="southwest" destination="52" />
    <arc exit="go" move="go longbow bridge" destination="43" />
  </node>
  <node id="47" name="The Crossing, 3 Retainers' Crescent">
    <description>The Longbow Bridge is due east, as the river flows beneath it, just at the edge of your vision.  To the south is the Shipyard and The Strand, a pleasant beach where the two rivers that define the life of the Crossing meet.  To the west are the commercial institutions that are the centers of trade and finance.</description>
    <position x="90" y="100" z="0" />
    <arc exit="north" move="north" destination="48" />
    <arc exit="south" move="south" destination="46" />
    <arc exit="west" move="west" destination="79" />
  </node>
  <node id="48" name="The Crossing, 3 Retainers' Crescent">
    <description>There seems to be great confusion along this narrow stretch of road, as folk of all races and professions pass by and overflow the curbs.  They spill into the street to better make their way, crisscrossing at no particular corner, and running in front of lumbering wagons, darting handcarts or mounted travelers.</description>
    <position x="90" y="60" z="0" />
    <arc exit="south" move="south" destination="47" />
    <arc exit="west" move="west" destination="80" />
    <arc exit="go" move="go old warehouse" destination="437" />
  </node>
  <node id="49" name="The Strand, Sandy Path">
    <description>Light filters through a line of trees as you make your way down this cheerful dirt path.  A narrow clearing affords you a view of sandy embankments and the lapis-colored waters of the Oxenwaithe River.  A number of townsfolk and itinerant merchants greet you as you press along this thoroughfare. </description>
    <description>The wind rustles through a stand of trees which line the path, their tops rising like dark shadows against the night sky.  Occasionally you encounter a lone traveller, but for the most part it is quiet here.</description>
    <position x="130" y="180" z="0" />
    <arc exit="southeast" move="southeast" destination="50" />
    <arc exit="northwest" move="northwest" destination="46" />
    <arc exit="go" move="go rickety wagon" destination="653" />
  </node>
  <node id="50" name="The Strand, Sandy Path" note="Premium Portal|Portal|banyan tree|Kintalia" color="#FF00FF">
    <description>Following the roadside along the Oxenwaithe's bank, you are struck by the quiet beauty of the place.  Taking pause to breathe in the crisp, clean air, you reflect on your surroundings.  Sand, sparkling as if mixed with diamond dust, pours into deep blue undulating waters.  A lush copse of trees spreads to the north, while to the southeast, a series of delightful small buildings is set back from the river's edge.</description>
    <description>You can hear the Oxenwaithe lapping gently at its bank, creating a soothing sound not unlike a lullaby.  The light reflected from the moons provide shimmery paths along the sandy embankments at water's edge.</description>
    <position x="170" y="220" z="0" />
    <arc exit="southeast" move="southeast" destination="51" />
    <arc exit="northwest" move="northwest" destination="49" />
    <arc exit="go" move="go meeting portal" destination="652" />
  </node>
  <node id="51" name="The Strand, Crystalline Beach">
    <description>Several bungalows surround a large communal center sporting a long, wide veranda.  These form the heart of The Strand's resort area, providing respite from day-to-day concerns.  Each bungalow is a simple, single-story unit, positioned to afford an uninterrupted view of the delta where the Oxenwaithe and Segoltha meet.  Beyond the bungalows, sparkling sand stretches from a grassy knoll down a gentle incline, ending in a low ledge of rock pocked with tidal pools.</description>
    <description>Several bungalows surround a large communal center sporting a long, wide veranda.  With the exception of a lighted window on the top floor of the center, all is silent and dark against the night sky.  The constant crash of waves upon a ledge of rocks at river's edge is the only sound you hear, save for the occasional bustle of a resort worker on the communal center's veranda.</description>
    <position x="210" y="260" z="0" />
    <arc exit="west" move="west" destination="54" />
    <arc exit="northwest" move="northwest" destination="50" />
    <arc exit="go" move="go veranda" destination="483" />
  </node>
  <node id="52" name="The Crossing, Chieftain Walk">
    <description>The warehouses and low buildings to the northwest resolve into a flat, open stretch of turf to the south, where the two rivers that shape the Crossing begin to come together.  This level alluvial delta is home to the Crossing's main shipyard, where many of the barges, ferries, frigates, merchant ships, and corsairs that ply the rivers and seas of Elanthia are built.  The weathered shipyard gate leads southeast.</description>
    <position x="50" y="180" z="0" />
    <arc exit="northeast" move="northeast" destination="46" />
    <arc exit="west" move="west" destination="53" />
    <arc exit="go" move="go shipyard gate" destination="237" />
  </node>
  <node id="53" name="The Crossing, Esplanade Eluned">
    <description>The promenade here is a pleasant place to stroll along the riverbank and watch the activities on the broad and swift Segoltha River.  The walkway is broad and clean, paved with bright red bricks forming whimsical patterns and abstract designs.  The breeze off the river is invigorating.  Several young hawkers try to peddle snacks and flowers to families or couples out taking the air, while merchants and seamen rush by.</description>
    <position x="10" y="180" z="0" />
    <arc exit="east" move="east" destination="52" />
    <arc exit="west" move="west" destination="56" />
  </node>
  <node id="54" name="The Strand, Crystalline Beach">
    <description>Sand continues to stretch from east to west.  Children of all races can often be found at the water's edge, playing games or building ephemeral castles.  To one side, a grove of spreading Wyndwood trees provides the perfect spot for quiet meditation, while further off, several braziers set on piles of rock indicate that this is a favorite picnic location.</description>
    <description>The gently rushing waters of the Segoltha fill the air with a pleasant drone.  Traveling along the riverbank, you chance upon a large picnic area dotted with iron braziers set neatly on low rock pillars.</description>
    <position x="170" y="260" z="0" />
    <arc exit="east" move="east" destination="51" />
    <arc exit="west" move="west" destination="55" />
    <arc exit="go" move="go grill" destination="856" />
  </node>
  <node id="55" name="The Strand, Crystalline Beach">
    <description>Short grasses and flowering dirdel provide a carpet in the sand along this part of the Segoltha.  A jagged rock juts out of the water just beyond the river bank, its dark surface streaked with deep green moss.  A group of Nadira turn lazy circles just off shore, no doubt hunting for their next meal.  In the distance, lovers walk arm in arm along the river, while a lone beach-goer scours the sand for unique shells.</description>
    <description>Short grasses and flowering dirdel provide a carpet in the sand along this part of the Segoltha.  A jagged rock breaks the surface of the water just off shore, obscuring part of the starry sky.  The intermittent chatter of a family of nesting Nadira birds reaches your ear.</description>
    <position x="150" y="260" z="0" />
    <arc exit="east" move="east" destination="54" />
    <arc exit="go" move="go sandstone tower" destination="602" />
    <arc exit="go" move="go sturdy pier" destination="606" />
  </node>
  <node id="56" name="The Crossing, Esplanade Eluned">
    <description>Hustling businessmen mingle with grimy dockworkers and indolent strollers here, all proceeding at very different paces.  Handcarts filled with baskets and burlap bundles are pushed by stout, young lads past ladies decked in their finery.  Most of the well-heeled leisure set seems to be headed to and from the freshly painted dock here.  Some private boats and pleasure craft are moored to it.</description>
    <position x="-30" y="180" z="0" />
    <arc exit="east" move="east" destination="53" />
    <arc exit="west" move="west" destination="57" />
    <arc exit="go" move="go freshly dock" destination="169" />
  </node>
  <node id="57" name="The Crossing, Esplanade Eluned">
    <description>The path here runs right along the river bank, as the shore curves into the land to form a small protected inlet.  Directly south, a few small craft are beached, anchored by heavy rocks.  One has oars but no rudder, another has a rudder but no bottom, and yet another has a bottom riddled with holes.  Several tattered nets are hung on driftwood frames to dry, and alongside them, a few gutted fish.</description>
    <position x="-70" y="180" z="0" />
    <arc exit="north" move="north" destination="77" />
    <arc exit="east" move="east" destination="56" />
    <arc exit="west" move="west" destination="58" />
  </node>
  <node id="58" name="The Crossing, Esplanade Eluned">
    <description>An apparent contradiction, the toney esplanade here is right in the midst of a group of warehouses to the north and the customs and storage house of Riverfront Portage to the west.  The strollers and workers mingle, with most of the leisure traffic centering around the noisy amusement pier to the south.</description>
    <position x="-150" y="180" z="0" />
    <arc exit="east" move="east" destination="57" />
    <arc exit="southwest" move="southwest" destination="60" />
    <arc exit="west" move="west" destination="61" />
    <arc exit="northwest" move="northwest" destination="59" />
    <arc exit="go" move="go amusement pier" destination="477" />
    <arc exit="go" move="go mahogany building" destination="671" />
  </node>
  <node id="59" name="The Crossing, Stevedore's Wend">
    <description>The scene is monotonous - warehouses to the west, warehouses to the east, and the hulking shell of the customs clearing house and main warehouse, Riverfront Portage.  Its back wall looms due south, as you skirt around this corner.  Few but the bedraggled longshoremen trudging by have business along this byway and they eye you listlessly.</description>
    <position x="-190" y="140" z="0" />
    <arc exit="north" move="north" destination="72" />
    <arc exit="southeast" move="southeast" destination="58" />
    <arc exit="go" move="go old warehouse" destination="673" />
  </node>
  <node id="60" name="The Crossing, Lemicus Square">
    <description>This corner of Lemicus Square is dotted with litter and looks a bit neglected.  The hulk of Riverfront Portage looms along the north edge of the square and extends for several blocks west.  To the south is a wooden pier with a painted sign arched over the entrance.</description>
    <position x="-190" y="220" z="0" />
    <arc exit="northeast" move="northeast" destination="58" />
    <arc exit="southwest" move="southwest" destination="66" />
    <arc exit="west" move="west" destination="64" />
    <arc exit="go" move="go wooden pier" destination="236" />
  </node>
  <node id="61" name="The Crossing, Esplanade Eluned">
    <description>The road winds among narrow, aged apartments built from brown sandstone.  Their elaborate vine traceries and gargoyle reliefs have been dusted nearly smooth with the passage of years.  Rows of large, unpaned windows stare out upon the world like dozens of sightless eyes.</description>
    <position x="-205" y="180" z="0" />
    <arc exit="east" move="east" destination="58" />
    <arc exit="west" move="west" destination="62" />
    <arc exit="go" move="go sandstone apartment" destination="685" />
  </node>
  <node id="62" name="The Crossing, Esplanade Eluned">
    <description>Light blue sandstone apartments rise from the roadside, their color in stark contrast to the brown of the surrounding buildings.  A small patch of ground near one entrance has been made into a small desert garden, and contains dozens of kronar-sized holes, from which small, black lizards with long, green-tipped whiptails occasionally streak forth.</description>
    <position x="-215" y="180" z="0" />
    <arc exit="east" move="east" destination="61" />
    <arc exit="west" move="west" destination="63" />
    <arc exit="go" move="go brick building" destination="691" />
    <arc exit="go" move="go sandstone apartment" destination="688" />
  </node>
  <node id="63" name="The Crossing, Esplanade Eluned">
    <description>A large oak tree stands in a wide cul-de-sac at the end of the road, its arms arching high above the surrounding buildings as if straining to best them in a contest of size.  Behind its gnarled, massive trunk stands a weathered three-story apartment building formed of white sandstone.</description>
    <position x="-310" y="180" z="0" />
    <arc exit="east" move="east" destination="62" />
    <arc exit="go" move="go thatched cottage" destination="692" />
    <arc exit="go" move="go apartment building" destination="693" />
  </node>
  <node id="64" name="The Crossing, Lemicus Square">
    <description>A wide square here opens up to the town's main river freight, storage and customs house, Riverfront Portage.  Crowds of dockworkers, wharf rats and riffraff mingle with the customs brokers, agents and emissaries of the wealthy merchants and trading houses of the town.</description>
    <position x="-230" y="220" z="0" />
    <arc exit="east" move="east" destination="60" />
    <arc exit="south" move="south" destination="66" />
    <arc exit="northwest" move="northwest" destination="65" />
    <arc exit="go" move="go portage" destination="696" />
  </node>
  <node id="65" name="The Crossing, Kertigen Road">
    <description>Kertigen Road cuts a broad diagonal swath through the neighborhood here, separating the working class residences and old crofts on the west side of the road, from the storage facilities and trading houses to the east.</description>
    <position x="-310" y="126" z="0" />
    <arc exit="north" move="north" destination="69" />
    <arc exit="southeast" move="southeast" destination="64" />
  </node>
  <node id="66" name="The Crossing, Lemicus Square">
    <description>The east side of the Sand Spit Tavern is here, its dilapidated and weathered clapboard attesting its owner's neglect.  Still, the rowdy laughter and shouts from within make it a somewhat homey and attractive roost, a haven for sailors and seamen, dockworkers and locals who seek some relief from their toil and travels.</description>
    <position x="-230" y="260" z="0" />
    <arc exit="north" move="north" destination="64" />
    <arc exit="northeast" move="northeast" destination="60" />
    <arc exit="northwest" move="northwest" destination="67" />
    <arc exit="go" move="go dock" destination="235" />
  </node>
  <node id="67" name="The Crossing, Haven's End">
    <description>The word to describe the building in front of you would be "ramshackle", a tavern to judge from the sign hanging loose from a rod jutting out over the door.  Apparently built from a medley of materials, including what looks like part of the hull of an old trading galleon, the place seems to fit well into the general neighborhood.</description>
    <description>The word to describe the building in front of you would be ramshackle, a tavern to judge from the sign hanging loose from a rod jutting out over the door.  Apparently built from a medley of materials, including what looks like part of the hull of an old trading galleon, the place seems to fit well into the general neighborhood.</description>
    <position x="-270" y="220" z="0" />
    <arc exit="southeast" move="southeast" destination="66" />
    <arc exit="west" move="west" destination="68" />
    <arc exit="go" move="go sand tavern" destination="699" />
  </node>
  <node id="68" name="The Crossing, Haven's End">
    <description>This is the end of the road - literally.  All to the north and west, this dead end is surrounded by a weed-choked vacant lot, a remnant of some ancient farmer's croft or field that was incorporated into the Crossing early on in its evolution.  The dark, rich bank of the Segoltha River rises to the south, too steep here to attempt to climb.</description>
    <description>This is the end of the road - literally.  All to the north and west, this dead end is surrounded by a weed-choked vacant lot, a remnant of some ancient farmer's croft or field that was incorporated into the Crossing early on in its evolution.  The dark, rich bank of the Segoltha River rises steeply to the south, a difficult climb due to the slick and precipitous slope.</description>
    <position x="-310" y="220" z="0" />
    <arc exit="east" move="east" destination="67" />
    <arc exit="climb" move="climb bank" destination="476" />
  </node>
  <node id="69" name="The Crossing, Kertigen Road">
    <description>A spacious, clean facade of Ulven's Warehouse fronts the east side of the road here.  To the west, Elmod Close forms the southernmost boundary of a rather downbeat neighborhood that is home to rickety rowhouses, dilapidated crofts and the infamous Drelstead Prison.</description>
    <position x="-310" y="100" z="0" />
    <arc exit="north" move="north" destination="70" />
    <arc exit="south" move="south" destination="65" />
    <arc exit="west" move="west" destination="106" />
    <arc exit="go" move="go warehouse" destination="702" />
  </node>
  <node id="70" name="The Crossing, Kertigen Road">
    <description>An overloaded flatbed wagon races past, its driver pushing the horses to their limits.  A small child emerging from the lane to the west is knocked to the ground by its passing, while a group of older lads gather up some boxes that have fallen off the wagon in its hasty flight north to the gates.</description>
    <position x="-310" y="66" z="0" />
    <arc exit="north" move="north" destination="71" />
    <arc exit="east" move="east" destination="73" />
    <arc exit="south" move="south" destination="69" />
    <arc exit="west" move="west" destination="103" />
  </node>
  <node id="71" name="The Crossing, Kertigen Road">
    <description>The streets conform to a right angle in the town walls here.  The back of the Guard House, with a narrow barred window in it, stands on the east curb.  A uniformed deputy, surrounded by heavily armed guards, conducts a lawbreaker in irons from the Guard House for a very long vacation in Drelstead Prison, which lies several blocks west.</description>
    <position x="-310" y="20" z="0" />
    <arc exit="north" move="north" destination="99" />
    <arc exit="south" move="south" destination="70" />
    <arc exit="west" move="west" destination="100" />
  </node>
  <node id="72" name="The Crossing, Ustial Road">
    <description>This stretch of Ustial Road is a strange mixture of people and buildings.  Several prosperous-looking townhouses line the north side of the street.  Their windowless exteriors rise above thick town walls decorated with glazed ceramic tiles.  Through the iron gates that lead within, you spy well-appointed rooms clustered around shady courtyards.  On the south side of the street, the houses are more modest, as though some invisible boundary had been drawn straight down the middle of the road.</description>
    <position x="-190" y="66" z="0" />
    <arc exit="north" move="north" destination="85" />
    <arc exit="east" move="east" destination="74" />
    <arc exit="south" move="south" destination="59" />
    <arc exit="west" move="west" destination="73" />
    <arc exit="go" move="go large building" destination="525" />
  </node>
  <node id="73" name="The Crossing, Ustial Road">
    <description>The two-story dwellings on the north side of the street are sequestered by high town walls.  Shade trees from the inner yards of the houses hang over into the street.  Surrounding one well-kept gate, a colorful wall mural relieves the dun-colored monotony of the protective ramparts.  To the south, the equally humdrum back wall of a warehouse looms.</description>
    <position x="-241" y="66" z="0" />
    <arc exit="east" move="east" destination="72" />
    <arc exit="west" move="west" destination="70" />
    <arc exit="go" move="go limestone building" destination="937" />
  </node>
  <node id="74" name="The Crossing, Mercantile Street">
    <description>This is a quiet section of Mercantile Street, leading behind the Traders' Guild and between sundry warehouses holding goods awaiting shipment or sale.  Just against the back wall of the whitewashed Guildhall is what appears to be a small rock garden.  On closer inspection, you see by the offerings in the midst of the rocks that it is a shrine of some kind.</description>
    <position x="-108" y="66" z="0" />
    <arc exit="east" move="east" destination="75" />
    <arc exit="west" move="west" destination="72" />
    <arc exit="go" move="go shrine" destination="703" />
  </node>
  <node id="75" name="The Crossing, Mercantile Street">
    <description>The road here is partially blocked by an overturned oxcart.  Large, burlap-wrapped bales are scattered over the cobbles and the sidewalk, making you detour around them.  Other wagons and barrows wait rather impatiently for the harried driver to right his cart, rehitch his team and clear the way.</description>
    <position x="-70" y="66" z="0" />
    <arc exit="east" move="east" destination="76" />
    <arc exit="south" move="south" destination="77" />
    <arc exit="west" move="west" destination="74" />
  </node>
  <node id="76" name="The Crossing, Mercantile Street">
    <description>On the north side of the street is the back of the tall bank building, looking daunting and impregnable with its thick, windowless walls.  Just opposite, a secure, expansive warehouse has a gang of uniformed Gor'Togs surrounding it on all sides.  Armed to the teeth, they glower at you, as a S'Kra Mur foreman hisses some order to them.</description>
    <position x="-28" y="66" z="0" />
    <arc exit="east" move="east" destination="78" />
    <arc exit="west" move="west" destination="75" />
  </node>
  <node id="77" name="The Crossing, Scullion Way">
    <description>Squeezed between overpoweringly solid warehouses on two sides, Scullion Way leads north-south between Mercantile Street and the waterside concourse, Esplanade Eluned.  Servants, humble working folk, laborers, artisans, shopkeepers and other stalwarts on whose backs rest the commerce, defense and very life of the Crossing itself flow past you.  A few gull calls and a light riverine scent drift up from the south.</description>
    <position x="-70" y="140" z="0" />
    <arc exit="north" move="north" destination="75" />
    <arc exit="south" move="south" destination="57" />
  </node>
  <node id="78" name="The Crossing, Drayhorse Trace">
    <description>A long, fortified warehouse here extends to the west into Mercantile Street.  It looks more like some kind of military storehouse or armory.  Guards dressed in some kind of private uniforms discourage you from further satisfying your curiosity about the structure.  You turn your attention to the waters of the River Oxenwaithe, which from this spot is visible both to the north and the east, as it snakes its way southwards around this promontory.</description>
    <position x="10" y="66" z="0" />
    <arc exit="north" move="north" destination="81" />
    <arc exit="southeast" move="southeast" destination="79" />
    <arc exit="west" move="west" destination="76" />
  </node>
  <node id="79" name="The Crossing, Drayhorse Trace">
    <description>The constant clamor of hooves on cobblestones echoes off the walls of the distribution centers, granaries, magazines, and storehouses that border the street in this part of town.  Horse-drawn flatbed wagons, mounted merchants on fine steeds, and carriages bearing regal ladies all clatter by, raising whorls of dust.</description>
    <position x="44" y="100" z="0" />
    <arc exit="east" move="east" destination="47" />
    <arc exit="northwest" move="northwest" destination="78" />
  </node>
  <node id="80" name="The Crossing, 3 Retainers' Crescent">
    <description>Here the way diverges from the riverbank and is set off as it connects between major arteries leading to the commercial heart of the Crossing, the water transport hub, and Longbow Bridge.</description>
    <position x="30" y="60" z="0" />
    <arc exit="east" move="east" destination="48" />
    <arc exit="northwest" move="northwest" destination="81" />
  </node>
  <node id="81" name="The Crossing, Gold Barque Quay">
    <description>Several swank-looking private boats, gondolas and a few sleek, flat-bottomed river boats are tied up here.  A large log raft stands in dry dock on some stone pilings, ready to be put into service on those occasions when the floods of demonic weather cause the River Oxenwaithe to o'erflow its banks and wash out the town's two bridges or if invaders breach the town's defenses and set torch to them.</description>
    <position x="10" y="40" z="0" />
    <arc exit="southeast" move="southeast" destination="80" />
    <arc exit="south" move="south" destination="78" />
    <arc exit="west" move="west" destination="82" />
  </node>
  <node id="82" name="The Crossing, Bank Street">
    <description>The Moneylender's commands a breathtaking view of the River Oxenwaithe and its aquatic commerce flowing south towards the mighty Segoltha River and thence eastward to the sea.  From its top-floor windows the bankers can keep watch over the Traders' Guild to the west, and can view the low sprawling warehouses and docks to the south.  Directly across the river is a curious dwelling with a glass gazebo atop it.</description>
    <position x="-30" y="40" z="0" />
    <arc exit="east" move="east" destination="81" />
    <arc exit="west" move="west" destination="83" />
    <arc exit="go" move="go well-used road" destination="874" />
    <arc exit="go" move="go society building" destination="898" />
  </node>
  <node id="83" name="The Crossing, Bank Street">
    <description>A lovely view of the river bend is afforded to the northeast, but the vast majority of the pedestrians here hurry by oblivious, as they make their way to the various commercial, financial and trade establishments located in this part of town.  Wealthy merchants, determined traders, intent-looking shopkeepers and wholesalers, and their hangers-on, pass you by.  You could swear you also see a crafty cutpurse or two among the jostling throng.</description>
    <position x="-70" y="40" z="0" />
    <arc exit="east" move="east" destination="82" />
    <arc exit="west" move="west" destination="84" />
    <arc exit="go" move="go society building" destination="851" />
  </node>
  <node id="84" name="The Crossing, Bank Street">
    <description>You stand at the entrance to the Traders' Guildhall, an understated, elegant structure with carved wooden doors, stout brick chimneys, tiled gables, pargetted decorations and leaded glass windows.  The door that leads inside is guarded by an officious concierge.  Due west along this busy street is the Crossing's Guard House, and east is the Moneylender, a financial institution for merchants great and small all over Elanthia.</description>
    <position x="-110" y="40" z="0" />
    <arc exit="north" move="north" destination="88" />
    <arc exit="east" move="east" destination="83" />
    <arc exit="west" move="west" destination="85" />
    <arc exit="go" move="go traders' guildhall" destination="339" />
  </node>
  <node id="85" name="The Crossing, Commerce Avenue">
    <description>The congested junction of Commerce Avenue, Bank Street and Ustial Road is here.  One block east is the Traders' Guildhall, and to the south lie the giant warehouses and customs clearing houses that serve the river trade.  Farther east lies the Mercantile Union, and farther south lie the docks and the roaring currents of the great Segoltha River itself.  The wealthy traders in the immediate vicinity deemed this the perfect spot for the Guard House.</description>
    <position x="-190" y="40" z="0" />
    <arc exit="north" move="north" destination="86" />
    <arc exit="east" move="east" destination="84" />
    <arc exit="south" move="south" destination="72" />
    <arc exit="go" move="go guard house" destination="404" />
  </node>
  <node id="86" name="The Crossing, Commerce Avenue">
    <description>This is a transitional block of busy Commerce Avenue, leading between the mercantile, financial and dock districts to the south, and the somewhat shabby, older and less savory neighborhood to the north.</description>
    <position x="-190" y="-40" z="0" />
    <arc exit="north" move="north" destination="87" />
    <arc exit="east" move="east" destination="88" />
    <arc exit="south" move="south" destination="85" />
    <arc exit="go" move="go iron doors" destination="357" />
  </node>
  <node id="87" name="The Crossing, Scorpion Lane">
    <description>Though no sinister dead-end or perilous cul-de-sac, you feel wary as you make your way along this lane.  The shadowy rear wall of a large nondescript building bounds the north side of the street here, instilling an irrational but unshakable sensation of countless unseen departures and arrivals through secret doors at your back and hidden tunnels beneath your feet.  Glimmers of light east toward Water Sprite Way provide some comfort, as do the busy sounds from Kertigen Road to the west.</description>
    <position x="-190" y="-60" z="0" />
    <arc exit="north" move="north" destination="118" />
    <arc exit="east" move="east" destination="89" />
    <arc exit="south" move="south" destination="86" />
    <arc exit="west" move="west" destination="97" />
    <arc exit="go" move="go artificer's shop" destination="223" />
  </node>
  <node id="88" name="The Crossing, Water Sprite Way">
    <description>The road curves slightly in concert with the river here, gradually merging with Bank Street.  Rising to the south you see the wood and white plaster facade of the Traders' Guildhall.  From this vantage point, it is more modest looking than you would have expected but still impeccably designed and executed.</description>
    <position x="-110" y="-40" z="0" />
    <arc exit="north" move="script crossingtrainerfix north" destination="89" />
    <arc exit="south" move="script crossingtrainerfix south" destination="84" />
    <arc exit="west" move="script crossingtrainerfix west" destination="86" />
    <arc exit="go" move="script crossingtrainerfix go cottage" destination="385" />
    <arc exit="go" move="script crossingtrainerfix go haberdashery" destination="704" />
  </node>
  <node id="89" name="The Crossing, Water Sprite Way">
    <description>Water Sprite Way intersects here with Scorpion Lane to the west.  Although this riverside walk is pleasant and refreshing, you cannot help but notice a large proportion of rather seedy-looking characters coming and going from the various side streets to the west and northwest.  Prosperous, beefy-faced traders stroll north and south, destined for the various commercial areas down by the river and in the eastern half of town.</description>
    <position x="-110" y="-60" z="0" />
    <arc exit="north" move="north" destination="90" />
    <arc exit="south" move="south" destination="88" />
    <arc exit="west" move="west" destination="87" />
  </node>
  <node id="90" name="The Crossing, Water Sprite Way">
    <description>The currents of the River Oxenwaithe undulate past, almost hypnotically.  Tiny points of light reflect and dance on the water's surface like a congregation of fey folks and water sprites playing amongst the waves.  Directly across the river, you see the low profiles of the locksmith's and other shops and residences of the east bank of town.  The embankment on the opposite shore rises a few feet high.</description>
    <position x="-110" y="-100" z="0" />
    <arc exit="north" move="north" destination="91" />
    <arc exit="south" move="south" destination="89" />
  </node>
  <node id="91" name="The Crossing, Damaris Lane">
    <description>The river bends slightly west here, and your path verges on the low embankment.  The blue currents carry a wide range of river traffic southwards downstream.  Barges straining their way upstream, urged on by polemen or dragged by teams of oxen along the shore.  The glistening surface of the water and the bright view of the town on the eastern shore is a welcome sight, compared to the murky shadows looming farther west down the street.</description>
    <position x="-110" y="-140" z="0" />
    <arc exit="northeast" move="northeast" destination="92" />
    <arc exit="south" move="south" destination="90" />
    <arc exit="west" move="west" destination="117" />
  </node>
  <node id="92" name="The Crossing, Nightrunner's Quay">
    <description>In one of the most unsavory parts of the Crossing, this little spit of land juts out into the Oxenwaithe just far enough to take advantage of its swift currents.  A small pier, barely more than a few crude planks, is buoyed up by some empty barrels.  Tied to a rusty nail in one of the planks is a low-floating barge.</description>
    <position x="-70" y="-180" z="0" />
    <arc exit="southwest" move="southwest" destination="91" />
    <arc exit="northwest" move="northwest" destination="93" />
  </node>
  <node id="93" name="The Crossing, Varlet's Run">
    <description>You happen upon a shadowy street corner, within leaping distance of the riverbank for a quick getaway via the River Oxenwaithe or a fast dart into the murky underpinnings of Oxenwaithe Bridge.  The lack of illumination also serves to protect the identities of the customers of the small, dimly-lit shop by the side of the road.</description>
    <position x="-110" y="-220" z="0" />
    <arc exit="north" move="north" destination="94" />
    <arc exit="southeast" move="southeast" destination="92" />
    <arc exit="west" move="west" destination="115" />
    <arc exit="go" move="go shop" destination="433" />
  </node>
  <node id="94" name="The Crossing, Oxenwaithe Bridge" note="Oxenwaithe Bridge">
    <description>This bridge is wide and sturdy, its strong oaken planks weathered but in good repair.  Across this span must stream all the traffic directly proceeding to or coming from the Northern and Western Tiers.  Oxcarts laden with imports and exports rumble past.</description>
    <position x="-110" y="-368" z="0" />
    <arc exit="east" move="east" destination="30" />
    <arc exit="south" move="south" destination="93" />
    <arc exit="west" move="west" destination="114" />
  </node>
  <node id="95" name="The Crossing, Water Street">
    <description>A fascinating mix of townsfolk and adventurers pass by, frequenting the taverns, shops and bathhouse in this part of town, or taking the scenic path along the east bend in the Oxenwaithe on their way to or from far-off destinations.</description>
    <position x="-40" y="-20" z="0" />
    <arc exit="east" move="east" destination="96" />
    <arc exit="west" move="west" destination="35" />
  </node>
  <node id="96" name="The Crossing, Water Street">
    <description>The low, long Orem's Bathhouse building squats along the north side of Water Street.  Its reddish-brown walls feel warm and moist to the touch.  People emerge all relaxed and rosy-cheeked while clients entering look sorely in need of a good, hot bath.  Orem is famed for his clean establishment and for the lack of problems the place generates for the local guard house.</description>
    <position x="10" y="-20" z="0" />
    <arc exit="east" move="east" destination="37" />
    <arc exit="west" move="west" destination="95" />
    <arc exit="go" move="go bathhouse" destination="325" />
  </node>
  <node id="97" name="The Crossing, Scorpion Lane">
    <description>The east end of the lane here seems dark and shabby, with cloaked figures striding by, strangely silent.  A few wealthy traders, surrounded by private mercenaries, hurry by, glancing to and fro nervously.  A lone town deputy patrols the cobbled road, conspicuously avoiding the shadowy areas around the characterless buildings.</description>
    <position x="-230" y="-60" z="0" />
    <arc exit="east" move="east" destination="87" />
    <arc exit="west" move="west" destination="98" />
  </node>
  <node id="98" name="The Crossing, Kertigen Road">
    <description>Kertigen Road intersects Scorpion Lane to the east.  Due west rise the town walls, which the road here follows, straight north to the gate leading to the Northern Tier, and almost all the way south to the banks of the Segoltha.  The crowds jostling you on all sides bear eloquent, if annoying, testament to this street's crucial position.</description>
    <position x="-310" y="-60" z="0" />
    <arc exit="north" move="north" destination="109" />
    <arc exit="east" move="east" destination="97" />
    <arc exit="south" move="south" destination="99" />
  </node>
  <node id="99" name="The Crossing, Kertigen Road">
    <description>The calls of a few creatures, some bird and other wild beings, reach your ears from just over the town wall here.  Though the walls are high enough to protect the Crossing, the scents of hill and forest cannot be kept out, nor can the winds from the mountains and plateaus to the west.</description>
    <position x="-310" y="-20" z="0" />
    <arc exit="north" move="north" destination="98" />
    <arc exit="south" move="south" destination="71" />
  </node>
  <node id="100" name="The Crossing, Swithen's Court" note="Swithen's Court" color="#00FFFF">
    <description>A thatched house with a cruck frame sits on a small plot of land here.  Its archaic, rustic design reminds you that this part of town used to be crofts and farmland, until the walls were extended in the quest for more living space and protection.</description>
    <position x="-330" y="20" z="0" />
    <arc exit="east" move="east" destination="71" />
    <arc exit="west" move="west" destination="101" />
  </node>
  <node id="101" name="The Crossing, Swithen's Court" color="#00FFFF">
    <description>Gaunt hounds root around in the rubbish that lines the street and the sewage ditches here.  Their forlorn yelps echo off the closely-spaced housing blocks of the town's working poor.  Built of humble mud bricks and flammable wood, they lean out across the narrow street.  Across the narrow gap, standing on rickety landings or balconies, neighbors call to each other with the latest gossip, or quarrel or trade bawdy stories.</description>
    <position x="-350" y="20" z="0" />
    <arc exit="east" move="east" destination="100" />
    <arc exit="west" move="west" destination="102" />
  </node>
  <node id="102" name="The Crossing, Swithen's Court">
    <description>The ruins of the old prison stand here, due north of the newly built Drelstead Prison.  It is nothing but a charred pile of rubble, mute testament to some old uprising or invasion to free ransom prisoners or those of conscience.  The local elders may still recall, most though have forgotten.</description>
    <position x="-370" y="20" z="0" />
    <arc exit="east" move="east" destination="101" />
    <arc exit="go" move="go prison ruins" destination="439" />
  </node>
  <node id="103" name="The Crossing, Inkhorne Street" note="Inkhorne Street">
    <description>The cobblestones are uneven and crumbling here, and a view to the west down the narrow street indicates ramshackle single story huts long inured to neglect.  The bustling traffic and commerce that is carried by Kertigen Road due east does not seem to stray down this path.</description>
    <position x="-330" y="66" z="0" />
    <arc exit="east" move="east" destination="70" />
    <arc exit="west" move="west" destination="104" />
  </node>
  <node id="104" name="The Crossing, Inkhorne Street">
    <description>A beggar hobbles by you, swathed in rags.  As you try to ignore his pleas, you cannot help notice that through one of his torn sleeves is visible a purple, raised scar -- the brand of justice which marks him as a former long-term inhabitant of the town's infamous Drelstead Prison, which lies at the end of this street.</description>
    <position x="-350" y="66" z="0" />
    <arc exit="east" move="east" destination="103" />
    <arc exit="west" move="west" destination="105" />
  </node>
  <node id="105" name="The Crossing, Inkhorne Street" note="Drelstead Prison">
    <description>A three-story brick building, with slits for windows, covered by iron bars, abruptly blocks your way.  The path is strewn with garbage, and an open ditch brimming with filth runs around the structure and out under the town wall which stands directly behind it.  Before the grim building, some workmen are mending a raised wooden platform on which stands a gallows.</description>
    <position x="-370" y="66" z="0" />
    <arc exit="east" move="east" destination="104" />
  </node>
  <node id="106" name="The Crossing, Elmod Close" note="Elmod Close" color="#00FFFF">
    <description>Elmod Close, a quiet dead end, merges to the east with bustling Kertigen Road.  The shouts of workmen and merchants can be heard from that direction, and the clattering of wagons and barrows laden with trade goods.  A few locals rest under the shady elmod trees that line the street and engage in idle banter about the affairs of the neighborhood.</description>
    <position x="-330" y="100" z="0" />
    <arc exit="east" move="east" destination="69" />
    <arc exit="west" move="west" destination="107" />
  </node>
  <node id="107" name="The Crossing, Elmod Close" color="#00FFFF">
    <description>Some modest, single-story residences line the street here, long buildings with a single door in the middle, and hoary thatched roofs.  You notice both people and livestock crossing the thresholds of some of the homes, which apparently serve as living quarters, hearth and manger.  The cobbled streets of the lane are strewn with straw.</description>
    <position x="-350" y="100" z="0" />
    <arc exit="east" move="east" destination="106" />
    <arc exit="west" move="west" destination="108" />
  </node>
  <node id="108" name="The Crossing, Elmod Close" color="#00FFFF">
    <description>The street ends here and the pavement gives way to rich, damp earth.  A small garden plot extends west, the apparent pride and joy of the dwellers at this end of the lane.  It is carefully tended, with piles of fertilizer lovingly heaped around green, tender seedlings.  A scarecrow done up like a raggedy Gor'Tog keeps the winged neighborhood riffraff away.</description>
    <position x="-370" y="100" z="0" />
    <arc exit="east" move="east" destination="107" />
  </node>
  <node id="109" name="The Crossing, Kertigen Road">
    <description>Although there is a varied mix of adventurers and townsfolk around you, the section of the Crossing just east strikes you as somewhat disreputable.  The walls that parallel Kertigen Road on its western edge offer security from the evils that dwell without, but do little to protect against those miscreants who choose to make the city streets their hunting grounds.</description>
    <position x="-310" y="-100" z="0" />
    <arc exit="north" move="north" destination="110" />
    <arc exit="south" move="south" destination="98" />
  </node>
  <node id="110" name="The Crossing, Kertigen Road">
    <description>Your journey brings you hard in the shadow of the town walls here, that separate the Crossing from the wilds of the Western Tier.  The northwest corner of the barricades lies a few hundred paces north, where the gates are guarded throughout all watches of the day and night.</description>
    <position x="-310" y="-140" z="0" />
    <arc exit="north" move="north" destination="111" />
    <arc exit="south" move="south" destination="109" />
  </node>
  <node id="111" name="The Crossing, Kertigen Road">
    <description>The rather unsavory side of the Viper's Nest Inn borders the east side of the curb.  Its windows are dirty and opaque, except where panes of glass have been shattered here and there.  The sounds and smells that emanate from it are rank and unappetizing, but you figure it must appeal to a certain clientele.  Draft animals, carts, soldiers, and traders stream by, in between ragamuffin urchins and stray dogs picking at the rubbish heaps around the inn.</description>
    <position x="-310" y="-180" z="0" />
    <arc exit="north" move="north" destination="112" />
    <arc exit="south" move="south" destination="110" />
  </node>
  <node id="112" name="The Crossing, Goodwhate Pike">
    <description>Old woodframe buildings that appear to be vacant border the wide pike here.  Heavy traffic has taken its toll, leaving deep ruts and almost demolishing the curb, so that the already decrepit mud-and-twig structures almost seem to spill out upon the road.  You have no doubt that, during the height of the rainy season, they literally do.  Directly west lies the Western Gate.</description>
    <position x="-310" y="-368" z="0" />
    <arc exit="east" move="east" destination="113" />
    <arc exit="south" move="south" destination="111" />
    <arc exit="west" move="west" destination="121" />
  </node>
  <node id="113" name="The Crossing, Goodwhate Pike">
    <description>A long, barn-like structure hunkers just by the road here, wedged between the cobbled way and the high outer walls of town that lie just north.  A very high, very wide double door leads in and from it you hear the lowing of oxen, the whinnying of steeds and the braying of obstinate pack animals.  An exotic-looking trader in a silk robe forcibly leads a recalcitrant camel from the building, almost knocking you over.</description>
    <description>A long, barn-like structure hunkers just by the road here, wedged between the cobbled way and the high outer walls of town that lie just north.  A very high, very wide double door leads in and from it the lowing of oxen, the whinnying of steeds and the braying of obstinate pack animals can be heard.  An exotic-looking trader in a silk robe forcibly leads a recalcitrant camel from the building, almost knocking a nearby attendant to the ground.</description>
    <position x="-230" y="-368" z="0" />
    <arc exit="east" move="east" destination="114" />
    <arc exit="south" move="south" destination="119" />
    <arc exit="west" move="west" destination="112" />
    <arc exit="go" move="go barnlike structure" destination="568" />
  </node>
  <node id="114" name="The Crossing, Goodwhate Pike">
    <description>The gates to the west, the river and Oxenwaithe Bridge to the east, the town walls and dense forests and scrub just beyond to the north - all serve to remind you of the dichotomy between the untamed forces of nature and the works of mortals that life in Elanthia constantly confronts you with.  Such cosmic musings are soon cut short, however, as a foul-smelling Dwarf barbarian shoves you aside rudely and lumbers past.</description>
    <description>The gates to the west, the river and Oxenwaithe Bridge to the east, the town walls and dense forests and scrub just beyond to the north - all serve as a reminder of the dichotomy between the untamed forces of nature and the works of mortals that life in Elanthia constantly confronts its inhabitants with.  Such cosmic musings are soon cut short, however, as a foul-smelling Dwarf barbarian shoves aside a few passersby rudely and lumbers past.</description>
    <position x="-190" y="-368" z="0" />
    <arc exit="east" move="east" destination="94" />
    <arc exit="south" move="south" destination="115" />
    <arc exit="west" move="west" destination="113" />
  </node>
  <node id="115" name="The Crossing, Varlet's Run">
    <description>This murky lane connects the Viper's Nest Inn, whose entrance is to the southwest, and the Pawnshop, whose doors are just east, around the corner.  Anonymous but brisk traffic between the two establishments makes you wonder whether the patrons are pawning their goods to buy more drink or are relieving themselves of slightly hot merchandise acquired in some ill-lit nook of the tavern.</description>
    <position x="-190" y="-220" z="0" />
    <arc exit="north" move="north" destination="114" />
    <arc exit="east" move="east" destination="93" />
    <arc exit="south" move="south" destination="116" />
    <arc exit="west" move="west" destination="119" />
    <arc exit="go" move="go scruffy doorway" destination="338" />
  </node>
  <node id="116" name="The Crossing, Cutpurse Alley">
    <description>Cutpurse Alley runs between the Pawn Shop on the east side of the way, and the notorious Viper's Nest Inn on the west.  You feel a mob of shadowy figures skulking past you, although you can discern no one clearly.  The hot breath of a covetous scoundrel on the nape of your neck reminds you of how this byway got its name and causes you to quicken your step.</description>
    <position x="-190" y="-180" z="0" />
    <arc exit="north" move="north" destination="115" />
    <arc exit="south" move="south" destination="117" />
  </node>
  <node id="117" name="The Crossing, Damaris Lane">
    <description>Unlike most of the Crossing's broad and expansive intersections, the corners where Damaris Lane meets Cutpurse Alley are shadowy and sinister.  Though the junction makes for a small plaza of sorts, there is a claustrophobic feel here that does not bode well.</description>
    <position x="-190" y="-140" z="0" />
    <arc exit="north" move="script crossingtrainerfix north" destination="116" />
    <arc exit="east" move="script crossingtrainerfix east" destination="91" />
    <arc exit="south" move="script crossingtrainerfix south" destination="118" />
    <arc exit="west" move="script crossingtrainerfix west" destination="120" />
    <arc exit="go" move="script crossingtrainerfix go academy" destination="367" />
  </node>
  <node id="118" name="The Crossing, Dodgers' Row">
    <description>Feet tread the cobbled streets here, booted feet, sandaled feet, armored feet, rag-wrapped feet, all thumping against the pavement and reverberating off the closely-spaced, rundown buildings.  In the slimy gutter, along the west curb, a pile of dry straw has been heaped up against a sewer grating.</description>
    <position x="-190" y="-120" z="0" />
    <arc exit="north" move="north" destination="117" />
    <arc exit="south" move="south" destination="87" />
    <arc exit="climb" move="climb sewer grating" destination="295" />
  </node>
  <node id="119" name="The Crossing, Varlet's Run">
    <description>This is a small, foul-smelling byway that most civilized folks would flee through as quickly as their feet would carry them.  And yet, this lane seems to exert a perverse fascination, a hint of things unseen, sinister or forbidden always just about to transpire.</description>
    <position x="-230" y="-220" z="0" />
    <arc exit="north" move="north" destination="113" />
    <arc exit="east" move="east" destination="115" />
    <arc exit="go" move="go dark shrine" destination="707" />
  </node>
  <node id="120" name="The Crossing, Damaris Lane">
    <description>Broken bottles, filthy rags, rotting food and less identifiable rubbish litter the road just in front of the unsavory Viper's Nest Inn.  There seems to be no usable sidewalks, or else the curbs and cobblestones are in such disrepair that there is no way to tell where one ends and the other begins.  Trying to avoid either stumbling or stepping in something awful, you pick your way along, with evident distaste and distrust.</description>
    <position x="-210" y="-140" z="0" />
    <arc exit="east" move="east" destination="117" />
    <arc exit="go" move="go viper's inn" destination="708" />
  </node>
  <node id="121" name="The Crossing, Western Gate">
    <description>Camels, oxen, and mules compete with Elves, Gor'Togs, and Humans to pass through the narrow gate which breaches the stone wall between town and the western reaches.  The lowing of animals, and the bellowing of irate travelers become almost indistinguishable the more you listen.  After a few minutes, so do the unmistakable odors of unwashed sojourners and domestic beasts of burden.  It begins to dawn on you why folks are anxious to pass through customs, whatever the cost, as quickly as possible.</description>
    <position x="-341" y="-368" z="0" />
    <arc exit="east" move="east" destination="112" />
    <arc exit="go" move="go western gate" destination="172" />
    <arc exit="go" move="go stone stairs" destination="398" />
    <arc exit="go" move="go guard house" destination="712" />
  </node>
  <node id="122" name="The Crossing, Truffenyi Place">
    <description>Truffenyi Place runs straight along the north-south axis of the Crossing and leads to the Guilds and Academy, vital institutions of town life.  A quiet but constant buzz of citizens and adventurers engaged in missions, commerce, debate and worship fills the street.  More pronounced are the peals of amiable laughter and snippets of modest songs that come from Taelbert's Inn, perched proudly on the west curb.</description>
    <position x="10" y="-408" z="0" />
    <arc exit="north" move="north" destination="123" />
    <arc exit="east" move="east" destination="128" />
    <arc exit="south" move="south" destination="31" />
    <arc exit="go" move="go oak door" destination="465" />
    <arc exit="go" move="go inn" destination="713" />
  </node>
  <node id="123" name="The Crossing, Truffenyi Place">
    <description>Stands of sicle trees shade the intersection here, and continue to line the lane leading west.  Your path follows the town wall, which takes a 90-degree turn here from east to north.  Over the wall, to the west, beyond the low fruit trees, you see taller, darker vegetation, as though the forest itself is gathering its forces to lay siege to this outpost of civilization set among the wilderness.</description>
    <position x="10" y="-448" z="0" />
    <arc exit="north" move="north" destination="124" />
    <arc exit="south" move="south" destination="122" />
    <arc exit="west" move="west" destination="126" />
  </node>
  <node id="124" name="The Crossing, Truffenyi Place">
    <description>The road here is smooth and clear of debris, the cobblestones underfoot flawlessly dressed.  To the north, the way opens into a wide plaza, paved in bright mosaics depicting the gods of Elanthia in their benevolent and terrifying aspects.  To the south and west, lie the Tannery and the way to the Rangers' Guild.</description>
    <position x="10" y="-488" z="0" />
    <arc exit="north" move="north" destination="125" />
    <arc exit="south" move="south" destination="123" />
  </node>
  <node id="125" name="The Crossing, Fostra Square" note="Fostra Square">
    <description>Truffenyi Place ends in a broad plaza here, a pleasant river- and pine-scented breeze greeting you in the open space.  Several tall, sculpted columns flank a heavily-carved rosewood door that serves as the entryway to the Clerics' Guild.  The sounds of muttered chants, invocations and lessons are audible from the building's stained-glass windows.</description>
    <position x="10" y="-528" z="0" />
    <arc exit="south" move="script crossingtrainerfix south" destination="124" />
    <arc exit="go" move="script crossingtrainerfix go guild" destination="344" />
    <arc exit="go" move="script crossingtrainerfix go hovel" destination="366" />
    <arc exit="go" move="script crossingtrainerfix go portico gate" destination="725" />
  </node>
  <node id="126" name="The Crossing, Sicle Grove Lane">
    <description>A low, shed-like building stands beneath the trees along the road here.  It has a gabled roof that dips off to the side, covering a smaller annex from which a vent disgorges noxious vapors into the street.  Various antlers, skulls, and tusks decorate the outside of the shed.</description>
    <position x="-30" y="-448" z="0" />
    <arc exit="east" move="east" destination="123" />
    <arc exit="west" move="west" destination="127" />
    <arc exit="go" move="go tanner's shed" destination="220" />
  </node>
  <node id="127" name="The Crossing, Sicle Grove Lane">
    <description>The town wall here is overgrown with flowering vines and herbs, making it appear to be a barrier of intertwining branches and blossoms.  A small path leads north through an ivy-covered gateway in the wall.  Though the trail may have been a temporary one at first, long years of use by visitors to and from the Rangers' Guild at its end have assured its permanent existence.</description>
    <position x="-70" y="-448" z="0" />
    <arc exit="east" move="east" destination="126" />
    <arc exit="go" move="go path" destination="336" />
  </node>
  <node id="128" name="The Crossing, Covered Alleyway">
    <description>This alleyway runs between Gildleaf Circle and Truffenyi Place.  It is covered with a makeshift tin canopy supported by iron nails in the closely-spaced buildings.  Although narrow and unpaved, it is free of debris and appears to be frequented for deliveries and shortcuts.  An archway on one side leads between the buildings.</description>
    <position x="50" y="-408" z="0" />
    <arc exit="east" move="east" destination="129" />
    <arc exit="west" move="west" destination="122" />
    <arc exit="go" move="go side door" destination="463" />
  </node>
  <node id="129" name="The Crossing, Gildleaf Circle">
    <description>Mouthwatering aromas, gentle laughter and refined conversation emanating from the quaint twin cottages here make this corner of the Crossing a popular destination.  The famed shop of the town's leading purveyor of fine victuals, Barsabe the Halfling, snuggles next to the bakery of Saranna, his wife of many years.  Rotund boys scurry between both shops and dart out with baskets and trays laden with fresh delicacies.  A narrow alley runs between the two shops and leads west.</description>
    <position x="90" y="-408" z="0" />
    <arc exit="north" move="north" destination="132" />
    <arc exit="east" move="east" destination="130" />
    <arc exit="west" move="west" destination="128" />
    <arc exit="go" move="go grocer" destination="870" />
    <arc exit="go" move="go baker" destination="464" />
  </node>
  <node id="130" name="The Crossing, Gildleaf Circle">
    <description>The wide path curves here, its borders marked in high, straight marble curbstones.  Beds of flowers and foliage separate the street from the sidewalk, and still more trees and shrubs separate the walkways from the residences.  Around the bend to the west are the busy shops of the Grocer and Baker, while north is the quirky storefront of Elanthia's most adept and eccentric Alchemist, Chizili.</description>
    <position x="130" y="-408" z="0" />
    <arc exit="north" move="north" destination="131" />
    <arc exit="west" move="west" destination="129" />
  </node>
  <node id="131" name="The Crossing, Gildleaf Circle">
    <description>Pungent, noxious fumes waft out of the open door of the Alchemist's Shop on the west side of the street here.  Vapors of sulfur, formaldehyde, alcohol and methane are just a few of the odors you can identify, among myriad more you'd rather not hazard a guess at.  Serious, stooped figures with long, grey locks or beards go and come through the door, oblivious to the choking miasma.</description>
    <position x="130" y="-448" z="0" />
    <arc exit="north" move="north" destination="135" />
    <arc exit="east" move="east" destination="136" />
    <arc exit="south" move="south" destination="130" />
    <arc exit="go" move="go alchemist's shop" destination="226" />
  </node>
  <node id="132" name="The Crossing, Gildleaf Circle">
    <description>Well-heeled folk stroll past on their way south for a bite to eat or to errands in the heart of the Crossing.  Draped in rich fur cloaks, velvets and brocades, sporting rings and brooches of rare gems and precious metals, these prosperous burghers seem a far cry from the veteran, hardened adventurers encountered elsewhere within the city limits.  They are even more remote from the shanty dwellers of the Middens, who subsist on the outskirts of society.</description>
    <position x="90" y="-448" z="0" />
    <arc exit="north" move="north" destination="133" />
    <arc exit="south" move="south" destination="129" />
  </node>
  <node id="133" name="The Crossing, Eylhaar Bane Road">
    <description>Eylhaar Bane Road curves sharply here to become the expansive arc of Gildleaf Circle, a broad, clean road with gravel shoulders and terrazzo sidewalks.  The footpaths are lined with cultivated beds of azaleas and marigolds between rows of ornamental dwarf fruit trees and dazzling gildleaf shrubs.  Ornate gingerbread cottages and elegant townhouses with wrought-iron balconies and grillwork are set back from the curb, behind sturdy gates or thickets of topiary.</description>
    <position x="90" y="-528" z="0" />
    <arc exit="east" move="east" destination="135" />
    <arc exit="south" move="south" destination="132" />
    <arc exit="west" move="west" destination="134" />
    <arc exit="go" move="go almhara arch" destination="274" />
    <arc exit="go" move="go stone building" destination="735" />
  </node>
  <node id="134" name="North Gate, Gate">
    <description>Nearly forgotten and in disrepair, the North Gate sits untended among a cluster of weeds.  Thorny vines grow unheeded against its crumbling archway, and the decorative carvings along the sides of the arch have long since eroded to impressionistic ridges and gashes.  Deep ruts slicing through the road's surface waylay unwary travelers even in the daylight.</description>
    <description>Nearly forgotten and in disrepair, the North Gate sits untended among a cluster of weeds.  Night's dim light casts shadows among the impressionistic ridges and gashes covering the sides of the arches:  all that erosion has left of once magnificent decorative carvings.  Loose stones scattered across the broken pavement threaten to send unwary travelers sprawling.</description>
    <position x="50" y="-528" z="0" />
    <arc exit="east" move="east" destination="133" />
    <arc exit="go" move="go crumbling archway" destination="173" />
  </node>
  <node id="135" name="The Crossing, Eylhaar Bane Road">
    <description>Looking north, scanning from east to west, you can see the profiles of the Paladins' and Clerics' Guilds rising above the shops and homes that dot the neighborhood like patches of a crazy quilt.  To the south, you can barely discern the top story of Academy Asemath, with its white marble friezes in high relief.  A row of prickly privet hedges, their intertwining branches creating a formidable fence, line both sides of the way.</description>
    <position x="130" y="-528" z="0" />
    <arc exit="east" move="east" destination="137" />
    <arc exit="south" move="south" destination="131" />
    <arc exit="west" move="west" destination="133" />
    <arc exit="go" move="go lattice-work gate" destination="294" />
  </node>
  <node id="136" name="The Crossing, Flamethorn Way">
    <description>Tapering flamethorn trees line the road, their scarlet leaves swaying vividly against the sky in a slight breeze.  A red-crested woodpecker, invisible among the branches until it reveals itself with a sharp *RAT-TAT-TAT* in search of food, harshly chides you for interrupting its meal and flits away, over the rooftops of the Healing Hospital and Empaths' Guild to the east.  To the south, the tree-lined path continues.</description>
    <position x="200" y="-448" z="0" />
    <arc exit="south" move="south" destination="7" />
    <arc exit="west" move="west" destination="131" />
    <arc exit="go" move="go wrought-iron gate" destination="248" />
  </node>
  <node id="137" name="The Crossing, Eylhaar Bane Road">
    <description>Low, long houses border the south side of the road here, simple, one-room affairs with doors in the center, and chimney holes cut through the thatched roofs.  The lowing of cattle from within also bespeaks of the humbleness of the inhabitants.</description>
    <position x="170" y="-528" z="0" />
    <arc exit="east" move="east" destination="138" />
    <arc exit="west" move="west" destination="135" />
    <arc exit="go" move="go wooden gate" destination="822" />
    <arc exit="go" move="go thatched cottage" destination="736" />
  </node>
  <node id="138" name="The Crossing, Herald Street">
    <description>Herald Street leads west here into Eylhaar Bane Road.  A few modest residences hug the curb, and you swerve to avoid a group of children hard at play.  They are wielding whittled sticks and trash can covers as they engage each other in mock battles and jousts.</description>
    <position x="210" y="-528" z="0" />
    <arc exit="north" move="north" destination="142" />
    <arc exit="south" move="south" destination="139" />
    <arc exit="west" move="west" destination="137" />
  </node>
  <node id="139" name="The Crossing, Firulf Vista">
    <description>The roads here follow the inner perimeter of the town walls, meeting at a right angle.  Sparse, colorful wildflowers have taken root in the crevices where the walls abut here.  Several blocks north rises the building that houses the Paladins' Guild.  Light glints off its crystal-paned skylight and circular stained-glass windows, surrounding the edifice with an aura of power and purity.</description>
    <position x="210" y="-488" z="0" />
    <arc exit="north" move="north" destination="138" />
    <arc exit="east" move="east" destination="140" />
    <arc exit="go" move="go hall" destination="994" />
  </node>
  <node id="140" name="The Crossing, Firulf Vista">
    <description>Firulf Vista is a broad thoroughfare leading to the northeastern town gate.  Farther to the east, beyond the crenellated tops of the town walls, is the tall, thin spire of the Warrior Mages' Guild, and the dark, swelling hills of the wilderness that lies outside the safety of the confines of civilization.</description>
    <position x="330" y="-488" z="0" />
    <arc exit="east" move="east" destination="143" />
    <arc exit="south" move="south" destination="141" />
    <arc exit="west" move="west" destination="139" />
  </node>
  <node id="141" name="The Crossing, Via Mandroga">
    <description>This narrow alley leads between the northern angle of the town wall and the Arena.  The backdoor to the Healing Hospital and to the Empaths' Guild is here, and burlap bags filled with soiled gauze, empty vials and the remains of herbs and potions litter the gutter.  A few bold mice nibble at the heaps of debris.</description>
    <position x="330" y="-448" z="0" />
    <arc exit="north" move="north" destination="140" />
    <arc exit="south" move="south" destination="2" />
    <arc exit="go" move="go hospital backdoor" destination="737" />
  </node>
  <node id="142" name="The Crossing, Herald Street">
    <description>The town wall is close to the side of the road here, affording a roost for the wrens and crows that make their more permanent homes in the woods beyond the ramparts to the east.</description>
    <position x="210" y="-568" z="0" />
    <arc exit="north" move="north" destination="788" />
    <arc exit="south" move="south" destination="138" />
  </node>
  <node id="143" name="The Crossing, Firulf Vista">
    <description>The stone town walls seal off the city from the wilds beyond to the north.  Still, the scents of damp earth and leaf mold, pine and cedar, and feral creatures drift over the barricade.  Directly to the east, within spitting distance, is the Northeast town gate.  Through the gap in the wall, you can make out the low rise of the slate hills to the northwest and the lone, aloof tower of the Warrior Mages' Guild to the east.</description>
    <position x="370" y="-488" z="0" />
    <arc exit="east" move="east" destination="145" />
    <arc exit="south" move="south" destination="144" />
    <arc exit="west" move="west" destination="140" />
  </node>
  <node id="144" name="The Crossing, Boar Alley">
    <description>This quaint alley connects Magen Road to the south and Firulf Vista to the north.  An ornately carved building with an ancient wooden door is set back from the curb.  You would hardly stop and give it a second glance, except that the windows on the second story all seem to glow with soft, pulsating hues that cycle through the colors of the spectrum.</description>
    <position x="370" y="-448" z="0" />
    <arc exit="north" move="north" destination="143" />
    <arc exit="east" move="east" destination="147" />
    <arc exit="south" move="south" destination="3" />
    <arc exit="go" move="go ancient door" destination="738" />
  </node>
  <node id="145" name="The Crossing, Firulf Vista">
    <description>Utter bedlam confronts you as you step out into this street.  This is the point where anyone and everyone who passes through the Northeast Gate either leaving town or arriving must cross paths.  You quickly conclude this is no spot to stop and admire the scenery of the regions of the Eastern Tier beyond, nor to study the local architecture around you, since the momentum of the crowd carries you along, almost without your realizing it.</description>
    <position x="410" y="-488" z="0" />
    <arc exit="east" move="east" destination="146" />
    <arc exit="south" move="south" destination="147" />
    <arc exit="west" move="west" destination="143" />
    <arc exit="go" move="go stone stairway" destination="386" />
  </node>
  <node id="146" name="The Crossing, Northeast Customs" note="NE Customs">
    <description>Here stands the Northeast Gate, two massive doors of steel-banded ironwood securely attached to the masonry of the town walls.  The traffic here is thick with travelers, and the Customs Officers are alert to any sign of trouble.</description>
    <position x="440" y="-488" z="0" />
    <arc exit="west" move="west" destination="145" />
    <arc exit="go" move="go northeast gate" destination="171" />
    <arc exit="go" move="go winding trail" destination="806" />
  </node>
  <node id="147" name="The Crossing, Oralana Ramble">
    <description>Oralana Ramble runs along the east wall of town, leading between the Northeast and the Eastern Gates.  Somehow, it is relatively calm compared to those roads that lead to the Town Green, Town Hall, the Bank and the other nerve centers of the Crossing.  The three towers guarding the temple thrust into the sky to the southwest, their flames a beacon for miles.  A bluejay lands on a ledge atop the wall, chasing a pair of mudwrens from their comfy perch into a clump of weeds along the side of the path.</description>
    <description>Oralana Ramble runs along the east wall of town, leading between the Northeast and the Eastern Gates.  Somehow, it is relatively calm and empty compared to those roads that lead west and southwest to the Town Green, Town Hall, the Bank and the other vital nerve centers of the Crossing.  The three towers guarding the temple thrust into the sky to the southwest, their flames a beacon for miles.  The shadowy images of nightingales swoop high in the sky, their gentle lullabies decorating the cool night air.</description>
    <position x="410" y="-448" z="0" />
    <arc exit="north" move="north" destination="145" />
    <arc exit="south" move="south" destination="148" />
    <arc exit="west" move="west" destination="144" />
  </node>
  <node id="148" name="The Crossing, Oralana Ramble">
    <description>A great deal of traffic passes through here, as travelers, merchants, rogues, adventurers, ne'er-do-wells and savants make their way to and from the Eastern Tier.  The Ramble continues south, leading into the heart of the Crossing, while a stone's throw away are the northeast gates.  All these pedestrians make this the ideal location for the shop of Talmai the Cobbler, whose business in new footwear and repairs prospers despite his lack of shrewdness.</description>
    <position x="410" y="-408" z="0" />
    <arc exit="north" move="north" destination="147" />
    <arc exit="south" move="south" destination="149" />
    <arc exit="go" move="go cobbler's shop" destination="436" />
  </node>
  <node id="149" name="The Crossing, Oralana Ramble">
    <description>The road continues north and south, and merges on the west with Trothfang Street.  In that direction, you see the turquoise- and crimson-tiled dome of the Champions' Arena.  Your proximity to the town wall blocks out any view of the Eastern Tier which lies beyond it.  Lowering your gaze to the path beneath your feet, you notice a spotted beetle wriggle into a chink in the wall and disappear.</description>
    <position x="410" y="-328" z="0" />
    <arc exit="north" move="north" destination="148" />
    <arc exit="south" move="south" destination="150" />
    <arc exit="west" move="west" destination="4" />
    <arc exit="none" move="go sewer grate" destination="854" />
  </node>
  <node id="150" name="The Crossing, Oralana Ramble">
    <description>You are traveling just inside the eastern town wall.  Mosses, grasses, and weeds blooming with brilliant wildflowers grow between the road and the wall, climbing right up to the edge of the rampart itself.  The way bends to the southwest, and continues straight north toward the northeastern gate.</description>
    <position x="410" y="-180" z="0" />
    <arc exit="north" move="north" destination="149" />
    <arc exit="southwest" move="southwest" destination="151" />
  </node>
  <node id="151" name="The Crossing, Betany Street">
    <description>Someone has taken the time and care to attach flowerpots to the stone wall here, and plant cheerful flowers and fragrant herbs in them.  It provides a lovely contrast to the fact that it was built to keep out marauders bringing death and destruction.  The wall curves gently northeast, and off in the distance to the west, on either side of the street, you see the Seamstress and the Jeweler's shop, both about a block away.</description>
    <position x="370" y="-140" z="0" />
    <arc exit="northeast" move="northeast" destination="150" />
    <arc exit="south" move="south" destination="154" />
    <arc exit="west" move="west" destination="152" />
  </node>
  <node id="152" name="The Crossing, Betany Street">
    <description>Potted plants and verdant window boxes decorate the front of Marcipur's Stitchery here.  Climbing vines of maiden tress plants poke their tendrils into any nook or cranny afforded by the clean, white stucco walls, including windows and the door.  Rather plainly dressed women file into the Stitchery, while stunningly garbed ones, attired in the latest adventuring fashions, emerge, all smiles.</description>
    <position x="290" y="-140" z="0" />
    <arc exit="east" move="east" destination="151" />
    <arc exit="west" move="west" destination="153" />
    <arc exit="go" move="go stitchery" destination="435" />
  </node>
  <node id="153" name="The Crossing, Betany Street">
    <description>Adventurers jostle you in a hurry to reach their guilds for training, while those engaged in commerce or town affairs stride by with less urgent gaits.  You seem to come into full body contact with every pedestrian, and a few stray dogs to boot, since the road narrows here as Albreda Boulevard flows into Betany Street.  A low hedgerow due west divides this corner from the wide swath of Town Green while high above an iron Temple walkway hovers over the low outline of Town Hall to the southwest.</description>
    <description>Adventurers stroll through the night air, some retiring to their guilds while others still intent on training stride purposefully in those directions.  The normally bustling area is peaceful, the twittering of a few nightingales interspersing with the quiet conversations of people just passing through.  Albreda Boulevard flows into Betany Street here, while a low hedgerow due west divides this corner from Town Green.  An iron Temple walkway hovers over the outline of Town Hall to the southwest.</description>
    <position x="250" y="-140" z="0" />
    <arc exit="east" move="east" destination="152" />
    <arc exit="south" move="south" destination="155" />
  </node>
  <node id="154" name="The Crossing, Dafora Row">
    <description>The town wall marking the Eastern Tier continues north-south along here.  A back door with a thick iron padlock is opposite the wall.  You notice that there are marks and scratches around the padlock, as though it had been a target for thieves.</description>
    <position x="370" y="-100" z="0" />
    <arc exit="north" move="north" destination="151" />
    <arc exit="south" move="south" destination="157" />
  </node>
  <node id="155" name="The Crossing, Albreda Boulevard">
    <description>This broad junction links Albreda Boulevard with the pleasant, tree-lined street to the west and the flower-dappled lane to the north.  Such a refreshing vista invites you to stop and soak in the town's atmosphere.  To the west you see the gabled slate roof of Town Hall.  From the northwest comes the hue and cry of itinerant merchants, peddlers and soothsayers, vying for the attention of the adventurers gathered there in the Town's Green.</description>
    <position x="250" y="-100" z="0" />
    <arc exit="north" move="north" destination="153" />
    <arc exit="south" move="south" destination="156" />
    <arc exit="west" move="west" destination="41" />
    <arc exit="go" move="go jewelry shop" destination="369" />
  </node>
  <node id="156" name="The Crossing, Albreda Boulevard">
    <description>The blank side of the Town Hall building stands to the west, its modest construction evident from this oblique angle.  Upscale emporiums and services line the east side of the broad boulevard here, with shoppers casually glancing in the windows and doors to see the latest in trade goods from the outlying lands of Elanthia.</description>
    <position x="250" y="-13" z="0" />
    <arc exit="north" move="north" destination="155" />
    <arc exit="south" move="south" destination="160" />
    <arc exit="west" move="west" destination="161" />
  </node>
  <node id="157" name="The Crossing, Dafora Row">
    <description>Dafora Row runs along the easternmost path inside the town walls.  The backs of shops line the quiet byway, and travelers seeking to bypass the traffic on the main streets bound past, headed north and south on matters of great commercial or personal import.</description>
    <position x="370" y="-20" z="0" />
    <arc exit="north" move="north" destination="154" />
    <arc exit="south" move="south" destination="158" />
    <arc exit="go" move="go oak tower" destination="751" />
  </node>
  <node id="158" name="The Crossing, Hodierna Way">
    <description>The wall surrounding the town snakes from north to south directly to the east.  The towers of the Temple to the west cast a shadow that at times reaches clear to the pointed roof of the structure that guards the Eastern Gate.  To the north, a narrow, cheerful street opens up.</description>
    <description>The wall surrounding the town snakes from north to south directly to the east.  The towers of the Temple to the west are barely seen in the dark, its merry lights minutely visible in the distance, twinkling through stained-glass windows.  To the north, a narrow, cheerful street opens up.</description>
    <position x="370" y="20" z="0" />
    <arc exit="north" move="north" destination="157" />
    <arc exit="east" move="east" destination="162" />
    <arc exit="west" move="west" destination="159" />
  </node>
  <node id="159" name="The Crossing, Hodierna Way">
    <description>Much of the heavy traffic that passes along Hodierna Way bespeaks of its place as a vital link through town to the shops, public institutions and the guilds, as well as to the observatory and rocky coast eastward beyond the wall.  Part of the rush here, no doubt, is generated by Catrox's Forge, where the repair and refurbishing of arms, armor and shields draws a constant clientele of ardent adventurers.</description>
    <position x="290" y="20" z="0" />
    <arc exit="east" move="east" destination="158" />
    <arc exit="west" move="west" destination="160" />
    <arc exit="go" move="go catrox's forge" destination="228" />
  </node>
  <node id="160" name="The Crossing, Hodierna Way" note="First Land Herald|Herald|newspaper|news stand" color="#00FF00">
    <description>This busy intersection is a conduit for travelers -- wheeled, mounted or on foot -- moving in and out of the Eastern Gate or northwest to the heart of the city.  The Orders headquarters stands here, its doors open.  Due west is a granite structure, and to the southwest the skyline is dominated by the magnificent High Temple of Zoluren.</description>
    <description>When no straggling pedestrian heads home for the night and no squeaking caravan wheels break the silence, sometimes a nightingale can be heard.  Lamps in the windows of the Orders headquarters show someone is working late, and light shines to the southwest, where the Temple illuminates the dark sky.</description>
    <position x="250" y="20" z="0" />
    <arc exit="north" move="north" destination="156" />
    <arc exit="east" move="east" destination="159" />
    <arc exit="south" move="south" destination="163" />
    <arc exit="west" move="west" destination="42" />
    <arc exit="go" move="go walkway ramp" destination="382" />
    <arc exit="go" move="go order headquarters" destination="833" />
  </node>
  <node id="161" name="The Crossing, Albreda Alley">
    <description>Just behind the Town Hall, this short and obviously recent alley dead-ends at a new wooden building with a large sign over the door.  Toolbelted Dwarven builders and a variety of customers, many tanned and dressed in weathered buckskin, pass in and out.</description>
    <position x="210" y="-13" z="0" />
    <arc exit="east" move="east" destination="156" />
    <arc exit="go" move="go door" destination="571" />
  </node>
  <node id="162" name="The Crossing, Eastern Gate">
    <description>Camels, oxen and mules compete with Elves, Gor'Togs and Humans to pass through the Eastern Gate which leads to the Middens, and the Observatory beyond.  The lowing of animals and the bellowing of travelers become almost indistinguishable the more you listen.  After a few minutes, so do the mingled odors of unwashed sojourners and beasts of burden.  It begins to dawn on you why folks are anxious to pass through customs, whatever the cost, as quickly as possible.</description>
    <position x="410" y="20" z="0" />
    <arc exit="west" move="west" destination="158" />
    <arc exit="go" move="go eastern gate" destination="170" />
    <arc exit="go" move="go stone stairs" destination="395" />
    <arc exit="go" move="go guard house" destination="756" />
  </node>
  <node id="163" name="The Crossing, Gull's View Lane">
    <description>Off in the northern distance the solid granite side of the bank building overshadows the west side of the street with small, barred windows and an impressive length of spiked fence around the narrow service alley that runs along the curb.  The wide vista of Hodierna Way, one of the major routes through town and towards the Eastern Tier, lies to the north.  You can catch a glimpse of the Segoltha River to the south.</description>
    <position x="250" y="40" z="0" />
    <arc exit="north" move="north" destination="160" />
    <arc exit="south" move="south" destination="164" />
  </node>
  <node id="164" name="The Crossing, Gull's View Lane">
    <description>Small shops and a few sparsely-stocked pushcarts line this street.  One elderly street vendor is selling small clay cups of steaming hot tea which he hawks with a hearty smile.  The clapboard buildings are weathered but well maintained, giving a shabbily genteel impression.  Shrill cries and the sound of rushing water drift up from the south, plaintive and forlorn, causing you to shake off a clammy chill.  Civilization, and the town's center, beckon to the north.</description>
    <position x="250" y="100" z="0" />
    <arc exit="north" move="north" destination="163" />
    <arc exit="south" move="south" destination="165" />
    <arc exit="go" move="go outdoor shrine" destination="757" />
  </node>
  <node id="165" name="The Crossing, Gull's View Terrace">
    <description>Shrill calls of shorebirds sound overhead, while the scent of mingled river and sea water fills the air on this terraced overlook.  Multihued blue currents form swirling patterns just off the riverbank, the inexorable forces of Elanthia's three major moons holding the tide's ebb and flow in their sway.  Gulls, terns and stilt-legged fishers hover near the choppy surface, some seeking man's leftovers, others pursuing nature's aquatic bounty.  To the east grows a stand of tall pine and cedar trees.</description>
    <position x="250" y="120" z="0" />
    <arc exit="north" move="north" destination="164" />
    <arc exit="east" move="east" destination="174" />
    <arc exit="climb" move="climb stair" destination="166" />
  </node>
  <node id="166" name="The Crossing, Winding Wooden Stairs">
    <description>You are on some winding wooden stairs, with a strong, sea-tinged breeze tugging at your clothes.  The steps lead up to Gull's View Terrace and into the heart of town, and down to Landfall Jetty where the ships bringing travelers, merchants, adventurers and cargo to the Crossing pull into the dock.</description>
    <position x="250" y="140" z="0" />
    <arc exit="up" move="up" destination="165" />
    <arc exit="down" move="down" destination="167" />
  </node>
  <node id="167" name="The Crossing, Landfall Jetty">
    <description>Swarms of seafarers crowd the jetty here, some waiting to embark.  Others, looking a bit befuddled, have just disembarked.  On Landfall Dock just to the south, cargo from far ports is being off loaded at the same time that the varied commodities of the Crossing's crafty traders is being hoisted off carts and handtrucks.</description>
    <position x="250" y="160" z="0" />
    <arc exit="go" move="go dock" destination="168" />
    <arc exit="climb" move="climb stair" destination="166" />
    <arc exit="go" move="go tidal cave" destination="1017" />
  </node>
  <node id="168" name="The Crossing, Landfall Dock" note="Landfall Dock" color="#FF00FF">
    <description>The dock here is teeming with travelers, stevedores and bales and bales of goods.  The waves of the Segoltha River mingle with the darker blue, salty water of the ocean to the east, marking this as a deep water estuary.  Ships from all corners of Elanthia put into port here, bringing all the races and professions together in this waterfront town.</description>
    <position x="250" y="180" z="0" />
    <arc exit="north" move="north" destination="167" />
  </node>
  <node id="169" name="The Crossing Docks, South End" note="Docks|First Land Herald|Herald|newspaper|news stand" color="#FF00FF">
    <description>A cacophony of smells erupt from this bustling area, most notably those of ripe fish and new wood.  Created especially for handling passengers arriving from or departing to outlying towns and provinces, the dock is often lined with ships of varying types and sizes.</description>
    <position x="-30" y="200" z="0" />
    <arc exit="out" move="out" destination="56" />
    <arc exit="go" move="go skirr'lolasu" destination="368" />
  </node>
  <node id="170" name="Eastern Tier, Outside Gate" note="Map8_Crossing_East_Gate.xml|E Gate|East|egate">
    <description>The eastern gate of the Crossing stands before you, an incomplete, but serviceable stone structure.  To the north are grey slate hills rising out of dense clumps of deobar trees and groves of tall almur poplars.  The land to the east is flat, and dips and rises almost imperceptibly into the distance.  A single, wide path winds through it, surrounded by ruins, debris and small huts.</description>
    <position x="439" y="20" z="0" />
    <arc exit="east" move="east" />
    <arc exit="go" move="go eastern gate" destination="162" />
    <arc exit="go" move="go stunted bushes" destination="170" />
    <arc exit="climb" move="climb wall" destination="395" />
  </node>
  <node id="171" name="Northeast Wilds, Outside Northeast Gate" note="Map7_NTR.xml|NE Gate|NTR|NEGATE">
    <description>You are before the Northeast Gate of the Crossing, surrounded by wayfarers and adventurers also in mid-journey.  Above, guardsmen stare down from the thick stone wall that encloses the city, wary for hostile visitors.  Whether they travel to destinations in town or farther west, or to the north and east, they all appear to be seeking something beyond themselves.</description>
    <position x="480" y="-488" z="0" />
    <arc exit="north" move="north" />
    <arc exit="east" move="east" />
    <arc exit="southeast" move="southeast" />
    <arc exit="climb" move="climb battlement wall" destination="386" />
  </node>
  <node id="172" name="Mycthengelde, Flatlands" note="Map4_Crossing_West_Gate.xml|W Gate|West|wgate">
    <description>Well-worn paths lead through a grove of trees to a gate in The Crossing's western wall.  Now and again you hear birds calling to one another in the branches, or the bustling of a merchant's cart as it makes its way past.  A handful of adventurers nod at you in greeting as they make their way into town.  An aromatic mix of wildflowers mingles with wyndwood, oak and juniper trees as the grove stretches north and south, while to the west, you can see grassy flatlands through a small clearing.</description>
    <position x="-401" y="-368" z="0" />
    <arc exit="northwest" move="northwest" />
    <arc exit="go" move="go western gate" destination="121" />
    <arc exit="climb" move="climb town wall" destination="398" />
  </node>
  <node id="173" name="North Turnpike, Forest" note="Map6_Crossing_North_Gate.xml|N Gate|North|ngate">
    <description>Plunging into the woods, the road deteriorates still further into a track of loose stones and cobbles.  Brambles, spike bushes, and poison fern line the edges of the turnpike, forming an impassable barrier to anyone who wished to explore the depths of the forest.</description>
    <position x="80" y="-558" z="0" />
    <arc exit="north" move="north" />
    <arc exit="go" move="go arch" destination="134" />
  </node>
  <node id="174" name="The Crossing, Riverpine Way" color="#00FFFF">
    <description>Fragrant cedars and majestic pine trees line a narrow dirt path that ambles eastward along the north bank of the Segoltha, its swift waters churning with the silt and bustle of nearby Landfall Dock.  Small cabins and fishermens' crofts dot the landscape between the trees, the peaceful riverside community blending seamlessly into its idyllic setting.</description>
    <position x="290" y="120" z="0" />
    <arc exit="east" move="east" destination="175" />
    <arc exit="west" move="west" destination="165" />
  </node>
  <node id="175" name="The Crossing, Riverpine Way" color="#00FFFF">
    <description>The thick girths of tall pines form a living colonnade either side of the path, before branching ever upward to meet high overhead in a canopy of perfumed evergreen.  A thick layer of drying needles and kernel-laden cones carpets the ground, muting all sound save for the eternal whisper of the wind.</description>
    <position x="330" y="120" z="0" />
    <arc exit="southeast" move="southeast" destination="176" />
    <arc exit="west" move="west" destination="174" />
  </node>
  <node id="176" name="The Crossing, Riverpine Way" color="#00FFFF">
    <description>The path dips slightly as it meanders around a small hollow close to the riverbank, the black soil of the forest floor occasionally broken by smooth river rocks spread with a thin layer of wind-scattered needles.  Mud stains on the bark of nearby trees demonstrate the high-water mark achieved by the river during periods of heavy rainfall.</description>
    <position x="370" y="160" z="0" />
    <arc exit="northeast" move="northeast" destination="177" />
    <arc exit="northwest" move="northwest" destination="175" />
  </node>
  <node id="177" name="The Crossing, Riverpine Circle" note="Riverpine Circle">
    <description>A platoon of tall cedars encircles and shelters a flat clearing of packed dark earth, their branches casting spindly shadows across the oft-trodden ground.  A huge firepit dominates the center of the clearing, its soot-blacked red clay lining dug from the shore of the Segoltha.  The tantalizing aroma of roasting meat lingers perpetually in the air.</description>
    <position x="390" y="140" z="0" />
    <arc exit="north" move="north" destination="179" />
    <arc exit="northeast" move="northeast" destination="178" />
    <arc exit="southeast" move="southeast" destination="180" />
    <arc exit="south" move="south" destination="181" />
    <arc exit="southwest" move="southwest" destination="176" />
    <arc exit="west" move="west" destination="182" />
    <arc exit="northwest" move="northwest" destination="183" />
  </node>
  <node id="178" name="The Crossing, Riverpine Circle" color="#00FFFF">
    <description>A thickly wooded path slopes down gently to the southwest from this grassy clearing perched atop a rotund hillock.  Cabins stand beneath the trees, hazy curls of sweet-smelling woodsmoke drifting from their chimneys and floating up to the branches above.  The town walls of the Crossing rise silently in the distance to the west, visible through occasional gaps in the dense foliage.</description>
    <position x="410" y="120" z="0" />
    <arc exit="southwest" move="southwest" destination="177" />
  </node>
  <node id="179" name="The Crossing, Riverpine Circle" color="#00FFFF">
    <description>Lush branches mesh overhead to drape this clearing in cool, deep shadow.  Cabins nestle beneath the leafy ceiling, sleepy and half-hidden by rambling berry bushes, their foundations firmly seated in the spongy bed of dark green mosses that thrives on the moist, loamy soil of the forest floor.</description>
    <position x="390" y="120" z="0" />
    <arc exit="south" move="south" destination="177" />
  </node>
  <node id="180" name="The Crossing, Riverpine Circle" color="#00FFFF">
    <description>Even the most robust trees on this rocky stretch of the riverbank offer little resistance to the brisk breeze that blusters up from the water, their trunks and boughs swept into uniform angular shapes by years of exposure.  A huddle of low-lying bothies braves the rugged location, the boldness of their occupants in the face of nature's whim rewarded by an enviable view of the river.</description>
    <position x="410" y="160" z="0" />
    <arc exit="northwest" move="northwest" destination="177" />
  </node>
  <node id="181" name="The Crossing, Riverpine Circle" color="#00FFFF">
    <description>A gathering of tidy log cabins enjoys a slightly elevated location overlooking the choppy waters of the Segoltha, where the swift brown flow plunges like an arrow toward the distant ocean.  Patches of wildflowers grow between the homes, their colorful splashes of pink and yellow contrasting pleasantly with the muted, earthy tones of the woodland.</description>
    <position x="390" y="160" z="0" />
    <arc exit="north" move="north" destination="177" />
  </node>
  <node id="182" name="The Crossing, Riverpine Circle" color="#00FFFF">
    <description>Thick banks of ferns flourish between the evergreens, their dappled fronds laden with deep green seed pods.  Despite the vigorous growth of trees and underbrush, a small clearing emerges from the verdant riot, revealing neat cabins set among the trunks and grasses.  A faint salt breeze mingles with the cool scents of the forest.</description>
    <position x="370" y="140" z="0" />
    <arc exit="east" move="east" destination="177" />
  </node>
  <node id="183" name="The Crossing, Riverpine Circle" note="Caele|Daartin" color="#00FFFF">
    <description>Streaks of daylight filter through the thick canopy of branches, picking out the busy wings of tiny birds and glinting softly on a mist of spores that drifts on the still air.  Tangled brambles flourish in hearty clumps around the trunks of surrounding trees, their thorny fingers twisting across the paths that lead to the homes sitting within the clearing.</description>
    <description>Moonlight filters through the thick canopy of branches, occasionally flickering with the erratic flight of bats and glinting off the delicate wings of the insects they hunt.  Tangled brambles flourish in hearty clumps around the trunks of surrounding trees, their thorny fingers twisting across the paths that lead to homes sitting within the clearing.</description>
    <position x="370" y="120" z="0" />
    <arc exit="southeast" move="southeast" destination="177" />
  </node>
  <node id="184" name="Crossing, Carousel Square">
    <description>A massive conical building rises from the cobbles at the square's center, its snowy alabaster surfaces gleaming brilliantly against the drab backdrop of the surrounding stone and wood.  A bejeweled mosaic set above an oval doorway reads THE CAROUSEL.</description>
    <description>A massive conical building rises from the cobbles at the square's center, its snowy alabaster surfaces gleaming brilliantly against the drab backdrop of the surrounding stone and wood.  Rows of torches encircle the structure's girth, their flames wavering lightly with the surrounding commotion and casting the building in sconces of shifting red tint.  A bejeweled mosaic set above an oval doorway reads THE CAROUSEL.</description>
    <position x="140" y="-40" z="0" />
    <arc exit="out" move="out" destination="39" />
    <arc exit="go" move="go oval doorway" destination="185" />
  </node>
  <node id="185" name="Crossing, The Carousel" note="Carousel|Vault">
    <description>Exotic tapestries of every possible description drape the wall ringing the Carousel's core.  A circular roof supports a vast framework of iron and timbers rising to the building's apex.  Countless gears, pulleys and weights within the structure form the strikingly complex and beautiful mechanism which drives the Carousel.</description>
    <position x="130" y="-50" z="0" />
    <arc exit="out" move="out" destination="184" />
    <arc exit="go" move="go arch" destination="186" />
    <arc exit="go" move="go registration desk" destination="188" />
    <arc exit="south" destination="993" />
  </node>
  <node id="186" name="Crossing, Carousel Booth">
    <description>A polished steel lever protrudes from the eastern wall of the small, ebony-panelled room, flanking a steel door to the north.</description>
    <position x="120" y="-50" z="0" />
    <arc exit="go" move="pull lev;go door" destination="187" />
    <arc exit="go" move="go arch" destination="185" />
  </node>
  <node id="187" name="Crossing, Carousel Chamber">
    <description>A sturdy vault, set in the back wall, stands ready for your use.  The floor is covered by a soft thick carpet of deep red, and the walls are paneled in polished gold pine.  Looking at the back wall, you notice a tiny gap between it and the rest of the room.   Resting on a polished bronze stand is a tiny porcelain figure.</description>
    <position x="120" y="-60" z="0" />
    <arc exit="none" move="close vault;go door" destination="186" />
  </node>
  <node id="188" name="Crossing, Carousel Desk" note="Lost and Found" color="#00FF00">
    <description>A long wooden desk spans the width of the western wall.  Brass lanterns hang from the ceiling, and the floor behind the desk is covered in spotless red tile.</description>
    <position x="130" y="-60" z="0" />
    <arc exit="out" move="out" destination="185" />
    <arc exit="go" move="go registrar's office" destination="973" />
  </node>
  <node id="189" name="Berolt's Dry Goods, Showroom" note="Berolt's Dry Goods|General" color="#FF0000">
    <description>Rough walls and floors covered with a gritty layer of dirt attest to the constant traffic in what must be one of the more popular establishments in town.  Shelves and counters crowd together, displaying all manner of equipment for a rugged lifestyle in an orderly, if dustridden manner.  Berolt, the proprietor, keeps a close eye on business, but still manages a quick, hearty laugh at a rather bawdy joke from a coarse-looking character who is obviously a regular visitor here.</description>
    <position x="150" y="-80" z="0" />
    <arc exit="out" move="out" destination="40" />
    <arc exit="go" move="go scarred doorway" destination="190" />
  </node>
  <node id="190" name="Berolt's Dry Goods, Storage" note="Dry Goods Storage|foot brush|scale brush|weapon strap" color="#FF0000">
    <description>Except for a few dusty old crates and splintering barrels shoved up against one wall, this small, close room is bare.  On top of one barrel, someone's lunch of cheese and bread is awaiting their return, provided it survives the obvious interest of a tiny mouse, who is now snuffling among some of the larger crumbs.</description>
    <position x="150" y="-70" z="0" />
    <arc exit="go" move="go scarred doorway" destination="189" />
  </node>
  <node id="191" name="Milgrym's Weapons, Showroom" note="Milgrym's Weapons|Weapons" color="#FF0000">
    <description>This is a plain and businesslike shop carrying a wide variety of weapons.  A fair assortment of the wide range of methods to cut, bash, crush, eviscerate and otherwise discomfit your enemies can be had here.  Traders with exotic or unusual weapons are welcome to come in and dicker as Milgrym has an eye for bargains and an appreciation of good weapons.</description>
    <position x="150" y="-200" z="0" />
    <arc exit="out" move="out" destination="14" />
  </node>
  <node id="192" name="Tembeg's Armory, Salesroom" note="Tembeg's Armory|Armor" color="#FF0000">
    <description>This shop is filled with a goodly array of armor of all the more popular types.  Tembeg himself, a Gor'Tog of some skill at ironwork and smithing, believes in plain but serviceable goods.  Simple of speech, he prefers direct deals to bargaining and haggling.  Good armor at good prices is Tembeg's motto.  You may not find the latest fashions in engraved jousting plate, but you will find good, honest metal and sturdy workmanship.</description>
    <position x="130" y="-200" z="0" />
    <arc exit="out" move="script crossingtrainerfix out" destination="225" />
    <arc exit="go" move="script crossingtrainerfix go doorway" destination="193" />
  </node>
  <node id="193" name="Tembeg's Armory, Workroom">
    <description>This room, dark and crowded with iron-working tools, is where Tembeg and his assistants perform repairs and simple manufacturing of the armors and weapons sold here.  A massive set of bellows in the next room awaits the sweat and labor of someone sturdy enough to waken the forge fire into life.  A massive anvil takes up much of the rest of the floor space.</description>
    <position x="130" y="-210" z="0" />
    <arc exit="out" move="out" destination="192" />
    <arc exit="go" move="go room" destination="194" />
  </node>
  <node id="194" name="Tembeg's Armory, Bellows Room" note="Strength" color="#FFFF00">
    <description>A sweating Dwarf grunts at you and gestures towards a line of equally perspiring beings laboring to haul an enormous set of bellows up and down.  Somewhere nearby, a forge fire roars and hisses in time to the rush of air from the effort and someone beats a deep-voiced drum to call the cadence of work.  You keep muttering to yourself the old mantra "That which does not kill you, makes you stronger" as you grimly ready yourself.</description>
    <position x="130" y="-220" z="0" />
    <arc exit="out" move="out" destination="193" />
  </node>
  <node id="195" name="Asemath Academy, Entrance" note="Asemath Academy">
    <description>The magnificent and renowned grey granite edifice of the Asemath Academy stands here before you.  Solid and impressive, the buildings surround a wooded courtyard.  Though severe in decor, there is no denying the high Elvish heritage in the design and execution of this learned establishment.  Famed far and wide for its scholarship and teaching, many come here but few are allowed to enroll in its varied courses.</description>
    <position x="50" y="-292" z="0" />
    <arc exit="out" move="out" destination="234" />
    <arc exit="go" move="go memorial arch" destination="196" />
  </node>
  <node id="196" name="Asemath Academy, Porte-cochere">
    <description>A flagstone pavement and a covered porte-cochere lead into the grounds of the Academy.  West of you the campus opens out into a series of lovely wooded gardens with the buildings arranged in a quadrangle all around it.  Students and professors stroll about, engaged in deep discussions or forming small study groups under the trees.  To either side of the entrance are the administration offices and the admissions center.</description>
    <position x="40" y="-292" z="0" />
    <arc exit="north" move="north" destination="197" />
    <arc exit="south" move="south" destination="198" />
    <arc exit="west" move="west" destination="199" />
    <arc exit="go" move="go memorial arch" destination="195" />
    <arc exit="go" move="go low gate" destination="31" />
  </node>
  <node id="197" name="Asemath Academy, Administration Office">
    <description>The administration office is staffed mostly with students working off their rather steep tuition fees.  Rows of plain desks covered with stacks of papers and untidy piles of scrolls are crammed in everywhere.  The elegant stonework of the walls still delights the eye, but the necessity of paperwork and the burden of success make the atmosphere a trifle less than stimulating here.  A senior clerk perches on a high stool with a desk to match and oversees the chaos.</description>
    <position x="40" y="-302" z="0" />
    <arc exit="south" move="south" destination="196" />
  </node>
  <node id="198" name="Asemath Academy, Admissions Center" note="Admissions Center">
    <description>This large room is busy at all hours of the day with hopeful people wishing to be admitted to this prestigious academy.  Harried clerks hand out application packets and explain rules and procedures to applicants.  Promising students are interviewed quietly at one side of the room and those who pass will be brought back for testing and more interviews.  The air is full of the smell of fresh parchment and nervous people.</description>
    <position x="40" y="-282" z="0" />
    <arc exit="north" move="north" destination="196" />
  </node>
  <node id="199" name="Asemath Academy, Eastern Walkway" note="Ozursus">
    <description>A walkway paved with crushed stone in a soft blue-green hue runs between tastefully arranged copses of trees in a large central open area.  The trees show signs of Elvish life-sculpting and form harmonious groupings that display their dense foliage to perfect advantage.  Here and there, groups of flowering bushes or plantings of bright blossoms lend a serene touch of color to the scene.  Groups of students wander about or study quietly.</description>
    <position x="30" y="-292" z="0" />
    <arc exit="north" move="north" destination="207" />
    <arc exit="east" move="east" destination="196" />
    <arc exit="south" move="south" destination="206" />
    <arc exit="west" move="west" destination="200" />
  </node>
  <node id="200" name="Asemath Academy, Central Fountain">
    <description>Here in the center, at the very heart of the Academy, a fountain stands.  Carved with cunning and skill, it represents Knowledge pouring out her wisdom to a thirsty world and the academy's founder stooping to drink deeply of her gift.  Coins glitter in the pool, tossed there by superstitious students hoping for luck on an exam.  Walkways lead from here in several directions to other parts of the institution.</description>
    <description>A fountain gurgles cheerfully somewhere nearby and the scent of plants and flowers fills the night air.  You stand in a large open space but you can sense the presence of buildings nearby.</description>
    <position x="10" y="-292" z="0" />
    <arc exit="north" move="north" destination="210" />
    <arc exit="east" move="east" destination="199" />
    <arc exit="south" move="south" destination="214" />
    <arc exit="west" move="west" destination="201" />
  </node>
  <node id="201" name="Asemath Academy, Western Walkway">
    <description>This walkway, shaded by trees, leads back to the kitchen and dining areas for the students and staff.  Believing that a full stomach aids the mind in learning, the founder provided that every student shall be well fed.  The cooks take this dictum to heart and there is always the smell of fresh pies or a good roast drifting on the breeze.  Several students sit nearby, working their way through their lessons and a large pile of fresh lemon cream tarts.</description>
    <description>Trees block even the starlight and you see almost nothing.  Somewhere, someone is baking something wonderful to judge by the scent.</description>
    <position x="0" y="-292" z="0" />
    <arc exit="east" move="east" destination="200" />
    <arc exit="west" move="west" destination="202" />
  </node>
  <node id="202" name="Asemath Academy, Western Hallway">
    <description>This hallway divides the refectories from the kitchens.  There is a bustling of servants as they clear out the remains of the last meal and prepare for the next.  Students everywhere are perpetually hungry it seems. </description>
    <position x="-10" y="-292" z="0" />
    <arc exit="north" move="north" destination="217" />
    <arc exit="east" move="east" destination="201" />
    <arc exit="south" move="south" destination="216" />
    <arc exit="west" move="west" destination="203" />
  </node>
  <node id="203" name="Asemath Academy, Western Hallway">
    <description>The hallway ends here with the school kitchen's pantries and staff dining area.</description>
    <position x="-20" y="-292" z="0" />
    <arc exit="north" move="north" destination="204" />
    <arc exit="east" move="east" destination="202" />
    <arc exit="south" move="south" destination="205" />
  </node>
  <node id="204" name="Asemath Academy, Pantries">
    <description>This room is crowded with barrels and crates and sacks of food of all kinds.  Bins full of flour, ice-boxes with cold meats and perishables and all the other things needed to keep a large assembly of very hungry people fed are in here.</description>
    <position x="-20" y="-302" z="0" />
    <arc exit="south" move="south" destination="203" />
  </node>
  <node id="205" name="Asemath Academy, Staff Refectory">
    <description>This compact and elegant room serves the teaching staff as their dining room.  Small tables seat either two or four and softly padded chairs covered with fine leather are placed at each.  Crystal globes hold candles on each table that shed a soft golden light.  Crisp white cloths cover the tables.  The walls are painted with scenes of legend with themes of education and learning predominating.</description>
    <position x="-20" y="-282" z="0" />
    <arc exit="north" move="north" destination="203" />
  </node>
  <node id="206" name="Asemath Academy, Path of Wisdom">
    <description>The path here goes from the library entrance out to the quadrangle.  Low bushes line the walk and the path is smooth and well-paved.  The doors of the library gleam almost mystically here in the shaded light.</description>
    <position x="30" y="-282" z="0" />
    <arc exit="north" move="north" destination="199" />
    <arc exit="go" move="go polished doors" destination="759" />
  </node>
  <node id="207" name="Asemath Academy, Freshman Walk">
    <description>This path leads to the classroom used by the beginning students and has come by tradition to be called 'Freshman Walk'.  Scrupulously avoided by upperclassmen, it is an item of humor if a senior student has to go this way.  The path itself is laid out in soft green paving stones and the border is lined with benches for outdoor studying.</description>
    <position x="30" y="-312" z="0" />
    <arc exit="north" move="north" destination="208" />
    <arc exit="east" move="east" destination="209" />
    <arc exit="south" move="south" destination="199" />
  </node>
  <node id="208" name="Asemath Academy, Freshman Classroom" note="Freshman Classroom">
    <description>Long tables in neat rows face a lectern made of ebony wood.  Straight-backed chairs with no padding sit closely together at the tables.  The walls are a dusty rose colored marble and high windows allow a pure light in for clarity of seeing.  A large sign hangs on the wall above the lectern.</description>
    <position x="30" y="-322" z="0" />
    <arc exit="out" move="out" destination="207" />
  </node>
  <node id="209" name="Asemath Academy, Freshman Library" note="Freshman Library">
    <description>Books lie piled, sometimes waist high, in irregular stacks along the walls, in corners, and on a few cluttered desks.  Multicolored pillows scattered across the floor provide students with a comfortable seat and add to the tiny library's casual atmosphere.  A shelf along the wall houses dozens of volumes, the works of the Crossing's own talented writers.</description>
    <position x="40" y="-312" z="0" />
    <arc exit="west" move="west" destination="207" />
  </node>
  <node id="210" name="Asemath Academy, Northern Walkway">
    <description>This walkway leads to some of the classrooms of the Academy.  Lined with sweet-scented flowers, it is a pleasant place to be almost any day of the year.</description>
    <description>You stand on some sort of stone walkway.  There are pleasantly scented flowers nearby and in the distance, you can hear a fountain splashing.</description>
    <position x="10" y="-302" z="0" />
    <arc exit="north" move="north" destination="212" />
    <arc exit="northeast" move="northeast" destination="213" />
    <arc exit="south" move="south" destination="200" />
    <arc exit="northwest" move="northwest" destination="211" />
  </node>
  <node id="211" name="Asemath Academy, Auditorium" note="Auditorium">
    <description>This hall, used for lectures and other presentations, can hold the entire student body and faculty of the Academy.  Rows of benches for the students and chairs for the professors are arranged before a low platform for the speakers or guests.  The room is done in polished rosewood walls enlivened with woven hangings in abstract patterns.  Brass and crystal lightglobes hold candles for evening presentations.</description>
    <position x="0" y="-312" z="0" />
    <arc exit="out" move="out" destination="210" />
  </node>
  <node id="212" name="Asemath Academy, Classroom" note="Wisdom" color="#FFFF00">
    <description>This large classroom is used at various times for general instruction and the more specialized classes.  Worktables with chairs sit in rows facing a larger table and lectern.  The walls are painted a cheerful powder blue with cream accents, and the tables are painted a soft grey.  In one corner, a group of anatomical skeletons are grouped for comparison.  The students have nicknamed them The Board of Regents.</description>
    <position x="10" y="-312" z="0" />
    <arc exit="out" move="out" destination="210" />
  </node>
  <node id="213" name="Asemath Academy, Classroom" note="Intelligence" color="#FFFF00">
    <description>This classroom is done in tones of golden yellow and a gentle aqua.  Brightly varnished desks and chairs form neat rows facing the instructor's desk.  A large map of the world is hung from the front wall and a smaller map of some region unknown to you hangs next to it.</description>
    <position x="20" y="-312" z="0" />
    <arc exit="out" move="out" destination="210" />
  </node>
  <node id="214" name="Asemath Academy, Southern Walkway">
    <description>This path leads to the Performance and Arts wing.  Lined with low shrubs, alternating with small statues showing actors and other performers, the path is set with crushed white stone.  Many performances are held here to which the public is welcome and the art gallery is often open to the public for a small fee.</description>
    <description>Dim humanoid shapes seem to rise up on both sides.  You tense for attack but realize with a start that they are but statues arrayed along a walkway.</description>
    <position x="10" y="-282" z="0" />
    <arc exit="north" move="north" destination="200" />
    <arc exit="south" move="south" destination="215" />
  </node>
  <node id="215" name="Asemath Academy, Artists' Hallway">
    <description>This hallway is wide and high-ceilinged.  Often crowded before a performance, it is heavily carpeted, with upholstered benches scattered about.</description>
    <position x="10" y="-272" z="0" />
    <arc exit="north" move="north" destination="214" />
    <arc exit="go" move="go stone door" destination="760" />
    <arc exit="go" move="go wooden door" destination="761" />
  </node>
  <node id="216" name="Asemath Academy, Student Dining Hall">
    <description>This is the dining room for the students.  Plain trestle tables and long benches are racked up against the wall so the staff can scrub the flagstone flooring.  At meal times this place gets very crowded and noisy as the students relax from their studies and fill themselves with the fine food served here.  The walls are an off-white, scrubbed till it gleams and the tables are made from a light-colored wood, bleached almost white as part of their cleaning.</description>
    <position x="-10" y="-282" z="0" />
    <arc exit="out" move="out" destination="202" />
  </node>
  <node id="217" name="Asemath Academy, Kitchens">
    <description>These are the kitchens of the Academy.  Full of hustle and bustle most days, the cooks and scullery maids work long hours keeping the students and staff well-fed as the rules of the Founder dictate.  There is a large fireplace with several roasting spits and a huge cauldron for making soups and stews.  Heavy tables hold trays of fresh fruits and vegetables.  Racks of trays stand ready to hold their loads of breakfasts, lunches and dinners.</description>
    <position x="-10" y="-302" z="0" />
    <arc exit="south" move="south" destination="202" />
  </node>
  <node id="218" name="Ragge's Locksmithing, Salesroom" note="Ragge's Locksmithing|Locksmith" color="#FF0000">
    <description>Through the mingled gloom of shadows and tobacco smoke, you can barely make out the vague outlines of some rather sinister looking figures as they skulk in and out of a room to the east.  On the heavily scarred counter, a single oil burning lamp provides the only pool of light in the room, which radiates only a few feet outward before being swallowed by the shadows.</description>
    <position x="-40" y="-100" z="0" />
    <arc exit="out" move="out" destination="33" />
    <arc exit="go" move="go shadows" destination="762" />
  </node>
  <node id="219" name="Mauriga's Botanicals, Salesroom" note="Mauriga's Botanicals|Herbs" color="#FF0000">
    <description>The clean, pungent scents of herbs, medicinal plants and dried flowers envelop you in the cheerful, soothing salesroom.  Mauriga the Botanist beams at you as she arranges bunches of stalks, leaves, roots and seeds hanging from cedar racks overhead in order to dry or concentrate their potent properties.  She sniffs at a vase filled with fragrant jadice flowers, picks the freshest one, and offers it to you.  You are sure her potions, salves and herbs must be of the highest quality.</description>
    <position x="190" y="-408" z="0" />
    <arc exit="out" move="out" destination="7" />
    <arc exit="climb" move="climb carpeted stair" destination="764" />
  </node>
  <node id="220" name="Falken's Tannery, Workshop" note="Bundles" color="#00FF00">
    <description>The Tannery, presided over by the ever-alert Falken, reeks of dead things, chemicals, and unwashed adventurers who rush in to sell or appraise their latest haul of skins and furs.  On the rough, deobar-paneled walls are mounted stuffed heads of animals, and specimens of birds and fish.  You are struck by the absence of stuffed reptiles, however.  On the counter lies a bundle of assorted furs and hides.</description>
    <position x="-30" y="-468" z="0" />
    <arc exit="west" move="west" destination="221" />
    <arc exit="out" move="out" destination="126" />
    <arc exit="go" move="go sturdy door" destination="570" />
  </node>
  <node id="221" name="Falken's Tannery, Fitting Room">
    <description>Here Falken personally fits you for your new hide, skin, fur or leather accoutrements.  A full-length sheet of metal, polished to a mirror-like finish, on the far wall reflects your image.  In the mirror's reflection, you also notice that the walls of the fitting room are hung with rare furs and exotic pelts, some of creatures you have only heard or dreamt about, but never seen.  On a cluttered worktable in the corner, awls, leather thongs and other tools of the trade are scattered about.</description>
    <position x="-40" y="-468" z="0" />
    <arc exit="east" move="east" destination="220" />
    <arc exit="west" move="west" destination="222" />
  </node>
  <node id="222" name="Falken's Tannery, Supply Room" note="Falken's Tannery|Tannery" color="#FF0000">
    <description>Jars and bottles are neatly arranged on a number of well-made pine shelves affixed to the walls.  Several bins overflow with small tools and crude scrapers.  A bored clerk lounges on a stout chair behind a wide counter.</description>
    <position x="-50" y="-468" z="0" />
    <arc exit="east" move="east" destination="221" />
  </node>
  <node id="223" name="Herilo's Artifacts, Showroom" note="Herilo's Artifacts|Artificer's Shop|Magic" color="#FF0000">
    <description>Herilo the Artificer Exemplar squints over the marble counter muttering over a tattered manuscript.  You feel powerful forces at work all around you in this atelier of arcana.  A low cabinet of satiny shaal wood holds scrolls and parchments, as well as a small carved statue.  On hooks and trays around the room are beads, talismans, amulets, crystals and odd ornaments fashioned from animal parts of assorted and disgusting nature, for use as catalysts in the practice of magical arts and divination.</description>
    <position x="-170" y="-50" z="0" />
    <arc exit="out" move="out" destination="87" />
    <arc exit="go" move="go mother-of-pearl screen" destination="224" />
  </node>
  <node id="224" name="Herilo's Artifacts, Consulting">
    <description>High wooden chests, with row upon row of small, painstakingly labeled drawers, line the walls of this tiny room.  The only light seems to come from the mother-of-pearl screen that serves as the far wall.  A table, with a brass balance scale and small envelopes, vials and cloth pouches, is crammed between the chests.  It is here that Herilo prepares his charms, powders, potions and artifacts, as he holds forth on their various virtues, uses and cautions.</description>
    <position x="-160" y="-50" z="0" />
    <arc exit="go" move="go mother-of-pearl screen" destination="223" />
  </node>
  <node id="225" name="The Crossing, Town Green Northwest" note="TGNW">
    <description>The entrance to Tembeg's Armory is through a hacked-out breach in the thick hedges that border the Green here.  Tembeg, being a humble sort, has laid down a few planks leading into his establishment to serve as a walkway.  Samples of his work are hung on hooks on the exterior of the unpainted wood structure but no sign or other eye-catching gimmicks are noticeable.</description>
    <position x="130" y="-180" z="0" />
    <arc exit="east" move="east" destination="14" />
    <arc exit="southeast" move="southeast" destination="16" />
    <arc exit="south" move="south" destination="23" />
    <arc exit="northwest" move="northwest" destination="24" />
    <arc exit="go" move="go shop" destination="192" />
  </node>
  <node id="226" name="Chizili's Alchemical Goods, Salesroom" note="Chizili's Alchemical Goods|Alchemy" color="#FF0000">
    <description>An almost overwhelming array of scents attacks your nose the moment you enter this place.  While strikingly clean, the room is also filled with jars and barrels and pots and carboys of every size and description.  Bundles of dried herbs hang from racks overhead and glass amphorae are filled with strange animal parts being pickled.  Lore and Science, superstition and practicality meet in this place where alchemists can re-stock almost all their bizarre needs in one place.</description>
    <position x="110" y="-468" z="0" />
    <arc exit="out" move="out" hidden="True" destination="131" />
    <arc exit="go" move="go curtained doorway" destination="227" />
  </node>
  <node id="227" name="Chizili's Alchemical Goods, Workroom">
    <description>This small and cramped room is full of odds and ends not sold in the main store.  A long worktable holds a number of peculiar things and several varieties of philosopher's stone, none of which seem to work or else Chizili would not need to be in business.</description>
    <position x="110" y="-478" z="0" />
    <arc exit="out" move="out" destination="226" />
  </node>
  <node id="228" name="Catrox's Forge, Entryway" note="Catrox's Forge|Repair Metal" color="#00FF00">
    <description>The forge of Catrox the Dwarf is known throughout the lands.  Here mundane metal is transformed into tools, and weapons, damaged armor and shields are made whole again.  This entryway is covered by a tin roof, with no walls, in the hope of letting some air into the smoky, noisy and sweltering compound.  The ringing of metal on metal, the sputtering of cinders and slag, the hissing of steel meeting water, all are audible from within.</description>
    <position x="290" y="40" z="0" />
    <arc exit="out" move="out" hidden="True" destination="159" />
    <arc exit="go" move="go swinging door" destination="229" />
  </node>
  <node id="229" name="Catrox's Forge, Work Room">
    <description>Catrox has frugally combined his hearth and forge with a sales area, which must make perfect sense to him but tends to cause the customers to get a bit overheated.  Fortunately Catrox's affable manner and solid craftsmanship wins them over.  At the glowing forge, gathered around a huge bellows, are his two Dwarven apprentices.  The soot and smoke in the air, and the shimmering heat do not faze them.</description>
    <position x="290" y="50" z="0" />
    <arc exit="west" move="west" destination="230" />
    <arc exit="go" move="go swinging door" destination="228" />
  </node>
  <node id="230" name="Catrox's Forge, Repairs">
    <description>You shoulder your way through the crowd, some awaiting their armor, some wanting to get weapons sharpened or repaired, others with broken or badly battered shields in need of attention.  It is clear that the competent Catrox has all the business he can handle.  An apprentice dashes in with an overflowing armful of weapons, armor and shields, all affixed with tags, and tries to sort them out for the gathered customers.</description>
    <position x="280" y="50" z="0" />
    <arc exit="east" move="east" destination="229" />
  </node>
  <node id="231" name="First Provincial Bank, Lobby" note="Bank">
    <description>Marble tiled floors covered with heavy rugs and walls of polished jasper that gleam a cool blue mark this bank as solid and secure (and expensive).  An official money-changing booth is to one side and a row of tellers windows faces you.  Several guards, armed and armored, stand ready for trouble of any sort.  Near the tellers stands a table of fine wood for those who need to do some writing.</description>
    <position x="170" y="20" z="0" />
    <arc exit="out" move="out" destination="42" />
    <arc exit="go" move="go money-changer's booth" destination="232" />
    <arc exit="go" move="go tellers' windows" destination="233" />
  </node>
  <node id="232" name="Provincial Bank, Money-changer" note="Exchange" color="#00FF00">
    <description>This small booth holds the official money-changing office for the town.  The clerk works behind a thickly barred window and you pass your money in and out via a small drawer that can only be worked by the clerk.  A well-padded chair is placed for your comfort while waiting for your money to be processed.</description>
    <position x="170" y="10" z="0" />
    <arc exit="out" move="out" destination="231" />
  </node>
  <node id="233" name="Provincial Bank, Teller" note="Teller" color="#00FF00">
    <description>A neat row of barred windows faces you along a marble counter.  Several patrons are already busy but there seems to be one window available.  The clerk smiles at you and beckons you over.</description>
    <position x="160" y="20" z="0" />
    <arc exit="out" move="out" destination="231" />
  </node>
  <node id="234" name="The Crossing, Lorethew Street">
    <description>Here figures clad in black flowing robes, trimmed with white piping, wander past in a continuous parade.  The focus of the throng is the impressive structure to the northwest, the town's main seat of learning and scholarship, Academy Asemath.  It encompasses libraries, dormitories, convocations and lectures by the most respected thinkers of Elanthia.  Some of the facilities are open to the public, while others are restricted to faculty, students and alumni.</description>
    <position x="60" y="-242" z="0" />
    <arc exit="north" move="north" destination="19" />
    <arc exit="south" move="south" destination="20" />
    <arc exit="west" move="west" destination="36" />
  </node>
  <node id="235" name="Riverfront Portage, Dock" note="Riverfront Portage" color="#FF00FF">
    <description>The planks of this river dock float directly on the water's surface.  Tied together with thick ropes, they pitch and yaw as though you were already aboard a vessel.  Cold, greenish water sloshes up through the gaps and soaks your feet.  A group of Gor'Tog bargemen, garish tattoos on their bulging arms, scowl at you and laugh derisively.  A very discomfited dwarf stands at the water's edge of the dock, most anxious to return upriver to his mountain fastness by the swiftest means possible.</description>
    <position x="-230" y="290" z="0" />
    <arc exit="north" move="north" destination="66" />
  </node>
  <node id="236" name="The Crossing, Alfren's Ferry" note="Alfren's Ferry|Ferry|First Land Herald|Herald|newspaper|news stand" color="#FF00FF">
    <description>Alfren's Ferry is a privately owned and operated ferry that carries folks over the broad and swift Segoltha River.  The ferry does a brisk business, since the trade route to the Elven forest reaches lies south across the river.  In the face of hostile assaults, the river serves as a formidable barrier.</description>
    <position x="-190" y="260" z="0" />
    <arc exit="go" move="go lemicus square" destination="60" />
    <arc exit="go" move="go ferry" destination="935" />
    <arc exit="go" move="go ferry" destination="936" />
  </node>
  <node id="237" name="Barana's Shipyard, Receiving Yard" note="Rats">
    <description>The receiving yard of Barana's Shipyard and Boat Repair is a cluttered and hectic place.  Huge piles of lumber wait to be formed into the ships this yard is known for.  They vie for space with barrels of tar and kegs of nails.  Piled neatly by the main office, a stack of ruler-straight ash poles, each the thickness of a stout Dwarf, await conversion into the proud masts of some ocean-going lady.</description>
    <position x="50" y="260" z="0" />
    <arc exit="south" move="south" destination="238" />
    <arc exit="go" move="go streetside gate" destination="52" />
    <arc exit="go" move="go shipyard office" destination="454" />
  </node>
  <node id="238" name="Barana's Shipyard, Lumber Storage">
    <description>Raw lumber, cut into various lengths and sorted by type of wood, is stacked in loose piles to cure.  Narrow pathways wind among the stacks.  You can hear small skittering noises from inside the nearest woodpile.  The ground is thick with splinters and curled shavings.</description>
    <position x="50" y="280" z="0" />
    <arc exit="north" move="north" destination="237" />
    <arc exit="southeast" move="southeast" destination="245" />
    <arc exit="southwest" move="southwest" destination="239" />
  </node>
  <node id="239" name="Barana's Shipyard, Lumber Storage">
    <description>The sweet smell of hickory blends with the tang of pine resin as you pass among many stacks of wood in dozens of varieties.  Several long poles of ash stand upright, braced and trussed together, so they will dry ramrod straight, to be used as masts and spars.</description>
    <position x="30" y="300" z="0" />
    <arc exit="northeast" move="northeast" destination="238" />
    <arc exit="southeast" move="southeast" destination="240" />
  </node>
  <node id="240" name="Barana's Shipyard, Lumber Storage">
    <description>Huge piles of wood teeter uneasily all about you.  The smell of sawdust and the fresh green scent of raw wood is everywhere.  A layer of wood shavings, scattered on the ground, shows numerous tiny tracks running in all directions. Nearby, a rickety old dock sags, a shabby barge tied up to it.  At the opposite end of the wood-lot, a large kiln stands alone.</description>
    <position x="50" y="320" z="0" />
    <arc exit="northeast" move="northeast" destination="245" />
    <arc exit="southeast" move="southeast" destination="244" />
    <arc exit="south" move="south" destination="243" />
    <arc exit="southwest" move="southwest" destination="241" />
    <arc exit="northwest" move="northwest" destination="239" />
  </node>
  <node id="241" name="Barana's Shipyard, Lumber Storage">
    <description>Piles of sawdust are scattered everywhere but there are only fragments and splinters of wood here.  Heavy ruts worn into the ground indicate the path taken by loads of wood from the dock to the south.  The smell of the nearby river and its mudflats wars with the clean fresh scent of new-cut wood to make your nose twitch.</description>
    <position x="30" y="340" z="0" />
    <arc exit="northeast" move="northeast" destination="240" />
    <arc exit="east" move="east" destination="243" />
    <arc exit="south" move="south" destination="242" />
  </node>
  <node id="242" name="Barana's Shipyard, Lumber Storage">
    <description>Old stone pilings support a sagging dock.  Like the shoemaker's children who go barefoot, this place, with wood aplenty, has let its delivery pier half rot away.  The wood is sagging and some planks are gone.  The stone footings in the river are cracked and tilted.  One good tidal surge and the entire dock may head for Riverhaven.  An equally squalid barge sits at the dock, looking as if it might collapse from overwork, and the decay of age, at any moment.</description>
    <position x="30" y="360" z="0" />
    <arc exit="north" move="north" destination="241" />
    <arc exit="down" move="down" destination="246" />
  </node>
  <node id="243" name="Barana's Shipyard, Lumber Storage" note="Shipyard">
    <description>Massive lengths of wood, destined to become tillers and rudder-posts, lie in staggered rows.  Each one has been cut and sanded to a fine smoothness that gives each the soft sheen of satin.  A portable block and tackle mounted on wheels stands nearby, as each post easily weighs as much as several Gor'Tog.</description>
    <position x="50" y="340" z="0" />
    <arc exit="north" move="north" destination="240" />
    <arc exit="east" move="east" destination="244" />
    <arc exit="west" move="west" destination="241" />
  </node>
  <node id="244" name="Barana's Shipyard, Lumber Storage">
    <description>Various lengths of green wood are stacked up before the low entrance to a large kiln.  The wood will be lugged inside, to be dried over slow fires for several weeks.  The resulting timbers will be strong and straight, suitable for the ribs and keel of a mighty sea-going warship.</description>
    <position x="70" y="340" z="0" />
    <arc exit="west" move="west" destination="243" />
    <arc exit="northwest" move="northwest" destination="240" />
    <arc exit="go" move="go lumber" destination="441" />
    <arc exit="go" move="go low entrance" destination="765" />
  </node>
  <node id="245" name="Barana's Shipyard, Lumber Storage">
    <description>A heavy, two-man bandsaw leans against a huge pile of rough logs.  They seem to be oak, to judge by the grain.  They are in the process of being split into planks.  Someday, once crafted together by the master wrights here, they will carry freight or passengers to and from exotic lands.  For now, a nest of rats somewhere within is making good use of their sturdy nature, to judge by bits of chewed straw and tiny droppings.</description>
    <position x="70" y="300" z="0" />
    <arc exit="southwest" move="southwest" destination="240" />
    <arc exit="northwest" move="northwest" destination="238" />
  </node>
  <node id="246" name="Barana's Shipyard, Delivery Pier">
    <description>The dock tilts and groans underfoot with each passing wave.  Water-logged timbers sag perilously close to the muddy river.  A barge is tied to the decaying pier, looking equally as worn and run-down.  A dispirited sea-gull sits on the short stump of a mast and surveys the scene, croaking some avian word of disgust for the conditions.</description>
    <position x="30" y="380" z="0" />
    <arc exit="up" move="up" destination="242" />
    <arc exit="go" move="go decrepit barge" destination="247" />
  </node>
  <node id="247" name="Barana's Shipyard, Sail Barge" note="Sail Barge">
    <description>At any moment, you are convinced your feet are going to break right through the rotting bilges of this craft and plunge you into the chill river below.  A few broken oarlocks line the sagging gunwales and a stump mast that once stood much higher holds a dispirited square sail.  Ropes and chains for tying off the cargo lie in untidy heaps all about.  The stink of mildew and wood rot is everywhere.  Even the rats, so common hereabouts, appear too fastidious for this floating junk pile.</description>
    <position x="30" y="400" z="0" />
    <arc exit="go" move="go rickety dock" destination="246" />
  </node>
  <node id="248" name="Willow Walk, Garden Gate" color="#00FFFF">
    <description>Towering flamethorn trees line the path to the west.  Their scarlet leaves contrast with the pale green of small weeping willows that stand on either side of a wrought-iron gate, sentinels keeping the bustle of the city streets away from the quiet peace of the gardens.  The whitewashed stones of the Empaths' Guild rise to the south, with lacy ivy tendrils tracing patterns across their shaded surface.</description>
    <description>Towering flamethorn trees line the path to the west.  Even in the dim light, their dark leaves contrast with the pale green of small weeping willows that stand on either side of a wrought-iron gate, sentinels keeping the bustle of the city streets away from the quiet peace of the gardens.  The whitewashed stones of the Empaths' Guild rise to the south, gleaming faintly through the darkness.</description>
    <position x="230" y="-448" z="0" />
    <arc exit="north" move="north" destination="249" />
    <arc exit="east" move="east" destination="259" />
    <arc exit="go" move="go wrought-iron gate" destination="136" />
  </node>
  <node id="249" name="Willow Walk, Garden Path" color="#00FFFF">
    <description>A high stone wall to the west closes off this area from the traffic, noise, and smells of the city, providing a quiet oasis that protects and encourages many delicate flowers and herbs to flourish.  Small cottages seem to blend into the lush growth, becoming an integral part of a living whole rather than an intrusion upon it.</description>
    <position x="230" y="-458" z="0" />
    <arc exit="north" move="north" destination="250" />
    <arc exit="east" move="east" destination="261" />
    <arc exit="south" move="south" destination="248" />
  </node>
  <node id="250" name="Willow Walk, Garden Path" color="#00FFFF">
    <description>Centered in the path of tiny white quartz pebbles, an ancient sugar maple has been lifesculpted to suggest the figure of a dark unicorn emerging from its trunk.  So subtle was the work of the ancient Elven masters that the image sometimes seems visible only from the corner of the eye, disappearing into bark, branches and leaves when looked at directly.</description>
    <position x="230" y="-468" z="0" />
    <arc exit="east" move="east" destination="251" />
    <arc exit="south" move="south" destination="249" />
  </node>
  <node id="251" name="Willow Walk, Garden Path" color="#00FFFF">
    <description>Overlooking several wooden chaises that have been polished to a smooth shine by years of use, a row of cherry trees lines the space between the white gravel path and the garden wall.  An oddly shaped porcelain bird feeder hangs from the branches of one tree, and the area is usually filled with chirps and birdsong.</description>
    <position x="240" y="-468" z="0" />
    <arc exit="east" move="east" destination="252" />
    <arc exit="southeast" move="southeast" destination="260" />
    <arc exit="west" move="west" destination="250" />
  </node>
  <node id="252" name="Willow Walk, Garden Path" color="#00FFFF">
    <description>A towering linden tree rises high over the garden, a remnant of the forest rising over the city walls to the northeast.  The spreading branches have become a home for squirrels and birds, who have learned that the visitors beneath them frequently leave edible treats behind.</description>
    <position x="250" y="-468" z="0" />
    <arc exit="east" move="east" destination="253" />
    <arc exit="south" move="south" destination="260" />
    <arc exit="west" move="west" destination="251" />
    <arc exit="climb" move="climb linden tree" destination="766" />
    <arc exit="go" move="go gravel path" destination="263" />
  </node>
  <node id="253" name="Willow Walk, Garden Path" color="#00FFFF">
    <description>The high grey limestone garden wall to the north provides protection from storms, sheltering the plantings at its base from harsh winds and rains.  Flowers normally found in more tropical climes flourish in this little enclave, their exotic and tantalizing scents filling the air even when winter holds the rest of the world in its icy fangs.</description>
    <position x="260" y="-468" z="0" />
    <arc exit="east" move="east" destination="254" />
    <arc exit="southwest" move="southwest" destination="260" />
    <arc exit="west" move="west" destination="252" />
  </node>
  <node id="254" name="Willow Walk, Garden Path" color="#00FFFF">
    <description>Visible over the top of the garden wall rises the far higher wall guarding the perimeter of the city.  The southwest-facing stones trap all available sunlight, and this area is normally several degrees warmer than the rest of the garden.  Brilliant flame-colored tiger lilies flourish year-round under the clement conditions, and in front of them, a tangle of lepradria orchids sends up delicate vivid yellow blooms.</description>
    <position x="270" y="-468" z="0" />
    <arc exit="south" move="south" destination="255" />
    <arc exit="west" move="west" destination="253" />
  </node>
  <node id="255" name="Willow Walk, Garden Path" color="#00FFFF">
    <description>A sense of peace, of bustling and burgeoning life, pervades the gardens.  In all seasons, plants and creatures grow and bloom when it is their time to flourish, and die only when it is their time to make way.  With care and attention, the living things inhabiting this area thrive and multiply, with each having a valued and necessary place and purpose.</description>
    <position x="270" y="-458" z="0" />
    <arc exit="north" move="north" destination="254" />
    <arc exit="south" move="south" destination="256" />
    <arc exit="west" move="west" destination="262" />
  </node>
  <node id="256" name="Willow Walk, Garden Path" color="#00FFFF">
    <description>The whitewashed walls of the Empaths' Guild and Hospital rise to the south, with a neat row of taffelberry bushes planted at their base.  To one side, surrounded by a well-tended bed of flowers, is an alabaster figurine of an Elven woman holding a human child.</description>
    <position x="270" y="-448" z="0" />
    <arc exit="north" move="north" destination="255" />
    <arc exit="west" move="west" destination="257" />
  </node>
  <node id="257" name="Willow Walk, Garden Path" color="#00FFFF">
    <description>A tangle of cloudberry bushes has grown so lush and tall that those seeking to walk by must move to the edge of the path, pushing past their sturdy stems.  In season, the berries are gathered and made into both tasty foodstuffs, and a particularly sweet and intoxicating wine.</description>
    <position x="260" y="-448" z="0" />
    <arc exit="east" move="east" destination="256" />
    <arc exit="west" move="west" destination="258" />
    <arc exit="northwest" move="northwest" destination="260" />
  </node>
  <node id="258" name="Willow Walk, Willow Tree" color="#00FFFF">
    <description>The massive weeping willow tree for which the garden is named spreads its trailing branches toward the ground, veiling the area and swaying with every breath of passing breeze to both reveal and conceal.  Occasionally, the leaves part enough to allow a glimpse to the south of the Sorrow Garden in which the Empath Guild Leader stands, and the tall wrought-iron fence running between there and here.</description>
    <position x="250" y="-448" z="0" />
    <arc exit="north" move="north" destination="260" />
    <arc exit="east" move="east" destination="257" />
    <arc exit="west" move="west" destination="259" />
  </node>
  <node id="259" name="Willow Walk, Garden Path" color="#00FFFF">
    <description>Bounded on the south by the whitewashed stones of the Empaths' Guild, the white-graveled path wanders past small, neat cottages surrounded by well-tended plantings.  To the east, an ancient weeping willow tree looms protectively over the area, providing dappled shade and shelter.  A bronze sundial has been placed in the center of the white gravel path.</description>
    <position x="240" y="-448" z="0" />
    <arc exit="northeast" move="northeast" destination="260" />
    <arc exit="east" move="east" destination="258" />
    <arc exit="west" move="west" destination="248" />
  </node>
  <node id="260" name="Willow Walk, Fountain" note="Willow Walk">
    <description>Randomly shaped leaves of verdigrised copper form a tall fountain in the middle of a large pool filled with water lilies, which is surrounded by a low garden of flowers and herbs that shifts in color with the seasons.  Benches shaped of polished copperwood are scattered about, inviting the weary passerby to sit and be soothed by the music of the water trickling its random way down from one copper leaf to another into the surrounding pond.</description>
    <position x="250" y="-458" z="0" />
    <arc exit="north" move="north" destination="252" />
    <arc exit="northeast" move="northeast" destination="253" />
    <arc exit="east" move="east" destination="262" />
    <arc exit="southeast" move="southeast" destination="257" />
    <arc exit="south" move="south" destination="258" />
    <arc exit="southwest" move="southwest" destination="259" />
    <arc exit="west" move="west" destination="261" />
    <arc exit="northwest" move="northwest" destination="251" />
    <arc exit="go" move="go pool" destination="767" />
  </node>
  <node id="261" name="Willow Walk, Garden Path" color="#00FFFF">
    <description>A small grove of silverwillow trees shelters the homes clustered around it, and someone has slung a mesh hammock in between two well-spaced trunks.  An industrious colony of ants works away at building its anthill higher, well away from the homes in the area.</description>
    <position x="240" y="-458" z="0" />
    <arc exit="east" move="east" destination="260" />
    <arc exit="west" move="west" destination="249" />
  </node>
  <node id="262" name="Willow Walk, Garden Path" color="#00FFFF">
    <description>Several of those living in this area have created a small but thriving vegetable garden.  All who pass by here help in caring for the plants, and are free to share in the bounty that it produces as the seasons turn.</description>
    <position x="260" y="-458" z="0" />
    <arc exit="east" move="east" destination="255" />
    <arc exit="west" move="west" destination="260" />
  </node>
  <node id="263" name="Emmiline's Cottage, Path">
    <description>A white gravel path, speckled lightly with grey stone, winds leisurely to the painted steps of a moderately sized cottage.  Wrapped around the front of the cheery yellow building is a pillared porch with a small seating area, and the steps are flanked by flower beds and small shrubs.  Lace curtains shroud the windows at the front of the home, and a third window, etched and frosted, is mounted into the polished wooden door.</description>
    <description>A path of white gravel winds through the darkness to the steps of a moderately sized cottage.  Dark shapes hunch on either side of the steps, outlined dimly by the lantern shining through white lace in one window.  The white porch rails and pillars are muted by the night, the porch furniture crouched like slumbering beasts.  A greyish oval glows from the center of the door.</description>
    <position x="250" y="-478" z="0" />
    <arc exit="go" move="go wooden steps" destination="478" />
    <arc exit="go" move="go gravel path" destination="252" />
  </node>
  <node id="264" name="Crossing, Midton Circle" note="Navesi" color="#00FFFF">
    <description>Neatly clipped hedgerows line both sides of a cobblestone path leading into a quiet neighborhood of modest homes and well-tended gardens.  A profusion of mature oak and maple trees spread throughout the neighborhood, their thickly leaved branches providing a natural screen of privacy for the homes that shelter beneath their boughs.</description>
    <position x="230" y="-180" z="0" />
    <arc exit="north" move="north" destination="265" />
    <arc exit="west" move="west" destination="17" />
  </node>
  <node id="265" name="Crossing, Midton Circle" color="#00FFFF">
    <description>The cobblestone path underfoot splits to the east and west and spreads out to circle around an open plaza to the north.  Tufts of tall grasses intermingled with fragrant herbs line the outer edges of the path, where well-kept homes peep from behind the trunks of several venerable oaks.  The sound of running water provides a pleasant backdrop to the domestic scene, the source nearby but not immediately visible.</description>
    <position x="210" y="-210" z="0" />
    <arc exit="north" move="north" destination="266" />
    <arc exit="east" move="east" destination="270" />
    <arc exit="south" move="south" destination="264" />
    <arc exit="west" move="west" destination="271" />
  </node>
  <node id="266" name="Crossing, Midton Circle" note="Midton Circle">
    <description>An apple tree spreads its branches over the open lawn in the center of the neighborhood.  Stepping stones radiate across the grass in several directions, leading to a cobblestone path that circles past an assortment of thatch-roofed cottages and other homes constructed of brick and hand-worked stone.  A pebble-lined creek of sparkling water cuts across the plaza, flowing east to west in a merry rush of ripples and waves.</description>
    <position x="210" y="-220" z="0" />
    <arc exit="north" move="north" destination="267" />
    <arc exit="northeast" move="northeast" destination="268" />
    <arc exit="east" move="east" destination="269" />
    <arc exit="southeast" move="southeast" destination="270" />
    <arc exit="south" move="south" destination="265" />
    <arc exit="southwest" move="southwest" destination="271" />
    <arc exit="west" move="west" destination="272" />
    <arc exit="northwest" move="northwest" destination="273" />
    <arc exit="climb" move="climb apple tree" destination="768" />
  </node>
  <node id="267" name="Crossing, Midton Circle" color="#00FFFF">
    <description>A windswept fall of leaves creates a soft cushion over the cobblestone path that winds its way around the open plaza to the south.  The curved limbs of oak trees form a leafy canopy over the path, casting sun-dappled shadows across the ground.  To the north the trailing blossoms of a bramble rose soften the edges of the stacked stone wall that separates the neighborhood from the outer street.</description>
    <description>A windswept fall of leaves creates a soft cushion over the cobblestone path that winds its way around the open plaza to the south.  The curved boughs of oak trees form a leafy canopy over the path, casting dark shadows across the ground.  To the north the trailing blossoms of a bramble rose soften the edges of the stacked stone wall that separates the neighborhood from the outer street.</description>
    <position x="210" y="-230" z="0" />
    <arc exit="east" move="east" destination="268" />
    <arc exit="south" move="south" destination="266" />
    <arc exit="west" move="west" destination="273" />
  </node>
  <node id="268" name="Crossing, Midton Circle" color="#00FFFF">
    <description>A stretch of paving bricks trails off towards the homes on the southwest side of the path.  The occasional Rat-Tat-Tat! of a woodpecker drilling the trunk of one of the ubiquitous oaks provides a rhythmic counterpoint to the throaty warbling of a songbird perched high on another nearby tree.</description>
    <description>A stretch of paving bricks trails off towards the homes on the southwest side of the path.  The twittering coo of sleeping birds perched among the ubiquitous oaks provides a melodic counterpoint to the chirping drone of crickets going about their nighttime business.</description>
    <position x="220" y="-230" z="0" />
    <arc exit="south" move="south" destination="269" />
    <arc exit="southwest" move="southwest" destination="266" />
    <arc exit="west" move="west" destination="267" />
  </node>
  <node id="269" name="Crossing, Midton Circle" color="#00FFFF">
    <description>A wide trail of closely-spaced stepping stones provides passage across the shallow creek that ripples across this portion of the cobblestone path.  The tangled roots of several maple trees have been exposed by the water running beneath their branches, causing several to lean across the streambed into a protective arch.  The homes lining either side of the creek are slightly stained around their stone foundations, evidence of seasons when heavy rains caused the little creek to overflow its customary bed.</description>
    <position x="220" y="-220" z="0" />
    <arc exit="north" move="north" destination="268" />
    <arc exit="south" move="south" destination="270" />
    <arc exit="west" move="west" destination="266" />
  </node>
  <node id="270" name="Crossing, Midton Circle" color="#00FFFF">
    <description>Grapes growing in a small front yard garden spread fruit-laden branches over a low-lying wall to the southwest.  A few wayward green tendrils have crept onto the cobblestone path, their vines mingling with the purple stains of grapes crushed underfoot by passing pedestrians.  The faint smell of fermenting fruit drifts out of the little garden, mingling with the scent of woodsmoke rising from the hearth of a nearby home.</description>
    <position x="220" y="-210" z="0" />
    <arc exit="north" move="north" destination="269" />
    <arc exit="west" move="west" destination="265" />
    <arc exit="northwest" move="northwest" destination="266" />
  </node>
  <node id="271" name="Crossing, Midton Circle" color="#00FFFF">
    <description>The sound of bees buzzing about a crack in the trunk of an ancient maple blends with the gentle murmur of running water a little to the north.  Clumps of low-growing herbs line the cobblestone path, their blooms imparting a pleasant scent to the air.</description>
    <description>The sound of chirping crickets and croaking frogs blends with the gentle murmur of running water a little to the north.  Clumps of low-growing herbs line the cobblestone path, their blooms imparting a pleasant scent to the crisp night air.</description>
    <position x="200" y="-210" z="0" />
    <arc exit="north" move="north" destination="272" />
    <arc exit="northeast" move="northeast" destination="266" />
    <arc exit="east" move="east" destination="265" />
  </node>
  <node id="272" name="Crossing, Midton Circle" color="#00FFFF">
    <description>A gradual slope carries the water of a shallow creek over the cobblestone path to an opening beneath the honey-colored stones of a high wall to the west.  Moss creeps from the water's edge towards the surrounding homes, where its stealthy advance is brought to a halt by sturdy growths of berry bushes planted in a long line between the creek and the nearby dwellings.</description>
    <position x="200" y="-220" z="0" />
    <arc exit="north" move="north" destination="273" />
    <arc exit="east" move="east" destination="266" />
    <arc exit="south" move="south" destination="271" />
  </node>
  <node id="273" name="Crossing, Midton Circle" color="#00FFFF">
    <description>Low hedges of lavender form a divider between the cobblestone path and the front gardens of the homes on the northwest side of the plaza.  A crisp, sweet fragrance rises from the silvery foliage, providing a floral counterpoint to the woody scents of oak and maple and the nose-tickling smell of fresh-cut grass.</description>
    <position x="200" y="-230" z="0" />
    <arc exit="east" move="east" destination="267" />
    <arc exit="southeast" move="southeast" destination="266" />
    <arc exit="south" move="south" destination="272" />
  </node>
  <node id="274" name="Fayl'Shar Court, Almhara Arch" note="Fayl'Shar Court|Almhara Arch" color="#00FFFF">
    <description>Curiously quiet despite its metropolitan location, Fayl'Shar Court occupies a prime plot in the city's most affluent quarter.  A broad tree-lined boulevard of imposing estates sweeps southwest toward a quadrangle of grand residences, offering a vista of outstanding architectural beauty.  Fronted by flawless lawns and exquisite specimens of rare Elanthian flora, the boulevard provides a pleasant promenade for residents and a living monument to the skills of the master gardeners they employ.</description>
    <position x="70" y="-508" z="0" />
    <arc exit="southwest" move="southwest" destination="275" />
    <arc exit="go" move="go almhara arch" destination="133" />
  </node>
  <node id="275" name="Fayl'Shar Court, Baluster Boulevard" color="#00FFFF">
    <description>Perfectly uniform regiments of mature copperleaf trees border the expanse of warm sandstone and form a whispering canopy above the boulevard as it parades between mansions and sprawling villas.  Most of the residences on this stretch of the boulevard boast a magnificent portico resplendent with the marble pillars which give the thoroughfare both its name and the imposing dignity of its appearance.</description>
    <position x="60" y="-498" z="0" />
    <arc exit="northeast" move="northeast" destination="274" />
    <arc exit="southwest" move="southwest" destination="276" />
  </node>
  <node id="276" name="Fayl'Shar Court, Baluster Boulevard" color="#00FFFF">
    <description>Several of the homes on Baluster Boulevard possess grand gates and driveways wide enough to accommodate an entire collection of opulent carriages, and even properties on the smaller lots are served by lengthy stretches of immaculate gravel or goldstone.  Those residents who prefer privacy surround their homes with seamless banks of thick privet and poplar, while others offer a clear view of their magnificent abodes through smart black iron railings.</description>
    <position x="50" y="-488" z="0" />
    <arc exit="northeast" move="northeast" destination="275" />
    <arc exit="south" move="south" destination="277" />
  </node>
  <node id="277" name="Fayl'Shar Court, Baluster Boulevard">
    <description>Baluster Boulevard closes sedately in an elegant crescent, the gentle curve of the pavement punctuated by carved marble stepping stones placed to allow visitors a dignified descent from their carriages.  A group of elegant white-painted ironwork benches sits around the base of a large oak tree, providing a pleasant place to sit beneath the spreading boughs and watch the world go by in all its finery.</description>
    <position x="50" y="-478" z="0" />
    <arc exit="north" move="north" destination="276" />
    <arc exit="east" move="east" destination="288" />
    <arc exit="west" move="west" destination="278" />
    <arc exit="go" move="go white building" destination="619" />
  </node>
  <node id="278" name="Fayl'Shar Court, Goldstone Square" note="Anli Arch|Sophieann" color="#00FFFF">
    <description>A smooth walkway of lustrous goldstone encloses the edge of the Square, passing by the elegant facades of the rich homes that occupy this desireable address.  Stunning arrays of seasonal flowers and shrubs in polished acanth tubs decorate the promenade, contributing a colorful and leafy display to the park-like atmosphere of the Square.</description>
    <position x="30" y="-478" z="0" />
    <arc exit="east" move="east" destination="277" />
    <arc exit="south" move="south" destination="279" />
    <arc exit="go" move="go anli arch" destination="289" />
  </node>
  <node id="279" name="Fayl'Shar Court, Goldstone Square" color="#00FFFF">
    <description>The homes on this side of the Square are set back from the promenade, their own private gardens offered as frontage to the quadrangle.  Each lawn is a perfectly uniform deep, lush green, surrounded by elegant trees and eye-catching beds of unusual blooming shrubbery.  Private pathways lead away from the Square toward each front door, curving gently through the gardens.</description>
    <position x="30" y="-468" z="0" />
    <arc exit="north" move="north" destination="278" />
    <arc exit="south" move="south" destination="280" />
  </node>
  <node id="280" name="Fayl'Shar Court, Goldstone Square" color="#00FFFF">
    <description>A bronze statue of two elegant men dressed in lavish robes stands at the side of the promenade, the foot of one of the figures polished to a bright sheen as if frequently rubbed for luck.  Two splendid fir trees flank the statue, the piquant fragrance of their evergreen foliage filling the air with a lush, cool scent reminiscent of trade routes leading through distant forests.</description>
    <position x="30" y="-458" z="0" />
    <arc exit="north" move="north" destination="279" />
    <arc exit="south" move="south" destination="281" />
  </node>
  <node id="281" name="Fayl'Shar Court, Goldstone Square" color="#00FFFF">
    <description>Most of Goldstone Square's lofty edifices boast luxurious leaded windows paned with high quality glass, the better to admire the Arboretum and neighboring buildings.  Those windows overlooking the Square are polished to a radiant shine, causing them to glint warmly in sunshine or lamplight.  From a distance, the sparkling windows might be rich gems embedded into every facade.</description>
    <position x="30" y="-448" z="0" />
    <arc exit="north" move="north" destination="280" />
    <arc exit="south" move="south" destination="282" />
  </node>
  <node id="282" name="Fayl'Shar Court, Goldstone Square" note="Tulvora Arch" color="#00FFFF">
    <description>Two spreading tulvora trees form a living arch leading onto the southwest lawn of the Arboretum.  The sweet and spicy fragrance of their palm-sized leaves fills the air with a heady perfume that drifts gently around this corner of the Square, mingling with the fresh scent of a bank of mimosa climbing elegantly around the porch of a large residence in the corner of the quadrangle.</description>
    <position x="30" y="-438" z="0" />
    <arc exit="north" move="north" destination="281" />
    <arc exit="east" move="east" destination="283" />
    <arc exit="go" move="go tulvora arch" destination="292" />
  </node>
  <node id="283" name="Fayl'Shar Court, Goldstone Square" color="#00FFFF">
    <description>One particularly impressive mansion dominates the southernmost end of the Square, its extensive frontage commanding an unparalleled view of the Arboretum.  The palatial residence is set back from the promenade, putting a dignified distance between itself and the public in the Square.  Its vast plot of land is surrounded by tall poplars which bend gracefully in the scented breeze.</description>
    <position x="50" y="-438" z="0" />
    <arc exit="east" move="east" destination="284" />
    <arc exit="west" move="west" destination="282" />
  </node>
  <node id="284" name="Fayl'Shar Court, Goldstone Square" note="Ban-Minahle Arch" color="#00FFFF">
    <description>Two large homes overlook the Southeast Lawn of the Arboretum, the broad balconies under their upper windows suggesting they were designed with a view of the park and passers-by in mind.  A pair of mature ban-minahle trees provides a slender arched entrance to the Arboretum, their branches forming a silvery canopy overhead.</description>
    <position x="70" y="-438" z="0" />
    <arc exit="north" move="north" destination="285" />
    <arc exit="west" move="west" destination="283" />
    <arc exit="go" move="go ban-minahle arch" destination="291" />
  </node>
  <node id="285" name="Fayl'Shar Court, Goldstone Square" color="#00FFFF">
    <description>Perched atop the ornate iron railings outside a magnificent villa, two carved obsidian ravens stand sentry over the activity in the Square.  Each has glittering sapphire stones for eyes, and the deep sheen of their midnight plumage is carved with an expert hand, such that the symbols are a fitting tribute to the god they represent.</description>
    <position x="70" y="-448" z="0" />
    <arc exit="north" move="north" destination="286" />
    <arc exit="south" move="south" destination="284" />
  </node>
  <node id="286" name="Fayl'Shar Court, Goldstone Square" color="#00FFFF">
    <description>Glossy black railings run along the side of the promenade between the elegant residences and the goldstone pavement, supporting elegant glass streetlamps on ornate poles at regular intervals.  Well-scrubbed steps lead from the walkway up to the front door of each home, where a liveried butler can be expected to greet visitors to the monied families who occupy the Square.</description>
    <position x="70" y="-458" z="0" />
    <arc exit="north" move="north" destination="287" />
    <arc exit="south" move="south" destination="285" />
  </node>
  <node id="287" name="Fayl'Shar Court, Goldstone Square" color="#00FFFF">
    <description>The homes on the east side of the Square present dramatic facades, each frontage carefully designed to demonstrate both the wealth and the good taste of its owner.  Every front door is polished to a deep gleam, each doorknob handled only by white-gloved servants.  Tradesmen never see this side of the homes they serve, since functional entrances and kitchen gardens have their own place out of sight behind the buildings.</description>
    <position x="70" y="-468" z="0" />
    <arc exit="north" move="north" destination="288" />
    <arc exit="south" move="south" destination="286" />
    <arc exit="go" move="go black building" destination="618" />
  </node>
  <node id="288" name="Fayl'Shar Court, Goldstone Square" note="Peregan Arch" color="#00FFFF">
    <description>The splendid architecture of Goldstone Square may be viewed in a pleasurable stroll along the broad walkway which leads around the edge of the quadrangle.  Each home here is a magnificent example of prime Elanthian architecture, using only the finest materials and ornaments transported across the lands by discerning merchants.</description>
    <position x="70" y="-478" z="0" />
    <arc exit="south" move="south" destination="287" />
    <arc exit="west" move="west" destination="277" />
    <arc exit="go" move="go peregan arch" destination="290" />
  </node>
  <node id="289" name="Goldstone Arboretum, Northwest Lawn">
    <description>The Northwest Lawn of the Arboretum demonstrates formal gardening at its best.  Impressive examples of cunning topiary surround the uniform green of the lawn, each perfect privet fashioned into a lifelike representation of animal or bird.  A pair of polished oak benches sits beside the lawn, allowing visitors to inspect the horticultural artworks at leisure.</description>
    <position x="40" y="-468" z="0" />
    <arc exit="east" move="east" destination="290" />
    <arc exit="southeast" move="southeast" destination="293" />
    <arc exit="south" move="south" destination="292" />
    <arc exit="go" move="go anli arch" destination="278" />
  </node>
  <node id="290" name="Goldstone Arboretum, Northeast Lawn">
    <description>Inside the Peregan Arch, the Northeast Lawn of the Arboretum is surrounded by groves of trees arranged in such a way as to give the impression they grow wild, untouched by human hands.  Large nuts falling from the peregans have been allowed to take root around their parents, and banks of carefree wildflowers grow with elegant abandon in this unconstrained corner of the park.</description>
    <position x="60" y="-468" z="0" />
    <arc exit="south" move="south" destination="291" />
    <arc exit="southwest" move="southwest" destination="293" />
    <arc exit="west" move="west" destination="289" />
    <arc exit="go" move="go peregan arch" destination="288" />
  </node>
  <node id="291" name="Goldstone Arboretum, Southeast Lawn">
    <description>An impressive collection of boulders from every corner of Elanthia forms the rock garden, each crack and crevice providing an unlikely new terrain for a selection of flowers and shrubs drawn from remote, mountainous regions.  The air remains cool here at all times of year, as if the Gardeners have employed some clever means to duplicate the freshness of the mountain air.</description>
    <position x="60" y="-448" z="0" />
    <arc exit="north" move="north" destination="290" />
    <arc exit="west" move="west" destination="292" />
    <arc exit="northwest" move="northwest" destination="293" />
    <arc exit="go" move="go ban-minahle arch" destination="284" />
  </node>
  <node id="292" name="Goldstone Arboretum, Southwest Lawn">
    <description>The elegant Water Garden takes pride of place on the Southwest Lawn.  Elegant white wooden bridges traverse tiny brooks which flow gently from some unseen water source into a sparkling pond.  Fat, colorful fish swim lazily in the clear waters, their spectacular hues flaming dramatically with every flash of light on their scales.</description>
    <position x="40" y="-448" z="0" />
    <arc exit="north" move="north" destination="289" />
    <arc exit="northeast" move="northeast" destination="293" />
    <arc exit="east" move="east" destination="291" />
    <arc exit="go" move="go tulvora arch" destination="282" />
  </node>
  <node id="293" name="Goldstone Arboretum, Crystal Fountain" note="Goldstone Arboretum">
    <description>A circular area paved with glittering goldstone surrounds the Crystal Fountain, its countless spouts providing a fascinating display of dancing waters.  Elegant wrought iron benches surround the fountain, allowing visitors to the park a place to sit and relax while observing the aquatic spectacle.  Carefully-tended willows surround the area, hushing all but the restful splash of water on crystal and the occasional snippet of quiet conversation.</description>
    <position x="50" y="-458" z="0" />
    <arc exit="northeast" move="northeast" destination="290" />
    <arc exit="southeast" move="southeast" destination="291" />
    <arc exit="southwest" move="southwest" destination="292" />
    <arc exit="northwest" move="northwest" destination="289" />
  </node>
  <node id="294" name="Jadewater Mansion, Cobbled Path" note="Map1m_Crossing_Jadewater.xml|Jadewater Mansion|Mentors|Tenderfoot">
    <description>Brown cobbles set in herringbone rows lead from the gate to the door of an elegant mansion resting against the town wall.  Borders of waxy green boxwood interspersed with pale yellow roses hem in either side of the path.  Close-cropped grass stretches away from the borders towards the stone fencing that separates the building and the rest of The Crossing.</description>
    <position x="149" y="-557" z="0" />
    <arc exit="east" move="east" />
    <arc exit="west" move="west" />
    <arc exit="go" move="go silverwood door" />
    <arc exit="go" move="go lattice-work gate" destination="135" />
  </node>
  <node id="295" name="Sewer" color="#0000FF">
    <description>A swift draft sweeps in from above, whispering crisply as it whooshes through the slats of an iron grate set into the ceiling.  The air streams across your body, tingling your senses as it slices through the stagnant stench all around you.</description>
    <position x="-210" y="-120" z="0" />
    <arc exit="southwest" move="swim southwest" destination="296" />
    <arc exit="climb" move="climb ladder" destination="118" />
  </node>
  <node id="296" name="Sewer" color="#0000FF">
    <description>The floor slants in from the northeast, converging to a shallow gray-brown pool at the alcove's center.  The water eddies, swirling stagnantly, and sinks slowly into sludge.</description>
    <position x="-220" y="-110" z="0" />
    <arc exit="northeast" move="swim northeast" destination="295" />
    <arc exit="southeast" move="swim southeast" destination="300" />
    <arc exit="south" move="swim south" destination="297" />
  </node>
  <node id="297" name="Sewer" color="#0000FF">
    <description>The packed dirt tunnel leads north and south through soggy piles of refuse.</description>
    <position x="-220" y="-100" z="0" />
    <arc exit="north" move="swim north" destination="296" />
    <arc exit="south" move="swim south" destination="298" />
  </node>
  <node id="298" name="Sewer" color="#0000FF">
    <description>A thick coating of dingy scum clings to a wrought-iron gate fixed into the wall, preventing further passage west.  The low hiss of moving water echoes in the distance.</description>
    <position x="-220" y="-90" z="0" />
    <arc exit="north" move="swim north" destination="297" />
    <arc exit="east" move="swim east" destination="299" />
    <arc exit="go" move="go wrought-iron gate" destination="408" />
  </node>
  <node id="299" name="Sewer" color="#0000FF">
    <description>The packed dirt tunnel leads east and west through soggy piles of refuse.</description>
    <position x="-210" y="-90" z="0" />
    <arc exit="east" move="swim east" destination="621" />
    <arc exit="west" move="swim west" destination="298" />
  </node>
  <node id="300" name="Sewer">
    <description>The tunnel ends, its rounded terminus piled high with pungent mildewed rubbish.</description>
    <position x="-210" y="-100" z="0" />
    <arc exit="northwest" move="northwest" destination="296" />
  </node>
  <node id="301" name="Barbarian Guild, Stamina Training Room" note="Stamina" color="#FFFF00">
    <description>A circular cage set vertically awaits you.  The axis runs across the room and is attached to a set of gears and lead weights.  The entire apparatus seems designed to wear a person out.  A Gor'Tog steps out of the wheel with a heavy sheen of sweat on his massive body.  He glances at you and snorts What makes YOU think you can handle this sort of workout?  You grit your teeth as you realize the test of endurance you will soon undergo.</description>
    <position x="280" y="-338" z="0" />
    <arc exit="out" move="out" destination="335" />
  </node>
  <node id="302" name="Barbarian Guild, Main Hall" note="GL Barbarian|Agonar|RS Barbarian" color="#FF8000">
    <description>The austere granite walls of this immense great hall tower upward to the full height of the building.  A banner hangs from the ceiling far above.  Intricately woven carpets soften the polished mahogany floor and provide traction in the event of a fight.  Even in his home, a Barbarian remains ever-vigilant and ready for battle.  An enormous jeweled steel greatsword glints above a raised podium at the far end of the hall, from which the Barbarian Guild Leader performs his duties.</description>
    <position x="320" y="-378" z="0" />
    <arc exit="east" move="east" destination="303" />
    <arc exit="south" move="south" destination="304" />
    <arc exit="out" move="out" destination="335" />
    <arc exit="climb" move="climb winding stairway" destination="777" />
  </node>
  <node id="303" name="Barbarian Guild, Hall of Fame">
    <description>Framed by four colossal statues that serve to bear the weight of the ceiling, this area houses artifacts of the guild.  Preserved for eternity, pelts of vanquished creatures alternate with beastial trophy heads, framing a large steel sheet embossed with the maker's marks of guild weaponsmiths.  On one wall, portraits of leading guild members hang beneath mounted weapons.  A round padded leather bench provides a place to sit while examining the exhibits.</description>
    <position x="330" y="-378" z="0" />
    <arc exit="west" move="west" destination="302" />
    <arc exit="go" move="go door" destination="305" />
  </node>
  <node id="304" name="Barbarian Guild, Armory">
    <description>Dark and solemn, the confines of this expansive chamber are lit only by several lone wicker torches.  Their dim glow flickers and dances along the lengths of wood and steel, a destructive arsenal of weaponry that has been amassed over many ages into the guild Armory.  Row upon row of devastating armaments crowds the area, evoking images of brutal conflicts and violent battles of the past.</description>
    <position x="320" y="-368" z="0" />
    <arc exit="north" move="north" destination="302" />
  </node>
  <node id="305" name="Barbarian Guild, Stadium Pits" note="Stadium Pits|Pits">
    <description>Dark and dank, the musty pits are set into the ground and offer little room for comfort.  The acrid tang of sweat drifts through the hot and humid air, assaulting the senses.  Narrow shafts of light from the well-lit arena pierce through the steel prongs of a massive portcullis, fracturing the gloom like glowing spears.  Through the foreboding gate, the imposing battle arena takes shape, beckoning all who dare.</description>
    <position x="320" y="-398" z="0" />
    <arc exit="southeast" move="southeast" destination="306" />
    <arc exit="go" move="go door" destination="303" />
    <arc exit="go" move="go portcullis" destination="769" />
    <arc exit="climb" move="climb staircase" destination="770" />
  </node>
  <node id="306" name="Barbarian Guild, Recovery Room">
    <description>The moans of the recently fallen would echo against the stark stone walls of this room.  Several iron cots line the walls, ready to bear the weight of the next bloodied combatant.  An enameled steel cabinet in the corner holds herbs and salves, while on the cold, hard floor, a braided red-brown rug provides a matching accent to the random splatters of dried blood.</description>
    <position x="330" y="-388" z="0" />
    <arc exit="northwest" move="northwest" destination="305" />
  </node>
  <node id="307" name="Empaths' Guild, Courtyard Garden" note="Empaths' Guild|vela'tohr plant|RS Empath">
    <description>Open to the sky, this spot is sheltered from the worst of the weather and elements by a rich cedar arbor.  In the center of the courtyard, a small fountain, filled with the darting forms of tiny fish, babbles to itself.  Several elaborately-carved cedar benches are placed at one edge of the garden, directly across from a cushioned swing hanging from the arbor by wrought iron chains.  A riot of seasonal plants compete for the attention of those who pass here, and a whispering willow tree looms overhead as if creating a protective mantle.</description>
    <position x="300" y="-428" z="0" />
    <arc exit="northeast" move="northeast" destination="308" />
    <arc exit="east" move="east" destination="310" />
    <arc exit="west" move="west" destination="309" />
    <arc exit="down" move="down" destination="426" />
    <arc exit="out" move="out" destination="1" />
  </node>
  <node id="308" name="Empaths' Guild, Guildleader's Office" note="GL Empath|Salvur" color="#FF8000">
    <description>Paneled in dark mahogany, this richly appointed office is redolent with the scent of amber and leather.  A massive mahogany desk dominates the space, its glossy lacquered surface scattered with papers and writing implements.  Behind the desk is an enormous tufted leather wing chair, its rich brown leather complementing the lustrous mahogany.  A decanter of ruby port sits atop a mahogany liquor cabinet, numerous bottles of various colors and sizes visible behind the closed glass doors.  The open-skied courtyard garden of the guild proper is visible to the southwest, through a short stone-lined antechamber.</description>
    <position x="310" y="-438" z="0" />
    <arc exit="southwest" move="southwest" destination="307" />
  </node>
  <node id="309" name="Empaths' Guild, Infirmary" note="Infirmary">
    <description>The walls enclosing this spacious room are adorned with thousands of tiny tiles in various shades of white, pearl, cream, and ivory, reminiscent of sun-touched summer clouds.  Underfoot, the massive white marble tiles are grooved slightly to provide a surer surface for booted and slippered feet.  The large windows are cracked open to let in fresh air, and a massive skylight above contributes to this spot's feeling of healthful openness.  A row of white-draped cots occupies one side of the room, while several large examination tables are arrayed neatly along the opposite wall.</description>
    <position x="290" y="-428" z="0" />
    <arc exit="east" move="east" destination="307" />
    <arc exit="go" move="go mahogany door" destination="966" />
  </node>
  <node id="310" name="Empaths' Guild, Library" note="Empath library">
    <description>A simple folding table and some canvas chairs make the Empaths' Guild library quickly transformable into an emergency room in case the wounded overflow from the hospital's facilities.  In this spartan and spotless chamber, oft-read works on healing, herbs, medicinals, and other empathic arts fill a long shelf against the wall.</description>
    <position x="310" y="-428" z="0" />
    <arc exit="west" move="west" destination="307" />
  </node>
  <node id="311" name="Town Hall, Lobby" note="Town Hall">
    <description>Surrounded by the nerve centers of the administrative arm of the local government, the lobby is an area open to the second floor with skylights in the roof overhead.  Various offices open off the main floor, and a flight of stairs leads upward.  An attempt at a cheerful paint scheme has become worn and faded with time until it is now a dusty grey and anemic beige, dull and unremarkable.</description>
    <position x="210" y="-70" z="0" />
    <arc exit="out" move="out" destination="41" />
    <arc exit="go" move="go registration office" destination="312" />
    <arc exit="go" move="go collection office" destination="314" />
    <arc exit="climb" move="climb stairs" destination="316" />
  </node>
  <node id="312" name="Town Hall, Citizenship Registration Office" note="Citizenship Registration Office" color="#00FF00">
    <description>Several oval paintings line the off-white walls of this office, and a faint scent of old paper fills the air.  A bored clerk sits behind a semi-polished desk occasionally glancing at a book entitled, Rules and Regulations.  A couple of plush wine velvet couches provide seating for those waiting, while a colorful fringed rug entertains a kitten that seems to have found its way through the doors.</description>
    <position x="200" y="-70" z="0" />
    <arc exit="out" move="out" destination="311" />
  </node>
  <node id="313" name="Town Hall, Permits Office" note="Permits Office" color="#00FF00">
    <description>This is a large office with a well-worn counter, several windows each with a Use Next Window, Please sign and apparently one clerk actually working.  Every town in the land seems cursed with lines and waiting and fees.  This office is for the obtaining of permits, licenses and similar matters.</description>
    <position x="220" y="-80" z="0" />
    <arc exit="east" move="east" destination="315" />
    <arc exit="out" move="out" destination="311" />
  </node>
  <node id="314" name="Town Hall, Debtors' Office" note="Debt" color="#00FF00">
    <description>This large room is full of clerks processing citizens' and travellers' payments for the various debts, fines and taxes any town needs to operate.  A well-worn and scuffed counter keeps the public at bay from the harried civil servants and the tile floor is badly in need of waxing from the countless feet that have shuffled in and out during the day.  The room has that somewhat grim and cheerless feel common to most places where people are forced to hand over money.</description>
    <position x="200" y="-80" z="0" />
    <arc exit="out" move="out" destination="311" />
  </node>
  <node id="315" name="Town Hall, Home Exchange Office" note="Home Exchange Office" color="#00FF00">
    <description>Tiny, stuffed with old, dusty furniture, and smelling like yesterday's laundry, this office is anything but a testimony to bureaucratic efficiency.  Large piles of yellowing papers spill from cracked file cabinets and lie scattered upon the floor, fallen from large, ungainly stacks on what little desk space is not taken up by piles of mouldering food.</description>
    <position x="230" y="-80" z="0" />
    <arc exit="west" move="west" destination="313" />
  </node>
  <node id="316" name="Town Hall, Second Floor Landing">
    <description>A large but scraggly palm tree in a pot sits at the top of the stairs in an effort to liven the dull civic atmosphere.  This floor contains the Mayor's Office and meeting rooms.</description>
    <position x="210" y="-56" z="0" />
    <arc exit="go" move="go short hall" destination="317" />
    <arc exit="go" move="go mayor's office" destination="320" />
    <arc exit="go" move="go council doors" destination="321" />
    <arc exit="climb" move="climb stairs" destination="311" />
  </node>
  <node id="317" name="Town Hall, Short Hallway">
    <description>This short hallway leads from the second floor landing to the public Meeting Hall.  Cream-colored walls are hung with portraits of various famous citizens and a series of engravings, copies actually, of the famed Elothean artist Hoa Kiu-Sawa's series called 7 River Views.</description>
    <position x="200" y="-56" z="0" />
    <arc exit="east" move="east" destination="316" />
    <arc exit="west" move="west" destination="318" />
    <arc exit="go" move="go double doors" destination="322" />
  </node>
  <node id="318" name="Town Hall, Short Hallway">
    <description>Austere and formal, this section of the hallway is bare of plants and clutter.  An archway framed by ivy-carved molding opens in the south wall, its size and shape implying that a door should be housed within the arch's confines.  An unsigned portrait of a woman hangs directly across from the archway.</description>
    <position x="190" y="-56" z="0" />
    <arc exit="east" move="east" destination="317" />
    <arc exit="west" move="west" destination="319" />
    <arc exit="go" move="go archway" destination="323" />
    <arc exit="go" move="go arched door" destination="848" />
  </node>
  <node id="319" name="Town Hall, Short Hallway">
    <description>Continuing the austere style of this section of the Town Hall, the space is bare of decoration.  The walls are an unadorned pale yellow and the sole furnishing is an uncomfortable-looking bench opposite the oak door.  A rectangular patch of slightly lighter paint above the bench hints that there was once something more here.</description>
    <position x="180" y="-56" z="0" />
    <arc exit="east" move="east" destination="318" />
    <arc exit="go" move="go oak door" destination="324" />
  </node>
  <node id="320" name="Town Hall, Mayor's Office">
    <description>A large office, reasonably well-appointed with comfortable furnishings.  Portraits of past mayors line the walls and you notice they all smile in the same way, a bit too wide and a bit too sincerely to make you trust them.  An old but well-kept desk dominates the center of the room and a leather couch for guests sits along one wall.  A window looks out over the town.</description>
    <position x="220" y="-56" z="0" />
    <arc exit="out" move="out" destination="316" />
  </node>
  <node id="321" name="Town Hall, Council Chamber">
    <description>This spacious chamber, elegantly decorated, is where the Town Council meets in formal session.  One of the most notable features here is the domed ceiling painted to resemble the night sky spangled with stars and moons.  A very realistic and lovely work of art, this is a surprising find in this stuffy bureaucratic environment.  A large horseshoe-shaped table for the members is the main furniture.</description>
    <position x="210" y="-46" z="0" />
    <arc exit="out" move="out" destination="316" />
  </node>
  <node id="322" name="Town Hall, Public Meeting Room" note="Public Meeting Room">
    <description>The largest room in the Town Hall, this is used for public meetings.  Both official meetings and ones held at the behest of townsfolk will be had here.  Sometimes visiting scholars will lecture for the edification of the populace as well.  Dark oak panelled walls and polished floor are surprisingly clean and in good repair.  Padded benches for the public's use are arrayed about a small stage and podium.</description>
    <position x="200" y="-46" z="0" />
    <arc exit="go" move="go double doors" destination="317" />
  </node>
  <node id="323" name="Town Hall, Lottery Office" note="Lottery Office" color="#00FF00">
    <description>The expansive area is divided by a rosewood counter.  On the public side of the counter, there is a carpet with a threadbare path paced into it and a wilted plant.  Except for the smudged handprints smeared on the paint, the walls match the cream color of the hallway outside.  The work side of the counter is considerably less cheery, with desks centered in small partitioned squares.  Two dusty chandeliers attempting to compensate for the lack of windows cast a dreary glow on patron and civil servant alike.</description>
    <position x="190" y="-46" z="0" />
    <arc exit="go" move="go archway" destination="318" />
  </node>
  <node id="324" name="Town Hall, Genealogy Office" note="Genealogy Office" color="#00FF00">
    <description>Motes of dust drifting gracefully through muted shafts of light intertwine with the smell of old parchment.  A barrier of desks, dull with age and use, straddles the room to create a counter between the public and the clerk whose job it is to maintain the records of the province and handle citizens' requests.  Elegantly illuminated genealogical charts framed in rosewood hang behind the clerk's counter.</description>
    <position x="180" y="-46" z="0" />
    <arc exit="go" move="go oak door" destination="319" />
  </node>
  <node id="325" name="Orem's Bathhouse, Lobby" note="Orem's Bathhouse|Bathhouse" color="#FF0000">
    <description>White marble floors and clean white tile walls without a speck of dirt show the extreme care taken with cleanliness here.  A counter sits to one side where patrons may purchase bathing tickets, towels, soap, scrapers and other necessities for personal hygiene.</description>
    <position x="10" y="-40" z="0" />
    <arc exit="out" move="out" destination="96" />
    <arc exit="go" move="go men's room" destination="326" />
    <arc exit="go" move="go main area" destination="327" />
    <arc exit="go" move="go women's room" destination="897" />
  </node>
  <node id="326" name="Orem's Bathhouse, Men's Locker Room">
    <description>Stone benches, kept spotlessly clean, line the otherwise empty room.  A gentleman attendant keeps an eye on things so nothing improper goes on.  Though a large sign warns he is not responsible for anything left here.  The stone floor is kept warm by piping heated air underneath it, a pleasant luxury on cold days.</description>
    <position x="20" y="-40" z="0" />
    <arc exit="out" move="out" destination="325" />
  </node>
  <node id="327" name="Orem's Bathhouse, Main Bathing Hall">
    <description>This large room is comfortably warm.  Men and women mingle here sociably, most differences in class shed with their clothes.  Bathing pools of different temperatures lead off in several directions and a married couple are undergoing a vigorous massage therapy session from a winsome but apparently strong pair of twin Elven lasses.</description>
    <position x="0" y="-40" z="0" />
    <arc exit="out" move="out" destination="325" />
    <arc exit="go" move="go cold pool" destination="328" />
    <arc exit="go" move="go tepid pool" destination="329" />
    <arc exit="go" move="go hot pool" destination="330" />
    <arc exit="go" move="go hall" destination="331" />
  </node>
  <node id="328" name="Orem's Bathhouse, Cold Water Pool">
    <description>This large pool is filled with very cold water.  It provides a jolt to the system and invigorates your heart and circulation.  Or so you have been told.  Maybe it does, but right now you feel your lips are turning blue and large goosebumps cover your overly exposed skin.  Others nearby seem to be enjoying it, and you wonder which polar region they are from.</description>
    <position x="0" y="-50" z="0" />
    <arc exit="out" move="out" destination="327" />
  </node>
  <node id="329" name="Orem's Bathhouse, Warm Water Pool">
    <description>This pool is filled with water, warm but not overly so.  Comfortable to swim or relax in, it is enjoyed by the elderly and infirm of the town who cannot tolerate the hot and cold baths as well as anyone just wishing a comfortable soak.  You laze about, enjoying the feeling of the dust and dirt washing off you and you feel cleaner and greatly refreshed.</description>
    <position x="-10" y="-40" z="0" />
    <arc exit="out" move="out" destination="327" />
  </node>
  <node id="330" name="Orem's Bathhouse, Hot Water Pool">
    <description>Hot, hot, hot, all you can think of for a moment is how oatmeal must feel when being cooked.  As you get used to the temperature, you begin to relax and mellow out.  The heat loosens stiff joints and relaxes tired muscles.  You lean back against the tiled side of the pool and let the waters hold you as your cares and aches drift away.</description>
    <position x="-10" y="-50" z="0" />
    <arc exit="out" move="out" destination="327" />
  </node>
  <node id="331" name="Orem's Bathhouse, Blue Hallway">
    <description>This hallway is tiled in pleasing shades of blue that resemble flowing water rushing past you.  The hallway leads to the shower-bath room and the steam room and sauna.</description>
    <position x="10" y="-50" z="0" />
    <arc exit="out" move="out" destination="327" />
    <arc exit="go" move="go heavy door" destination="332" />
    <arc exit="go" move="go room" destination="333" />
    <arc exit="go" move="go fros door" destination="334" />
  </node>
  <node id="332" name="Orem's Bathhouse, Sauna">
    <description>This room is fully lined in slatted pine wood, unpainted and sanded smooth.  The temperature is staggering, the air is bone dry and you break into an intense sweat just standing.  Breathing is an interesting exercise as it feels a bit like leaning over a forge fire and inhaling.  After you sweat for a bit, it begins to feel good.  The dirt of city dwelling and of the road is washing itself from your pores and cleansing you.</description>
    <position x="0" y="-60" z="0" />
    <arc exit="go" move="go heavy door" destination="331" />
  </node>
  <node id="333" name="Orem's Bathhouse, Shower Room">
    <description>A row of brass nozzles along one wall gush forth a spray of warm water.  White tile floor and tiled sea-foam green walls echo the sound of the water until it roars like a mighty river.  The water is comfortably warm and bars of a refreshingly scented soap are at hand.  An attendant with a long-handled brush offers to scrub backs for a small fee.  The water feels good on you and you consider an urge to sing out loud and let the resonant chamber make even you sound good.</description>
    <position x="10" y="-60" z="0" />
    <arc exit="out" move="out" destination="331" />
  </node>
  <node id="334" name="Orem's Bathhouse, Steambath">
    <description>Clouds of hot steam obscure your vision and things are hard to see in here.  A tiled floor is somewhat slick with condensed water and you can make out several tiers of stone benches rising up through the mist.  Steam rushes forth from gratings in the walls and floor keeping the rooms hot and moist.  Several figures shrouded by steam and towels lounge on the seats and seem to be relaxed and languid.</description>
    <position x="20" y="-50" z="0" />
    <arc exit="go" move="go fros door" destination="331" />
  </node>
  <node id="335" name="The Crossing, Champions' Square">
    <description>Statues of famous barbarians and arena champions form an arcade leading to the arched steel-clad door of the Barbarians' Guild.  The building itself is high and massive, and the roof rises into a dome towards the east, covering the Champions' Arena.  Through narrow, slit windows you can hear the clang of weapon on shield, and the voice of the trainers barking out instructions to the would-be fighters, gladiators, knights and mercenaries within.</description>
    <position x="300" y="-368" z="0" />
    <arc exit="north" move="script crossingtrainerfix north" destination="1" />
    <arc exit="south" move="script crossingtrainerfix south" destination="6" />
    <arc exit="west" move="script crossingtrainerfix west" destination="8" />
    <arc exit="go" move="script crossingtrainerfix go stone structure" destination="301" />
    <arc exit="go" move="script crossingtrainerfix go barbarian guild" destination="302" />
  </node>
  <node id="336" name="Wilds, Pine Needle Path">
    <description>A well-trod path leads from a small open gateway in the town wall and heads into a grove of whispering pine.  Lean, muscular figures stride by briskly, some carrying longbows, others staves, and all garbed in muted tones of earth and forest.</description>
    <position x="-110" y="-448" z="0" />
    <arc exit="north" move="north" destination="337" />
    <arc exit="go" move="go path" destination="127" />
  </node>
  <node id="337" name="Wilds, Pine Needle Path" note="Rangers|Pine Needle Path">
    <description>Birds dart in and out of the dense shrubbery here, calling to one another in cadences that are almost comprehendible.  Responses seem to emanate from the wooden structure ahead, a timber building with ornately carved double doors, and seemingly without a roof.</description>
    <position x="-110" y="-468" z="0" />
    <arc exit="south" move="south" destination="336" />
    <arc exit="go" move="go double doors" destination="585" />
    <arc exit="go" move="go narrow tunnel" destination="1005" />
  </node>
  <node id="338" name="Exterior Motives" note="Exterior Motives|Mebblec Gumsroe" color="#FF0000">
    <description>This poky shop houses a motley assortment of building supplies.  The quality of the materials stacked against the walls is questionable -- the wood is pocked and scarred with large knots and mildew, and the clay bricks have a crude, uneven appearance.  The presence of Mebblec Gumsroe behind the battered deobar counter indicates him to be the salesman, although his utter lack of interest in the customers seems a concerted effort to appear otherwise.</description>
    <position x="-170" y="-240" z="0" />
    <arc exit="out" move="out" destination="115" />
    <arc exit="go" move="go deobar door" destination="772" />
  </node>
  <node id="339" name="Traders' Guild, Main Hall" note="Trader">
    <description>Not a hint of opulence is betrayed by the modest facade of the Traders' Guild Hall.  Yet opulence indeed there is within, to what some might call an excessive degree.  Displays of prosperity surround you, from the marble columns to the frescoed ceiling depicting the god Kertigen.</description>
    <position x="-130" y="-10" z="0" />
    <arc exit="out" move="out" hidden="True" destination="84" />
    <arc exit="go" move="go carved door" destination="342" />
    <arc exit="climb" move="climb winding stair" destination="352" />
    <arc exit="go" move="go auction foyer" destination="340" />
  </node>
  <node id="340" name="Traders' Guild, Auction Foyer">
    <description>This newly constructed room is devoid of any furnishing.  The breadth of the room is easily large enough to accommodate many potential buyers, while allowing them to converse freely without disrupting any auctions that may be underway.</description>
    <position x="-120" y="0" z="0" />
    <arc exit="out" move="out" destination="339" />
    <arc exit="go" move="go auction hall" destination="343" />
    <arc exit="go" move="go auction hall" destination="343" />
  </node>
  <node id="341" name="Traders' Guild, Mercantile Library">
    <description>Square, leather-covered tables with brightly burning lamps line this domed-covered chamber.  A stained glass skylight at the dome's center filters the light to a soothing softness.  A shelf of books and manuscripts describing theories of trade and economics, cabinets full of scrolls, and racks replete with detailed maps of all known trade routes of Elanthia form the Mercantile Library's collection.</description>
    <position x="-130" y="0" z="0" />
    <arc exit="go" move="go door" destination="339" />
  </node>
  <node id="342" name="Traders' Guild, Banquet Room">
    <description>A large seven-tiered crystal chandelier is poised high above and casts warm light throughout the room.  The dining tables are draped with pure white tablecloths and adorned with centerpieces of freshly cut flowers.  Carved mahogany chairs are pulled to the tables, an elegant place setting before each one.  Plush gold-flecked deep green carpeting borders the inlaid wood floor that bears the image of a gilded yak and looks well-suited to dancing.</description>
    <position x="-120" y="-10" z="0" />
    <arc exit="go" move="go carved door" destination="339" />
  </node>
  <node id="343" name="Traders' Guild, Auction Hall" note="Auction Hall" color="#FF0000">
    <description>This room is in the process of being finished.  The polished mahogany walls and ceiling are angled in such a way that would project the Auctioneer's voice clearly to the rear of the hall as well as to those listening in the front.  In the emptiness of the room one can imagine the many items and Kronars that will one day exchange hands here.</description>
    <position x="-120" y="10" z="0" />
    <arc exit="go" move="go foyer" destination="340" />
    <arc exit="go" move="go side door" destination="360" />
  </node>
  <node id="344" name="Clerics' Guild, Sanctorum" note="Sanctorum|RS Cleric">
    <description>Dark brown walls paneled with a coarse flowing grain mark this circular chamber.  Curved, comfortable-looking sofas are set about some potted acanth trees and you notice a few clerics sitting quietly while reading tomes from the guild's private library.  The guild's record keeper sits behind his desk in the corner next to some bins used for storage.</description>
    <position x="10" y="-558" z="0" />
    <arc exit="east" move="east" destination="346" />
    <arc exit="out" move="out" destination="125" />
    <arc exit="go" move="go study" destination="345" />
    <arc exit="go" move="go arched door" destination="348" />
    <arc exit="go" move="go building" destination="348" />
  </node>
  <node id="345" name="Clerics' Guild, Esuin's Study" note="GL Cleric|Esuin" color="#FF8000">
    <description>The plaster walls of this small chamber are smooth and white as shadowy snow.  A high circular window on the western wall filters light to softly illumine the sparsely furnished room.  Heavy drapes over the door mute the noise from the sanctorum outside, and a dark wooden desk and two primitively-made chairs provide a place for those who have business with Esuin to contemplate his words and advice.</description>
    <description>The plaster walls of this small chamber are smooth and white as shadowy snow.  A high circular window on the western wall provides a glimpse of night sky beyond.  A dark wooden desk and two primitively-made chairs furnish the otherwise bare room.  Heavy drapes over the door mute the sounds from the sanctorum beyond, providing those with business with Esuin a quiet room to contemplate his words and advice.</description>
    <position x="10" y="-568" z="0" />
    <arc exit="out" move="out" destination="344" />
  </node>
  <node id="346" name="Clerics' Guild, Library">
    <description>The shelf that lines the walls of this small private library holds many worn volumes and tomes devoted to scriptures, records, and religious lore.  Several robed clerics recline on cushioned seats near the windows, straining over thick texts in the dim light.</description>
    <position x="20" y="-558" z="0" />
    <arc exit="west" move="west" destination="344" />
    <arc exit="go" move="go doorway" destination="347" />
  </node>
  <node id="347" name="Clerics' Guild, Contemplation Cloister">
    <description>A slanting ceiling of timber and plaster shelters this small room in the interior section of the guild.  The stone floor is covered with thick tapestry rugs to create a cozy niche apart from the rest of the library.  An arching window looks out on an interior courtyard garden, and a heavy round table with numerous chairs sits in the center of the area.  A fireplace warms the room on chilly days, and though not a place of luxury, this is a comfortable site for self-reflection.</description>
    <position x="20" y="-568" z="0" />
    <arc exit="go" move="go doorway" destination="346" />
  </node>
  <node id="348" name="Clerics' Guild, Courtyard">
    <description>Several wooden benches face the center area of this large courtyard.  An older monk is demonstrating the art of the mace to a young acolyte, reminding you of the lesson of diligence from your youth.  At the far end of the courtyard, a sicle tree grove is being tended by a withered old monk with a serene look on his face.  Opposite the grove, a row of large lunat vats lend an unusual scent to the air.</description>
    <position x="0" y="-558" z="0" />
    <arc exit="go" move="go building" destination="349" />
    <arc exit="go" move="go arch" destination="351" />
    <arc exit="go" move="go arched door" destination="344" />
    <arc exit="go" move="go recessed cellar" destination="773" />
  </node>
  <node id="349" name="Clerics' Guild, Gathering Hall" note="Cleric|Gathering Hall">
    <description>Pallets of clean rush-filled linens lie about the perimeter of the long hall, available for the bodies of fallen souls in need of healing or new spirit.  The open beam ceiling admits light from frosted glass gable windows -- a soothing light spills over the dark stone floor.  Although bloodstains upon the floor attest to both death defeated and souls lost, this is a place of gathering to celebrate life and respect death, where clerics come together to work and to exchange information and inspiration.</description>
    <description>Pallets of clean rush-filled linens lie about the perimeter of the long hall, available for the bodies of fallen souls in need of healing or new spirit.  Lamps holding lit beeswax candles hang from the open beam ceiling, shadows spilling over the dark stone floor.  Although bloodstains upon the floor attest to both death defeated and souls lost, this is a place of gathering to celebrate life and respect death, where clerics come together to work and to exchange information and inspiration.</description>
    <position x="0" y="-568" z="0" />
    <arc exit="west" move="west" destination="350" />
    <arc exit="out" move="out" destination="348" />
  </node>
  <node id="350" name="Clerics' Guild, Refectory" note="Refectory">
    <description>Benches and a long, rectangular table, big enough to seat fifty at a time, fill most of the room.  Nearby, a massive stone fireplace bakes the bread and simmers the meals to serve the members of the guild.  A bronze bell hangs from the ceiling with a rope tied off near the fireplace.</description>
    <position x="-10" y="-568" z="0" />
    <arc exit="east" move="east" destination="349" />
  </node>
  <node id="351" name="Clerics' Guild, Chapel" note="Shrine1-04|Chapel" color="#A6A3D9">
    <description>The roof of this small, quaint chapel reaches a steep peak overhead, its beams of blond ash polished to a loving glow.  The floor is simply covered with a thin length of burgundy carpet that leads up to a square altar, located against the western wall.  A shining window of multi-colored stained glass rises up behind the altar, catching the light to transmute it into a cascading glory of rainbowed light that spills over everything in its path like a gift from the heavens.</description>
    <description>The roof of this small, quaint chapel reaches a steep peak above, its end eventually lost in the shadows.  Candles help to lift the veil of darkness, their silent flames sustaining the tranquility that engulfs the snug chamber.  A square altar, located against the western wall, is fitted in front of a window of multi-colored stained glass.  Although its colors are dimmed by night, the images fitted into it are illuminated by the burning tapers, rendering them clear enough for viewing.</description>
    <position x="-10" y="-558" z="0" />
    <arc exit="out" move="out" destination="348" />
  </node>
  <node id="352" name="Traders' Guild, South Hallway">
    <description>The faint outline of your image is blurred on the sheen of the highly polished mahogany walls.  Short red carpeting, maintained in pristine condition, cushions the hardwood floors.  Hand-carved cherrywood cuts horizontally across the paneling halfway from the ceiling in a decorative trim.</description>
    <position x="-140" y="-10" z="0" />
    <arc exit="north" move="north" destination="354" />
    <arc exit="west" move="west" destination="353" />
    <arc exit="down" move="down" destination="339" />
    <arc exit="go" move="go door" destination="364" />
  </node>
  <node id="353" name="Traders' Guild, Gathering Room">
    <description>This room serves as a social hub for the cherished members of the guild to gather and share their adventures and exploits with one another.  Highly polished mahogany walls open up to a large bay window overlooking the River Oxenwaithe.  The guild staff keeps fresh treats available on the serving cart.</description>
    <position x="-160" y="-10" z="0" />
    <arc exit="north" move="north" destination="361" />
    <arc exit="east" move="east" destination="352" />
  </node>
  <node id="354" name="Traders' Guild, Reception">
    <description>The reception desk is stacked with letters, invoices, purchase requests, and a general stream of bizarre visitors, yet still maintains a sense of orderliness, due mainly to the young Prydaen man behind it.  He seems the sort who can keep control of even the most stressful of situations without blinking.</description>
    <position x="-140" y="-20" z="0" />
    <arc exit="south" move="south" destination="352" />
    <arc exit="west" move="west" destination="355" />
    <arc exit="go" move="go guildleader's office" destination="365" />
  </node>
  <node id="355" name="Traders' Guild, West Hallway">
    <description>The faint outline of your image is blurred on the sheen of the highly polished mahogany walls.  Short red carpeting, maintained in pristine condition, cushions the hardwood floors.  Hand-carved cherrywood cuts horizontally across the paneling halfway from the ceiling in a decorative trim.</description>
    <position x="-150" y="-20" z="0" />
    <arc exit="east" move="east" destination="354" />
    <arc exit="down" move="down" destination="356" />
    <arc exit="go" move="go mahogany door" destination="565" />
  </node>
  <node id="356" name="Traders' Guild, Hall of Records" note="Trade Minister">
    <description>This is the nerve center of the Traders' Guild, a long narrow hall plunged into a state of utter chaos.  While harried clerks run to and fro collecting paperwork to assist the guild's members, others are busily calculating the ever-fluctuating exchange rates of nearby towns.  As your senses assimilate the free-flying information, you begin to notice a kind of method to this room's insatiable madness.</description>
    <position x="-150" y="10" z="0" />
    <arc exit="east" move="east" destination="360" />
    <arc exit="west" move="west" destination="357" />
    <arc exit="go" move="go winding stair" destination="355" />
    <arc exit="go" move="go brass-edged doorway" destination="567" />
  </node>
  <node id="357" name="Traders' Guild, Shipment Center" note="Shipment Clerk">
    <description>A sense of chaos mingled with urgency pervades the scene before you.  Harried stock clerks rush about, gathering orders and directing sweating laborers in assembling the contents of endless caravans.  The cavernous room echoes with grunts and banging and voices all shouting conflicting commands, each trying to drown the other out to be heard first.  Impatient traders try to catch the fleeting attention of the clerks and give vent to a varied array of oaths in many tongues when ignored.</description>
    <position x="-160" y="10" z="0" />
    <arc exit="north" move="north" destination="358" />
    <arc exit="east" move="east" destination="356" />
    <arc exit="south" move="south" destination="359" />
    <arc exit="out" move="out" destination="86" />
  </node>
  <node id="358" name="Traders' Guild, Foreign Trade Office" note="Interprovincial Broker">
    <description>This cramped office, a former broom closet, is a close definition of chaos.  An old desk, cluttered with orders awaiting delivery to other provinces, occupies most of this room.  A mottled carpet covers the floor except in the few spots it is burned through from carelessly dropped cigars butts.  What wall space is available is covered with hastily drawn charts tracking the movement of goods between provinces.</description>
    <position x="-160" y="0" z="0" />
    <arc exit="south" move="south" destination="357" />
  </node>
  <node id="359" name="Traders' Guild, The Pit" note="Pit">
    <description>Several short steps lead to a sunken floor, where a handful of frazzled clerks scramble about in an attempt to deal with a constant flow of tiny parchments.  Traders from all parts of the province are gathered here, awaiting word on trade opportunities or seeking information on purchasing goods.</description>
    <position x="-160" y="20" z="0" />
    <arc exit="north" move="north" destination="357" />
    <arc exit="go" move="go storage cellars" destination="563" />
    <arc exit="go" move="go swinging doors" destination="564" />
  </node>
  <node id="360" name="Traders' Guild, Narrow Corridor">
    <description>This seldom used corridor has become a favorite temporary storage room for excessive stock.  Stacks of various wares make quick passage through here difficult.  You notice a thick, steel door just peeking out from behind some wooden pallets.  A Gor'Tog guard leans against it, nonchalant and vigilant at the same time.</description>
    <position x="-140" y="10" z="0" />
    <arc exit="west" move="west" destination="356" />
    <arc exit="go" move="go side door" destination="343" />
    <arc exit="go" move="go steel door" destination="566" />
  </node>
  <node id="361" name="Traders' Guild, Gold Key Club" note="Gold Key Club">
    <description>The smoke in this room is thicker and more cloying than any encountered at Catrox's Forge, but its source is entirely different.  The finest cigars, the most expensive pipeweed, and imported maugwort weed are being puffed on by the prosperous merchants gathered in this inner sanctum of commerce.  Rotund Halflings in fancy vests, grey-bearded Humans in elegant, fur-trimmed jerkins, Elves in shimmering raiment, all are among the land's elite traders who form the heart of the Guild.</description>
    <position x="-160" y="-20" z="0" />
    <arc exit="south" move="south" destination="353" />
    <arc exit="west" move="west" destination="362" />
  </node>
  <node id="362" name="Traders' Guild, Gallery">
    <description>Immaculate partitions with carefully hung works of art are interspersed throughout the stark gallery.  Crushed velvet roping imposes several feet of distance from these treasured pieces.  Hand-carved sconces are discreetly positioned to cast soft ambient light to accentuate each masterpiece.</description>
    <position x="-170" y="-20" z="0" />
    <arc exit="east" move="east" destination="361" />
    <arc exit="go" move="go hallway" destination="363" />
  </node>
  <node id="363" name="Traders' Guild, Hall of Awards" note="RS Trader2">
    <description>The sheen of polished mahogany floors vanishes into dimness at the far end of the long hall.  As your eyes follow the length of the flooring, you notice a series of niches set into the walls.  Nearby, a delicate rope of fine silk stretches across the hallway.</description>
    <position x="-170" y="-30" z="0" />
    <arc exit="out" move="out" destination="362" />
  </node>
  <node id="364" name="Traders' Guild, Conference Room">
    <description>An air of formality can be felt throughout this stately room where conclaves are welcome to gather and collaborate on various guild matters.  The Crossing Traders' Guild crest is proudly displayed on the rear wall and next to it, in the corner, is a superbly stitched flag bearing the emblem of the Traders' Guild.  A large oval mahogany conference table dominates the room and is surrounded on all sides by finely crafted leather wingback chairs.</description>
    <position x="-140" y="0" z="0" />
    <arc exit="go" move="go door" destination="352" />
  </node>
  <node id="365" name="Traders' Guild, Office of the Guildleader" note="GL Trader|Ansprahv|RS Trader1" color="#FF8000">
    <description>Long imported silk drapes extend from ceiling to floor and are gathered on either side of a large area window that spans several paces in length.  From this vantage point the bank, gates and various guilds and merchants can be seen throughout Crossing.  An exceptional hand-spun silk carpet nearly covers the entire floor.  Positioned directly opposite the guildleader's desk is a large map of the province mounted high up on the wall.</description>
    <position x="-140" y="-30" z="0" />
    <arc exit="out" move="out" destination="354" />
  </node>
  <node id="366" name="A Mud Hovel" note="Discipline" color="#FFFF00">
    <description>The tiny windowless hovel feels cramped despite its minimal furnishings.  A coarsely woven blanket is folded neatly in the corner.  One lone shelf on the wall holds the occupant's only food supplies -- a sack of rice, a pitcher of water and a few wilted mustard stalks are arranged next to a single wooden bowl and spoon.  A wizened old Dwarf sits cross-legged in the center of the room.</description>
    <position x="-10" y="-528" z="0" />
    <arc exit="out" move="out" destination="125" />
  </node>
  <node id="367" name="The Academy of Agility" note="Agility" color="#FFFF00">
    <description>Many people stand about, watching others engaged in a bizarre ritual.  Four hold pairs of staves on the ground, the fifth stands in the center.  At a signal, the stave holders begin to sweep them across the floor in a rhythmic pattern of dazzling complexity.  The person in the middle begins to leap and caper, avoiding the impact of the heavy rods as they slap together.  You notice that you are being watched and you realize you must soon put your own agility to the test or leave untrained and unproven.</description>
    <position x="-170" y="-160" z="0" />
    <arc exit="out" move="out" destination="117" />
  </node>
  <node id="368" name="The Skirr'lolasu, Main Deck" note="Map998_Transports.xml|Skirr'lolasu">
    <description>In anticipation of the sudden influx of passengers, makeshift benches have been hastily constructed from kegs, driftwood, and nets stretched tight between boards, then have been cleverly placed so that they are as out of the way as possible.  Some coiled ropes and other rigging lie scattered around, pushed out of the way so no one will trip over them.</description>
    <position x="-50" y="220" z="0" />
    <arc exit="up" move="up" />
    <arc exit="go" move="go door" />
    <arc exit="go" move="go dock" destination="169" />
    <arc exit="climb" move="climb split staircase" />
    <arc exit="go" move="forward" />
    <arc exit="go" move="go narrow door" />
  </node>
  <node id="369" name="Grisgonda's Gems and Jewels" note="Grisgonda's Gems and Jewels|Jewelry" color="#FF0000">
    <description>As you step into the room, your feet sink into plush carpets.  The walls are set with numerous locked display cases.  A well-dressed guard gives you a polite visual once over and steps aside so you may enter.  Gems of every sort and size, from slivers of plain looking crystal to a massive heart-shaped gem the size of a Gor'Tog's fist are displayed.  Grisgonda herself sits at a plain black marble desk with a bright lamp upon it inspecting gems that have been brought in for sale by other adventurers.</description>
    <position x="280" y="-100" z="0" />
    <arc exit="out" move="out" destination="155" />
    <arc exit="go" move="go side room" destination="370" />
  </node>
  <node id="370" name="Grisgonda's, Appraisal Room" note="Gems" color="#00FF00">
    <description>This small room is filled with the subdued glimmer of many gems.  Locked cases of heavy crystal line the walls, each containing a staggering array of precious stones and gems of endless variety, cut, color and shape.  A soft white light falls upon a small table covered with black velvet.  It radiates from a curious lamp set in the center of the table.</description>
    <position x="290" y="-100" z="0" />
    <arc exit="out" move="out" destination="369" />
  </node>
  <node id="371" name="Behind the Amphitheater, Supply Stand">
    <description>Trampled grass and a pair of lingering mud puddles mar the once lush lawn surrounding the amphitheater.  Pickaxes and shovels lean against tables full of supplies, behind which sits a surly-looking Dwarf.</description>
    <position x="210" y="-120" z="0" />
    <arc exit="east" move="east" destination="372" />
    <arc exit="go" move="go path" destination="15" />
  </node>
  <node id="372" name="Behind the Amphitheater, Excavation Site">
    <description>This section of the site has had the top layer of soil removed.  Several shallow trenches have been roped off to preserve the integrity of the dig.</description>
    <position x="220" y="-120" z="0" />
    <arc exit="northeast" move="northeast" destination="373" />
    <arc exit="east" move="east" destination="376" />
    <arc exit="southeast" move="southeast" destination="375" />
    <arc exit="west" move="west" destination="371" />
  </node>
  <node id="373" name="Behind the Amphitheater, Excavation Site">
    <description>This section of the site has had the top layer of soil removed.  Several shallow trenches have been roped off to preserve the integrity of the dig.</description>
    <position x="230" y="-130" z="0" />
    <arc exit="southeast" move="southeast" destination="374" />
    <arc exit="south" move="south" destination="376" />
    <arc exit="southwest" move="southwest" destination="372" />
  </node>
  <node id="374" name="Behind the Amphitheater, Excavation Site">
    <description>This section of the site has had the top layer of soil removed.  Several shallow trenches have been roped off to preserve the integrity of the dig.</description>
    <position x="240" y="-120" z="0" />
    <arc exit="southwest" move="southwest" destination="375" />
    <arc exit="west" move="west" destination="376" />
    <arc exit="northwest" move="northwest" destination="373" />
  </node>
  <node id="375" name="Behind the Amphitheater, Excavation Site">
    <description>This section of the site has had the top layer of soil removed.  Several shallow trenches have been roped off to preserve the integrity of the dig.</description>
    <position x="230" y="-110" z="0" />
    <arc exit="north" move="north" destination="376" />
    <arc exit="northeast" move="northeast" destination="374" />
    <arc exit="northwest" move="northwest" destination="372" />
  </node>
  <node id="376" name="Behind the Amphitheater, Center of the Dig" note="Excavation Site">
    <description>This section of the site has had the top layer of soil removed.  Several shallow trenches have been roped off to preserve the integrity of the dig.</description>
    <position x="230" y="-120" z="0" />
    <arc exit="north" move="north" destination="373" />
    <arc exit="east" move="east" destination="374" />
    <arc exit="south" move="south" destination="375" />
    <arc exit="west" move="west" destination="372" />
  </node>
  <node id="377" name="The Crossing Amphitheater, The Back Lawn">
    <description>A sprawling lawn provides seating for those individuals wishing to listen to the discussion in the amphitheater while not wanting to be limited to the restrictions of the seating area.</description>
    <position x="230" y="-150" z="0" />
    <arc exit="go" move="go archway" destination="378" />
    <arc exit="go" move="go gate" destination="15" />
  </node>
  <node id="378" name="The Crossing Amphitheater, The Seating Area" note="Amphitheater">
    <description>Stone benches and wooden seats form a semi-circle around a stage at the north end of this theater.  Designed so even a whisper can be heard by all, this area is used for everything from town meetings to staged performances.</description>
    <position x="230" y="-160" z="0" />
    <arc exit="go" move="go archway" destination="377" />
  </node>
  <node id="379" name="The Crossing, Mongers' Bazaar" note="Mags|Firewood Peddler" color="#00FF00">
    <description>Some ramshackle stalls and tattered tents comprise the informal flea market known as Mongers' Bazaar.  The springy grass of the Green has been trampled into foot-sucking muck by folk seeking bargains, black-market goods, or unusual trinkets.  Exotic items of rare power and value are sometimes sold here by the itinerant vendors who flock to The Crossing from all corners of Elanthia.</description>
    <position x="240" y="-230" z="0" />
    <arc exit="north" move="script crossingtrainerfix north" destination="10" />
    <arc exit="southeast" move="script crossingtrainerfix southeast" destination="380" />
    <arc exit="go" move="script crossingtrainerfix go collegium" destination="381" />
    <arc exit="go" move="script crossingtrainerfix go path" destination="17" />
  </node>
  <node id="380" name="The Crossing, Mongers' Square" note="Gnomish workman|workman" color="#00FF00">
    <description>Set into the center of the bazaar's main square is a bronzed fountain depicting the fatherly figure of Divyaush, his long chiseled beard covering the top of his robes and his painted azure eyes gazing into the water below.  Children and shoppers stop on their way past, often wetting their hands or their faces in the cool clear water.  To the southwest, brightly covered pennants sail above the sea of canvas that is the Traders' Market tent.</description>
    <position x="280" y="-190" z="0" />
    <arc exit="go" move="go arch" destination="379" />
    <arc exit="go" move="go ramp" destination="384" />
    <arc exit="go" move="go tent" destination="391" />
    <arc exit="go" move="go market plaza" destination="850" />
  </node>
  <node id="381" name="Rartan's Collegium of Inner Juggling and Reflexology" note="Reflex" color="#FFFF00">
    <description>This room is filled with what at first seems to be a group of demented jugglers and acrobats.  Each person is engaged in various feats of balancing and reflexive behavior, such as dancing on a row of knife blades or balancing a lit torch upon one's nose.   There is a sense of intense concentration in the air.  The room is mostly silent, save for the occasional muttered curse or muffled scream as someone fails in their efforts.  Several professors gaze your way, waiting to begin your training.</description>
    <position x="260" y="-230" z="0" />
    <arc exit="out" move="out" destination="379" />
  </node>
  <node id="382" name="The Crossing, Bazaar Walkway">
    <description>Gently sloping above the shops along the eastern side of town, this elegant acanth walkway connects the bustling bazaar to the Hodierna Way, providing merchants and shoppers a quick and guarded way to reach the local bank.  Gilded rails and posts protect the pedestrians from misstepping off the bridge, while adding an element of beauty that complements the rich acanth wood.</description>
    <position x="320" y="-90" z="0" />
    <arc exit="north" move="north" destination="383" />
    <arc exit="go" move="go ramp" destination="160" />
  </node>
  <node id="383" name="The Crossing, Bazaar Walkway">
    <description>Bowing gracefully above the Town Green and the shops along Albreda Boulevard, the raised walkway leaps across the skyline, connecting the bazaar to Hodierna Way.  Merchants heavy with coin bustle quickly towards the bank, while more leisurely shoppers wander across the gilded walkway, pausing sometimes to admire the view of Crossing -- the spherical shape of the Temple majestically rising above the city proper.</description>
    <position x="320" y="-120" z="0" />
    <arc exit="north" move="north" destination="384" />
    <arc exit="south" move="south" destination="382" />
  </node>
  <node id="384" name="The Crossing, Bazaar Walkway">
    <description>Rising over the Mongers' Bazaar and Crossing's Town Green, this acanth walkway is expertly built with sturdy, thick planks and gold rails and posts.  Stretching north to south across the rooftops of the city, the walkway allows an excellent view of the surrounding area.</description>
    <position x="320" y="-160" z="0" />
    <arc exit="south" move="south" destination="383" />
    <arc exit="go" move="go bazaar ramp" destination="852" />
  </node>
  <node id="385" name="Woodruff's Recitation Room" note="Charisma" color="#FFFF00">
    <description>A smattering of applause greets you when you enter the cottage.  Several seated youths are listening attentively to an Elothean lad at a podium who is addressing them.  He speaks animatedly with eloquent gestures, and his audience leans forward in their seats, captivated by his speech.  A Halfling instructress studies him carefully, occasionally jotting down a notation in her book.</description>
    <position x="-90" y="-50" z="0" />
    <arc exit="out" move="out" destination="88" />
  </node>
  <node id="386" name="Crossing, Northeast Gate Battlements" note="NE Battlements">
    <description>Straddling the Northeast Gate, the stone battlements overlook the busiest entrance to the city.  Stone merlons offer some cover to those fighting, and the embrasures appear designed to accommodate either onager or archer.  The cobbled walk only stretches a short distance to the west and south, where it is broken by the tall but unfinished expanse of the town wall.</description>
    <position x="450" y="-528" z="0" />
    <arc exit="south" move="south" destination="387" />
    <arc exit="west" move="west" destination="388" />
    <arc exit="go" move="go stair" destination="145" />
    <arc exit="climb" move="climb embrasure" destination="171" />
  </node>
  <node id="387" name="Crossing, East Wall Battlements">
    <description>Before becoming impassable, the cobbled walkway atop the town wall slopes south toward the Segoltha River.  A small stone guardhouse is set snugly against the outer battlement wall, offering those warriors not on watch a place to shelter from the elements.  Some whimsical soul has set a flowerpot and a doormat proclaiming Go Away! by the guardhouse door.</description>
    <position x="450" y="-458" z="0" />
    <arc exit="north" move="north" destination="386" />
    <arc exit="climb" move="climb break" destination="389" />
    <arc exit="climb" move="climb embrasure" destination="171" />
    <arc exit="go" move="go guardhouse" destination="390" />
  </node>
  <node id="388" name="Crossing, North Wall Battlements">
    <description>Although the defensive wall itself is sturdy and serviceable as it stretches toward the North Gate, the cobbled walkway atop the town wall crumbles to incompletion.  The chisel marks in the wall's stones are still fresh and raw, as if the rocks were set into place just recently.  From here, the most notable landmark is the Paladin guild and the homes near it.  On the inner side of the walkway, a low wooden barrier prevents anyone from stumbling backwards and dropping to the ground below.</description>
    <position x="410" y="-528" z="0" />
    <arc exit="east" move="east" destination="386" />
  </node>
  <node id="389" name="Outside East Wall, Footpath" note="Map8_Crossing_East_Gate.xml">
    <description>Under the shadow of eastern section of The Crossing's stone town wall, this footpath serves as a shortcut.  Barely wide enough for one person, thick brambles and brush allow passage in single file.   A few crevices in the wall make adequate handholds as you squeeze your way along the uneven ground and past thorny branches.</description>
    <position x="470" y="-458" z="0" />
    <arc exit="north" move="north" />
    <arc exit="south" move="south" />
    <arc exit="climb" move="climb wall" destination="387" />
  </node>
  <node id="390" name="Crossing, Battlement Guardhouse" note="Battlement Guardhouse">
    <description>Sparsely furnished, the guardhouse has an odd sense of cheerfulness.  The single cot has a brightly quilted coverlet, and the only lantern in this windowless room sports a garland of dried flowers.  A desk and a stool are shoved up against one of the stone walls, and someone has made a chalk outline on the wall to mimic a figure sitting on the stool.</description>
    <position x="430" y="-458" z="0" />
    <arc exit="out" move="out" destination="387" />
  </node>
  <node id="391" name="Mongers' Bazaar, Traders' Market" note="Mongers' Bazaar|Bazaar|Tent" color="#FF0000">
    <description>The large open tent billows with every caress of wind from above, pressing against the taut lines and wooden frame that hold the structure in place.  Tables line the center of the tent, ready to be set full of wares in hopes of attracting an eager eye and a heavy pouch.</description>
    <position x="364" y="-190" z="0" />
    <arc exit="north" move="north" destination="392" />
    <arc exit="northeast" move="northeast" destination="393" />
    <arc exit="east" move="east" destination="394" />
    <arc exit="go" move="go flap" destination="380" />
  </node>
  <node id="392" name="Mongers' Bazaar, Traders' Market" color="#FF0000">
    <description>The large open tent billows with every caress of wind from above, pressing against the taut lines and wooden frame that hold the structure in place.  Tables line the center of the tent, ready to be set full of wares in hopes of attracting an eager eye and a heavy pouch.</description>
    <position x="364" y="-200" z="0" />
    <arc exit="east" move="east" destination="393" />
    <arc exit="southeast" move="southeast" destination="394" />
    <arc exit="south" move="south" destination="391" />
  </node>
  <node id="393" name="Mongers' Bazaar, Traders' Market" color="#FF0000">
    <description>The large open tent billows with every caress of wind from above, pressing against the taut lines and wooden frame that hold the structure in place.  Tables line the center of the tent, ready to be set full of wares in hopes of attracting an eager eye and a heavy pouch.</description>
    <position x="374" y="-200" z="0" />
    <arc exit="south" move="south" destination="394" />
    <arc exit="southwest" move="southwest" destination="391" />
    <arc exit="west" move="west" destination="392" />
  </node>
  <node id="394" name="Mongers' Bazaar, Traders' Market" color="#FF0000">
    <description>The large open tent billows with every caress of wind from above, pressing against the taut lines and wooden frame that hold the structure in place.  Tables line the center of the tent, ready to be set full of wares in hopes of attracting an eager eye and a heavy pouch.</description>
    <position x="374" y="-190" z="0" />
    <arc exit="north" move="north" destination="393" />
    <arc exit="west" move="west" destination="391" />
    <arc exit="northwest" move="northwest" destination="392" />
  </node>
  <node id="395" name="Crossing, East Gate Battlements">
    <description>From this height, Ulf'Hara Keep is visible in the far distance, and southward flows the churning Segoltha River.  Two of the wall's embrasures contain signal pots, an archaic backup should gwethdesuan or thoughtcast fail.  The cobbled walkway here is directly atop Crossing's eastern gate, overlooking the road into town.</description>
    <description>From this height, the ruins of Ulf'Hara Keep are visible in the far distance, and southward flows the churning Segoltha River.  Two of the wall's embrasures contain signal pots, an archaic backup should gwethdesuan or thoughtcast fail.  The cobbled walkway here is directly atop Crossing's eastern gate, overlooking the road into town.</description>
    <position x="430" y="40" z="0" />
    <arc exit="north" move="north" destination="396" />
    <arc exit="southwest" move="southwest" destination="397" />
    <arc exit="go" move="go stair" destination="162" />
    <arc exit="climb" move="climb embrasure" destination="170" />
  </node>
  <node id="396" name="Crossing, East Wall Battlements">
    <description>The roof of a tall oak tower abuts the town wall's inner side, just feet below the cobbled walkway.  Scattered stones and feathers among the droppings dappling the roof suggest that a favorite pastime of the soldiers stationed here is chucking rocks at roosting birds.  From the crenellated outer wall the view is uninspiring: broken hovels and barren land marking the biting poverty of the Middens.  Northward, the cobbled walkway abruptly ends at the jagged rock of the unfinished wall.</description>
    <position x="430" y="-20" z="0" />
    <arc exit="south" move="south" destination="395" />
    <arc exit="climb" move="climb break" destination="402" />
    <arc exit="climb" move="climb low embrasure" destination="862" />
  </node>
  <node id="397" name="Crossing, South Wall Battlements" note="S Battlements">
    <description>The town wall turns southwest, following where the old earthen wall once stood.  In the distance, the cabins of Riverpine Circle are visible through the embrasures.  The Segoltha River runs near the town wall here, bringing with it the sound of rushing water and sailors' shouts.  Further south, the cobbled walk dissolves into the jagged rock of the unfinished town wall.</description>
    <position x="410" y="60" z="0" />
    <arc exit="northeast" move="northeast" destination="395" />
    <arc exit="go" move="go campaign tent" destination="654" />
  </node>
  <node id="398" name="Crossing, West Gate Battlements" note="W Battlements">
    <description>The fitted stone of the town walls intersects in a curved angle, one side becoming the western wall and the other stretching out against the northern border of the town.  From this vantage point above the West Gate, a warrior can watch for enemies breaking from the cover of the northern forest or sweeping up from the grassy plains to the southwest.</description>
    <position x="-361" y="-408" z="0" />
    <arc exit="east" move="east" destination="400" />
    <arc exit="south" move="south" destination="399" />
    <arc exit="go" move="go stairs" destination="121" />
    <arc exit="climb" move="climb narrow embrasure" destination="172" />
  </node>
  <node id="399" name="Crossing, West Wall Battlements">
    <description>The cobbled pavement atop the walkway crumbles into the unfinished wall as it stretches south toward the Segoltha River.  The view over the wall of lush grassland and farms is a stark contrast to the sight of the slums and squalid buildings that line Kertigen Road.</description>
    <position x="-361" y="-328" z="0" />
    <arc exit="north" move="north" destination="398" />
    <arc exit="climb" move="climb embrasure" destination="403" />
    <arc exit="go" move="go enclosed lean-to" destination="569" />
  </node>
  <node id="400" name="Crossing, North Wall Battlements">
    <description>Rounding the city's northwestern-most point, the cobbled walkway stretches a short distance before being interrupted by an unfinished section of the town wall.  Although a stack of felled trees evidences the logging in progress, the forest is still perilously close to the new defenses and provides would-be attackers protective cover.</description>
    <position x="-341" y="-408" z="0" />
    <arc exit="west" move="west" destination="398" />
    <arc exit="climb" move="climb break" destination="434" />
    <arc exit="climb" move="climb jagged embrasure" destination="864" />
  </node>
  <node id="401" name="The True Bard D'Or, Fine Instruments" note="True Bard D'Or|Music" color="#FF0000">
    <description>This is THE shop for Bards.  Famed far and wide for its range of instruments and things bardic, customers travel far just to shop here and to exchange tunes and to hear the latest gossip from Esmaril the owner.  The walls are covered with dozens of music-making devices and glass counters hold strings and reeds and straps.  Rows of pigeonholes hold sheet music from a hundred cultures and more.  A backroom serves as a performance hall and a place for traveling bards to meet and catch up on goings-on.</description>
    <description>This is THE shop for Bards.  Famed far and wide for its range of instruments and things bardic, customers travel far just to shop here and to exchange tunes and to hear the latest gossip.  The walls are covered with dozens of music-making devices and glass counters hold strings and reeds and straps.  Rows of pigeonholes hold sheet music from a hundred cultures and more.  A backroom serves as a performance hall and a place for traveling bards to meet and catch up on goings-on.</description>
    <position x="80" y="-160" z="0" />
    <arc exit="out" move="out" destination="20" />
    <arc exit="go" move="go backroom" destination="651" />
    <arc exit="go" move="go dark curtain" destination="774" />
  </node>
  <node id="402" name="Outside East Wall, Footpath" note="Map8_Crossing_East_Gate.xml">
    <description>The path winds in and out of a thick patch of stunted bushes near the exterior wall.  It emerges into an area of chipped rock where workers have dumped debris from the town wall's construction.</description>
    <position x="450" y="-20" z="0" />
    <arc exit="north" move="north" />
    <arc exit="south" move="south" />
  </node>
  <node id="403" name="Mycthengelde, Flatlands" note="Map4_Crossing_West_Gate.xml">
    <description>The path winds through a thick grove of trees running north and south along the walls of The Crossing.  The pleasant smell of flowers mixed with damp earth permeates the air, and birds sing cheerfully from their homes in the foliage.  Directly south, the trees part to reveal a grassy expanse stretching towards a low series of hills.</description>
    <position x="-381" y="-308" z="0" />
    <arc exit="southeast" move="southeast" />
    <arc exit="west" move="west" />
    <arc exit="climb" move="climb town wall" destination="399" />
  </node>
  <node id="404" name="Guard House, Office" note="Guard House">
    <description>Like most towns, this one spared every expense when decorating the office of the local guard.  An ancient desk, battered and scarred from years of neglect, is positioned a little too closely behind the counter that divides the room in half.  Scraps of yellowed parchment flutter from a massive cork board just inside the door, where one of the local militia is busily arranging and rearranging the jumble.</description>
    <position x="-170" y="80" z="0" />
    <arc exit="east" move="east" destination="405" />
    <arc exit="out" move="out" destination="85" />
  </node>
  <node id="405" name="Guard House, Hallway">
    <description>At the far end of the hallway, faint light illuminates the iron grating set into a heavily barred door.  Hideous green paint flakes from the walls, settling onto the stone floors and crunching underfoot with each step.</description>
    <position x="-160" y="80" z="0" />
    <arc exit="east" move="east" destination="406" />
    <arc exit="west" move="west" destination="404" />
  </node>
  <node id="406" name="Guard House, Chamber of Justice" note="Judge">
    <description>A chill races through your spine as you stare up at the platform from which justice is so mercilessly dispensed by the local magistrate.  A few low benches stretch out along the western wall, where a heavily-armed guard oversees visitors and defendants alike with a stern, watchful eye.</description>
    <position x="-150" y="80" z="0" />
    <arc exit="west" move="west" destination="405" />
  </node>
  <node id="407" name="Brother Durantine's Shop" note="Brother Durantine's Shop|Durantine" color="#FF0000">
    <description>In this small adjunct to a local order of monks, Brother Durantine offers a variety of holy items and related things.  An assortment of holy symbols may be had as well as blessed waters, candles and ritual vestments for any who wish to serve their own religious needs.  Cool stone walls decorated with scenes from the life of the founder of the order doing various good deeds provide inspiration to all who see them.</description>
    <position x="110" y="0" z="0" />
    <arc exit="out" move="out" destination="38" />
    <arc exit="go" move="go private room" destination="775" />
    <arc exit="go" move="go dimly-lit storeroom" destination="863" />
  </node>
  <node id="408" name="Sewer">
    <description>Phosphorescent mosses line the damp rock, weakly piercing the gloom to reveal a narrow tunnel.  The odor of generations of refuse, stagnant water and things less unidentifiable assail your nose.  The faint sound of water can be heard in the distance. </description>
    <position x="-260" y="-130" z="0" />
    <arc exit="northeast" move="northeast" destination="409" />
    <arc exit="climb" move="climb stairs" destination="298" />
  </node>
  <node id="409" name="Sewer">
    <description>Moisture, seeping through the bedrock, has eroded the walls to the point of danger.  Once hard stone now crumbles at your touch making the footing slick and treacherous.</description>
    <position x="-250" y="-140" z="0" />
    <arc exit="north" move="north" destination="419" />
    <arc exit="northeast" move="northeast" destination="420" />
    <arc exit="southwest" move="southwest" destination="408" />
    <arc exit="go" move="go stone archway" destination="410" />
  </node>
  <node id="410" name="Sewer" color="#0000FF">
    <description>The water, fed by the city's drainage system, deepens into a swiftly moving spate.  Echoed back from the tunnel walls, the water's thrum reverberates in a primal rhythm.</description>
    <position x="-260" y="-150" z="0" />
    <arc exit="go" move="go stone archway" destination="409" />
    <arc exit="northwest" move="swim northwest" destination="411" />
  </node>
  <node id="411" name="Sewer" color="#0000FF">
    <description>Swirling and eddying, the water marches onward at a slightly slower pace.  Thigh high to a Gor'tog, the impenetrable blackness of the surface leaves you hoping that no aquatic creatures have chosen this as their home.</description>
    <position x="-270" y="-160" z="0" />
    <arc exit="southeast" move="swim southeast" destination="410" />
    <arc exit="northwest" move="swim northwest" destination="412" />
  </node>
  <node id="412" name="Sewer">
    <description>A layer of sludge coats the floor where the water, finally receding to a trickle, has deposited its burden of mud and sewage across the rock.</description>
    <position x="-280" y="-170" z="0" />
    <arc exit="northeast" move="northeast" destination="414" />
    <arc exit="southeast" move="southeast" destination="411" />
    <arc exit="northwest" move="northwest" destination="413" />
  </node>
  <node id="413" name="Sewer">
    <description>Aged oak timbers rise up to block off any further travel up this tunnel.   Fastened with thick iron spikes driven into the living rock, the heavy wood bears mute witness that this is no temporary blockade, though air rustling through some slight gaps indicates that there is space on the other side.</description>
    <position x="-290" y="-180" z="0" />
    <arc exit="southeast" move="southeast" destination="412" />
  </node>
  <node id="414" name="Sewer">
    <description>Bricked and mortared, the walls arch overhead to meet the stone of the ceiling while, underfoot, a channel carved into the floor carries run-off water into the darkness.</description>
    <position x="-270" y="-180" z="0" />
    <arc exit="east" move="east" destination="415" />
    <arc exit="southwest" move="southwest" destination="412" />
  </node>
  <node id="415" name="Sewer">
    <description>Piles of rusty scaffolding, illuminated from wall lanterns driven into the rock, fling angular shadows across heaps of unused stone.  Several cots molder in various corners and a disintegrating wheelbarrow stands frozen with its last load of debris.  Apparently a storage area or a worker's bunkhouse while the sewers were being constructed, the puffs of dust kicked up at every footfall prove it to be long abandoned.</description>
    <position x="-260" y="-180" z="0" />
    <arc exit="east" move="east" destination="416" />
    <arc exit="southeast" move="southeast" destination="418" />
    <arc exit="west" move="west" destination="414" />
  </node>
  <node id="416" name="Sewer">
    <description>Enveloping darkness has made this section of the sewers a hazardous obstacle course with loose bricks and slick rock waiting to catch unwary feet and elbows.  A sharp sound like an iron nail scratching across an articulated greave echoes faintly through the blackness.</description>
    <position x="-250" y="-180" z="0" />
    <arc exit="east" move="east" destination="417" />
    <arc exit="south" move="south" destination="418" />
    <arc exit="west" move="west" destination="415" />
  </node>
  <node id="417" name="Sewer">
    <description>The sewer suddenly empties out into a natural cavern substantially larger than the surrounding tunnels.  Phosphorous mosses and lichens, thriving in the damp air, add their light to more of the wall lanterns which, in turn, illuminate a huge mound of rubble growing from the floor of the cavern.  Several stories high, enterprising engineers apparently solved the problem of removing the detritus of tunnel excavation by simply dumping it here and forming the mound.</description>
    <position x="-240" y="-180" z="0" />
    <arc exit="southwest" move="southwest" destination="418" />
    <arc exit="west" move="west" destination="416" />
    <arc exit="climb" move="climb rubble mound" destination="888" />
  </node>
  <node id="418" name="Sewer">
    <description>Raggedly oval in shape, a pool of darkness dwarfs the drainage trench that leads to its very edge.  A roaring mist is carried aloft by the strong updraft swirling through the area revealing the nature of the darkness a vast oubliette that plunges towards the core of Elanthia carrying the wastewater of the city with it.</description>
    <position x="-250" y="-170" z="0" />
    <arc exit="north" move="north" destination="416" />
    <arc exit="northeast" move="northeast" destination="417" />
    <arc exit="northwest" move="northwest" destination="415" />
  </node>
  <node id="419" name="Sewer">
    <description>The walls, perhaps due to some natural fault in the rock, angle inward somewhat here, and the weight of the city above presses down upon you.</description>
    <position x="-250" y="-150" z="0" />
    <arc exit="east" move="east" destination="420" />
    <arc exit="south" move="south" destination="409" />
  </node>
  <node id="420" name="Sewer">
    <description>Water running off from other parts of the sewer has puddled here in a slight depression in the floor.  The corpse of a skinned rodent bobs slowly in the lightly swirling current, playing water tag with the decomposing remains of a wooden crate.</description>
    <position x="-240" y="-150" z="0" />
    <arc exit="east" move="east" destination="421" />
    <arc exit="southwest" move="southwest" destination="409" />
    <arc exit="west" move="west" destination="419" />
  </node>
  <node id="421" name="Sewer">
    <description>Sharp scrittering emanates from a tangle of debris that has piled against a turning in the tunnel.  Dotted with slimy patches of moss, an unnatural shifting of the mound indicates it has become a den for...something.</description>
    <position x="-230" y="-150" z="0" />
    <arc exit="south" move="south" destination="422" />
    <arc exit="west" move="west" destination="420" />
  </node>
  <node id="422" name="Sewer">
    <description>Piles of decomposing refuse line the walls and the stink of decay is almost intoxifying in its presence.</description>
    <position x="-230" y="-140" z="0" />
    <arc exit="north" move="north" destination="421" />
    <arc exit="southeast" move="southeast" destination="425" />
    <arc exit="southwest" move="southwest" destination="423" />
  </node>
  <node id="423" name="Sewer">
    <description>A jagged fissure scars the floor here.  Too narrow for even a Halfling to squeeze through yet wide enough for the air currents to send small dust devils dancing about, the edges of the fissure are worn smooth.</description>
    <position x="-240" y="-130" z="0" />
    <arc exit="northeast" move="northeast" destination="422" />
    <arc exit="east" move="east" destination="424" />
  </node>
  <node id="424" name="Sewer">
    <description>Long parallel lines score the packed earth floor from one end to the other.  Roughly an inch in depth, it appears as if something heavy has been recently dragged through the tunnel.</description>
    <position x="-230" y="-130" z="0" />
    <arc exit="east" move="east" destination="425" />
    <arc exit="west" move="west" destination="423" />
  </node>
  <node id="425" name="Sewer">
    <description>This section of the tunnel is unfinished by brick or mortar.  The stone is roughly hewn and marked by pick and shovel gouges.</description>
    <position x="-220" y="-130" z="0" />
    <arc exit="west" move="west" destination="424" />
    <arc exit="northwest" move="northwest" destination="422" />
  </node>
  <node id="426" name="The Healerie, Entrance Hall">
    <description>Moss and lichen thickly blanket the walls and floor of the damp underground hall.  At one end, long spiraling oaken stairs hug the side of the shaft that leads up to the main room of the distant Empath Guild.  At the other end, two swinging doors lead into the Healerie proper.  Near the middle, a walnut ramp goes up towards the Hospital Triage while an arch leads into other areas.  Shielded lanterns light the area.</description>
    <description>Moss and lichen thickly blanket the walls and floor of the damp underground hall.  At one end, long spiraling oaken stairs hug the side of the shaft that leads up to the main room of the distant Empath Guild.  Near the middle, a walnut ramp goes up towards the Hospital Triage while an arch leads into other areas.  Light reflected from aboveground through an intricate mirror system floods the area.</description>
    <position x="300" y="-448" z="0" />
    <arc exit="go" move="go swinging doors" destination="427" />
    <arc exit="go" move="go walnut ramp" destination="432" />
    <arc exit="go" move="go arch" destination="431" />
    <arc exit="go" move="go stone portal" destination="1007" />
    <arc exit="go" move="go stairs" destination="307" />
  </node>
  <node id="427" name="The Healerie, The Blue Area" note="Blue Area|triage">
    <description>Thick blue moss and lichen covering the floor absorb the water that falls from the ceiling of this enormous chamber as well as the blood from the many wounded who come here.  A vast forest of stone stalactites stretches from the ceiling above, the largest as big as great trees and bearing strange crystal orbs like fruit.  The orbs shed a strong bluish light that provides adequate illumination for healing.  A silver plaque has been set into the floor near the middle of this area.</description>
    <position x="290" y="-458" z="0" />
    <arc exit="north" move="north" destination="430" />
    <arc exit="northeast" move="northeast" destination="429" />
    <arc exit="east" move="east" destination="428" />
    <arc exit="go" move="go swinging doors" destination="426" />
  </node>
  <node id="428" name="The Healerie, The White Area" note="Healerie|White Area">
    <description>Thick white moss and lichen covering the floor absorb the water that falls from the ceiling of this enormous chamber as well as the blood from the many wounded who come here.  A vast forest of stone stalactites stretches from the ceiling above, the largest as big as great trees and bearing strange crystal orbs like fruit.  The orbs shed a strong white light that provides adequate illumination for healing.  Stalagmites block passage beyond the light where the moss and lichen fail.</description>
    <position x="300" y="-458" z="0" />
    <arc exit="north" move="north" destination="429" />
    <arc exit="west" move="west" destination="427" />
    <arc exit="northwest" move="northwest" destination="430" />
  </node>
  <node id="429" name="The Healerie, The Yellow Area" note="Yellow Area">
    <description>Thick yellow moss and lichen covering the floor absorb the water that falls from the ceiling of this enormous chamber as well as the blood from the many wounded who come here.  A vast forest of stone stalactites stretches from the ceiling above, the largest as big as great trees and bearing strange crystal orbs like fruit.  The orbs shed a strong yellow light that provides adequate illumination for healing.  Stalagmites block passage beyond the light where the moss and lichen fail.</description>
    <position x="300" y="-468" z="0" />
    <arc exit="south" move="south" destination="428" />
    <arc exit="southwest" move="southwest" destination="427" />
    <arc exit="west" move="west" destination="430" />
  </node>
  <node id="430" name="The Healerie, The Viewing Area" note="Viewing Area">
    <description>Thick white moss and lichen covering the floor absorb the water that falls from the ceiling of this enormous chamber as well as the blood from the many wounded who come here.  A vast forest of stone stalactites stretches from the ceiling above, the largest as big as great trees and bearing strange crystal orbs like fruit.  The orbs shed a strong white light that provides adequate illumination for healing.  Stalagmites block passage beyond the light where the moss and lichen fail.</description>
    <position x="290" y="-468" z="0" />
    <arc exit="east" move="east" destination="429" />
    <arc exit="southeast" move="southeast" destination="428" />
    <arc exit="south" move="south" destination="427" />
  </node>
  <node id="431" name="The Healerie, Dim Corridor">
    <description>The dim light coming through the arch at the end of the corridor delineates the long shadows of those moving about considerably more than it does the features of the people themselves.  The small amount of additional light coming through the doorway halfway down the corridor further accentuates and twists the shadows of those present, playing them across the floor, walls, and ceiling of smoothly polished black stone.  Cool moist air flows over the stone leaving it slick to the touch.</description>
    <position x="310" y="-448" z="0" />
    <arc exit="go" move="go arch" destination="426" />
    <arc exit="go" move="go stone door" destination="847" />
    <arc exit="east" move="east" destination="1018" />
  </node>
  <node id="432" name="Martyr Saedelthorp, Triage" note="Healer|Kaiva|Martyr Saedelthorp|Saedelthorp" color="#00BF80">
    <description>At first glance it is difficult to tell you are in the renowned healing arts' hospital of Martyr Saedelthorp.  It looks more like a battlefield healer's station.  Blood, gore, sweat and mud streak the tiled floor and the wooden benches.  Groaning adventurers in various states of shock and consciousness await tending by concerned but fatigued healers.  You gingerly step over a patient with a severed limb sprawled out on a canvas stretcher.</description>
    <position x="280" y="-428" z="0" />
    <arc exit="go" move="go wide arch" destination="1" />
    <arc exit="go" move="go walnut ramp" destination="426" />
  </node>
  <node id="433" name="Cormyn's House of Heirlooms" note="Cormyn's House of Heirlooms|Pawn" color="#FF0000">
    <description>The walls here of an odd white adobe, smeared with stucco that has been inlaid with broken bits of colored glass, mirror fragments and round disks of polished metal resembling coins.  This is obviously Cormyn's idea of elegance.  The merchandise that others have pawned, or that is awaiting redemption, seems to be mostly flotsam and jetsam.  Noting the huge ruby on Cormyn's finger, and the stout gold chain about his neck, it dawns on you that there may be more here than meets the eye.</description>
    <position x="-90" y="-240" z="0" />
    <arc exit="out" move="out" destination="93" />
    <arc exit="go" move="go lunat door" destination="1016" />
  </node>
  <node id="434" name="Northwall Trail, Wooded Grove" note="Map4_Crossing_West_Gate.xml">
    <description>A rhythmic chittering amid feathery patches of fern welcomes you to this grove.  Tall wyndwood and oak trees, thickly cloaked in ivy, arch over a thin trail that bends around the town wall to the northeast.  Like a puppeteer, the leafy canopy directs a dance of sunlight and shadow across the ground.</description>
    <description>The rhythmic song of cicadas hums through the grove, welcoming the passerby's footfalls.  The silvery eyes of night peer down through the rustling canopy overhead, illuminating the bare soil of a thin trail that bends around the town wall to the northeast.</description>
    <position x="-341" y="-428" z="0" />
    <arc exit="northeast" move="northeast" />
    <arc exit="south" move="south" />
    <arc exit="climb" move="climb town wall" destination="400" />
  </node>
  <node id="435" name="Marcipur's Stitchery, Workshop" note="Marcipur's Stitchery|Clothing" color="#FF0000">
    <description>Only one word could possibly describe the atmosphere of this charming establishment: chaos.  Fabric in every hue and pattern imaginable spills onto the floor from countertops and tables, making every step an exercise in coordination.  The diminutive proprietress happily scampers about from one customer to the next, pinning up a hem here, deftly stitching up a bodice there, and hopping up onto a crate to adjust a neckline over in the corner.</description>
    <position x="290" y="-120" z="0" />
    <arc exit="out" move="out" destination="152" />
  </node>
  <node id="436" name="Talmai's Cobblery, Salesroom" note="Talmai's Cobblery|Shoes" color="#FF0000">
    <description>Wiping his hands on his leather apron, Talmai emerges from the stockroom at the first sound of an approaching customer.  With one ham-sized, callused hand, he points first to the catalog lying on the low counter, and then to a makeshift wooden rack with sample shoes, boots, slippers and sandals.  With the other hand, he brandishes a measuring stick, almost like a club.  You smile and examine his wares.</description>
    <position x="390" y="-408" z="0" />
    <arc exit="out" move="out" destination="148" />
  </node>
  <node id="437" name="Old Warehouse, Storeroom">
    <description>The interior of this large warehouse is only partially filled with goods.  The squeak of rats scuttling in the shadows echoes eerily from the high ceiling.  Cracks and knotholes in the outer walls allow a dim grey light to penetrate the utter darkness.</description>
    <position x="110" y="90" z="0" />
    <arc exit="south" move="south" destination="438" />
    <arc exit="out" move="out" destination="48" />
  </node>
  <node id="438" name="Old Warehouse, River Side Storage">
    <description>This end of the warehouse projects out over the river on old and shaky pilings.  Waves echo through wide cracks in the flooring where dark waters thrash the muddy riverbank below.  There is a smell of must and rot, of things long away from clean air and warm sunshine.  Odd bits of mud here and there suggest that something has been dragged along the decking.</description>
    <position x="110" y="100" z="0" />
    <arc exit="north" move="north" destination="437" />
    <arc exit="go" move="go small trapdoor" destination="636" />
  </node>
  <node id="439" name="A Damp Cavern" note="Damp Cavern">
    <description>The fetid air in this portion of the dark cavern is heavy with a green mist of fungi spores.  They sting and itch wherever they touch unprotected skin, and leave a burning sensation in mouth and throat.</description>
    <position x="-370" y="0" z="0" />
    <arc exit="west" move="west" destination="572" />
    <arc exit="go" move="go splintered door" destination="102" />
  </node>
  <node id="440" name="Temple Grounds, Entry Gates" note="Map2a_Temple.xml|Temple">
    <description>The immense outer walls of the temple meet here, a thick lacquered mahogany gate acting as their mediator.  The hardwood entrance has been banded with sturdy bars of steel to ensure its stamina in the most dire of times.  A cobblestone path leads to the north, winding off into the various parts of the temple grounds.</description>
    <position x="200" y="90" z="0" />
    <arc exit="north" move="north" />
    <arc exit="go" move="go mahogany gate" destination="440" />
    <arc exit="go" move="go mahogany building" destination="440" />
  </node>
  <node id="441" name="Barana's Shipyard, Lumber Stacks">
    <description>A large kiln sits to the north, where stacks of lumber are slowly dried.  Here, close-set piles of green lumber air-dry before being taken to the kiln or used directly.  The huge piles of wood are stacked loosely, to allow air to circulate.  The local rats find these inner highways very much to their liking.</description>
    <position x="90" y="340" z="0" />
    <arc exit="south" move="south" destination="442" />
    <arc exit="go" move="go large kiln" destination="244" />
  </node>
  <node id="442" name="Barana's Shipyard, Lumber Stacks">
    <description>Several immense piles of rough-cut green lumber have been stacked in loose heaps to dry before further cutting and planing.  The air is rich with resin from the woodpiles.  Saw-dust and splinters form untidy heaps almost everywhere between the stacked boards.</description>
    <position x="90" y="370" z="0" />
    <arc exit="north" move="north" destination="441" />
    <arc exit="southeast" move="southeast" destination="449" />
    <arc exit="southwest" move="southwest" destination="443" />
  </node>
  <node id="443" name="Barana's Shipyard, Lumber Stacks">
    <description>A space has been cleared among the piles of lumber to allow planks and stringers to be hauled to the saw nearby.  The air is redolent with the smell of fresh-cut wood and a haze of saw-dust drifts in the air.  Several grunting laborers sweat and strain to arrange a pile of timbers as thick as a man's leg into some semblance of order.</description>
    <description>A space has been cleared among the piles of lumber to allow planks and stringers to be hauled to the saw nearby.  The air is redolent with the smell of fresh-cut wood and a haze of saw-dust drifts in the air.  Numerous rats scamper about on the nearby woodpiles and their droppings are everywhere.</description>
    <position x="80" y="380" z="0" />
    <arc exit="northeast" move="northeast" destination="442" />
    <arc exit="southwest" move="southwest" destination="444" />
    <arc exit="northwest" move="northwest" destination="451" />
  </node>
  <node id="444" name="Barana's Shipyard, Lumber Stacks">
    <description>Broken and rotted wood is piled in ragged heaps.  Lumber that has failed the grade is left here, to be used for lesser purposes or to be burned for fuel.  Some soul, with more time than sense, has made a neat pile of knots that have been knocked out of the wood.  Rats chitter from within the ruined stacks.</description>
    <description>A space has been cleared among the piles of lumber to allow planks and stringers to be hauled to the saw nearby.  The air is redolent with the smell of fresh-cut wood and a haze of saw-dust drifts in the air.  Numerous rats scamper about on the nearby woodpiles and their droppings are everywhere.</description>
    <position x="70" y="390" z="0" />
    <arc exit="northeast" move="northeast" destination="443" />
    <arc exit="southeast" move="southeast" destination="445" />
  </node>
  <node id="445" name="Barana's Shipyard, Lumber Stacks">
    <description>Wood, dark as the night sky, has been neatly stacked to dry.  Ebony and flame-grained oak mingle with ironwood and other rare species.  Barana never neglects the luxury trade that calls on his yard for their needs.</description>
    <position x="80" y="400" z="0" />
    <arc exit="southeast" move="southeast" destination="446" />
    <arc exit="northwest" move="northwest" destination="444" />
  </node>
  <node id="446" name="Barana's Shipyard, Lumber Stacks">
    <description>Light and dark woods alternate in a zig-zag pile that reaches to a considerable height.  Some lengths are a good thirty or more feet long and jut out of the pile in a stair-step effect.</description>
    <position x="90" y="410" z="0" />
    <arc exit="northeast" move="northeast" destination="447" />
    <arc exit="northwest" move="northwest" destination="445" />
    <arc exit="climb" move="climb wooden lengths" destination="452" />
  </node>
  <node id="447" name="Barana's Shipyard, Lumber Stacks">
    <description>Some accident or careless worker has tumbled a great stack of wood.  Broken and splintered lengths of ash and oak and other types litter the ground as though a tornado had whipped through the yard.  A dead rat hangs impaled on a jagged splinter high overhead where several lengths of wood from an adjoining pile protrude.</description>
    <position x="100" y="400" z="0" />
    <arc exit="northeast" move="northeast" destination="448" />
    <arc exit="southwest" move="southwest" destination="446" />
  </node>
  <node id="448" name="Barana's Shipyard, Lumber Stacks">
    <description>Huge piles of wood in varying states of dryness and type are heaped into untidy rows and piles.  There is a faint rustling from within the larger stacks, where the rats that infest this place make their nests and breed their endless young.</description>
    <position x="110" y="390" z="0" />
    <arc exit="southwest" move="southwest" destination="447" />
    <arc exit="northwest" move="northwest" destination="449" />
  </node>
  <node id="449" name="Barana's Shipyard, Lumber Stacks">
    <description>A few rough tree trunks, stripped of bark and limbs, are piled into a giant's version of jackstraws.  A huge lathe nearby shows their intended fate is to become sturdy masts and yards for ships waiting repair.  One thick ash log, perhaps not suited to its original purpose, has been carved into a fanciful shape.</description>
    <position x="100" y="380" z="0" />
    <arc exit="northeast" move="northeast" destination="450" />
    <arc exit="southeast" move="southeast" destination="448" />
    <arc exit="northwest" move="northwest" destination="442" />
  </node>
  <node id="450" name="Barana's Shipyard, Lathe Works">
    <description>A huge troughlike affair set low to the ground appears to be the bed of an enormous lathe.  Used to turn rough tree trunks into ruler-straight masts and yards, it is an awe-inspiring engine.  Several examples of its output lie scattered about on the chip-littered ground, awaiting further attention from spokeshave and drawknife to fit them for their role.</description>
    <position x="110" y="370" z="0" />
    <arc exit="southwest" move="southwest" destination="449" />
  </node>
  <node id="451" name="Barana's Shipyard, Circular Saw">
    <description>A large circular saw squats like some obscure god waiting for the sacrifice of the logs piled high nearby.  Neat rows of sacks containing the left-over sawdust and woodchips await transport elsewhere, while rows of rough-hewn planks ponder their destiny in the drying racks and kiln.</description>
    <position x="70" y="370" z="0" />
    <arc exit="southeast" move="southeast" destination="443" />
  </node>
  <node id="452" name="Barana's Shipyard, Lumber Stacks">
    <description>The huge tottering pile of wood is unsteady underfoot.  It creaks and shifts with each movement and there are many gaps where the planks have been separated to dry better.  There is a fine view of the rest of the wood-lot, as well as a few of the nearby roofs of other buildings and the adjacent river and mudflats.</description>
    <position x="110" y="410" z="0" />
    <arc exit="climb" move="climb wood" destination="446" />
    <arc exit="go" move="go dark niche" destination="453" />
  </node>
  <node id="453" name="Barana's Shipyard, Lumber Stacks">
    <description>Whether the gift of fate or the intent of lazy employees looking for a hide-out, this small space tucked deep between towering stacks of drying wood has an almost cozy feel to it.  An old rug, nailed to some boards, provides a modest shelter from the weather.  A few scattered tufts of fur show that the rats may enjoy this place as well.</description>
    <position x="120" y="410" z="0" />
    <arc exit="climb" move="climb lumber" destination="452" />
  </node>
  <node id="454" name="Barana's Shipyard, Office">
    <description>Unpolished and dusty, a rosewood counter -- bare except for a scarred leather appointment book -- straddles the center of the office.  Thick air, damp and sour with the smell of dust, marsh and ocean, makes breath difficult in this little reception room.  Directly behind the counter, there is an oak door that leads to Barana's office.  Punctuating the dark paneled walls, several windows overlook the construction yards where vessels rest in various states of completion.</description>
    <position x="110" y="280" z="0" />
    <arc exit="go" move="go short corridor" destination="455" />
    <arc exit="go" move="go leather flap" destination="237" />
  </node>
  <node id="455" name="Barana's Shipyard, Corridor">
    <description>Two long benches give the short walls of this stubby corridor the appearance of being even more short than they are.  A doorless exit going out at the end of the hallway leads to the construction yards.  Other directions lead back to the main office and to the drydock, cartography, and brokerage services offices.</description>
    <position x="90" y="280" z="0" />
    <arc exit="north" move="north" destination="456" />
    <arc exit="east" move="east" destination="454" />
    <arc exit="south" move="south" destination="457" />
    <arc exit="west" move="west" destination="458" />
    <arc exit="out" move="out" destination="459" />
  </node>
  <node id="456" name="Barana's Shipyard, Drydock Services">
    <description>Stacked crates lean against the walls, along with kegs of tar, coils of rope, and casks of paint.  Amidst all the clutter is an antique roll-top desk covered in dust, cobwebs and surprisingly healthy plants.  Half-used candles rest in a spray of brass sconces mounted upon each wall.</description>
    <position x="90" y="260" z="0" />
    <arc exit="south" move="south" destination="455" />
  </node>
  <node id="457" name="Barana's Shipyard, Brokerage">
    <description>Scraps of paper advertising ships for sale layer the walls and partially overlap the small windows.  Several chairs elegantly covered in soft, buttery leather are scattered around the room to facilitate negotiations between parties -- or simply provide a comfortable place to nap.  A low table laid out with refreshments rests against one wall, just the thing to grease a deal along.</description>
    <position x="90" y="300" z="0" />
    <arc exit="north" move="north" destination="455" />
  </node>
  <node id="458" name="Barana's Shipyard, Cartography Services">
    <description>Framed ocean charts hang unevenly upon the dark paneled walls.  The wooden floor, once handsomely inlaid with a mariner's compass, is now a scuffed mess in desperate need of sanding and polishing.  A clerk is hunched over a drawing board, working on a new chart.</description>
    <position x="70" y="280" z="0" />
    <arc exit="east" move="east" destination="455" />
  </node>
  <node id="459" name="Barana's Shipyard, Construction Yard">
    <description>Set near the main office, this wide expanse of muddy earth bordering the Segoltha is the perfect setting for a construction yard.  Positioned near the water is a massive wooden frame, used to form the hull and hold it in place while the rest of the ship is built.  Planks, kegs of tar, pegs and pulleys arranged in blocks and tackle are scattered about the area, ready for the shipbuilder's use.  The construction yard continues southeast.</description>
    <position x="110" y="300" z="0" />
    <arc exit="southeast" move="southeast" destination="460" />
    <arc exit="go" move="go main office" destination="454" />
  </node>
  <node id="460" name="Barana's Shipyard, Construction Yard">
    <description>Although sporadically flooded by seasonal rains and severe tides, the wooden cradle used for shipbuilding seems solidly stationed.  Another keel is being laid in it.  To the east is the mast pond, and in the distance, farther from the bank, is the sail-maker's shed.</description>
    <position x="130" y="320" z="0" />
    <arc exit="east" move="east" destination="461" />
    <arc exit="northwest" move="northwest" destination="459" />
  </node>
  <node id="461" name="Barana's Shipyard, Construction Yard">
    <description>Long, straight timbers of ash, ironwood and teak bob in the mast pond, awaiting their turn to be stepped into a ship to serve as proud bearer of sail.  Nearby, wooden scaffolding is ready to assist the shipwright in his trade.  Eastward, the mudflat juts a little further into the water, and moving westerly returns to the main shipyard office.</description>
    <position x="150" y="320" z="0" />
    <arc exit="east" move="east" destination="462" />
    <arc exit="west" move="west" destination="460" />
  </node>
  <node id="462" name="Barana's Shipyard, Construction Yard">
    <description>Set at the end of the muddy finger of land, this last construction area and its wooden cradle seem more a home for birds and fishermen than shipbuilding.  There is a neat row of small boats turned hull up to have the barnacles scraped from them.  The water's edge is littered with cracked mussel shells, dropped from above by gulls intent upon eating the soft interiors.</description>
    <position x="170" y="320" z="0" />
    <arc exit="west" move="west" destination="461" />
  </node>
  <node id="463" name="Saranna's Sweet Tooth, Kitchen">
    <description>Massive brick ovens take up at least half of the kitchen, keeping the room cozy in even the chilliest of weather. Pretty young maidens, elbow-deep in dough and frosting, work diligently behind heavy marble counters.  On the southern wall, an elderly halfling lady perches on the edge of a table, sculpting sugared roses and other decorations with deft fingers.</description>
    <position x="50" y="-395" z="0" />
    <arc exit="east" move="east" destination="464" />
    <arc exit="go" move="go side door" destination="128" />
  </node>
  <node id="464" name="Saranna's Sweet Tooth, Sales Room" note="Saranna's Sweet Tooth|Bakery" color="#FF0000">
    <description>All the loveliest colors of spring have been woven into the decor of the village bakery, from sky blue walls, to daffodil yellow countertops, to soft rose rugs dotting the hardwood floors. Young maidens shuffle in and out from the north, constantly replenishing the counters with fresh trays of cream puffs, pies, cakes, and breads.  The slender form of Saranna appears at intervals, smiling and chattering as she hustles between the main sales room and a narrow doorway to the northwest.</description>
    <position x="70" y="-395" z="0" />
    <arc exit="west" move="west" destination="463" />
    <arc exit="out" move="out" destination="129" />
    <arc exit="go" move="go narrow doorway" destination="869" />
  </node>
  <node id="465" name="Taelbert's Inn, Stables" note="Stable" color="#00FF00">
    <description>White plaster walls hung with drifting cobwebs enclose this dank space.  Identical narrow stalls, each blanketed with a thick carpet of fresh straw, line the walls allowing just enough room for a pathway west to a smaller work area.  Tools and grain barrels rest between each stall, at the ready for any stablehand to use to care for their charges.</description>
    <position x="-10" y="-378" z="0" />
    <arc exit="west" move="west" destination="466" />
    <arc exit="out" move="out" destination="122" />
  </node>
  <node id="466" name="Taelbert's Inn, Tack Storage">
    <description>Barely more than a closet, this tiny space is practically filled with dozens of trunks, boxes, and baskets.  Each is filled to overflowing with goods that often find their way here to be repaired and resold -- one person's loss is another's profit.  Standing in a narrow corner is Stablehand Ilinear, occasionally rummaging through containers apparently looking for a particular piece.</description>
    <position x="-20" y="-378" z="0" />
    <arc exit="east" move="east" destination="465" />
  </node>
  <node id="467" name="The Crossing, Town Green Pond" note="Pond">
    <description>You stand on the bank of a tiny pond in the middle of the square.  A thick layer of ice seals the water, and in the distance you can hear the bustle of the town.  The smooth ice looks very inviting, and quite safe!</description>
    <description>You stand on the bank of a tiny pond in the middle of the square.  Cool water laps against the soft, velvety silt that covers the shore, and in the distance you can hear the bustle of the town.  Sitting in the middle of the pond is a massive gelapod, looking content and not the least bit aggressive.</description>
    <position x="160" y="-160" z="0" />
    <arc exit="out" move="out" destination="14" />
  </node>
  <node id="468" name="Bards' Guild, Commons" note="Bard|GL Bard|Silvyrfrost|RS Bard" color="#FF8000">
    <description>Always a flurry of activity, the guild commons is a place where bards young and old meet to trade tips, tales, and motifs.  Thick, ruby-colored carpeting lines the floor while gold-laced red velvet curtains decorate the walls.  Padded benches surround the area, a few already in use by travelling musicians resting their tired legs.</description>
    <position x="-70" y="-398" z="0" />
    <arc exit="east" move="east" destination="469" />
    <arc exit="out" move="out" hidden="True" destination="29" />
    <arc exit="go" move="go mirrorlike portal" destination="470" />
  </node>
  <node id="469" name="Bards' Guild, Repair Room">
    <description>Shelves upon shelves of half-built mandolins, violins, lutes, flutes, and a slew of other unidentifiable parts cover the walls.  The scent of rosin and glue wafts in the air.  In the corner, a long sturdy workbench holds a plethora of specialized tools to aid in the crafting of the finest musical instruments.</description>
    <position x="-60" y="-398" z="0" />
    <arc exit="west" move="west" destination="468" />
  </node>
  <node id="470" name="Bards' Guild, Performance Hall">
    <description>Plush seats lined up in rows face a hardwood stage raised four feet from the ground.  Red velvet curtains draped from the high vaulted ceiling cover the walls.  The acoustics create a warm echo which lends an air of nobility to the place.  A podium in the corner hints that the hall must be used for formal meetings as well as performances.</description>
    <position x="-80" y="-398" z="0" />
    <arc exit="east" move="east" destination="468" />
    <arc exit="go" move="go draped archway" destination="471" />
  </node>
  <node id="471" name="Bards' Guild, Backstage Stairwell">
    <description>The base of a steep sweeping staircase faces the archway that leads to the performance hall.  However the railing that rises with the stairs appears to be rather shaky, despite the polished surface imposed by years of rapid descents by Bards.</description>
    <position x="-90" y="-398" z="0" />
    <arc exit="east" move="east" destination="470" />
    <arc exit="go" move="go door" destination="472" />
    <arc exit="climb" move="climb sweeping staircase" destination="473" />
  </node>
  <node id="472" name="Bards' Guild, Prop Room">
    <description>Set apart and removed from the guild proper by a sturdy door, this room serves as a waystation for traveling Bards to find a quiet place to put down for the night.  Several cots are set up around the room.</description>
    <position x="-100" y="-398" z="0" />
    <arc exit="go" move="go narrow door" destination="471" />
  </node>
  <node id="473" name="Bards' Guild, Conservatory">
    <description>Several smokeless candles flicker from behind cut-glass sconces, bathing the room in a soft and even light that refracts off the countertop of the wraparound bar.  The centerpiece of the conservatory is a beautiful ebonwood clavichord, framed by the top of a staircase and a sliding glass door.</description>
    <position x="-90" y="-388" z="0" />
    <arc exit="go" move="go small alcove" destination="474" />
    <arc exit="go" move="go glass door" destination="475" />
    <arc exit="climb" move="climb sweeping staircase" destination="471" />
  </node>
  <node id="474" name="Bards' Guild, Keg Alcove">
    <description>Three oversized oak kegs fill the alcove, leaving barely enough room to reach a curious-looking cupboard on the back wall.  Broken tankards lie carelessly discarded in the corners, and damp stains spot the carpet around each keg, mute reproach to the housekeeping skills of the residents.</description>
    <position x="-80" y="-388" z="0" />
    <arc exit="go" move="go conservatory" destination="473" />
  </node>
  <node id="475" name="Bards' Guild, Balcony">
    <description>Sweet fragrances of bright perennials fill the air of the covered balcony that overlooks the boulevard below.  Several outdoor chairs are surrounded by potted lilac, lavender, and gardenia, aiding in the air of relaxation supported by the clear view of the sky above.</description>
    <position x="-100" y="-388" z="0" />
    <arc exit="go" move="go glass door" destination="473" />
  </node>
  <node id="476" name="Riverbank Trail" note="Map50_Segoltha_River.xml|Segoltha River">
    <description>The sounds of the city fade slightly into the background, muffled by the steep slope of the riverbank that lines the trail.  The path follows the river, edging along the slippery slope that is littered with old bottles, broken wood and dead fish.</description>
    <position x="-350" y="220" z="0" />
    <arc exit="west" move="west" />
  </node>
  <node id="477" name="Amusement Pier, Entrance" note="Map1l_Crossing_Amusement_Pier.xml|Amusement Pier">
    <description>Throngs of children mill around, licking lollipops and poking at one another.  Salty air drifts upon the wind, causing bits of old paper to dance around freshly painted garbage bins.  Various buildings and attractions are visible further down the wide wooden and metal pier.</description>
    <description>Salty air drifts upon the wind causing bits of old paper to dance around half-full garbage bins, while sweepers go by cleaning up the day's refuse.  Various buildings and attractions are visible in the torchlight further down the wide wooden and metal pier.</description>
    <position x="-104" y="226" z="0" />
    <arc exit="southeast" move="southeast" />
    <arc exit="south" move="south" />
    <arc exit="southwest" move="southwest" />
    <arc exit="go" move="go elaborate gate" destination="58" />
  </node>
  <node id="478" name="Emmiline's Cottage, Porch">
    <description>Dimly lit by the lantern in one window, the corners of the wide porch are veiled in shadow.  Dark shapes at one end vaguely resemble a table and seating area, while only a greyish oval window hints at where the door might be.</description>
    <description>Swept clean of debris, the white porch stretches across the front of the cottage, protecting the entryway from the elements.  At one end is a small seating area with a swing, two chairs and a glass-topped table.  At the other is a wooden door to enter the cottage, polished to a high sheen and mounted with a frosted window.  The oval glass features an etching of a unicorn standing in a meadow with a small wren perched on its spiraling horn.</description>
    <position x="250" y="-498" z="0" />
    <arc exit="go" move="go wooden steps" destination="263" />
    <arc exit="go" move="go wooden door" destination="479" />
  </node>
  <node id="479" name="Emmiline's Cottage, Sales Floor" note="Emmiline's Cottage|Empath Shop" color="#FF0000">
    <description>Shelves of wares gleam from the warm glow of lanterns lit in corners and on surfaces.  The sales floor seems hushed in the night, though the clerks still busy themselves with cleaning the racks and displays, and with helping customers.  A curtain has been pulled, partially obscuring a set of steps, and a small lantern illuminates the archway that leads to the other sales area.</description>
    <description>Warmly toned, the large room invites browsing.  A rack stands in one corner, displaying fabrics in many hues, while in the center of the room, a large display holds an array of items.  Before one window sit a green striped sofa and chair, and a round table stands between them.  A maple and linen screen partially obscures an archway.  Two steps lead to an area hidden behind a curtain.</description>
    <position x="250" y="-508" z="0" />
    <arc exit="west" move="west" destination="480" />
    <arc exit="go" move="go wooden door" destination="478" />
    <arc exit="go" move="go wooden steps" destination="481" />
    <arc exit="go" move="go archway" destination="482" />
  </node>
  <node id="480" name="Emmiline's Cottage, Parlor" note="Emmiline Parlor" color="#FF0000">
    <description>Quiet murmurs accompany the rustle of paper as clerks and customers alike rifle through the wares offered in the parlor.  A white marble fireplace, clean and unused, displays a number of items on its mantle while a book rack in the corner supports assorted papers and bindings.  Near the window, a white basket glistens in the minimal light available.</description>
    <description>Sized and painted like a standard home's parlor, the room is bare of the typical seating arrangement one might expect.  In place of furniture, a large white basket is located near the window.  In one corner stands a book rack with assorted papers tucked into it and the mantle shelf above the fireplace holds additional items.</description>
    <position x="240" y="-508" z="0" />
    <arc exit="east" move="east" destination="479" />
  </node>
  <node id="481" name="Emmiline's Cottage, Kitchen">
    <description>The room is lit only by the lanterns down the hall in the shop area, casting odd shadows across the kitchen that nearly hide the closed bedroom door.  The fireplace is banked for the night, the kettle set on a granite stone in the ash to keep the contents warm for any late night guests.  Kitchen chairs are tucked neatly in their places next to the table, and the cushion in the corner looks lumpy, as if it has been pushed and pulled for hours.</description>
    <description>A tidy kitchen with whitewashed cabinets and a round oak table opens just beyond a short hall leading from the front of the house.  The scent of chocolate drifts in the air and a kettle of tea burbles over the fire.  Placed neatly near the fireplace is a green cushion with lumps and strands of fur in its cloth.  An occasional breeze moves curtains made of yellow gingham tied off with lace ribbon scraps that hang at the windows.  The table is set for company, and a plaque hangs on the wooden door.</description>
    <position x="250" y="-518" z="0" />
    <arc exit="go" move="go short hall" destination="479" />
  </node>
  <node id="482" name="Emmiline's Cottage, Pantry" note="Emmiline Pantry" color="#FF0000">
    <description>A shelving unit gleams from regular polishing, their shelves laden with supplies and wares both available for sale and those yet to be unpacked.  In the center of the room, a short table sits before a glass display case, both of which hold sparkling treasures.</description>
    <position x="260" y="-508" z="0" />
    <arc exit="go" move="go archway" destination="479" />
  </node>
  <node id="483" name="Communal Center, Veranda" note="Communal Center">
    <description>Stretching the entire length of the communal center, this veranda faces east towards the Oxenwaithe.  It's a favorite gathering place for resort occupants, but at any given time a travelling merchant or two can be found enjoying a cool drink and the delightful view.  Several tables covered in crisp white cloth stand in neat rows across its length.</description>
    <position x="270" y="320" z="0" />
    <arc exit="out" move="out" destination="51" />
    <arc exit="go" move="go louvered doors" destination="484" />
    <arc exit="go" move="go curving footpath" destination="505" />
  </node>
  <node id="484" name="Strand Communal Center, Common Room">
    <description>An itinerant mage keeps a fragrant breeze, heavy with the scent of shalyria blossoms growing outside the windows, swirling softly about the room.  White wicker tables provide a place to relax while nibbling from an array of snacks which are laid out on a lunat sideboard along the back wall.  Dangling strands of colorful glass beads clatter musically as a young boy veers around a potted fern on his way to an archway opposite the louvered doors leading to the veranda.</description>
    <position x="250" y="320" z="0" />
    <arc exit="go" move="go louvered doors" destination="483" />
    <arc exit="go" move="go curtained archway" destination="485" />
  </node>
  <node id="485" name="Strand Communal Center, Narrow Hallway">
    <description>Shifting patterns of deep red, sparkling sapphire, and clear yellow light dance about the white stucco walls of the hallway with each movement of a beaded glass curtain hanging over the archway leading to the common room.  The light, airy walls are a sharp contrast to the dark oak stairs which lead to the second floor of the building.</description>
    <position x="230" y="320" z="0" />
    <arc exit="go" move="go curtained archway" destination="484" />
    <arc exit="climb" move="climb narrow steps" destination="486" />
    <arc exit="climb" move="climb oak stairs" destination="487" />
  </node>
  <node id="486" name="Strand Communal Center, Basement">
    <description>Gently glowing pillars support the vaulted ceilings, illuminating the basement's nooks and corners.  Between the lack of furnishings and the softly shining light, the guards stationed at either end of the room seem almost superfluous, yet from the alert way they eye all who enter, they evidently take their duties seriously.  A series of narrow steps lead back to the main floor of the Communal Center, while a heavy oak door and a short passage lead to other areas of the basement.</description>
    <position x="210" y="340" z="0" />
    <arc exit="climb" move="climb narrow steps" destination="485" />
    <arc exit="go" move="go oak door" destination="500" />
    <arc exit="go" move="go short passage" destination="501" />
  </node>
  <node id="487" name="Strand Communal Center, Upstairs Hallway">
    <description>A kitten purrs contentedly as she drowses atop a small table at the end of the hallway, sleeping off a meal of scraps filched from guests.  One of several which inhabit the center, her usual mischievious demeanor is subdued now by slumber.  To the east, an airy white hallway runs the length of the building, while dark oak stairs lead down to the first floor.</description>
    <position x="250" y="280" z="0" />
    <arc exit="north" move="north" destination="488" />
    <arc exit="east" move="east" destination="489" />
    <arc exit="climb" move="climb oak stairs" destination="485" />
  </node>
  <node id="488" name="Strand Communal Center, Practice Room">
    <description>White walls are unadorned, providing little to no distractions for students who wish to practice their craft.  The sole furnishings of this spartan room are a worn table and a few wooden chairs, suitable for scholarly pursuits.  Yet despite the stark nature of the room, a window looks out onto the land around the center, and the young people playing outside.</description>
    <position x="250" y="260" z="0" />
    <arc exit="south" move="south" destination="487" />
  </node>
  <node id="489" name="Strand Communal Center, Upstairs Hallway">
    <description>A light breeze flows from the windows of a room to the south, gently turning a small pink and white mobile which hangs from the ceiling.  Made of twigs and seashells gathered from the nearby beach, it clicks softly as it moves, a charming memento of some child's visit to the center.</description>
    <position x="270" y="280" z="0" />
    <arc exit="east" move="east" destination="490" />
    <arc exit="south" move="south" destination="491" />
    <arc exit="west" move="west" destination="487" />
  </node>
  <node id="490" name="Strand Communal Center, Upstairs Hallway">
    <description>The white stucco walls of the Communal Center are cheerful and bright, reflecting light from sun and candle alike.  A heavy oak door, carved with images of dolphins and merfolk playing in the waves, leads north.  To the east and west, the hallway spans the length of the building.</description>
    <position x="290" y="280" z="0" />
    <arc exit="east" move="east" destination="492" />
    <arc exit="west" move="west" destination="489" />
  </node>
  <node id="491" name="Strand Communal Center, Gathering Room">
    <description>Flames crackle in the hearth of a stone fireplace.  They glow with a flickering light, casting shadows which dance about the dimly lit room.  The wooden shutters which cover the windows allow air to circulate, but block the light of both sun and moon.  Leather chairs surround the fireplace, with a low tray in easy reach holding a tempting array of snacks.  At the far end of the room stands an odd half-round table surrounded by five wooden stools.</description>
    <position x="270" y="300" z="0" />
    <arc exit="north" move="north" destination="489" />
  </node>
  <node id="492" name="Strand Communal Center, Upstairs Hallway">
    <description>Strains of music fill the air, echoing about the hallway.  The music room to the south has long been used by bards and others who seek to improve their skills, the pleasant room carefully designed to enhance the performance of artists.  In a shallow niche, a candle burns beneath a driftwood sculpture of wrens perched upon a gnarled branch.</description>
    <position x="310" y="280" z="0" />
    <arc exit="east" move="east" destination="494" />
    <arc exit="south" move="south" destination="493" />
    <arc exit="west" move="west" destination="490" />
  </node>
  <node id="493" name="Strand Communal Center, Music Room">
    <description>Soft yellow paint covers the stucco walls, reflecting the light with a soft amber glow.  Actors and musicians perform atop a low stage at one end of the music room, while the audience watches from rows of pale blue sofas and chairs.  Open windows line the southern wall, providing a view of the Crystalline Beach.</description>
    <position x="310" y="300" z="0" />
    <arc exit="north" move="north" destination="492" />
  </node>
  <node id="494" name="Strand Communal Center, Upstairs Hallway">
    <description>The hallway continues past a large room to the north.  Like most rooms along the hallway, there is no door barring the entrance, allowing air to circulate between the rooms in the hot summer months, and heat to spread evenly in winter.</description>
    <position x="330" y="280" z="0" />
    <arc exit="north" move="north" destination="496" />
    <arc exit="east" move="east" destination="495" />
    <arc exit="west" move="west" destination="492" />
  </node>
  <node id="495" name="Strand Communal Center, Upstairs Hallway">
    <description>Roses fill a crystal vase atop a polished cherry table at the eastern end of the hallway.  To the north, a tattered sign hangs on a louvered door, while to the south is an open room filled with sunlight, plants and the scent of green and growing things.</description>
    <position x="350" y="280" z="0" />
    <arc exit="south" move="south" destination="497" />
    <arc exit="west" move="west" destination="494" />
    <arc exit="go" move="go louvered door" destination="1019" />
  </node>
  <node id="496" name="Strand Communal Center, Lounge">
    <description>Off in a corner, palm trees silently wave in the draft from a nearby window, their leafy green fronds moving gracefully about.  In front of them, carefully placed to catch that same breeze, are some wicker chairs, a low table, and a pile of cushions, such as children use to sprawl upon the floor.  With snacks upon a low table, and the company of friends, this is a charming room in which to relax.</description>
    <position x="330" y="260" z="0" />
    <arc exit="south" move="south" destination="494" />
    <arc exit="west" move="west" destination="499" />
  </node>
  <node id="497" name="Strand Communal Center, Solarium" note="Solarium">
    <description>Windows surround the room on the east and south, flooding the solarium with sunshine during the day, and moonlight at night.  Taking advantage of this, the designers of the center have set out several small chaises upon which guests can lie back and relax while they bask in the light.  Against the north wall, a glass tank houses a brightly colored siren fish which lazily swims about.</description>
    <position x="350" y="300" z="0" />
    <arc exit="north" move="north" destination="495" />
    <arc exit="west" move="west" destination="498" />
  </node>
  <node id="498" name="Strand Communal Center, Conservatory" note="Conservatory">
    <description>Plants from all parts of the realm fill the room, from delicate palms to graceful lepradria orchids twining about the trunk of a fragrant lemon tree.  The spicy scent of a lily blends with the almost overwhelming sweetness of a freesia, the combination forming an altogether delightful aroma.  A glass door to the south leads to a small balcony.</description>
    <position x="330" y="300" z="0" />
    <arc exit="east" move="east" destination="497" />
    <arc exit="go" move="go glass door" destination="635" />
  </node>
  <node id="499" name="Strand Communal Center, Bar">
    <description>As in other places of the center, the white stucco walls contrast sharply with the dark oak used to build a small bar.  Atop the bar, a small but ever-changing assortment of drinks have been set out, allowing guests to help themselves.  Stools provide a place to sit, or people may take their drinks over to the lounge to the east.</description>
    <position x="310" y="260" z="0" />
    <arc exit="east" move="east" destination="496" />
  </node>
  <node id="500" name="Strand Communal Center, Bank Teller" note="Premium Bank|Premium Teller" color="#00FF00">
    <description>Clerks bustle about the tiny room, carrying bags of coins to and from the vault under the eye of a guard.  A teller stands behind a counter at one side of the room.  At the other end, the vault door stands open for those who must transact business via the moongates to other banks in the realms.</description>
    <description>Clerks bustle about the tiny room, carrying bags of coins to and from the vault under the eye of a guard.  Visible through a small window, a teller stands behind a counter at one side of the room.  At the other end, the vault door stands open for those who must transact business via the moongates to other banks in the realms.</description>
    <position x="190" y="340" z="0" />
    <arc exit="out" move="out" destination="486" />
    <arc exit="go" move="go tiny alcove" destination="502" />
    <arc exit="go" move="go vault door" destination="503" />
  </node>
  <node id="501" name="Strand Communal Center, Passage">
    <description>White walls combined with the soft warmth of gently glowing pillars chase away the shadows at the end of the passage.  A guard regards passers-by with an alert eye from his post beside a heavy oak door.</description>
    <position x="237" y="340" z="0" />
    <arc exit="west" move="west" destination="486" />
    <arc exit="go" move="go oak door" destination="504" />
  </node>
  <node id="502" name="Strand Communal Center, Gemsmith's Alcove" note="Premium Gems" color="#00FF00">
    <description>Gently glowing pillars stand to either side of the shallow alcove, their steady light illuminating the counter where the young gemsmith, Jasmine ap'Wyrr, does business.  Her nimble fingers and sharp eye expertly evaluate each gem offered her, while her ready smile and soft voice soften the disappointment when she refuses to purchase an item.</description>
    <position x="170" y="340" z="0" />
    <arc exit="out" move="out" destination="500" />
  </node>
  <node id="503" name="Strand Communal Center, Foreign Exchange" note="Premium Exchange" color="#00FF00">
    <description>The Communal Center prides itself on the special services it provides.  For the convenience of guests, the Center employs mages who, under the careful scrutiny of the guards, maintain moongates between the various banks, running the length and breadth of realms.  These gates allow customers to effortlessly transfer money from other banks, as well as to efficiently exchange currencies, saving their customers time as well as protecting their purses from the hazards of the road.</description>
    <position x="190" y="360" z="0" />
    <arc exit="out" move="out" destination="500" />
  </node>
  <node id="504" name="Fenwyrthie's Curio Shop" note="Fenwyrthie's Curio Shop|Premie Shop|Curio Shop" color="#FF0000">
    <description>Oak shelves line the walls from floor to ceiling, covered with a thin film of dust and cobwebs.  Nestled beneath the stairs leading to the first floor, the shop offers an odd collection of items which catch the fancy of Nathaniel Fenwyrthie, the owner.</description>
    <description>Cobweb-covered oak shelves line the walls from floor to ceiling while wicker baskets and oaken chests are nestled snugly before them.  Trays of copper and silver separate a maple table and a dusky oaken counter.  Too many items are certainly crammed into too small a space.</description>
    <position x="237" y="360" z="0" />
    <arc exit="west" move="west" destination="964" />
    <arc exit="out" move="out" destination="501" />
  </node>
  <node id="505" name="The Strand, Tree-lined Path" color="#00FFFF">
    <description>The smell of the sea hangs heavy in the night air, and the sound of activity from the Crossing Docks pierces the darkness.  Moreover, the curving footpath is illuminated by several gaethzen globes hanging from the branches of the bordering trees.</description>
    <description>Sand dotted with rocks and interspersed with wavy marram grass dominates the area.  The tree trunks lining the curving footpath tower above the hardy flowers that have managed to thrive.  Gaethzen globes hang from the branches, the orbs aglow despite the presence of daylight for added illumination.</description>
    <position x="350" y="320" z="0" />
    <arc exit="northeast" move="northeast" destination="506" />
    <arc exit="go" move="go curving footpath" destination="483" />
  </node>
  <node id="506" name="The Strand, Tree-lined Path" note="Isharon" color="#00FFFF">
    <description>The rhythmic sound and smell of the ocean linger faintly in the air, only interrupted by the occasional grunt, groan or curse for those working on the Crossing Docks.  Hanging gaethzen globes light a path in the darkness toward an old-growth forest northward and toward the sound of the crashing waves to the south.  Illuminated by the glow are several ants scurrying along the ground in and around a damaged anthill.</description>
    <description>A few pockets of marram grass stick out of the sand, mixing with more traditional short green tufts that dot the area.  The trees, laden with gaethzen globes, also grow denser as the pathway winds its way northward away from the docks towards an old-growth forest.  Breaking the serenity of the landscape are countless large black ants diligently swarming around a damaged anthill near the base of a nearby willow.</description>
    <position x="370" y="300" z="0" />
    <arc exit="north" move="north" destination="507" />
    <arc exit="southwest" move="southwest" destination="505" />
  </node>
  <node id="507" name="The Strand, Tree-lined Path" color="#00FFFF">
    <description>In the darkness, the gaethzen globes appear to simply hover several feet above the footpath.  However, their light shines on the trees and grasses that surround pathway and cause long shadows to dance on the dirt surface with even the slightest breeze.  Occasionally, a lone rabbit ventures out of its leafy home, braving the darkness for one last meal.</description>
    <description>Shaggy green grass and broad-leafed plants have mostly supplanted the marram stalks of the beach's sandy dunes.  Several young trees have gaethzen globes affixed to their braches, causing them to bend over the footpath and create a spacious, leafy arch large enough to permit even the tallest of Gor'Togs to easily pass under.  Woodland rabbits making their home in the foliage dart to and fro while searching for particular vegetarian delights.</description>
    <position x="370" y="280" z="0" />
    <arc exit="northeast" move="northeast" destination="508" />
    <arc exit="south" move="south" destination="506" />
  </node>
  <node id="508" name="The Strand, Tree-lined Path" note="Praxiuz" color="#00FFFF">
    <description>Glowing like stars captured in the trees' branches, dozens of gaethzen globes shine upon the trees flanking the footpath.  The soft illumination causes the sand tucked inside the grass to glitter.  Flickers of silver inside the darkened underbrush allude to the local foxes' nighttime activity.</description>
    <description>Only an occasional patch of sand can be seen in the grass when the wind caresses the blades a certain way.  Strung with gaethzen globes, the trees flanking the footpath are mature, although still not as tall as the old-growth trees that loom in the north.  Flickers of silver against the underbrush allude to the foxes forging a home in the nearby forest.</description>
    <position x="390" y="260" z="0" />
    <arc exit="north" move="north" destination="509" />
    <arc exit="southwest" move="southwest" destination="507" />
  </node>
  <node id="509" name="The Strand, Tree-lined Path" color="#00FFFF">
    <description>Though the darkness of night is omnipresent, the area retains a comfortable, homey feel due to the friendly chatter of woodland animals in the surrounding forest.  Gaethzen globes glow from their nests deep within the leafy branches of the arching trees.  A small wooden walkway leads toward an open glade astride the continuing route.</description>
    <description>Only a few beams of daylight pierce though the canopy of the mature trees edging the dirt path.  Their long, broad leaves arch over the grassy lawns, casting the area in permanent shade and leaving only the gaethzen globes hung from the branches to illuminate the area.  A small wooden walkway leads toward an open glade astride the continuing route.</description>
    <position x="390" y="240" z="0" />
    <arc exit="east" move="east" destination="510" />
    <arc exit="south" move="south" destination="508" />
  </node>
  <node id="510" name="The Strand, Tree-lined Path" color="#00FFFF">
    <description>The thickly wooded area surrounding the footpath does an admirable job of ensconcing the area in deep black shadows.  Fastened securely to the many trees along the border, glowing gaethzen globes add a touch of manmade art to the natural environment.  Noisy crickets chirp their rhythmic tones every now and then to break the night's silence.</description>
    <description>The thickly wooded area surrounding the footpath does an admirable job of ensconcing the area in muted green tones.  Fastened securely to the many trees along the border, gaethzen globes add a touch of manmade art to the natural environment.  Warbling birds sing their cheery songs every now and then to complement the rustling leaves.</description>
    <position x="410" y="240" z="0" />
    <arc exit="east" move="east" destination="511" />
    <arc exit="west" move="west" destination="509" />
  </node>
  <node id="511" name="The Strand, Tree-lined Path" color="#00FFFF">
    <description>Only glimpses of the night sky overhead filter through the trees towering overhead -- a clear indication that they're overdue for trimming.  Dark shapes skip eerily about when movement in the branches causes the dangling gaethzen globes to sway, oddly resembling the dance of shadows animated by a flickering flame.  The nocturnal animals inhabiting the brushwood don't seem to mind the sporadic illumination, scampering from black spot to black spot to avoid detection.</description>
    <description>Little light filters through the trees towering overhead -- a clear indication that they're overdue for trimming.  Radiant beams skip gaily about upon the path, making the dirt their own private dance floor.  The local avian population also seems to enjoy the sporadic illumination and that provided by the gaethzen globes, fluttering in between bright shafts as if they were spotlights.</description>
    <position x="430" y="240" z="0" />
    <arc exit="southwest" move="southwest" destination="512" />
    <arc exit="west" move="west" destination="510" />
  </node>
  <node id="512" name="The Strand, Tree-lined Path" color="#00FFFF">
    <description>The trees beyond the borders of the path thin out at the southern part of the meandering route, yet the light from the gaethzen globes remains constant.  Cool night breezes coming from the southeast bring the scent of fresh river water mingled with the ocean's salty tang.  As if to mimic the neighboring sea, the windswept leaves rustle softly in patterns akin to crashing waves.</description>
    <description>The trees beyond the borders of the path thin out at the southern part of the meandering route, yet the light from their gaethzen globes remains constant.  A breeze coming from the southeast brings the scent of the rivers occasionally mingled with the ocean's salty tang.  Gritty sand blends with the ground's dirt to create swirls of pale beige throughout the deeper brown.</description>
    <position x="410" y="260" z="0" />
    <arc exit="northeast" move="northeast" destination="511" />
    <arc exit="south" move="south" destination="513" />
  </node>
  <node id="513" name="The Strand, Tree-lined Path">
    <description>A small, dark area has been cleared of brush and shrubs to the side of the path.  Visible under the soft glow of numerous gaethzen globes, stone benches and matching tables enclose a communal firepit and public woodbox.  Shadowy willow trees hang over the gathering spot as if to protect visitors from the onslaught of night.</description>
    <description>A small area has been cleared of brush and shrubs to the side of the path.  Evenly spaced stone benches and matching tables enclose a communal firepit and public woodbox.  Graceful willow trees supporting numerous gaethzen globes hang protectively over the gathering spot, providing comfortable shade during the warmer months.</description>
    <position x="410" y="280" z="0" />
    <arc exit="north" move="north" destination="512" />
    <arc exit="southeast" move="southeast" destination="514" />
  </node>
  <node id="514" name="The Strand, Tree-lined Path">
    <description>The meticulously tended trees slowly encroach upon the beach, yawning open as if tired from the imposing company of night.  Varied footprints in the malleable ground indicate the preponderance of travelers through the junction, though visitors are relatively scarce compared to during the day.  A small track diverges from the route toward a secluded cove, while a path branches westward in the direction of a small hill.</description>
    <description>The meticulously tended trees slowly encroach upon the beach, with stalks of marram grass surrounding the sandy path.  Varied footprints in the malleable ground indicate the preponderance of travelers through the junction, though the atmosphere remains relatively calm and undisturbed.  A small track diverges from the route toward a secluded cove, while a path branches westward in the direction of a small hill.</description>
    <position x="430" y="300" z="0" />
    <arc exit="northwest" move="northwest" destination="513" />
    <arc exit="go" move="go winding path" destination="515" />
    <arc exit="go" move="go small track" destination="591" />
  </node>
  <node id="515" name="The Strand, Hilltop">
    <description>The top of this hilly knoll is devoid of foliage, thus allowing a decent view of the surrounding area from the city's glow cutting through the darkness.  To the north, the woods are dominated by shadowy trees.  Sounds of the burbling Oxenwaithe can be heard as it flows into the chatty Segoltha River to the southeast.  Lights twinkle from the side of the Communal Center situated past the gardens.</description>
    <description>The top of this hilly knoll is devoid of foliage, thus allowing a decent view of the surrounding area.  To the north, the thick woods are dominated by old-growth trees.  To the east, the Oxenwaithe River can be spotted as it flows into the Segoltha River to the southeast.  The Communal Center lies south and west past the gardens.</description>
    <position x="410" y="320" z="0" />
    <arc exit="go" move="go ornate gate" destination="516" />
    <arc exit="go" move="go winding path" destination="514" />
  </node>
  <node id="516" name="Strand Communal Center, Gardens" note="Gardens">
    <description>Though the evidence of lush foliage is present, mostly shadows greet the eye.  Vines heavy with roses twine themselves around the bordering fence, the blossoms adding their perfume to the fresh night air.  A path originates at the gate and drowns in the gardens' darkness.</description>
    <description>Varying shades of green greet the eye.  Vines heavy with selmor roses twine themselves around the white wrought iron fence, the colorful blossoms adding their perfume to the fresh sea air.  A variegated stone path originates at the ornate gate and leads further into the confines of the lush gardens.</description>
    <position x="430" y="320" z="0" />
    <arc exit="northeast" move="northeast" destination="517" />
    <arc exit="east" move="east" destination="519" />
    <arc exit="southeast" move="southeast" destination="518" />
    <arc exit="go" move="go ornate gate" destination="515" />
  </node>
  <node id="517" name="Strand Communal Center, Gardens">
    <description>Ethereal tenra blossoms quiver slightly within their cushy bush abodes, each petal glistening with collected condensation from the cool air.  The flowers' delicately sweet odor combines with the saltiness of the ocean breezes, both scents heightened by the serene night atmosphere.  Hooting from nocturnal owls hidden nearby interrupts the mellow atmosphere in the gardens only occasionally.</description>
    <description>Ethereal tenra blossoms bob their heads gaily from side to side on their cushy bush abodes.  Their delicately sweet odor is offset by the saltiness of the ocean breezes carried in on the wings of gulls and other water fowl.  The birds' waning cries interrupt the mellow atmosphere in the gardens only occasionally.</description>
    <position x="450" y="300" z="0" />
    <arc exit="east" move="east" destination="521" />
    <arc exit="southeast" move="southeast" destination="520" />
    <arc exit="south" move="south" destination="519" />
    <arc exit="southwest" move="southwest" destination="516" />
  </node>
  <node id="518" name="Strand Communal Center, Gardens">
    <description>Restful coos of contentment and the occasional fluttering sound of wings come from a nearby tree.  As the sea breeze blows through the branches, the leaves rustle continuously.  The smattering of enshaen near the trunk glows a deep goldenrod hue underfoot, the dim illumination from the Center's windows failing to highlight the vibrancy of the blossoms' true colors.</description>
    <description>Shrill chirps of rage interspersed with the gentle songs of more satisfied birds emanate from a low-lying scrub willow tree.  Gathered around the trunk, a smattering of yellow Zoluren enshaen grows together as if congregating for a party.  Only the uniformity of their hues gives away the master gardener's plan.</description>
    <position x="450" y="340" z="0" />
    <arc exit="north" move="north" destination="519" />
    <arc exit="northeast" move="northeast" destination="520" />
    <arc exit="east" move="east" destination="522" />
    <arc exit="northwest" move="northwest" destination="516" />
  </node>
  <node id="519" name="Strand Communal Center, Gardens">
    <description>Crickets and peepers serenade each other over the constant murmur of running water.  Faint floral aromas mingle with the misty spray from the fountains jetting between three pools artfully inlaid amongst the lush grass.</description>
    <description>Lush green grass grows close to a simple fountain consisting of three ground-level pools.  Water arcs at varying heights between the basins, filling the area with the soothing sound of running water.  The air thrums with their nose-tickling spray, which adjusts with each change of the wind's direction.</description>
    <position x="450" y="320" z="0" />
    <arc exit="north" move="north" destination="517" />
    <arc exit="northeast" move="northeast" destination="521" />
    <arc exit="east" move="east" destination="520" />
    <arc exit="southeast" move="southeast" destination="522" />
    <arc exit="south" move="south" destination="518" />
    <arc exit="west" move="west" destination="516" />
  </node>
  <node id="520" name="Strand Communal Center, Gardens">
    <description>Large bushes huddle close to the building as if afraid of the dark.  They block off much of the light from the windows, leaving very little to illuminate the stairs and the blossomed vines climbing their railings.</description>
    <description>Lozraet bushes grow close to the building, their berries harvested daily to create delectable desserts for Estate Holders.  Vines bearing brilliant white blossoms climb the railings of an ornate set of spiraling ironwork stairs leading to and from a small balcony above.</description>
    <position x="470" y="320" z="0" />
    <arc exit="north" move="north" destination="521" />
    <arc exit="south" move="south" destination="522" />
    <arc exit="southwest" move="southwest" destination="518" />
    <arc exit="west" move="west" destination="519" />
    <arc exit="northwest" move="northwest" destination="517" />
    <arc exit="climb" move="climb stone steps" destination="523" />
    <arc exit="climb" move="climb ironwork stairs" destination="635" />
  </node>
  <node id="521" name="Strand Communal Center, Gardens">
    <description>In the faint light coming from a window of the Community Center, roses droop sleepily atop a bower arcing over a stone bench.  Their faint odor floats on the air, mingled with the scent of dew on the grass and the nearby sea.</description>
    <description>The low drone of bees at work is constant, even when they are not visible.  Roses of crimson and pale pink cover a bower which arcs over a stone bench, their sweet scent tantalizing the noses of passers-by as much as it does the bees.</description>
    <position x="470" y="300" z="0" />
    <arc exit="south" move="south" destination="520" />
    <arc exit="southwest" move="southwest" destination="519" />
    <arc exit="west" move="west" destination="517" />
  </node>
  <node id="522" name="Strand Communal Center, Gardens">
    <description>Diamonds of light from the windows of the nearby building dapple a broad arbor as it curves around a nearby bench.  The air is scented with a mixture of floral tones and the salty ocean breeze.</description>
    <description>Bima vines climb a broad arbor affixed to the Center's side wall.  The tendrils attempt a daring escape up the textured stone, but the careful hand of the gardeners keeps them in check.  A stone bench rests underneath, its surface carved with many a whimsical rendering.  Tiny violets poke their heads above the manicured grass and bob merrily in any passing breeze.</description>
    <position x="470" y="340" z="0" />
    <arc exit="north" move="north" destination="520" />
    <arc exit="west" move="west" destination="518" />
    <arc exit="northwest" move="northwest" destination="519" />
  </node>
  <node id="523" name="Strand Communal Center, Herb Garden">
    <description>Lifted into the sky by gentle zephyrs, the faint aroma of herbs peppers the air from the growth around a shadowy path.  Buzzing insects enliven the still night atmosphere along with glimmering lights from the neighboring building.</description>
    <description>An abundance of herbs gathered from across the realms grow around a meandering cobblestone path.  Splitting and rejoining numerous times, the fitted stones wend their way almost haphazardly through the greenery.  The result is an intriguing way to effectively divide the various herbs from one another.</description>
    <position x="490" y="320" z="0" />
    <arc exit="up" move="up" destination="524" />
    <arc exit="climb" move="climb stone steps" destination="520" />
  </node>
  <node id="524" name="Strand Communal Center, Quiet Garden">
    <description>Merely a square of silky grass, the modest patch of land overlooks the rest of the property behind the Communal Center.  The natural carpet resembles an unfurling layer of black velvet.  Concave stone seats embedded in pairs in the ground allow nighttime visitors to relax under the stars.</description>
    <description>Merely a square of verdant grass, the modest patch of land overlooks the rest of the property behind the Communal Center.  The natural green carpet has been landscaped with a professional checkerboard pattern and remains free of intrusive weeds and dandelions.  Concave stone seats embedded in pairs in the ground allow visitors to relax in close proximity to the earth.</description>
    <position x="490" y="300" z="0" />
    <arc exit="down" move="down" destination="523" />
  </node>
  <node id="525" name="The Raven's Court, Foyer" note="Raven's Court">
    <description>Soft Ilithic carpetry, flanked by tiled marble flooring, muffles the sound of patrons entering and exiting the club.  Low tables are arrayed near the polished wooden walls, with plush high-backed chairs providing a place for members to chat with visiting guests.  Paintings of various Elanthian landscapes are placed aesthetically throughout the foyer, meshing with the rest of the decor to provide an aura of comfortable luxury.</description>
    <position x="-240" y="30" z="0" />
    <arc exit="north" move="north" destination="529" />
    <arc exit="northeast" move="northeast" destination="528" />
    <arc exit="east" move="east" destination="527" />
    <arc exit="west" move="west" destination="526" />
    <arc exit="go" move="go wooden door" destination="72" />
  </node>
  <node id="526" name="The Raven's Court, Membership Desk" note="Membership Desk">
    <description>This small room off the main foyer is dominated by a single oaken desk with stacks of paper neatly arrayed atop it.  Across the middle of the desk, a screen separates the clerk from the patrons, with a small opening in the middle so that items can be exchanged from within and without.</description>
    <position x="-250" y="30" z="0" />
    <arc exit="east" move="east" destination="525" />
  </node>
  <node id="527" name="The Raven's Court, Sun Room" note="Sun Room">
    <description>Walls of floor-to-ceiling windows reveal the nighttime darkness, each tall glass pane meticulously washed and pristinely free of smudges.  The plush Ilithic carpet recedes to unveil the smooth marble tiling, clean and glossy in the soft candlelight to complement the comfortable white leather couches and loveseats.  Enclosed by a short rail along the eastern border, the cozy room overlooks a quaint indoor pond, accessible by a small set of marble steps.</description>
    <description>Walls of floor-to-ceiling windows flood the space with daylight, each tall glass pane meticulously washed and pristinely free of smudges.  The plush Ilithic carpet recedes to unveil the smooth marble tiling, clean and bright in the sunlight to complement the comfortable white leather couches and loveseats.  Enclosed by a short rail along the eastern border, the cozy room overlooks a quaint indoor pond, accessible by a small set of marble steps.</description>
    <position x="-230" y="30" z="0" />
    <arc exit="west" move="west" destination="525" />
    <arc exit="climb" move="climb small steps" destination="1004" />
  </node>
  <node id="528" name="The Raven's Court, Ballroom">
    <description>Music seems to linger in the air of the ballroom, echoing from the parquet floor and crystal chandeliers.  Candlelight reflects off the stained glass windows, which encircle the ceiling.  Along the western wall, a screen conceals a small musician's gallery.</description>
    <description>With a heavily arched ceiling from which three massive crystal chandeliers hang, the ballroom has been designed to have excellent acoustics throughout the large space.  Colored light streams in through stained glass panels placed carefully across the ceiling, drawing attention towards the main floor.  A small screen is positioned discreetly along the western wall.</description>
    <position x="-230" y="20" z="0" />
    <arc exit="southwest" move="southwest" destination="525" />
    <arc exit="northwest" move="northwest" destination="529" />
    <arc exit="go" move="go glass doors" destination="546" />
  </node>
  <node id="529" name="The Raven's Court, Dining Room" note="Dining Room">
    <description>Crafted crystal glassware, delicately gilded china and elegant silver adorn each of the dozens of polished ebony tables in the large dining room.  A detailed menu rests upon a carved goldenoak easel along the wall closest to the foyer, visible to patrons before they have been seated.  Ringing the walls of the room is a well-maintained water garden, with small fountains emitting the soothing sound of gently splashing water at each corner.</description>
    <description>Crafted crystal glassware, delicately painted china and elegant silver adorn each of the dozens of polished ebony tables in the large dining room.  A menu is posted discreetly along the wall closest to the foyer, visible to patrons before they have been seated.  Ringing the walls of the room is a well-maintained water garden, small fountains emitting the soothing sound of gently splashing water at each corner.</description>
    <position x="-240" y="10" z="0" />
    <arc exit="southeast" move="southeast" destination="528" />
    <arc exit="south" move="south" destination="525" />
    <arc exit="west" move="west" destination="530" />
    <arc exit="climb" move="climb marble steps" destination="532" />
  </node>
  <node id="530" name="The Raven's Court, Kitchen">
    <description>No expense has been spared in supplying this immaculate kitchen with the modern technological advances necessary to create high-class Elanthian dining.  With room for two dozen chefs, one particular station stands out near the middle of the kitchen.  Twice as large as the others and ringed with heavily customized tools, it is surrounded by the mingling aromas of exquisitely prepared dishes.</description>
    <position x="-250" y="10" z="0" />
    <arc exit="east" move="east" destination="529" />
    <arc exit="south" move="south" destination="531" />
    <arc exit="go" move="go oaken door" destination="543" />
  </node>
  <node id="531" name="The Raven's Court, Pantry">
    <description>This massive pantry is stocked to the brim with exotic spices, packaged meats and baked goods, creating a cornucopia of scents warring for attention.  The air in the room is quite cool, aiding in maintaining the freshness of the food stocked within.  However, a near complete lack of dust indicates the constant use and replacement of every single object the Raven's Court has stored away.</description>
    <position x="-250" y="20" z="0" />
    <arc exit="north" move="north" destination="530" />
    <arc exit="go" move="go ironwood door" destination="545" />
  </node>
  <node id="532" name="The Raven's Court, Landing">
    <description>A portrait of the Raven's Court founders watches over members and guests as they reach the landing, its golden frame gleaming softly in the light from the dining room below.  Luscious crimson roses have been arranged in a crystal bowl atop a narrow mahogany table, their floral perfume mixing with the smell of the beeswax polish.</description>
    <position x="-240" y="-10" z="0" />
    <arc exit="climb" move="climb marble steps" destination="529" />
    <arc exit="climb" move="climb marble staircase" destination="533" />
  </node>
  <node id="533" name="The Raven's Court, Gallery Lobby" note="Gallery Lobby">
    <description>Colored a rich forest green, the painted walls retain an elegant matte finish to contrast with the gleaming polish of the golden oak wainscoting.  Padded benches border the area to provide seating for patrons who wish a brief respite from perusing the selection of fine art on display throughout the rest of the gallery.  Plush black carpeting cushions every footfall and dulls noise to allow for quiet observation and contemplation.</description>
    <position x="-290" y="-10" z="0" />
    <arc exit="south" move="south" destination="534" />
    <arc exit="southwest" move="southwest" destination="535" />
    <arc exit="climb" move="climb marble staircase" destination="532" />
  </node>
  <node id="534" name="The Raven's Court, Gallery">
    <description>Colored a rich forest green, the painted walls retain an elegant matte finish to contrast with the gleaming polish of the golden oak wainscoting.  Sculpted gaethzen orbs dangle strategically over each piece of artwork to provide ample lighting for the Court's treasures.  Plush black carpeting cushions every footfall and dulls noise to allow for quiet observation and contemplation.  An ornately gilded balustrade runs along the southern edge of the area, permitting patrons to survey the foyer below.</description>
    <position x="-290" y="0" z="0" />
    <arc exit="north" move="north" destination="533" />
    <arc exit="west" move="west" destination="535" />
  </node>
  <node id="535" name="The Raven's Court, Gallery">
    <description>Colored a rich forest green, the painted walls retain an elegant matte finish to contrast with the gleaming polish of the golden oak wainscoting.  Sculpted gaethzen orbs dangle strategically over each piece of artwork to provide ample lighting for the Court's treasures.  Plush black carpeting cushions every footfall and dulls noise to allow for quiet observation and contemplation.  An ornately gilded balustrade runs along the southeastern edge of the area, permitting patrons to survey the foyer below.</description>
    <position x="-300" y="0" z="0" />
    <arc exit="northeast" move="northeast" destination="533" />
    <arc exit="east" move="east" destination="534" />
    <arc exit="south" move="south" destination="536" />
  </node>
  <node id="536" name="The Raven's Court, Gallery">
    <description>Colored a rich forest green, the painted walls retain an elegant matte finish to contrast with the gleaming polish of the golden oak wainscoting.  Sculpted gaethzen orbs dangle strategically over each piece of artwork to provide ample lighting for the Court's treasures.  Plush black carpeting cushions every footfall and dulls noise to allow for quiet observation and contemplation.  An ornately gilded balustrade runs along the eastern edge of the area, permitting patrons to survey the foyer below.</description>
    <position x="-300" y="10" z="0" />
    <arc exit="north" move="north" destination="535" />
    <arc exit="south" move="south" destination="537" />
  </node>
  <node id="537" name="The Raven's Court, Gallery">
    <description>Colored a rich forest green, the painted walls retain an elegant matte finish to contrast with the gleaming polish of the golden oak wainscoting.  Sculpted gaethzen orbs dangle strategically over each piece of artwork to provide ample lighting for the Court's treasures.  Plush black carpeting cushions every footfall and dulls noise to allow for quiet observation and contemplation.  An ornately gilded balustrade runs along the northeastern edge of the area, permitting patrons to survey the foyer below.</description>
    <position x="-300" y="20" z="0" />
    <arc exit="north" move="north" destination="536" />
    <arc exit="east" move="east" destination="538" />
  </node>
  <node id="538" name="The Raven's Court, Gallery">
    <description>Colored a rich forest green, the painted walls retain an elegant matte finish to contrast with the gleaming polish of the golden oak wainscoting.  Sculpted gaethzen orbs dangle strategically over each piece of artwork to provide ample lighting for the Court's treasures.  Plush black carpeting cushions every footfall and dulls noise to allow for quiet observation and contemplation.  An ornately gilded balustrade runs along the northern edge of the area, permitting patrons to survey the foyer below.</description>
    <position x="-290" y="20" z="0" />
    <arc exit="west" move="west" destination="537" />
    <arc exit="go" move="go gold arch" destination="539" />
  </node>
  <node id="539" name="The Raven's Court, Bejeweled Nook" color="#00FFFF">
    <description>Glossy vermilion paint floods the walls with dominant color, coordinating brightly with the polished golden oak wainscoting.  An end table resting in one corner supports a shiny bowl filled with mock fruit, each piece smothered in gemstones that sparkle radiantly under the soft glow of the red crystal chandelier overhead.  Fashioned into the shape of a carved ruby, the thick area rug upon the hardwood floor features lines of silver and indigo to highlight the faceting.</description>
    <position x="-280" y="20" z="0" />
    <arc exit="north" move="north" destination="540" />
    <arc exit="go" move="go gold arch" destination="538" />
  </node>
  <node id="540" name="The Raven's Court, Bejeweled Nook" color="#00FFFF">
    <description>Colored a deep midnight hue, the walls create a subdued backdrop brightened only by the polished golden oak wainscoting that migrates inward from the surrounding rooms.  Motes of muted light from the blue crystal chandelier trickle downward, speckling the gemstone-encrusted urn resting in the corner with an ethereal mist of illumination.  The smooth area rug underfoot mimics a carved sapphire, enhanced with starbursts of white along the facet angles.</description>
    <position x="-280" y="10" z="0" />
    <arc exit="east" move="east" destination="541" />
    <arc exit="south" move="south" destination="539" />
  </node>
  <node id="541" name="The Raven's Court, Bejeweled Nook" color="#00FFFF">
    <description>Pristinely white, the walls almost seem to glow in the light shed by the transparent crystal chandelier, dangling overhead as the ceiling's centerpiece.  The polished golden oak wainscoting, too, obtains a soft halo effect from the lambent illumination, while the clear glass harp in the corner gleams as brightly as ever.  Crafted with perfect symmetry, the plush area rug resembles a cut diamond, its edges and facets delineated by bold black lines.</description>
    <position x="-270" y="10" z="0" />
    <arc exit="west" move="west" destination="540" />
    <arc exit="go" move="go velvet curtain" destination="542" />
  </node>
  <node id="542" name="The Raven's Court, Iolite Lounge" note="Iolite Lounge">
    <description>Beset with limpid jewels, large gaethzen orbs swell outward from the ceiling.  Each spills several strands of faceted iolite stones, meant to disseminate the light through twinkles of lavender and violet.  Luxury and regality abound in the secluded space, evidenced by the border of connected couches and layer of plush carpeting.  Though designed to nurture conversation and relaxation, the lounge does offer a modest supply of specialty items for the discerning patron upon a small silverwood table.</description>
    <position x="-270" y="20" z="0" />
    <arc exit="go" move="go velvet curtain" destination="541" />
  </node>
  <node id="543" name="The Raven's Court, Kitchen Garden">
    <description>The cooking staff prides itself on offering a premium selection of the freshest vegetables for sating the palates of its patrons, evidenced here by the wide variety of produce under protective glass row covers.  The Court's owners have spared no expense for the maintenance of the miniature greenhouses lining the area, ensuring the plants are safe from the nibbling mouths of the local rabbit population.</description>
    <position x="-260" y="10" z="0" />
    <arc exit="north" move="north" destination="544" />
    <arc exit="go" move="go oaken door" destination="530" />
  </node>
  <node id="544" name="The Raven's Court, Herb Garden" note="Garden of Herbs">
    <description>A flagstone walk winds past shadowy plant beds on its course through this tiny garden.  The subtle aromas of a mix of tasty and fragrant herbs linger in the air, indicating the presence of lavender, violet, sage, garlic and rosemary.  Creeping thyme cushions the space between the flagstones, evident from its perfume filling the air with each step.  A rustic stone bench surrounded by mint provides a quiet spot to rest in the darkness of night.</description>
    <description>A flagstone walk winds past well-kept plant beds on its course through this tiny garden.  The aroma of lavender and violets blends with sage, garlic and rosemary in a copious collection of tasty and fragrant herbs.  Creeping thyme cushions the space between the flagstones, its perfume filling the air with each step.  A rustic stone bench surrounded by mint provides a quiet spot to rest.</description>
    <position x="-260" y="0" z="0" />
    <arc exit="south" move="south" destination="543" />
  </node>
  <node id="545" name="The Raven's Court, Scullery">
    <description>Massive stone sinks are stationed along the wall for use by the service staff, designed to accommodate large loads of dishes used in the kitchen and dining room of the Court.  The room is quiet at the moment, the basins scrubbed clean and the tableware stored in cabinets until the next meal.</description>
    <position x="-260" y="30" z="0" />
    <arc exit="go" move="go ironwood door" destination="531" />
    <arc exit="none" move="go trapdoor" destination="861" />
  </node>
  <node id="546" name="The Raven's Court, Terrace">
    <description>An elegant rose garden borders this brick terrace along the side of the Raven's Court, the fragrance of flowers perfuming the air.  A fine mesh is strung overhead, providing further shade in moonlight, while marble benches edging the terrace perhaps enable companions to enjoy a quiet, romantic moment.</description>
    <description>An elegant rose garden borders this brick terrace along the side of the Raven's Court, the fragrance of flowers perfuming the air.  The sun is filtered through a fine mesh strung overhead, allowing for enjoyment of its rays while keeping the area's temperature pleasant.  Marble benches edge the terrace, providing a place for club patrons to relax and converse with their friends.</description>
    <position x="-200" y="20" z="0" />
    <arc exit="north" move="north" destination="547" />
    <arc exit="southwest" move="southwest" destination="551" />
    <arc exit="northwest" move="northwest" destination="549" />
    <arc exit="go" move="go glass doors" destination="528" />
  </node>
  <node id="547" name="The Raven's Court, Rock Garden" note="Rock Garden">
    <description>Towering oaks provide a deep carpet of shadow when moonlight strains to break through the foliage.  Weathered rocks are made visible by shaded lanterns casting their light across the path, providing an aura of safety and security as the flagstones wind up this small hill behind the Raven's Court.</description>
    <description>The flagstone path meanders up a small hill behind the Raven's Court, while lush oaks overhead provide a carpeting of shade.  Nestled under the protective embrace of the greenery, an array of weathered rocks dots the hill on either side of the path.  Green mosses and small flowers cling to the rocks, creating a splash of natural beauty while still appearing to enjoy the same level of care visible everywhere in the Court.</description>
    <position x="-200" y="10" z="0" />
    <arc exit="north" move="north" destination="548" />
    <arc exit="south" move="south" destination="546" />
  </node>
  <node id="548" name="The Raven's Court, Quiet Pool">
    <description>Just as the hill seems about to crest, it dips in the center to reveal a small hollow.  Nestled under the great oaks is a clear pool, disturbed only by the occasional fallen leaf.  A small deck, as well as several lounge chairs and mats, surrounds the pool, providing another peaceful opportunity for club patrons to relax.  A small sign is posted right at the edge of the pool's deck.</description>
    <position x="-200" y="0" z="0" />
    <arc exit="south" move="south" destination="547" />
  </node>
  <node id="549" name="The Raven's Court, Silver Walk" note="Raven Thief">
    <description>The flagstones, made with silver coating atop more traditional rocks, shimmer beneath your feet in the moonlight.  Shadows cast by large oaks are countered by shuttered lanterns, and a large arched door is visible ahead, set into the side of the back end of the Raven's Court.  A small slot is visible in the door at about eye level, a large golden knocker taking the place of a handle.  A very prominent sign is placed out in front of the door.</description>
    <description>The flagstones, made with silver coating atop more traditional rocks, glitter beneath your feet in the sunlight.  Large oaks provide shade while a large arched door is visible ahead, set into the side of the back end of the Raven's Court.  A small slot is visible in the door at about eye level, a large golden knocker taking the place of a handle.  A very prominent sign is placed out in front of the door.</description>
    <position x="-220" y="0" z="0" />
    <arc exit="southeast" move="southeast" destination="546" />
    <arc exit="west" move="west" destination="550" />
    <arc exit="none" move="knock knocker" destination="552" />
    <arc exit="none" move="tap knocker" destination="576" />
  </node>
  <node id="550" name="The Raven's Court, Garden of Midnight" note="Garden of Midnight">
    <description>Tall boxwood hedges enclose the area, shielding the flora from all but the softest starlight.  A striking statue stands in the very middle, the silvery flagstone path unfurling outward in a large spiral from the center.  Slender beds of midnight glories fill the coil's twisting gaps, matched by a stunning arrangement of Dergati's Night blossoms encircling the shadowy sculpture.</description>
    <description>Tall boxwood hedges enclose the area, shading the flora from the garish light of day.  A striking black jade statue stands in the very middle, the silvery flagstone path unfurling outward in a large spiral from the center.  Slender beds of midnight glories fill the coil's twisting gaps, matched by a curious arrangement of dark withered buds encircling the shadowy sculpture.</description>
    <position x="-230" y="0" z="0" />
    <arc exit="east" move="east" destination="549" />
    <arc exit="go" move="go hole" destination="859" />
  </node>
  <node id="551" name="The Raven's Court, Rose Garden" note="Rose Garden">
    <description>Roses of all colors grow in carefully tended beds, many mixed in with each other to build a vibrant tapestry of petals.  To the north, delicate white petals arranged in a half moon form a bed of Damaris' Dream, while to the west a flurry of pinks indicates the presence of Hodierna's Blush.  Lastly, a cluster of Smaragdaus' Glee forms a sea of crimson to the south.  A small path winds around the garden, with a wooden sign posted at the entry.</description>
    <position x="-210" y="30" z="0" />
    <arc exit="northeast" move="northeast" destination="546" />
  </node>
  <node id="552" name="The Raven's Court, VIP Suite" note="VIP Suite">
    <description>A large bar, fully stocked with an array of strong and exotic liqueurs, dominates the back side of this member's suite.  While plush stools are available, there are also an elegant fireplace and large ebony table surrounded by high-backed chairs on each side.  Sharply dressed waiters attend to each patron's needs immediately, weaving their way around priceless vases and past ancient paintings, simply another example of the opulence afforded to the Raven's Court's members.</description>
    <position x="-220" y="-10" z="0" />
    <arc exit="north" move="north" destination="554" />
    <arc exit="west" move="west" destination="553" />
    <arc exit="go" move="go ebony door" destination="549" />
    <arc exit="go" move="go satin curtain" destination="562" />
  </node>
  <node id="553" name="The Raven's Court, Cigar Lounge" note="Cigar Lounge">
    <description>Smoke fills the air as members relax with their drinks and discuss the day's trades in confident tones.  The major deals of the lands are made not in the banking halls or guilds, but amidst the pungent haze in the lounge's comfortable leather chairs.  Gnarled arms of iron candelabra reach upward to endow the area with just enough light so as to not disturb tired eyes.</description>
    <position x="-230" y="-10" z="0" />
    <arc exit="north" move="north" destination="555" />
    <arc exit="east" move="east" destination="552" />
  </node>
  <node id="554" name="The Raven's Court, Brandy Bar" note="Brandy Bar">
    <description>Aged wooden casks support caramel-colored glass tops to create makeshift tables interspersed between the comfortable leather chairs.  Each barrel bears official stamps from foreign lands, indicating only the finest imports are served to the Court's exclusive members.  Deep burgundy carpeting stretches between the black marble walls to immerse patrons in extravagance from all angles.  Dozens of glass snifters hang over a fine-grained goldenoak bar dominating the eastern half of the room.</description>
    <position x="-220" y="-20" z="0" />
    <arc exit="north" move="north" destination="556" />
    <arc exit="south" move="south" destination="552" />
    <arc exit="west" move="west" destination="555" />
    <arc exit="go" move="go curtained archway" destination="561" />
  </node>
  <node id="555" name="The Raven's Court, Entertainment Room" note="Entertainment Room">
    <description>A babble of noise greets those who enter the spacious room, from the quiet thud of well-aimed darts, to the tinkle of glasses, to the low murmur of voices as players strategize.  Challengers and onlookers gather around an armwrestling table in the center, while others observe and converse in one of the many leather chairs positioned near the gaming apparatuses.  Long mirrors placed along the upper halves of the black marble walls trick the eye into thinking the area is larger than its actual size.</description>
    <position x="-230" y="-20" z="0" />
    <arc exit="east" move="east" destination="554" />
    <arc exit="south" move="south" destination="553" />
  </node>
  <node id="556" name="The Raven's Court, Gamblers' Den" note="Gamblers' Den">
    <description>Clinking sounds of metal on metal follow the exchange of coins between hands at the various tables set up for card and dice games.  Two deep-backed couches line the sides, set against the black marble walls as a means of surveying the action while enjoying a beverage or two.  The occasional cheer peppers the air from the direction of the gleaming silver-trimmed slot machine in the corner.</description>
    <position x="-220" y="-30" z="0" />
    <arc exit="north" move="north" destination="557" />
    <arc exit="south" move="south" destination="554" />
    <arc exit="go" move="go adderwood door" destination="560" />
  </node>
  <node id="557" name="The Raven's Court, Hallway" color="#00FFFF">
    <description>Barely audible tones of laughter drift in from the rest of the club, yet the area here remains mostly quiet and calm.  Along the smooth marble walls, flecks of glowstone shine inside the images of stars and moons formed from inlays of yellow diamond.  Errant rays of light filter inward from the south, giving the plush black carpet a slight sheen.</description>
    <position x="-220" y="-40" z="0" />
    <arc exit="east" move="east" destination="558" />
    <arc exit="south" move="south" destination="556" />
    <arc exit="west" move="west" destination="559" />
  </node>
  <node id="558" name="The Raven's Court, Hallway" color="#00FFFF">
    <description>Channels of green diamond sprout into lily pads and frogs upon the smooth marble walls.  Tiny orbs of glowstone highlight the colorful jewels in addition to providing faint illumination for the dark, secluded corner.  Black as an ocean abyss, the plush carpeting underfoot appears to extend forever downward into endless depths.</description>
    <position x="-210" y="-40" z="0" />
    <arc exit="west" move="west" destination="557" />
    <arc exit="north" destination="949" />
  </node>
  <node id="559" name="The Raven's Court, Hallway" color="#00FFFF">
    <description>Grooves inlaid with blue diamond stream through the smooth marble walls, outlining raindrops and snowflakes.  Nestled amidst the precipitation, tiny dots of glowstone cast a delicate radiance in the otherwise dark corner.  The plush wall-to-wall carpet is completely black, creating the illusion of walking in space.</description>
    <position x="-230" y="-40" z="0" />
    <arc exit="east" move="east" destination="557" />
    <arc exit="north" destination="947" />
  </node>
  <node id="560" name="The Raven's Court, Artist's Parlor" note="Artist's Parlor" color="#FF8000">
    <description>Away from the busy sounds of the rest of the club, this small room offers solace for the creatively gifted.  Opposite a small stool, a long leather divan provides space for a muse to model various sitting or lying poses, as does the white bearskin rug upon the floor.  Filled with lush red roses, a golden vase decorates the adderwood desk adjacent to the door.</description>
    <position x="-210" y="-30" z="0" />
    <arc exit="go" move="go adderwood door" destination="556" />
  </node>
  <node id="561" name="The Raven's Court, Library">
    <description>Maps cover the black marble walls, showing the major trade routes and local cities.  Brass lamps with green glass domes rest atop square tables to bequeath modest light for reading activities.  A trio of leather couches aids leisurely pursuits, while a broad smokewood desk and matching chair allow for more diligent studies.  Shadowed in one corner, a secluded alcove appeals to those who seek a more private atmosphere.</description>
    <position x="-210" y="-20" z="0" />
    <arc exit="go" move="go curtained archway" destination="554" />
    <arc exit="go" move="go secluded alcove" destination="950" />
  </node>
  <node id="562" name="The Raven's Court, Commodities" note="Cigar Shop" color="#FF0000">
    <description>Deluging the area in ambient light, glowstone veins in the ceiling compose the elegant outline of a raven with outstretched wings.  The pattern extends to the black marble walls, where feathers detailed from the same illuminator flutter downward, stopping just before they land on the gilded cases lining the area.  A faint, smoky sweetness lingers in the air like the fading impression of a snuffed cigar.</description>
    <position x="-210" y="-10" z="0" />
    <arc exit="go" move="go satin curtain" destination="552" />
  </node>
  <node id="563" name="Traders' Guild, Cellars">
    <description>Giant bins, huge wooden barrels and piles of overstuffed hogsheads all await distribution to their final retail destination or to warehouses and shippers around town for export to far corners of Elanthia.</description>
    <position x="-160" y="30" z="0" />
    <arc exit="up" move="up" destination="359" />
  </node>
  <node id="564" name="Traders' Guild, Pure's Feed Emporium" note="Pure's Feed Emporium">
    <description>The scent of grains and cut grass permeates the room.  A broad straw broom and long-handled dustpan are propped against sacks of grain that have been neatly arranged along the back wall.  The worn mahogany floors show signs of frequent use.  A faint chirping emanates from somewhere inside the grass bin.</description>
    <position x="-170" y="20" z="0" />
    <arc exit="go" move="go swinging doors" destination="359" />
  </node>
  <node id="565" name="Traders' Guild, Guest Suite">
    <description>The suite is reserved for the elite of the Traders' Guild governing hierarchy, particularly those outlanders visiting the Guild headquarters on business.  The walls are paneled with rich, dark huljik wood, oiled to a fine sheen.  A mahogany writing table, decked with a silver inkwell and eagle quill stands before a tall bay window which affords a panoramic view of the town's commercial district.  A high, carved sleigh bed faces the window, flanked by nightstands holding books on trade and travel.</description>
    <position x="-150" y="-30" z="0" />
    <arc exit="go" move="go mahogany door" destination="355" />
  </node>
  <node id="566" name="Traders' Guild, Vault" note="Negotiants">
    <description>The vault walls are clad in thick steel plates, one of which has been engraved commissioned from Catrox the Smith.  Locked chests of various sizes, with members' names on them, are neatly stacked in metal racks.  You are being watched by the Gor'Tog guard through a narrow, almost imperceptible gap between two of the plates.</description>
    <position x="-140" y="20" z="0" />
    <arc exit="go" move="go steel door" destination="360" />
  </node>
  <node id="567" name="Traders' Guild, Wholesale Outlet" note="Wholesale Outlet|Trader Shop" color="#FF0000">
    <description>Plain fittings display luxury goods from the farthest corners of the realms, but this wholesaler makes no attempt to puff up the goods or cajole the buyers.  This is a place where professionals do business with other professionals, all of whom know and disdain the weaseling tricks commonly played on customers.  Displays are sturdy and pleasant, but not fancy, and everything is brightly lit.  Rugs are a plain brown, walls are an unpanelled beige, and the atmosphere is one of business.</description>
    <position x="-150" y="20" z="0" />
    <arc exit="out" move="out" destination="356" />
  </node>
  <node id="568" name="Haldofurd's Barn, Caravan Stable" note="Caravan Stable" color="#00FF00">
    <description>Light filters through the open double doors illuminating the clean, whitewashed expanse of the barn's walls and dozens of spacious stalls line the interior, each thickly carpeted with fresh straw.  Stable boys bustle about filling water troughs and currying road dust from newly-arrived pack animals under the watchful supervision of equally dusty caravan drivers.</description>
    <position x="-230" y="-408" z="0" />
    <arc exit="out" move="out" destination="113" />
  </node>
  <node id="569" name="Crossing, West Wall Battlements">
    <description>This hastily made lean-to is constructed of thin pine boards nailed to a poplar frame, with a water-resistant tarpaulin tacked across the top for a roof.  There is a pervasive musty odor that almost masks the fetid smell rising from the city below.  Bare and damp, there isn't even a discarded crate to sit upon.</description>
    <position x="-361" y="-288" z="0" />
    <arc exit="out" move="out" destination="399" />
  </node>
  <node id="570" name="Falken's Tannery, Vat Room">
    <description>Heaps of uncured pelts lie festering around a huge wooden vat at the center of the room.  Several young Gor'Togs, who seem oblivious to the stench, lumber about, tending to the tanning process.  Bubbles and fume spew forth from the vat each time they toss in a skin.  As you poke at a pile of hides awaiting tanning with your foot, you raise a storm of horseflies.</description>
    <position x="-30" y="-478" z="0" />
    <arc exit="go" move="go sturdy door" destination="220" />
  </node>
  <node id="571" name="MAMAS Company, Main Office" note="MAMAS" color="#00FF00">
    <description>The Assay Office looks like a contractor's storeroom: scaffolding, loose timbers, planks, and tools lie everywhere, as carpenters and plasterers work away.  Behind a tin-topped counter stands the assay clerk, who is adjusting the beam of the smallest of three graduated scales.</description>
    <position x="210" y="7" z="0" />
    <arc exit="out" move="out" destination="161" />
  </node>
  <node id="572" name="A Damp Cavern">
    <description>A series of yellowing wooden planks zigzag across a pitted cavern floor.  Water drips slowly from the darkened roof above, plinking in pools of lime green water.  Bulbous yellow eyes stare unwinking at you from small nooks in granite walls.</description>
    <position x="-380" y="0" z="0" />
    <arc exit="east" move="east" destination="439" />
    <arc exit="west" move="west" destination="573" />
    <arc exit="go" move="go space" destination="574" />
  </node>
  <node id="573" name="A Damp Cavern">
    <description>This dark, muddly corridor looks like an intestinal tract lined with roughage.  It smells like one, too.  Perhaps it's all the decaying vegetation or just the rats that seem to come here solely to die, but the fumes alone could crack leather armor.</description>
    <position x="-390" y="0" z="0" />
    <arc exit="east" move="east" destination="572" />
    <arc exit="go" move="go dark hole" hidden="True" destination="857" />
  </node>
  <node id="574" name="Thieves' Guild, Hallway" note="Thief|Bin">
    <description>Sculpted hooks of peridot-studded basalt hold brightly lit oil lamps.  A long rug woven with a wandering nightshade pattern partially covers the obsidian tiles underfoot, cushioning footfalls that would otherwise echo along the hall.  Tapestries grace the walls, many displaying silver-threaded moonlit cityscapes.  Across from a heavy ebonwood door, a bored-looking human boy sits beside a shadowy azurite bin.</description>
    <position x="-280" y="-100" z="0" />
    <arc exit="north" move="north" destination="575" />
    <arc exit="south" move="south" destination="576" />
    <arc exit="go" move="go niche" destination="572" />
    <arc exit="go" move="go ebonwood door" destination="579" />
  </node>
  <node id="575" name="Thieves' Guild, Hallway">
    <description>Lit by grey-tinted oil lamps is a broad ebonwood arch carved with a midnight cityscape, a narrow steel doorway and a thick wooden door propped open with a brass spittoon.  Overhead is a clouded glass mosaic skylight that matches the grey silk curtain leading to a shop along the northeast corner of the hall.</description>
    <position x="-280" y="-110" z="0" />
    <arc exit="south" move="south" destination="574" />
    <arc exit="go" move="go silk curtain" destination="580" />
    <arc exit="go" move="go wooden door" destination="583" />
    <arc exit="go" move="go steel doorway" destination="584" />
    <arc exit="go" move="go arch" destination="901" />
  </node>
  <node id="576" name="Thieves' Guild, Foyer">
    <description>Smooth tiles of gleaming obsidian reflect the rich burgundy hue of the papered walls from below a clouded glass skylight.  A copperwood table, its rich grain glinting with swirls of its namesake mineral, supports a dark stone vase filled with lush, blood-red roses.  Tall candlesticks of lustrous rosewood support white beeswax candles whose flickering light illuminates the room.</description>
    <description>Smooth tiles of gleaming obsidian reflect the rich burgundy hue of the papered walls.  A copperwood table, its rich grain glinting with swirls of its namesake mineral, supports a dark stone vase filled with lush, blood-red roses.  Overhead, a skylight of clouded glass allows sunlight to filter in.</description>
    <position x="-280" y="-90" z="0" />
    <arc exit="north" move="north" destination="574" />
    <arc exit="go" move="go black archway" destination="577" />
    <arc exit="go" move="go ebony door" destination="549" />
    <arc exit="go" move="go lattice grate" destination="97" />
  </node>
  <node id="577" name="Thieves' Guild, Library" note="Thief Library">
    <description>Hooded candles cast a dim glow about the spacious chamber, the light enhancing the polished shine of the silverwood bookcase holding the Guild's library.  A deep-piled grey rug under several hardwood desks and chairs dulls harsh sounds and helps provide a quiet place for guests and regulars to study in peace and safety.</description>
    <position x="-270" y="-90" z="0" />
    <arc exit="east" move="east" destination="578" />
    <arc exit="go" move="go black archway" destination="576" />
  </node>
  <node id="578" name="Thieves' Guild, Rescued Artifact Exhibition">
    <description>Lining the curved walls, a series of raised cases outfit the dark, circular sanctum.  Thick black carpet stretches across the entire expanse of floor to maintain an aura of almost reverent silence.  Small glowstones set into the ceiling offer focused illumination only for the items on display.  A miniature skylight in the domed ceiling is precisely located above one of the cases, providing little light for the rest of the room.</description>
    <position x="-260" y="-90" z="0" />
    <arc exit="west" move="west" destination="577" />
  </node>
  <node id="579" name="Thieves' Guild, Office" note="GL Thief|Kalag|Varsyth" color="#FF8000">
    <description>Painted pale blue with thin stripes of dark sapphire, the walls of this spacious office hold tapestries and wall hangings from exotic locales around Elanthia.  The room is dominated by a mahogany desk with a high-backed leather armchair behind it.</description>
    <position x="-270" y="-100" z="0" />
    <arc exit="go" move="go ebonwood door" destination="574" />
  </node>
  <node id="580" name="Thieves' Guild, Shop" note="Thief Shop" color="#FF0000">
    <description>An odd assortment of wares is on display for sale here, cluttering the smooth wooden floors protected by small woven hemp rugs.  A candelabrum of white beeswax candles high above illuminates the shop.</description>
    <position x="-290" y="-110" z="0" />
    <arc exit="north" move="north" destination="582" />
    <arc exit="south" move="south" destination="581" />
    <arc exit="go" move="go silk curtain" destination="575" />
  </node>
  <node id="581" name="Thieves' Guild, Shop">
    <description>Paneled deobar walls bear a variety of goods for sale.  A scrollwork rack and a smooth deobar shelf jut from the wood, displaying their wares at a slight angle.  Nearby, a coat rack, a brass stand and a low table sit across the room from a wide-mouthed barrel.  A woven spidersilk rug covers the polished hardwood floors.</description>
    <position x="-290" y="-100" z="0" />
    <arc exit="north" move="north" destination="580" />
  </node>
  <node id="582" name="Thieves' Guild, Shop">
    <description>Paneled walls match the hardwood floor here, though little is on display besides an open weapon crate atop a woven rug in the center of the room.  Overhead, the candlelight from the candelabra flickers slightly with the bustle of the occasional clerk.</description>
    <position x="-290" y="-120" z="0" />
    <arc exit="south" move="south" destination="580" />
  </node>
  <node id="583" name="Thieves' Guild, Alchemy Kitchen">
    <description>Below a centrally located skylight sits a Wayerd pyramid.  A thick column of leaded glass obscures the view to the outside world without blocking sunlight to the pyramid during the day.  A wide iron stove sits beside a fountain fed by a steady stream of water pouring from the wall.  Nestled within it is a water clock.</description>
    <position x="-270" y="-120" z="0" />
    <arc exit="go" move="go wooden door" destination="575" />
  </node>
  <node id="584" name="Thieves' Guild, Training Room">
    <description>Limestone floors, buffed but completely bare, indicate this room is more function than form.  Brightly lit oil lamps hang in abundance, the glare a definite change from the more subdued ambiance of the rest of the guild.  In the center of the room is an iron table surrounded by sturdy chairs.  A polished silver bucket sits to one side.</description>
    <position x="-280" y="-120" z="0" />
    <arc exit="go" move="go steel doorway" destination="575" />
  </node>
  <node id="585" name="Ranger Guild, Main Hall" note="GL Ranger|Kalika|RS Ranger" color="#FF8000">
    <description>The Main Hall lacks a permanent roof and is open to the wide sky in all but the harshest weather.  Atop the rear wall is a canvas canopy that can serve as a cover for the Hall when needed.  Several well-polished bows line the walls and a banner at the far end of the long room displays the guild emblem.  A large picture window provides a view of the grove behind the Hall.</description>
    <position x="-110" y="-488" z="0" />
    <arc exit="out" move="out" destination="337" />
    <arc exit="go" move="go open archway" destination="586" />
    <arc exit="go" move="go lunat door" destination="587" />
  </node>
  <node id="586" name="Ranger Guild, Storeroom">
    <description>This small storage area contains shelves to hold a variety of tools and supplies used by rangers in their explorations.  Guild members leave items here for their comrades who may need them, and the only expected payment is that the favor be returned whenever possible.  In the corner, a sturdy cabinet dispensing essential herbs is hung on the wall above a weapons rack.</description>
    <position x="-110" y="-498" z="0" />
    <arc exit="go" move="go open archway" destination="585" />
  </node>
  <node id="587" name="Ranger Guild, Tree Grove">
    <description>Nature's soothing embrace surrounds this private reserve of young felenok pines.  The rare trees bear golden-tipped cones and the aromatic scent of their needles fills the air.  Near the center of the grove, a mature pine rises majestically above the others, its branches supporting a small treehouse that is accessed by a dangling rope.  A tattered note is tacked to the wall of the guildhall between the large picture window and the door.</description>
    <position x="-120" y="-488" z="0" />
    <arc exit="west" move="west" destination="588" />
    <arc exit="go" move="go lunat door" destination="585" />
    <arc exit="climb" move="climb large rope" destination="589" />
  </node>
  <node id="588" name="Ranger's Guild, West Tree Grove">
    <description>The large trees that soar to the sky are home to the songs of several species of birds.  High above, their branches weave together to create a soothing green canopy.  Below, roots that bulge from the ground are bedded with leaves, twigs, and ferns, offering a silent invitation to a comfortable rest.  A few deer pause in their feeding to look around, before moving on to consume nearby flora.</description>
    <position x="-130" y="-488" z="0" />
    <arc exit="east" move="east" destination="587" />
  </node>
  <node id="589" name="Ranger's Guild, The Tree House">
    <description>In an effort not to hurt the tree, the wall supports of this large room built among the branches and leaves are lashed instead of nailed.  Several simple chairs offer a comfortable seat for those that choose to rest here.  A small ladder climbs up to another room and a large rope dangling through a hole in the floorboards leads back down to the ground.</description>
    <position x="-120" y="-498" z="0" />
    <arc exit="climb" move="climb large rope" destination="587" />
    <arc exit="climb" move="climb small ladder" destination="590" />
  </node>
  <node id="590" name="Ranger's Guild, The Tree House">
    <description>This plain room is made comfortable with several fluffy bear pelts strewn across the plank floor and clusters of beeswax candles that burden the narrow windowsills.  In the center, a thick pine stump sits next to a small sign and a wormwood crate filled with books.  A branch ladder leads down to the lower level and a set of crudely carved steps climbs upwards through a hole in the ceiling.</description>
    <position x="-120" y="-508" z="0" />
    <arc exit="climb" move="climb pine ladder" destination="589" />
    <arc exit="climb" move="climb carved steps" destination="984" />
  </node>
  <node id="591" name="The Strand, Large Dune">
    <description>The vantage point from this mound allows one to view most of the surrounding environs without much trouble.  Soft lights fade in and out of the trees' leafy cover in the western distance.  To the east lies a cove created by the turbulent convergence of the steel-grey flow of the Oxenwaithe and the greenish waters of the Segoltha.  Smiling visitors mingle about, traveling to and fro along the navigable routes, mainly heading in the direction of the Communal Center to see the activities planned for the day.</description>
    <description>During the daytime, this mound allows one to view most of the surrounding environs without much trouble.  In the darkness, however, only a few soft lights fade in and out of the trees' leafy cover in the western distance.  The rhythmic crashing of waves emanates from the cove to the east, created by the turbulent convergence of waters flowing inward from the Oxenwaithe and Segoltha Rivers.  The navigable routes are mainly empty save for a few lingering visitors traveling in the direction of civilization.</description>
    <position x="430" y="260" z="0" />
    <arc exit="northeast" move="swim northeast" destination="597" />
    <arc exit="east" move="swim east" destination="592" />
    <arc exit="go" move="go grassy track" destination="514" />
  </node>
  <node id="592" name="The Strand, Seardaz Cove" note="Seardaz Cove|Cove" color="#0000FF">
    <description>As the waves visit land, they forever change the shoreline's structure, brushing the sand upward and stealing some away.  The cove provides a relatively safe swimming area for visitors to The Strand, though one does need to mind the sporadic undertow.  Blending aesthetically with the water's soothing murmurs, the ships' bells in the distance announce the arrival of newly imported supplies for the city and surrounding towns.</description>
    <description>As the waves visit land, they brush up against the shoreline like unfurling folds of black satin.  The cove provides a relatively safe swimming area during the day, but one must mind the deceptive undertows during the night.  Sounds from the city drift across the river and contrast the water's soothing murmurs.</description>
    <position x="450" y="260" z="0" />
    <arc exit="north" move="swim north" destination="597" />
    <arc exit="northeast" move="swim northeast" destination="596" />
    <arc exit="east" move="swim east" destination="593" />
    <arc exit="southeast" move="swim southeast" destination="594" />
    <arc exit="west" move="swim west" destination="591" />
  </node>
  <node id="593" name="The Strand, Seardaz Cove" color="#0000FF">
    <description>Calmer here than to the east, the slightly turbid water swirls in an almost ritualistic fashion.  Overhead, a flock of gulls reels in the sky, hoping for a handout or for a chance to steal food from the beachgoers to the south.  Other swimmers bandy about in the waves for both relaxation and exercise.</description>
    <description>The calm, black water swirls in an almost ritualistic fashion.  A few gulls journey across the dark sky, intent on their destinations and traveling with haste.  Most other swimmers have long since abandoned the rocking waves in favor of other nighttime activities upon the shore.</description>
    <position x="470" y="260" z="0" />
    <arc exit="north" move="swim north" destination="596" />
    <arc exit="northeast" move="swim northeast" destination="599" />
    <arc exit="east" move="swim east" destination="595" />
    <arc exit="south" move="swim south" destination="594" />
    <arc exit="west" move="swim west" destination="592" />
    <arc exit="northwest" move="swim northwest" destination="597" />
  </node>
  <node id="594" name="The Strand, Cove Shallows" note="Cove Shallows" color="#0000FF">
    <description>Just coming to the shins of the taller races, the water here is shallow enough for children to swim safely, sheltered from the swifter currents in the cove.  Various chatty birds loiter on the shore, wading in the water as their beady eyes scan the surface.  Fresh breezes blow urban noise inward to remind visitors of their close proximity to the city.</description>
    <description>Just coming to the shins of the taller races, the opaque water here is shallow enough for a pleasant nighttime stroll without fear of sinking.  Several intrepid birds loiter on the shore despite the darkness in hopes of finding a late-night meal.  Fresh breezes blow the scent of river water inward to remind visitors of their close proximity to the major watery thoroughfares.</description>
    <position x="470" y="280" z="0" />
    <arc exit="north" move="swim north" destination="593" />
    <arc exit="northeast" move="swim northeast" destination="595" />
    <arc exit="northwest" move="swim northwest" destination="592" />
  </node>
  <node id="595" name="The Strand, Seardaz Cove" color="#0000FF">
    <description>To the south, the land protrudes out into the river, providing the cove's lower boundary.  Swift-moving currents strike the obstacle at full force, splitting the flow.  Most of the water continues its frantic pace, though some slows dramatically with the impact, causing weak whirlpools to spiral about.  Hustle and bustle from the nearby shipyards can be heard as ships laden with cargo come and go throughout the day.</description>
    <description>Shrouded in shadows, the land to the south protrudes out into the river, providing the cove's lower boundary.  Swift-moving currents strike the obstacle at full force, splitting the flow.  The typical hustle and bustle from the nearby shipyards has disappeared due to the onset of night, though a few deckhands are still scattered amongst the heavy cargo upon the docks.</description>
    <position x="490" y="260" z="0" />
    <arc exit="north" move="swim north" destination="599" />
    <arc exit="southwest" move="swim southwest" destination="594" />
    <arc exit="west" move="swim west" destination="593" />
    <arc exit="northwest" move="swim northwest" destination="596" />
  </node>
  <node id="596" name="The Strand, Seardaz Cove" color="#0000FF">
    <description>Topped with foam and smelling of brine, the chilly water churns at an easy pace.  The rivers' swift currents are largely diverted by a series of nearby boulders and filler stones.  Several seabirds -- resembling children's toys at this distance -- wade out in search of small fish that linger too close to shore.</description>
    <description>Pops and snaps erupt from the waves as salty bubbles explode from the water churning at its easy pace.  The rivers' swift currents are largely diverted by a series of dark, amorphous boulders further out.  A few lone transportation vessels -- resembling children's toys at this distance -- travel soberly toward the city's docks.</description>
    <position x="470" y="240" z="0" />
    <arc exit="north" move="swim north" destination="598" />
    <arc exit="northeast" move="swim northeast" destination="600" />
    <arc exit="east" move="swim east" destination="599" />
    <arc exit="southeast" move="swim southeast" destination="595" />
    <arc exit="south" move="swim south" destination="593" />
    <arc exit="southwest" move="swim southwest" destination="592" />
    <arc exit="west" move="swim west" destination="597" />
  </node>
  <node id="597" name="The Strand, Shore" color="#0000FF">
    <description>The ground, slightly inclined from the nearby dune, levels out to create stable footing along the waters of the cove.  Waves gently lap at the sand and leave fleeting traces of their presence.  Stones rubbed smooth by years of exposure to the moving waters allow easy passage for visitors -- both the four-legged and two-legged kinds.</description>
    <description>The ground, slightly inclined from the nearby dune, levels out to create stable footing along the waters of the cove.  Waves gently lap at the sand, and the habitual crashing lends a peaceful comfort to the night's chilly air.  Smooth bumps upon the shore indicate the presence of weathered stones that incidentally allow for easier passage through the darkness.</description>
    <position x="450" y="240" z="0" />
    <arc exit="northeast" move="swim northeast" destination="598" />
    <arc exit="east" move="swim east" destination="596" />
    <arc exit="southeast" move="swim southeast" destination="593" />
    <arc exit="south" move="swim south" destination="592" />
    <arc exit="southwest" move="swim southwest" destination="591" />
  </node>
  <node id="598" name="The Strand, Shore" color="#0000FF">
    <description>Narrowed by the moving currents, the strip of land juts into the Oxenwaithe before following the flow further northwest.  Strong eddies swirl within the cove as the two major rivers come together, creating a grey-green mix of water.  Waves splash relentlessly at the uneven shoreline, causing the larger stones to become round and smooth to the touch.</description>
    <description>Narrowed by the moving currents, the shadowy strip of land juts into the Oxenwaithe before following the flow further into darkness to the northwest.  Locals know to avoid the strong eddies swirling in the cove at night, created by the two major rivers coming together.  Heard but not always seen, the waves splash relentlessly at the uneven shoreline, pummeling the sand and stones.</description>
    <position x="470" y="220" z="0" />
    <arc exit="northeast" move="swim northeast" destination="601" />
    <arc exit="east" move="swim east" destination="600" />
    <arc exit="southeast" move="swim southeast" destination="599" />
    <arc exit="south" move="swim south" destination="596" />
    <arc exit="southwest" move="swim southwest" destination="597" />
  </node>
  <node id="599" name="The Strand, Seardaz Cove" color="#0000FF">
    <description>Riptides suck water out of the cove along with unsuspecting swimmers, so constant vigilance is necessary when negotiating the flows.  Slightly brackish, the waters at the junction of the Segoltha and Oxenwaithe noticeably change temperature on a whim.  Glints flash underneath the surface from schools of fish moving between the buoys marking the cove's outer limit.</description>
    <description>Riptides suck water out of the cove along with unsuspecting swimmers, so constant vigilance is necessary when negotiating the flows, especially at night.  Murky and black in the dim, the waters at the junction of the Segoltha and Oxenwaithe noticeably change temperature on a whim.  A short distance away, dark buoys nod like disembodied heads upon the surface, marking the cove's outer limit.</description>
    <position x="490" y="240" z="0" />
    <arc exit="north" move="swim north" destination="600" />
    <arc exit="south" move="swim south" destination="595" />
    <arc exit="southwest" move="swim southwest" destination="593" />
    <arc exit="west" move="swim west" destination="596" />
    <arc exit="northwest" move="swim northwest" destination="598" />
  </node>
  <node id="600" name="The Strand, Seardaz Cove" color="#0000FF">
    <description>The turbulent waters create frothy white foam atop the moving currents as they crash into smoothed boulders shielding the cove.  Loud caws and twitters of sea birds pierce the clamoring din as they circle and dive at the fish that break the river's surface from time to time.  Lazy gulls often perch atop the buoys demarcating the small cove from the expansive crux of the Oxenwaithe and Segoltha rivers.</description>
    <description>The turbulent waters noisily crash into the boulders shielding the cove, creating foamy spray that slaps and abuses swimmers nearby.  Chased away by the darkness, the sea birds retreat to the shore for the night, their loud caws and twitters silenced, at least for the time being.  A few dozing gulls still perch atop the amorphous buoys demarcating the small cove from the expansive crux of the Oxenwaithe and Segoltha rivers.</description>
    <position x="490" y="220" z="0" />
    <arc exit="north" move="swim north" destination="601" />
    <arc exit="south" move="swim south" destination="599" />
    <arc exit="southwest" move="swim southwest" destination="596" />
    <arc exit="west" move="swim west" destination="598" />
  </node>
  <node id="601" name="The Strand, Seardaz Cove" color="#0000FF">
    <description>A strong current threatens to unbalance the unwary as flows from the Oxenwaithe are forced to change course.  Occasionally, otters playfully dart around as if in some sort of game known only to them.  Bobbing buoys corral swimmers into the cove, lest they inadvertently stray further into the unsafe waters where boats traverse.</description>
    <description>A strong current threatens to unbalance the unwary as flows from the Oxenwaithe are forced to change course.  Every push and pull from the river creates the feeling of invisible hands tugging at one's extremities, bullying their way toward the body.  Dark shapes bobbing up and down in the water signify the buoys used to corral swimmers into the cove, lest they inadvertently stray further into the shadowy, unsafe waters beyond.</description>
    <position x="490" y="200" z="0" />
    <arc exit="south" move="swim south" destination="600" />
    <arc exit="southwest" move="swim southwest" destination="598" />
  </node>
  <node id="602" name="Tower South, Air Floor" note="Tower South|Air Floor" color="#00FFFF">
    <description>A dark grey carpet decorated with a pattern of crossing black lightning bolts covers the floor, matching the decoration on the grey-painted walls.  A constant, low thrum hangs just inside the range of hearing, its source nearby but not readily apparent.  Doors spaced in an even circle around the perimeter lead to initiates' private cells.</description>
    <position x="130" y="260" z="0" />
    <arc exit="up" move="up" destination="603" />
    <arc exit="out" move="out" destination="55" />
    <arc exit="climb" move="climb sandstone staircase" destination="896" />
  </node>
  <node id="603" name="Tower South, Water Floor" note="Water Floor" color="#00FFFF">
    <description>Deep blue carpeting covers the floor, its surface cut in a manner that suggests the rippling of waves upon the surface of a lake.  Bright blue spirals, representing the element of water, fill the walls between a series of doors leading to initiates' private cells.  The air here is moist and cool upon the skin.</description>
    <position x="130" y="250" z="0" />
    <arc exit="up" move="up" destination="604" />
    <arc exit="down" move="down" destination="602" />
  </node>
  <node id="604" name="Tower South, Fire Floor" note="Fire Floor" color="#00FFFF">
    <description>Lush, red carpeting covers the floor, muffling any ambient noise into oblivion.  Images of bloated red suns, representing the element of fire, fill the walls between a series of doors leading to initiates' private cells.  The air here is significantly warmer than on the tower's other floors, although the reason is not readily apparent.</description>
    <position x="130" y="240" z="0" />
    <arc exit="up" move="up" destination="605" />
    <arc exit="down" move="down" destination="603" />
  </node>
  <node id="605" name="Tower South, Aether Floor" note="Aether Floor" color="#00FFFF">
    <description>Carpeting the color of a death shroud covers the floor, devouring the light as hungrily as Aldauth consumes souls.  The walls are devoid of decoration, instead painted a uniform black to match the floor.  Only the doors leading to initiates' cells betray any hint of color in this otherwise cold, bleak room.</description>
    <position x="130" y="230" z="0" />
    <arc exit="down" move="down" destination="604" />
  </node>
  <node id="606" name="The Strand, Old Pier" note="Old Pier">
    <description>This short pier juts several yards into the Oxenwaithe.  There's a nice mix of recreational vessels bobbing up and down at their moorings, while a larger fishing boat is tied to its end.  A salty old fisherman, following his daily routine, sits at the end of the pier, whistling a merry tune as he repairs the holes in his net.  Occasionally he glances up, nods, and returns to his work.</description>
    <description>This short pier juts several yards into the Oxenwaithe.  There's a nice mix of recreational vessels bobbing up and down at their moorings, while a larger fishing boat is tied to its end.  Beyond the pier, the Segoltha runs lazily by, glimmering in the light of the moons.</description>
    <position x="150" y="280" z="0" />
    <arc exit="north" move="north" destination="55" />
  </node>
  <node id="607" name="The Crossing, Smithy Lane" color="#00FFFF">
    <description>Clean, golden straw strews the walkway inside a low wooden gate, cushioning the dirt path underfoot and providing a ready source of nesting materials for the occasional bold sparrow.  A cluster of immaculate thatched cottages enjoys this vantage point, their brightly-curtained windows affording a pleasant view of the residents and visitors passing back and forth on their daily business.</description>
    <position x="90" y="-240" z="0" />
    <arc exit="northeast" move="northeast" destination="608" />
    <arc exit="go" move="go wooden gate" destination="24" />
  </node>
  <node id="608" name="The Crossing, Smithy Lane" color="#00FFFF">
    <description>This stretch of the lane is nothing more than a packed earth track bordered by grassy verges, but even so it is neatly criss-crossed with the even strokes of a willow broom.  Several of the homes here boast intricate knotted adornments of dried wildflowers and pungent herbs hanging under their eaves.  Punctuating the lush green verges, flat white stepping-stones lead to the front door of each tidy cottage.</description>
    <position x="100" y="-250" z="0" />
    <arc exit="northeast" move="northeast" destination="609" />
    <arc exit="southwest" move="southwest" destination="607" />
  </node>
  <node id="609" name="The Crossing, Smithy Lane" color="#00FFFF">
    <description>A raised pavement of speckled granite cobbles runs along the center of the lane.  Stucco-fronted cottages stand in smart rows on either side, their squat chimneys exhaling hazy clouds of bluish charcoal smoke.  The inviting aroma of hearty stew and fresh-baked bread permeates the air, combining comfortably with the warm scent of drying pine that emanates from a large woodpile between two homes.</description>
    <position x="110" y="-260" z="0" />
    <arc exit="north" move="north" destination="611" />
    <arc exit="east" move="east" destination="610" />
    <arc exit="southwest" move="southwest" destination="608" />
  </node>
  <node id="610" name="The Crossing, Smithy Lane" color="#00FFFF">
    <description>Several well-maintained brick and stone homes line the lane as it follows a gentle incline.  Weeping willows flourish between the cottages, draping each front door in frail tendrils and sweeping the pristine cobbled pavement with every flutter of their feathered residents.  A gentle breeze carries with it the musical twitter of birdsong.</description>
    <position x="120" y="-260" z="0" />
    <arc exit="north" move="north" destination="612" />
    <arc exit="west" move="west" destination="609" />
  </node>
  <node id="611" name="The Crossing, Crofton Walk" note="Crofton Walk">
    <description>Sparkling white-painted wooden benches sit beneath ivied trellises at intervals around this tidy square, each tranquil bower carefully placed to provide a pleasant view of a crescent-shaped ornamental pond.  Flowerbeds fashioned from interlocking blocks of smooth granite and sandstone dot the square, their bright displays ablaze with seasonal blossoms and neatly-trimmed shrubs.</description>
    <position x="110" y="-270" z="0" />
    <arc exit="east" move="east" destination="612" />
    <arc exit="south" move="south" destination="609" />
    <arc exit="southwest" move="southwest" destination="616" />
    <arc exit="west" move="west" destination="615" />
  </node>
  <node id="612" name="The Crossing, Smithy Lane" color="#00FFFF">
    <description>Flowerbeds line the cobblestones, filling the air with a heady floral fragrance.  Elegant flamestalks bend in a gentle breeze, adding their fiery orange hues to a hedge of bright firethorn, and yellow vines twine around the sun-bleached garden gates which lead off the lane.  Rows of thatched cottages overlook the triangular intersection, basking in the blaze of color.</description>
    <position x="120" y="-270" z="0" />
    <arc exit="north" move="north" destination="613" />
    <arc exit="south" move="south" destination="610" />
    <arc exit="west" move="west" destination="611" />
  </node>
  <node id="613" name="The Crossing, Smithy Lane" color="#00FFFF">
    <description>Small landscaped lawns surround neat cottages of golden sandstone on both sides of the narrow, cobbled lane.  Behind the low buildings, tall aspen and silverwillow trees sway gracefully in the high breeze that drifts down from the wilds beyond Crossing's walls, enfolding the city's spires and treetops in faint traces of cool, green freshness.</description>
    <position x="120" y="-280" z="0" />
    <arc exit="south" move="south" destination="612" />
    <arc exit="west" move="west" destination="614" />
  </node>
  <node id="614" name="The Crossing, Smithy Lane" color="#00FFFF">
    <description>The cool granite cobbles draw to a close at the foot of a wooden bridge that arches gently over a crescent-shaped pond.  Matching the bridge's carefully-maintained woodwork, polished acanth slats form narrow pathways leading from the lane to a group of cozy homes which overlook the pond, their crisp gingham curtains and bright, floral windowboxes adding a cheerful splash of color to the area.</description>
    <position x="110" y="-280" z="0" />
    <arc exit="east" move="east" destination="613" />
    <arc exit="go" move="go wooden bridge" destination="617" />
  </node>
  <node id="615" name="The Crossing, Crofton Walk" color="#00FFFF">
    <description>An ancient oak tree dominates this corner of the lane, its massive trunk and outstretched boughs dwarfing the neat cottages under its broad span.  Noticeable fractures in the cobblestone pavement stretching some twenty paces from the oak's base bear witness to the extent of its root mass, but the homes clustered upon the uneven ground seem to glory in its grandeur all the same.</description>
    <position x="100" y="-270" z="0" />
    <arc exit="north" move="north" destination="617" />
    <arc exit="east" move="east" destination="611" />
  </node>
  <node id="616" name="The Crossing, Crofton Close" color="#00FFFF">
    <description>The handiwork of some clever gardener adorns this quiet cul-de-sac in the form of a low topiary hedgerow.  Carefully crafted from the privet, various figures caper in a charming parade, enclosing the whitewashed stone cottages which occupy the Close.  Intermittent arches trimmed from the glossy, deep green foliage open onto short gravel pathways leading to the homes.</description>
    <position x="100" y="-260" z="0" />
    <arc exit="northeast" move="northeast" destination="611" />
  </node>
  <node id="617" name="The Crossing, Crofton Walk" color="#00FFFF">
    <description>A mosaic of red, umber and brown baked clay tiles spreads across the footpath here, the tiles' earthy tones swirling in a pattern reminiscent of windblown autumn leaves.  Several enormous oaks stand aside the unusual pavement, their enormous boughs bending over rows of tidy stone cottages and carefully-planted gardens of herbs and roses.</description>
    <position x="100" y="-280" z="0" />
    <arc exit="south" move="south" destination="615" />
    <arc exit="go" move="go wooden bridge" destination="614" />
  </node>
  <node id="618" name="Hameel's Carpet Emporium" note="Hameel's Carpet Emporium|Carpets" color="#FF0000">
    <description>Hameel oversees his fine collection of carpets and rugs like a hawk, moving between the display racks and picking invisible specks of dust from the fine wools and silks.  His spotless showroom complements the outstanding handiworks he imports from all over Elanthia, and much as he might prefer to maintain his collection as if it were a museum, he is known to part with the occasional carpet to the right customer at the right price.</description>
    <position x="80" y="-468" z="0" />
    <arc exit="out" move="out" destination="287" />
  </node>
  <node id="619" name="Medratha's Designs in Marble" note="Medratha's Designs in Marble|Marble" color="#FF0000">
    <description>The air is cool and still within Medratha's salesroom, where samples of flawless marble are on display around the walls like masterpieces in an upmarket art gallery.  The artisan himself moves among his customers, silent and catlike, his footsteps soundless on the expanse of snowy-white marble beneath his feet.</description>
    <position x="40" y="-488" z="0" />
    <arc exit="out" move="out" destination="277" />
  </node>
  <node id="620" name="Guard House, Jail Cell" note="Jail Cell">
    <description>From the stench here, it is apparent that the guards have little interest in coddling criminals.  Mounds of musty-smelling hay have been pushed up along the walls, though it is impossible to imagine sleep as a viable possibility here.</description>
    <position x="-150" y="90" z="0" />
  </node>
  <node id="621" name="Sewer" color="#0000FF">
    <description>The packed dirt tunnel leads east and west through soggy piles of refuse.</description>
    <position x="-200" y="-90" z="0" />
    <arc exit="west" move="swim west" destination="299" />
    <arc exit="go" move="go narrow opening" destination="622" />
  </node>
  <node id="622" name="Sewer">
    <description>The intermittent sound of mud echos down the passage as drops of water fall from strands of slimy brown moss and smack the damp dirt lightly at your feet.</description>
    <position x="-170" y="-90" z="0" />
    <arc exit="go" move="go narrow opening" destination="621" />
    <arc exit="east" move="east" destination="623" />
    <arc exit="southwest" move="southwest" destination="633" />
  </node>
  <node id="623" name="Sewer" color="#0000FF">
    <description>The packed dirt tunnel leads east and west through soggy piles of refuse.</description>
    <position x="-160" y="-90" z="0" />
    <arc exit="east" move="swim east" destination="624" />
    <arc exit="west" move="swim west" destination="622" />
  </node>
  <node id="624" name="Sewer" color="#0000FF">
    <description>The packed dirt tunnel leads east and west through soggy piles of refuse.</description>
    <position x="-150" y="-90" z="0" />
    <arc exit="east" move="swim east" destination="625" />
    <arc exit="west" move="swim west" destination="623" />
  </node>
  <node id="625" name="Sewer" color="#0000FF">
    <description>The packed dirt tunnel leads east and west through soggy piles of refuse.</description>
    <position x="-140" y="-90" z="0" />
    <arc exit="east" move="swim east" destination="626" />
    <arc exit="west" move="swim west" destination="624" />
  </node>
  <node id="626" name="Sewer" color="#0000FF">
    <description>A large pile of dark sludge, rat carcasses and other refuse nearly clogs the passage.  The radiating stench prods you to move on.</description>
    <position x="-130" y="-90" z="0" />
    <arc exit="northeast" move="swim northeast" destination="631" />
    <arc exit="east" move="swim east" destination="627" />
    <arc exit="west" move="swim west" destination="625" />
  </node>
  <node id="627" name="Sewer" color="#0000FF">
    <description>The tunnel bends in a sweeping curve to the south and northwest.  Deposited by high water, a ridge of dirt and broken wood rises against the curve of the eastern wall.</description>
    <position x="-120" y="-90" z="0" />
    <arc exit="go" move="go jaged opening" destination="628" />
    <arc exit="west" move="swim west" destination="626" />
  </node>
  <node id="628" name="Sewer" color="#0000FF">
    <description>A thick coating of dingy scum clings to a wrought-iron gate fixed into the wall, preventing further passage east.  The low hiss of moving water echoes in the distance.</description>
    <position x="-100" y="-90" z="0" />
    <arc exit="southeast" move="swim southeast" destination="629" />
    <arc exit="go" move="go jagged opening" destination="627" />
  </node>
  <node id="629" name="Sewer" color="#0000FF">
    <description>The tunnel bends in a sweeping curve to the south and northwest.  Deposited by high water, a ridge of dirt and driftwood rises against the curve of the eastern wall.</description>
    <position x="-90" y="-80" z="0" />
    <arc exit="south" move="swim south" destination="630" />
    <arc exit="northwest" move="swim northwest" destination="628" />
  </node>
  <node id="630" name="Sewer">
    <description>Relatively dry and free of refuse, this small recess offers welcome relief from sewer filth.</description>
    <position x="-90" y="-70" z="0" />
    <arc exit="north" move="north" destination="629" />
  </node>
  <node id="631" name="Sewer" color="#0000FF">
    <description>Several wooden crates lie about the area, their rotting surfaces painted thickly with mold and mildewed dirt.  Corroded, empty bottles and other containers tipped lackadaisically on their sides bear witness to someone's enjoyment of the ballroom atmosphere.</description>
    <position x="-120" y="-100" z="0" />
    <arc exit="north" move="swim north" destination="632" />
    <arc exit="southwest" move="swim southwest" destination="626" />
  </node>
  <node id="632" name="Sewer" color="#0000FF">
    <description>A shallow depression at the tunnel's end traps the murky water in which you stand, fostering clods of rotting vegetation along its edges.</description>
    <position x="-120" y="-110" z="0" />
    <arc exit="south" move="swim south" destination="631" />
  </node>
  <node id="633" name="Sewer">
    <description>Branching here to the southwest, the dingy mud of the main tunnel gives way to hard clay.  A torch, flickering against the eastern wall, casts the area in deep ruddy red.</description>
    <position x="-180" y="-80" z="0" />
    <arc exit="northeast" move="northeast" destination="622" />
    <arc exit="south" move="south" destination="634" />
  </node>
  <node id="634" name="Sewer">
    <description>Bumps and knobs of clay feel smooth beneath your feet, hard and slippery, as if the floor were made of tempered glass.  Flecks of orange, reflected from the north, dance vividly along the alcove's surfaces.</description>
    <position x="-180" y="-70" z="0" />
    <arc exit="north" move="north" destination="633" />
  </node>
  <node id="635" name="Strand Communal Center, Balcony">
    <description>Palm fronds have been woven into an umbrella to shade a small table and chairs upon the balcony.  To the south, ships ply their trade on the river.  From a distance, the brightly-colored boats look more like children's toys than working vessels, as though a small boy had carefully set them adrift on a stream.</description>
    <position x="460" y="350" z="0" />
    <arc exit="go" move="go glass door" destination="498" />
    <arc exit="climb" move="climb stairs" destination="520" />
  </node>
  <node id="636" name="Old Warehouse, Riverbank Cave">
    <description>The base of a weathered warehouse overhead casts a shadowy gloom over this small cave which opens onto the river.  The remains of small boat lie cast aside against a rotten set of pilings, abandoned and forgotten long ago.</description>
    <position x="150" y="140" z="0" />
    <arc exit="north" move="north" destination="637" />
    <arc exit="up" move="up" destination="438" />
    <arc exit="go" move="go river" destination="641" />
  </node>
  <node id="637" name="Warehouse Caves, Smuggler's Den">
    <description>The stale air of this narrow crevice virtually drips with must and mildew.  Murky shadows roll across the slick floor, disguising footfalls and hiding obstacles from the unwary traveler.</description>
    <position x="150" y="130" z="0" />
    <arc exit="northeast" move="northeast" destination="638" />
    <arc exit="south" move="south" destination="636" />
    <arc exit="northwest" move="northwest" destination="639" />
  </node>
  <node id="638" name="Warehouse Caves, Smuggler's Den">
    <description>Through a thin shroud of oozing yellow-green algae, phosphorescent fungi cast a spectral glimmer across the cavern.  The eerily iridescent light reveals crates, barrels and bundles stacked randomly in rows and heaps, leaving little room for unencumbered passage.</description>
    <position x="160" y="120" z="0" />
    <arc exit="north" move="north" destination="640" />
    <arc exit="southwest" move="southwest" destination="637" />
    <arc exit="west" move="west" destination="639" />
  </node>
  <node id="639" name="Warehouse Caves, Smuggler's Den">
    <description>An overwhelming dank stench and the hollow echo of dripping water provide an incessant reminder of the river's proximity.  Nestled among the countless rocks and stones, aged bone splinters and fragments of skeletal remains rest beside thick mats of fungus.  Streams of slick and fetid scum cascade down the rock walls and drip from stalactites to pool on the cavern floor.</description>
    <position x="140" y="120" z="0" />
    <arc exit="northeast" move="northeast" destination="640" />
    <arc exit="east" move="east" destination="638" />
    <arc exit="southeast" move="southeast" destination="637" />
  </node>
  <node id="640" name="Warehouse Caves, Smuggler's Den">
    <description>The telltale signs of a hurried flight lie scattered haphazardly across the moss-covered floor of this chamber.  A pair of dilapidated boxes and an overturned crate are displaced beside a small pyramid of hastily discarded bottles.  A half-burned torch rests butt down on the cavern floor, as if recklessly extinguished.</description>
    <position x="160" y="100" z="0" />
    <arc exit="south" move="south" destination="638" />
    <arc exit="southwest" move="southwest" destination="639" />
  </node>
  <node id="641" name="Old Warehouse, Riverbank Mudflats">
    <description>A dilapidated warehouse looms ominously above, perched precariously on decayed wooden pilings.  Hordes of black flies, drawn by the fetor of rotting wood and organic wastes, choke the air and dart among crates half-submerged in yellowish mud.  To the south, long water grasses and thorny marsh brush effectively block your view of the river.</description>
    <position x="150" y="150" z="0" />
    <arc exit="east" move="east" destination="642" />
    <arc exit="west" move="west" destination="646" />
    <arc exit="go" move="go old warehouse" destination="636" />
  </node>
  <node id="642" name="Riverbank Mudflats">
    <description>Splintered wooden fragments, remnants of tattered clothing, and other refuse discarded by careless citizens offer a hospitable habitat for the breeding of countless diseases and pests.  A dense overgrowth of water grasses and thorny marsh brush obstructs the view of the river and provides a refuge to those clandestine merchants wishing unseen passage.</description>
    <position x="160" y="150" z="0" />
    <arc exit="east" move="east" destination="643" />
    <arc exit="west" move="west" destination="641" />
  </node>
  <node id="643" name="Riverbank Mudflats">
    <description>A thin layer of lime-green algae atop knee-deep mud is broken only by a heavily trodden path, indicative of the frequent night-time passage of smugglers.  On the sprouting shoots of a hardy variety of vilt, tiny white and yellow blossoms break the bland monotony of green on grey.</description>
    <position x="170" y="150" z="0" />
    <arc exit="east" move="east" destination="644" />
    <arc exit="west" move="west" destination="642" />
  </node>
  <node id="644" name="Riverbank Mudflats">
    <description>The putrid stench of rubbish and rotting offal rises from off-colored swill in a cloud of faintly yellowish vapors.  The corner of an aged crate jutting above the bog serves as a sunning perch for a crusty scaled creature.  Other more elusive vermin scurry over the muddy surface of the bank, dodge between rustling bushes, or *PLOP!* into the murky waters of the river.</description>
    <position x="180" y="150" z="0" />
    <arc exit="east" move="east" destination="645" />
    <arc exit="west" move="west" destination="643" />
  </node>
  <node id="645" name="Riverbank Mudflats">
    <description>To the east a tangle of thorny weeds and yellowish mud conquer a narrow path and bring it to an end.  From the vantage point of an abandoned crate, the river is a tranquil and soothing sight of cool, crystalline water bubbling over smooth aged stone.  The contrast to the neglected riverbank is strikingly sharp.</description>
    <position x="190" y="150" z="0" />
    <arc exit="west" move="west" destination="644" />
  </node>
  <node id="646" name="Riverbank Mudflats">
    <description>A rotted warehouse pylon has collapsed and fallen into the depths of mud and reeds.  Quick to take advantage of the situation, a host of the riverbank's insectoid citizenry has taken up residence.  Already the column has begun an early decomposition as it becomes the focus of a swarm of termites, mosquitoes and beetles.</description>
    <position x="140" y="150" z="0" />
    <arc exit="north" move="north" destination="647" />
    <arc exit="east" move="east" destination="641" />
    <arc exit="northwest" move="northwest" destination="648" />
  </node>
  <node id="647" name="Riverbank Mudflats">
    <description>Against the rotting warehouse pylons, a makeshift dwelling has been built of broken boxes and stray boards.  A roof composed of dried vilt reeds woven tight and sealed with mud is a temporary but effective relief from the sun.  However, the structure's stopgap construction provides little shelter from the other elements.</description>
    <position x="140" y="140" z="0" />
    <arc exit="south" move="south" destination="646" />
    <arc exit="west" move="west" destination="648" />
    <arc exit="go" move="go makeshift dwelling" destination="649" />
    <arc exit="go" move="go panel" destination="650" />
  </node>
  <node id="648" name="Riverbank Mudflats">
    <description>Although the earth is firm here, one quickly becomes caught in sinking mud and a tangle of river reeds another ten paces closer to the river.  Shattered fragments of wood, broken tools and castoff bits of clothing lie scattered about, washed up from the river and left to rot.</description>
    <position x="130" y="140" z="0" />
    <arc exit="east" move="east" destination="647" />
    <arc exit="southeast" move="southeast" destination="646" />
  </node>
  <node id="649" name="Mud Hovel">
    <description>Not much more than a hastily assembled lean-to, this shack doesn't have much in the way of headroom and barely enough floorspace to curl up on.  The ground is covered in a thick layer of dried grass and reeds to keep out the ever-present mud.  A rusted oil lamp sits in the corner, empty and devoid of light.</description>
    <position x="130" y="130" z="0" />
    <arc exit="out" move="out" destination="647" />
  </node>
  <node id="650" name="Riverbank Mudflats, Rough Stairway" note="Map1a_Crossing_Thief.xml|5th Passage" color="#808080">
    <description>Barely visible in the murky air of the room, broken boards have been set into the earth to form a crude set of steps that tilt precariously away from the base of the panel to drop into the darkness beyond.  Shredded oilcloth has been jammed into the cracks around the panel as if an attempt has been made to prevent light or sounds from betraying activity here to the world outside.</description>
    <position x="130" y="160" z="0" />
    <arc exit="out" move="out" destination="647" />
    <arc exit="climb" move="climb crude steps" destination="650" />
  </node>
  <node id="651" name="Luthier's, Performance Room">
    <description>Tucked behind the Luthier's shop, this room serves as impromptu performance hall and lounge for wandering Bards.  Occasional performances are given here and sometimes the public is invited in for a few coins.  Wine and ale can be had, albeit discreetly since the place is not licensed.  A dozen or so comfortable benches are scattered about and in one corner a rather rag-tag troubadour seems to be sleeping off yesterday's tipple.</description>
    <position x="80" y="-170" z="0" />
    <arc exit="south" move="south" destination="401" />
  </node>
  <node id="652" name="Fang Cove, Fate's Fortune Lane" note="Map150_Fang_Cove.xml">
    <description>A towering marble archway opens a gap in the wall to the north and separates the ongoing construction and somewhat more refined completed structures of Fate's Fortune Lane from the crude structures and makeshift walkway along the beach.  The entrance to a squat, wide bungalow sits in opposition to the arch, and the sheltering cliffs of Fang's Peak rise up from behind it.  To either side of the arch, cobblestones of different shapes and sizes have been laid out to form the wide Fate's Fortune Lane.</description>
    <position x="179" y="206" z="0" />
    <arc exit="north" move="north" />
    <arc exit="east" move="east" />
    <arc exit="west" move="west" />
    <arc exit="go" move="go exit portal" destination="50" />
  </node>
  <node id="653" name="A Wagon" note="Card Shop|Card Collector" color="#FF0000">
    <description>The dark cedar paneled walls commingle their essence with the scents of strong ink and old parchment that permeate this wagon.  Suspended just beneath the ceiling, locked iron-strapped cabinets hang far above the few thin cushions that are the room's only concession to comfort.</description>
    <position x="110" y="180" z="0" />
    <arc exit="out" move="out" destination="49" />
  </node>
  <node id="654" name="Crossing Battlements, Campaign Tent" note="Campaign Tent">
    <description>This temporary structure offers few amenities, other than shelter from the weather.  A lone lantern swings from the top of the central tent post, showing only an upturned crate to sit upon and a couple of neatly stowed bedrolls.</description>
    <position x="390" y="60" z="0" />
    <arc exit="out" move="out" destination="397" />
  </node>
  <node id="655" name="Orielda's Blossoms, Front Room" note="Orielda's Blossoms|Florist|Flowers" color="#FF0000">
    <description>Beautifully crafted earthen pots filled with brightly hued blossoms form a narrow walkway that curves from the doorway all the way to the counter of this tiny but airy shop.  Alongside the large cluttered counter, barrels overflowing with roses and carnations glisten with a delicate webbing of moisture, their luscious scent only slightly overpowered by the exquisite colors of the blooms themselves.</description>
    <position x="220" y="-318" z="0" />
    <arc exit="out" move="out" destination="9" />
    <arc exit="go" move="go beaded doorway" destination="656" />
  </node>
  <node id="656" name="Orielda's Blossoms, Workroom">
    <description>Scarred counters and workbenches covered with all manner of floral arrangements, garlands, wreaths, corsages, and living plants, line all four walls of this tiny room.  From time to time, one of Orielda's assistants scurries through, whistling a merry tune as her hands fly gracefully over her work, then turning to chatter happily with another worker or the occasional customer wandering in.</description>
    <position x="210" y="-318" z="0" />
    <arc exit="go" move="go beaded doorway" destination="655" />
  </node>
  <node id="657" name="Menevia the Seeress, Seance Parlor" note="Menevia the Seeress|Seeress|Seance Parlor">
    <description>In a velvet robe punctuated with beetle-wing spangles, Menevia the Blind Seeress holds forth, seated at a round table.  She does not rise to greet you.  Querents huddle around her, awaiting answers on what the future holds.  Several cowled figures stand by a trelium display case, pointing at talismans, orbs and other trinkets, debating their virtues and price.</description>
    <position x="-40" y="-40" z="0" />
    <arc exit="up" move="up" destination="658" />
    <arc exit="out" move="out" destination="35" />
  </node>
  <node id="658" name="Menevia the Seeress, Rooftop Gazebo" note="Rooftop Gazebo|telescope|astrolabe">
    <description>This pleasant gazebo is a surprising annex to Menevia's stuffy chambers below.  Light from the astral bodies envelops you through enchanted glass, a kind that permits the full spectrum to penetrate.  Stained glass lightcatchers of unicorns, chimeras and griffins cast tiny rainbows on everything in the room, including you.  Menevia seems totally aware of the state of the heavens, sensing rather than seeing.</description>
    <position x="-40" y="-50" z="0" />
    <arc exit="down" move="down" destination="657" />
  </node>
  <node id="659" name="Half Pint, Grand Foyer" note="Half Pint">
    <description>The two-story foyer of Skalliweg's Half Pint always seems crowded with jovial merrymakers coming and going.  All kinds gather here, but there is a noticeable predominance of Humans, Halflings and Dwarves.  An ornate wrought-iron spiral stair dominates the room, sweeping upwards to the second floor.  From a high archway to the east waft the sounds of good company and the smells of even better ale and victuals, and through some stout double doors to the south are heard roars of encouragement.</description>
    <position x="70" y="20" z="0" />
    <arc exit="out" move="out" destination="45" />
    <arc exit="go" move="go high archway" destination="660" />
    <arc exit="go" move="go double doors" destination="663" />
    <arc exit="climb" move="climb spiral stair" destination="664" />
  </node>
  <node id="660" name="Half Pint, Main Saloon" color="#FF0000">
    <description>Skalliweg Barrelthumper, proud proprietor of The Half Pint, perches alertly on a high stool behind the sleek, polished bar, shouting at serving wenches, cooks and customers alike.  Patrons dine, drink, dispute and dream on, in spite of the constant hum, draped over comfortable rush-seated chairs or hunched over well-worn tables.  Faces flicker and eyes glimmer in the dim light of the wrought-iron chandelier and candle stubs sputtering in crocks on the tables.</description>
    <position x="70" y="10" z="0" />
    <arc exit="go" move="go dimly arch" destination="661" />
    <arc exit="go" move="go high doorway" destination="659" />
  </node>
  <node id="661" name="Half Pint, Bards' Corner">
    <description>In sharp contrast to the Main Saloon and more boisterous reaches of The Half Pint, this quiet chamber is softly lit and tastefully decorated with antique tapestries depicting famed minstrels and legendary troubadours from the annals of Elanthia.  The room itself has no tables and chairs, but rather a recessed wooden seating pit with overstuffed cushions scattered about the floor.  At the far end is a raised platform with a lectern, a low ottoman and a music stand.</description>
    <position x="70" y="0" z="0" />
    <arc exit="go" move="go dance floor" destination="662" />
    <arc exit="go" move="go dimly arch" destination="660" />
  </node>
  <node id="662" name="Half Pint, Dance Floor" note="Dance Floor" color="#FF0000">
    <description>A more recent addition to the Half Pint, the dance floor has a polished hardwood floor and a chandelier crafted from brushed silver and tiny blue crystals.  A strategic placement of mirrors makes the room seem bigger then it really is.  The musicians sit behind a decorated rail that keeps the dancers from accidentally falling into their beloved instruments.</description>
    <position x="80" y="0" z="0" />
    <arc exit="out" move="out" destination="661" />
  </node>
  <node id="663" name="Half Pint, Gaming Room" note="Gaming Room|Dartboard">
    <description>Here are gathered some of town's most serious gamblers, gamers and wagerers.  They cluster about a few round tables rolling dice, rattling bones and casting shells.  Several square tables bear cards, tokens, game pieces, and painted wooden boards with various runes and numbers on them.  You observe a curious fact: the round tables heaped high with gold are surrounded by tense faces, while the crowds around the square tables are laughing, joking, drinking and enjoying themselves immensely.</description>
    <position x="70" y="30" z="0" />
    <arc exit="go" move="go double doors" destination="659" />
  </node>
  <node id="664" name="Half Pint, Spiral Stair">
    <description>The long spiral staircase seems to twist about for quite some time, with only a wrought-iron railing to keep travelers from taking a misstep off it to the floor below.  Many of those who climb tightly grip the rails as they make their way up, or down to their destinations.</description>
    <position x="60" y="20" z="0" />
    <arc exit="up" move="up" destination="665" />
    <arc exit="down" move="down" destination="659" />
  </node>
  <node id="665" name="Half Pint, Upstairs Hall" color="#00FFFF">
    <description>Richly flocked fabric covers the walls here, and all manner of greenery in ceramic pots line the floor.  Large enamel vases of foreign design hold aromatic bunches of dried flowers, branches and herbs.  A rich, velvety carpet muffles footsteps, permitting guests to come and go with the utmost discretion.</description>
    <position x="60" y="10" z="0" />
    <arc exit="west" move="west" destination="666" />
    <arc exit="climb" move="climb wrought-iron staircase" destination="664" />
    <arc exit="go" move="go mahogany door" destination="667" />
  </node>
  <node id="666" name="Half Pint, Upstairs Hall" color="#00FFFF">
    <description>The hall here is hung with paintings of various knights, maidens and wildlife in idealized, pastoral scenes.  The signatures scrawled in the corners of the artwork cover an impressive variety of notable artisans from around the realms.</description>
    <position x="50" y="10" z="0" />
    <arc exit="east" move="east" destination="665" />
    <arc exit="go" move="go iron-studded door" destination="668" />
    <arc exit="go" move="go crystal door" destination="669" />
  </node>
  <node id="667" name="Half Pint, Rainforest Suite" note="Rainforest Suite">
    <description>Gentle clucking noises from one corner draw attention to a gilded bird cage holding a riotously-colored parrot.  Approaching the bird sends it conversing in some unknown tongue.  The chamber is softly lit, like the light that filters down through the dense, leafy canopy of a tropical jungle.  Furnishings of rattan and bamboo surround a small, gurgling fountain in the midst of a pool, around which are potted palms and exotic dwarf fruit trees.</description>
    <position x="60" y="0" z="0" />
    <arc exit="go" move="go mahogany door" destination="665" />
  </node>
  <node id="668" name="Half Pint, Nightshade Suite" note="Nightshade Suite">
    <description>The wallpaper in this chamber is midnight blue.  Heavy velvet curtains with satin lining drape the windows, so that what little light can filter in seems tinged with the blush of eternal night.  An oil lamp burns with a bluish cast, illuminating a recessed pit in the floor which is filled with black silk pillows and dark blue comforters.</description>
    <position x="50" y="20" z="0" />
    <arc exit="go" move="go iron-studded door" destination="666" />
  </node>
  <node id="669" name="Half Pint, Moonlight Suite" note="Moonlight Suite">
    <description>A crescent-shaped, billowing bed dominates the center of this room.  The ceiling is painted midnight blue, with glowing gems twinkling in rhythmic sequence like some perfect night sky.  On the deep blue walls are depictions of the eleven planets and scenes of the Immortals who govern them engaged in feasting and merriment.</description>
    <position x="40" y="10" z="0" />
    <arc exit="go" move="go crystal door" destination="666" />
    <arc exit="go" move="go blue-tinted door" destination="670" />
  </node>
  <node id="670" name="Half Pint Inn, Balcony">
    <description>This intimate balcony looks out of the top story of the inn, over the river and the town, facing south.  From here, stunning views of the dawns, sunsets and the night's sky over the water greet you.</description>
    <position x="30" y="10" z="0" />
    <arc exit="go" move="go blue-tinted door" destination="669" />
  </node>
  <node id="671" name="The Thin Veneer" note="Thin Veneer|Lustre|Walls|Floors" color="#FF0000">
    <description>The walls and floor of this salesroom are a strange yet pleasing patchwork of polished woods in a variety of finishes and hues, each gleaming section an attractive example of the fine wood fittings stocked by the owner, Lustre.  In one corner, a selection of elegant tables complements the inventory, and the rich aroma of deep orange polishing oil hangs heavily in the air.</description>
    <position x="-150" y="196" z="0" />
    <arc exit="out" move="out" destination="58" />
    <arc exit="go" move="go mahogany arch" destination="672" />
  </node>
  <node id="672" name="The Thin Veneer, Chair Gallery" note="Chairs" color="#FF0000">
    <description>Lustre's own exquisite woods line the floor and walls of this pleasant showroom.  Groups of elegant chairs are arranged around the room in attractive displays, and yet more selections hang upon the walls, allowing customers to inspect the craftsman's high-quality products from all angles.</description>
    <position x="-150" y="206" z="0" />
    <arc exit="out" move="out" destination="671" />
  </node>
  <node id="673" name="Old Warehouse">
    <description>The reek of dead fish permeates your nostrils making you feel ill.  Besides the stench, you notice piles and piles of old crates almost entirely filling this rotting deobar-paneled warehouse.  One of the crates in the corner has been smashed open, straw and broken glass spilling across the floor from it.</description>
    <position x="-202" y="142" z="0" />
    <arc exit="out" move="out" destination="59" />
    <arc exit="go" move="go crate" destination="674" />
  </node>
  <node id="674" name="Aesthene's Close, Chamber">
    <description>You find yourself on a slimy cobblestone floor in a dark, dank and smelly chamber.  Noxious trickles of effluent seep through tiny cracks in the tortured walls, which appear to be on the verge of collapse.  The hole in the rotted timber high above is hardly convenient for escape, and you realize with a chill that you must find another way out.</description>
    <position x="-212" y="152" z="0" />
    <arc exit="north" move="north" destination="675" />
  </node>
  <node id="675" name="Aesthene's Close, Corridor">
    <description>The walls of this narrow corridor are closer than is comfortable.  Bits and pieces of once-glorious tapestries still cling to their surfaces, caked with crud and sagging from the weight of the water they have absorbed.  Certain stones in the wall threaten to fall at any moment, and the floor is smattered with debris.</description>
    <position x="-212" y="142" z="0" />
    <arc exit="north" move="north" destination="676" />
    <arc exit="south" move="south" destination="674" />
  </node>
  <node id="676" name="Aesthene's Close, Corridor">
    <description>Broken stones litter this part of the corridor.  The cobblestone floor is suddenly uneven, buckled by some ancient cataclysm.  A great boulder has punched its way through one wall, almost completely obstructing any northward progression.  Fine stress fractures trace the western wall, ending in a narrow crevice high above your head.</description>
    <position x="-212" y="132" z="0" />
    <arc exit="east" move="east" destination="677" />
    <arc exit="south" move="south" destination="675" />
    <arc exit="climb" move="climb great boulder" destination="875" />
  </node>
  <node id="677" name="Aesthene's Close, Corridor">
    <description>Tattered pieces of cloth are hung from rusted bars along each wall of this corridor.  While most of the fabric has disintegrated over time, a few remain somewhat complete, though dark splotches of mildew make it difficult to discern their patterns.  By the regularity of their placement, you gather that these are the remains of a series of heraldic banners.</description>
    <position x="-202" y="132" z="0" />
    <arc exit="west" move="west" destination="676" />
    <arc exit="go" move="go curved arch" destination="678" />
  </node>
  <node id="678" name="Aesthene's Close, Corridor">
    <description>Passing through this corridor, you are greeted by the overwhelming stench of the mushy, decaying rug beneath your feet.  Bedraggled and torn asunder, only the intricate thick binding along its edges is more or less intact.  A stark-white lizard appears out of a crack in the oozing walls and scurries for the other end of the corridor.</description>
    <position x="-100" y="132" z="0" />
    <arc exit="east" move="east" destination="679" />
    <arc exit="go" move="go curved arch" destination="677" />
  </node>
  <node id="679" name="Aesthene's Close, Corridor">
    <description>Iron brackets in the walls suggest that weapons once hung here, but nothing else remains in this spartan hallway.</description>
    <position x="-90" y="132" z="0" />
    <arc exit="south" move="south" destination="681" />
    <arc exit="west" move="west" destination="678" />
    <arc exit="northwest" move="northwest" destination="680" />
  </node>
  <node id="680" name="Aesthene's Close, Corridor">
    <description>A mass of crumbled wall and jagged rock fill the northern end of this corridor, making any further progress impossible.  Mixed in the rubble are shards of broken pottery and the bent remains of an iron torch ring.  Frozen in mid-crawl within a pool of mire, the mottled torso of a skeleton seems to be clawing its way from the ruins.</description>
    <position x="-100" y="122" z="0" />
    <arc exit="southeast" move="southeast" destination="679" />
  </node>
  <node id="681" name="Aesthene's Close, Corridor">
    <description>You find yourself in a narrow passageway where the stone walls have been overlain with wood slats.  Whatever purpose this room may have served at one time, it is now nothing more than a reeking mess of rotting boards and pooling ooze.  Every sloshing footfall stirs up a horrid odor as you make your way through.</description>
    <position x="-90" y="142" z="0" />
    <arc exit="north" move="north" destination="679" />
    <arc exit="southwest" move="southwest" destination="682" />
  </node>
  <node id="682" name="Aesthene's Close, Corridor">
    <description>A collapsing wall spans the width of the eastern end of this corridor.  Crumbling bricks lie strewn across the cobblestones, and a thin layer of mortar dust coats tiny puddles of effluent.</description>
    <position x="-100" y="152" z="0" />
    <arc exit="northeast" move="northeast" destination="681" />
    <arc exit="climb" move="climb broken wall;climb broken wall" destination="683" />
  </node>
  <node id="683" name="Aesthene's Close, Corridor">
    <description>Something about this room causes you to give pause.  The air seems charged with some fantastic energy, and eventually you realize there is no destruction here.  Not a single stone is out of place, nothing putrid festers or fouls.  Though the hall bears no visible sign of an egress, something stirs you to press forward with extreme caution.  You give hefty consideration to the pristine floor, which is made of twelve massive tiles deeply etched with the icons of various items.</description>
    <position x="-110" y="152" z="0" />
    <arc exit="climb" move="climb broken wall" destination="682" />
    <arc exit="go" move="go portal" destination="684" />
  </node>
  <node id="684" name="Aesthene's Close, Crystal Chamber" note="Crystal Chamber" color="#FF00FF">
    <description>To your utter astonishment, you find yourself engulfed in a breathtaking array of vivid, sparkling colors.  Constantly shifting in their prismic dance, they seem to make up the very air in the room, for as you move the hues and tones retreat and reconverge like liquid.  You feel as though you are standing at the very source of rainbows.  A pleasant, resonant hum reaches your ears.</description>
    <position x="-120" y="152" z="0" />
    <arc exit="go" move="go portal" destination="868" />
  </node>
  <node id="685" name="Merchant Apartments, First Floor" note="Merchant Apartments" color="#00FFFF">
    <description>This semicircular corridor is dry and slightly cool.  Its floor of packed earth is covered with an intricately woven, red and gold rug.  Lamps of glowstone line the room and a nearby staircase, bringing to the area a subdued but warm light.</description>
    <position x="-205" y="190" z="0" />
    <arc exit="south" move="south" destination="686" />
    <arc exit="out" move="out" destination="61" />
  </node>
  <node id="686" name="Merchant Apartments, First Floor" color="#00FFFF">
    <description>The jackdaw sounds of everyday business in the Crossing have faded completely from this section of semicircular corridor.  Underneath a glowstone, a small wooden icon of Peri'el rests upon a sandstone lip.  An archway outlined in fluted columns leads south.</description>
    <position x="-205" y="200" z="0" />
    <arc exit="north" move="north" destination="685" />
    <arc exit="go" move="go archway" destination="687" />
  </node>
  <node id="687" name="Merchant Apartments, Plaza">
    <description>Grape vines delicately entwine across grey trellises and eroded stone benches in this rounded, open area between the first floor corridors.  A faintly smiling water nymph carved from granite pours from a never-emptying pitcher into a small fountain.  A patch of the Crossing's sky functions for the plaza's dome, but no sound of the Crossing permeates this space.  An archway leads north.</description>
    <position x="-205" y="210" z="0" />
    <arc exit="go" move="go archway" destination="686" />
  </node>
  <node id="688" name="Korhege Apartments, First Floor" note="Korhege Apartments" color="#00FFFF">
    <description>The surface of this hallway is an aquamarine sandstone, buffed to a dull, marbled sheen.  The firmly encased, calcified remains of small marine creatures lay scattered about the top of the floor, one a large, golden starfish and the other an opalescent sea conch.</description>
    <position x="-215" y="190" z="0" />
    <arc exit="south" move="south" destination="689" />
    <arc exit="out" move="out" destination="62" />
  </node>
  <node id="689" name="Korhege Apartments, First Floor" color="#00FFFF">
    <description>A large, decorative walnut chest adorns the end of this corridor.  Above it, wall-mounted iron supports in the shape of wave-lapped seahorses uphold a pair of cylindrical glowstones.  A stairwell leads to the second floor.</description>
    <position x="-215" y="200" z="0" />
    <arc exit="north" move="north" destination="688" />
    <arc exit="go" move="go archway" destination="690" />
    <arc exit="climb" move="climb stairwell" destination="1008" />
  </node>
  <node id="690" name="Korhege Apartments, Garden">
    <description>Oralana and climbers of maugwort, gravid with brown berries, tumble in profusion over gently eroded stone benches and tables in this central garden area.  The fragrance is mellow yet spicy, like standing downwind of a distant caravan loaded with herbs and costly fabrics.</description>
    <position x="-215" y="210" z="0" />
    <arc exit="go" move="go archway" destination="689" />
  </node>
  <node id="691" name="Burning Desires" note="Burning Desires|Akhbar|Braziers" color="#FF0000">
    <description>Braziers of all shapes and sizes, all of the finest quality, stand in neat rows on the floor of this immaculate shop.  The air is heady with a potpourri of incenses burning in the models on display.</description>
    <position x="-227" y="166" z="0" />
    <arc exit="out" move="out" destination="62" />
  </node>
  <node id="692" name="Windows to the Universe" note="Windows to the Universe|Fenster" color="#FF0000">
    <description>Paneless windows of various shapes and sizes line the walls, near them stacked large piles of multi-colored sands and small tubs of dyes.  Several sheets of finished glass sit near the exit, awaiting insertion into frames.</description>
    <position x="-330" y="160" z="0" />
    <arc exit="out" move="out" destination="63" />
  </node>
  <node id="693" name="Dintacui Apartments, First Floor" note="Dintacui Apartments" color="#00FFFF">
    <description>The spare sandstone corridor is cool and quiet, its walls unsanded and rugged.  Running diagonally through one wall from ceiling to floor is a broad, glittering vein of golden feldspar.  Several lines of poetry, written in the Common tongue but using the flowing, elusive S'Kra script, have been incised across it.</description>
    <position x="-330" y="180" z="0" />
    <arc exit="south" move="south" destination="694" />
    <arc exit="out" move="out" destination="63" />
  </node>
  <node id="694" name="Dintacui Apartments, First Floor" color="#00FFFF">
    <description>The bare, rocky hallway of white stone looks almost bleached in the light of several glowstone globes.  Four lines of poetry have been carved in a continuous, single wave along walls of the area.  A plain stairway leads up to the second floor.</description>
    <position x="-330" y="190" z="0" />
    <arc exit="north" move="north" destination="693" />
    <arc exit="go" move="go archway" destination="695" />
    <arc exit="climb" move="climb plain stairway" destination="892" />
  </node>
  <node id="695" name="Dintacui Apartments, Garden Room">
    <description>This garden is furnished with thick pillows laid upon a tiled floor.  They form a hexagonal pattern around a single rosebush, fragrant with flowers.  Orange trees form a canopy, supplying sustenance and shelter from inclement weather.</description>
    <position x="-320" y="190" z="0" />
    <arc exit="go" move="go archway" destination="694" />
  </node>
  <node id="696" name="Riverfront Portage, Office">
    <description>The shouts of the dockworkers and the tang of river water penetrate even through the thick, earthen walls of this secure warehouse office.  Here are kept the records of all barge traffic along the river, the tariffs for haulage and storage.  A burlwood cabinet crammed chock full of files, a likewise overburdened rolltop desk and a brimming wastebasket all attest to the amount of paperwork that passes through this room.</description>
    <position x="-260" y="250" z="0" />
    <arc exit="out" move="out" destination="64" />
    <arc exit="go" move="go bronze door" destination="697" />
    <arc exit="go" move="go narrow arch" destination="698" />
  </node>
  <node id="697" name="Riverfront Portage, Warehouse">
    <description>Here, inside this brick hulk, merchants, traders and brokers store their goods bound for destinations along the river.  Offloaded cargo is also kept here, awaiting customs inspectors, tariff officers and hungry mice.  Pallet upon pallet of crates, barrels and boxes are lined up in neat rows, with the aisles between them wide enough for a horse-drawn cart to negotiate.</description>
    <position x="-260" y="260" z="0" />
    <arc exit="go" move="go bronze door" destination="696" />
  </node>
  <node id="698" name="The Crossing, Shipping Office" note="Shipping Office" color="#00FF00">
    <description>The hustle and bustle of the customs house seems magnified in the cramped shipping office as Traders rush in to ship their packages or wait for some to be delivered to them from other ports of call.  Dutiful clerks mark and organize the incoming crates, lining them according to their own system of letters and numbers to fit within deep, towering shelves that line the back wall.</description>
    <position x="-270" y="260" z="0" />
    <arc exit="out" move="out" destination="696" />
  </node>
  <node id="699" name="Sand Spit Tavern, Barroom" note="Sand Spit Tavern" color="#FF0000">
    <description>Apparently made from a section of salvaged ship's hull the main bar area is constructed of ancient and scavenged nautical ware.  The decor is of the same vintage, an old hatch cover for a door, worn and broken capstans for tables with a hodge-podge of chairs of all sorts.  A long bar that has seen much better days is the main focus of the room.  The lighting is dim and there are many dark corners.  The clientele seems to prefer it that way to judge from the heavily curtained porthole windows.</description>
    <position x="-290" y="240" z="0" />
    <arc exit="out" move="out" destination="67" />
    <arc exit="go" move="go shadowed table" destination="700" />
    <arc exit="go" move="go dark corner" destination="701" />
    <arc exit="go" move="go back area" destination="858" />
  </node>
  <node id="700" name="Sand Spit Tavern, Round table">
    <description>Here in a very dark corner of the bar, sits a large table.  A rough wooden bench and some chairs are drawn up about it and a shaded oil-lamp sitting on it throws a narrow cone of light on the surroundings.  An ideal place to sit and drink or talk for those who'd prefer not to be disturbed.</description>
    <position x="-300" y="240" z="0" />
    <arc exit="go" move="go main bar" destination="699" />
  </node>
  <node id="701" name="Sand Spit Tavern, Dark Corner">
    <description>This corner is dark and isolated from the main bar by a low wooden wall made from old spars bound together with rope.  A small square table and four chairs are the only furnishings.  Overhead, an old lantern sheds a pallid light over the nook.  The air is stale and smells of spilled beer and worse things.</description>
    <position x="-300" y="250" z="0" />
    <arc exit="out" move="out" destination="699" />
  </node>
  <node id="702" name="Ulven's Warehouse, Storage" note="Ulven's Warehouse" color="#00FF00">
    <description>This storage area consists of a single well-ventilated, vast room with high ceilings.  Square wooden pallets hold stacks of bales, crates, kegs and hogsheads.  The stored goods all look fresh and intact, and the hustling workers running down the aisles pay you no heed.</description>
    <position x="-330" y="120" z="0" />
    <arc exit="out" move="out" destination="69" />
  </node>
  <node id="703" name="Shrine of Kertigen" note="Shrine1-03|Kertigen" color="#A6A3D9">
    <description>The shrine here consists of a small rock garden with several stone benches placed at odd angles for meditation.  It is a cool and quiet respite that so delights you that you do not at first notice something most remarkable.  The miniature landscapes of tiny mountains and dwarf trees are not of stone and twig, but are actually fashioned out of precious metals and minerals.</description>
    <position x="-108" y="86" z="0" />
    <arc exit="out" move="out" destination="74" />
  </node>
  <node id="704" name="Brisson's Haberdashery, Sales Salon" note="Brisson's Haberdashery|Haberdashery" color="#FF0000">
    <description>If understated elegance has a home, this is certainly it.  Rich mahogany floors, polished to a soft gleam are accented by thick handwoven rugs in burgundy and dark grey, that cushion each footfall.  Heavy cabinets with their doors ajar display a variety of handsome accoutrements for gentlemen of all tastes, ranging from understated to the more flamboyant apparel preferred by dandies.</description>
    <position x="-80" y="-30" z="0" />
    <arc exit="east" move="east" destination="706" />
    <arc exit="west" move="west" destination="705" />
    <arc exit="out" move="out" destination="88" />
  </node>
  <node id="705" name="Brisson's Haberdashery, Storage">
    <description>Though quiet elegance may be the watchword in the salesroom, mayhem comes closer to describing these surroundings. Clerks, their arms piled high with exquisite garments, hats, canes, and scarves, scurry back and forth, whistling happily over their work. Near a large window in the back of the room, a new shipment is arriving, the burly delivery men looking coarse and rough compared to the smaller, softer appearance of the salespeople.</description>
    <position x="-90" y="-30" z="0" />
    <arc exit="east" move="east" destination="704" />
  </node>
  <node id="706" name="Brisson's Haberdashery, Fitting Room" note="Brisson's Fitting Room" color="#FF0000">
    <description>Long rods suspended from the low ceiling display a mind-boggling variety of clothing.  Capes lined with silk, fine ceremonial tunics, and elegant frock coates nudge up against leather jerkins and other more protective garments, all awaiting the touch of a master tailor to define them more perfectly for their new owners. Bolts of fabric, march like small sentinels along sturdy shelves along the edges of the room, protecting the modesty of some of the more bashful patrons.</description>
    <position x="-70" y="-30" z="0" />
    <arc exit="west" move="west" destination="704" />
  </node>
  <node id="707" name="Shrine of Ushnish" note="Shrine1-02|Ushnish" color="#A6A3D9">
    <description>In a dark, fetid alley, hard behind the Viper's Nest Inn, you happen upon a small shrine.  Kicking away what appears to be rubbish from around it, you reveal a sculpted granite image of the serpent god Ushnish.  Seeing that, you realize with a shudder that it is not rubbish you just pushed aside, but offerings of dead rats, uncured, fresh skins and other offal left by devotees of the viper-headed deity.</description>
    <position x="-250" y="-240" z="0" />
    <arc exit="out" move="out" destination="119" />
  </node>
  <node id="708" name="Viper's Nest, Courtyard">
    <description>Cracked flagstones pave the grim courtyard of the Viper's Nest Inn, making you stumble as you feel your way along.  A scabrous-looking, dense deobar tree blocks off any light.  Trails of mud, dust, sweat and blood streak the pavement, as if heavy burdens of all ilk had been dragged through here.  In a corner of the patio is a broken clay urn filled with water, the only place where guests and carousers can wash, or dunk themselves to shake off the haze of their intoxicants of choice.</description>
    <position x="-210" y="-160" z="0" />
    <arc exit="out" move="out" destination="120" />
    <arc exit="go" move="go storm cellar" destination="709" />
    <arc exit="go" move="go scarred door" destination="710" />
  </node>
  <node id="709" name="Viper's Nest, Storm Cellar" color="#00FFFF">
    <description>A battered storm cellar door leads down into the room via a few rickety, decrepit wooden steps.  The musty odor and clammy air are intensified by the darkness.  A constant dripping sound and the scurrying of creatures unseen about your feet makes you utter a quick prayer that there are no impending squalls out over Segoltha Bay.  Leaking casks of sour ale, maggot-ridden hogsheads of flour, and dark-stained, shapeless burlap bundles can barely be discerned in the half-murk.</description>
    <position x="-200" y="-160" z="0" />
    <arc exit="up" move="up" destination="708" />
  </node>
  <node id="710" name="Viper's Nest, The Pit" note="Viper's Nest">
    <description>The Viper's Nest is known throughout the land for catering to the dregs of society.  The premises are often frequented by spies, conspirators, thieves, smugglers, rogue adventurers and crooked traders.  Folks congregate around long, rough-hewn tables, hunched forward listening, gesturing or speaking in harsh, sibilant whispers.  The ale is warm, the viands are inedible, nonetheless the Pit is jammed.  You notice a large proportion of S'Kra Mur and Gor'Togs in the mix.</description>
    <position x="-210" y="-170" z="0" />
    <arc exit="go" move="go scarred door" destination="708" />
    <arc exit="climb" move="climb dimly-lit staircase" destination="711" />
  </node>
  <node id="711" name="Viper's Nest, Attic">
    <description>The inn is not set up for overnight guests, but this cramped garret is often pressed into service for that purpose.  A filthy mattress with discolored ticking is thrown haphazardly in a corner.  Your feet adhere to the planks and, wondering why, you glance down to see reddish-brown spots that trail out the door.  A lone oil lamp provides dim light.  The harsh chatter of the crowd downstairs, and the scuffles from the courtyard insure that sleep here will be fitful at best.</description>
    <position x="-210" y="-180" z="0" />
    <arc exit="down" move="down" destination="710" />
  </node>
  <node id="712" name="Western Gate Tier, Guard House" note="W Guard House">
    <description>This customs post is the roughest and least desirable station in the entire Militia, and looking at the guards here, you have no doubt of it.  Recruits from the town's most formidable dungeons, a stint in the Militia their ticket to freedom.  Weary traders and travelers argue with them about tariffs, and a badly beaten thief and an unconscious black marketeer both dangle from iron manacles against the far wall.  You quickly turn and leave, hoping not to catch the eye of a surly guard.</description>
    <position x="-341" y="-328" z="0" />
    <arc exit="out" move="out" destination="121" />
  </node>
  <node id="713" name="Taelbert's Inn, Lobby" note="Taelbert's Inn" color="#00FF00">
    <description>Though many such inns dot the landscape, Taelbert's is known as especially hospitable to locals and wayfarers alike.  Here in the lobby, clerks busy themselves behind an antique mahogany counter, seeing to the needs of guests and directing the activities of the rather large staff.</description>
    <position x="-10" y="-418" z="0" />
    <arc exit="south" move="south" destination="715" />
    <arc exit="west" move="west" destination="714" />
    <arc exit="out" move="out" destination="122" />
    <arc exit="climb" move="climb wooden staircase" destination="719" />
  </node>
  <node id="714" name="Taelbert's Inn, Bar">
    <description>Bursts of laughter and excited shouts ring out from a game of dice being played at a corner table.  Other tables and chairs are scattered haphazardly through the room, but most of the regulars perch on high stools near the bar.  Apparently, the view of the buxom barmaid is more enticing from that angle.</description>
    <position x="-20" y="-418" z="0" />
    <arc exit="east" move="east" destination="713" />
  </node>
  <node id="715" name="Taelbert's Inn, Dining Room">
    <description>The spacious dining room is elegant, if slightly frayed at the edges.  Faded blue velvet chairs cluster around white linen-covered tables set with fine old silver and occasionally mismatched china.  Set between two pillars on the southwest wall, a curtained alcove offers privacy, and to the southeast, soft light spills outward from a quiet corner.</description>
    <position x="-10" y="-408" z="0" />
    <arc exit="north" move="north" destination="713" />
    <arc exit="go" move="go wide arch" destination="716" />
    <arc exit="go" move="go mahogany door" destination="718" />
  </node>
  <node id="716" name="Taelbert's Inn, Banquet Room">
    <description>Candles placed at regular intervals along several wide banquet tables light the room with a warm golden glow.  A single table placed at right angles to the rest sits atop a low platform near the northern wall.  Garlands of wildflowers drape in gentle spirals around stone pillars, filling the air with their delicate, sweet scent.</description>
    <position x="-10" y="-398" z="0" />
    <arc exit="go" move="go wide arch" destination="715" />
    <arc exit="go" move="go tiny alcove" destination="717" />
  </node>
  <node id="717" name="Taelbert's Inn, Alcove">
    <description>Little more than a niche off of the main banquet room, this dark alcove is at least quiet, if not sumptuous.  A faded sofa takes up much of the floorspace, and though not elegant by any means, it certainly appears inviting.</description>
    <position x="0" y="-398" z="0" />
    <arc exit="out" move="out" destination="716" />
  </node>
  <node id="718" name="Taelbert's Inn, Private Dining">
    <description>Softly polished mahogany lines the walls in this small room, creating an intimate setting for private dining.  The high-backed chairs are upholstered in rich forest-green velvet and are gathered round an elegantly set table.  On the wall opposite the doorway, a rough stone fireplace offers striking counterpoint to the simple elegance of the furnishings.</description>
    <position x="-20" y="-398" z="0" />
    <arc exit="out" move="out" destination="715" />
  </node>
  <node id="719" name="Taelbert's Inn, Hallway">
    <description>At one time, this inn must have been a private home, which explains the relatively few rooms available for guests.  Several doors open up off this second floor hallway, which makes a sharp turn to the north at the far end.</description>
    <position x="-10" y="-428" z="0" />
    <arc exit="north" move="north" destination="720" />
    <arc exit="climb" move="climb wooden staircase" destination="713" />
    <arc exit="go" move="go narrow door" destination="722" />
    <arc exit="go" move="go blue door" destination="723" />
    <arc exit="go" move="go oaken door" destination="724" />
  </node>
  <node id="720" name="Taelbert's Inn, Hallway" color="#00FFFF">
    <description>The north hall ends abruptly here at the quietest corner of the house.</description>
    <position x="-10" y="-438" z="0" />
    <arc exit="south" move="south" destination="719" />
    <arc exit="go" move="go white door" destination="721" />
  </node>
  <node id="721" name="Taelbert's Inn, Yellow Room">
    <description>White lace curtains flutter at the windows on the wall opposite the door, as a gentle breeze wafts through the room.  A sofa covered with yellow and blue chintz looks inviting, as does the massive bed set on a platform just to the left of the window.  Soft yellow wallpaper in a simple stripe pattern completes the picture of a quiet, inviting place to relax in peace.</description>
    <position x="-20" y="-438" z="0" />
    <arc exit="go" move="go white door" destination="720" />
  </node>
  <node id="722" name="Taelbert's Inn, Linen Closet">
    <description>Shelves stacked neatly with fresh linens line the walls from floor to ceiling.  In one corner, a pile of fluffy comforters looks oddly out of place in the otherwise well-ordered room.</description>
    <position x="0" y="-428" z="0" />
    <arc exit="go" move="go narrow door" destination="719" />
  </node>
  <node id="723" name="Taelbert's Inn, Blue Room">
    <description>Sky blue walls and indigo carpets combine to give this room a cool, soothing atmosphere.  The mahogany four-poster bed is covered with a patchwork satin comforter in shades of green and turquoise, offering a striking counterpoint to the crisp white, lace-edged linens that peek out from underneath.</description>
    <position x="-30" y="-428" z="0" />
    <arc exit="go" move="go blue door" destination="719" />
  </node>
  <node id="724" name="Taelbert's Inn, Cozy Room">
    <description>Though small in size, the room is comfortably furnished with a sturdy brass bed taking up much of the wall opposite the door, and a tiny desk tucked into one corner.  Thick braided rugs of deep green wool complement the walls, which have been painted a soft grey.</description>
    <position x="-30" y="-418" z="0" />
    <arc exit="go" move="go oaken door" destination="719" />
  </node>
  <node id="725" name="Clerics' Guild, Residential Cloisters">
    <description>A peaceful sitting area occupies the Fostra Square end of the cloisters, its three walls lined with low oak benches.  Plush velvet floor cushions in shades of cream and gold offer casual seating at the foot of each bench.  An elegant arrangement of flowers and fruits stands upon a highly polished table that occupies the center of the room, bringing a vibrant splash of color to the neutral tones of the cloister.</description>
    <position x="50" y="-558" z="0" />
    <arc exit="north" move="north" destination="726" />
    <arc exit="go" move="go portico gate" destination="125" />
  </node>
  <node id="726" name="Clerics' Guild, Residential Cloisters" color="#00FFFF">
    <description>The heady, cleansing aroma of incense wafts about the corridor, carried on a light breeze which floats in through an open window.  From outside, the peaceful cloister garden contributes its own natural perfume to the combination of fragrances which drift along the corridor and into the residential rooms which occupy this tranquil wing of the guild.</description>
    <position x="50" y="-578" z="0" />
    <arc exit="north" move="north" destination="727" />
    <arc exit="south" move="south" destination="725" />
  </node>
  <node id="727" name="Clerics' Guild, Residential Cloisters" color="#00FFFF">
    <description>The soft candlelight flickers soothingly in this corner, where the gentle motion of air from the cloister's windows combines to provide a refreshing, scented breeze.  Delicate twists of dried flowers and grasses decorate the otherwise unadorned white walls, and though their colors are faded, they are still as pleasing to the eye as they were the day the Gods first painted their frail petals.</description>
    <position x="50" y="-598" z="0" />
    <arc exit="south" move="south" destination="726" />
    <arc exit="west" move="west" destination="728" />
  </node>
  <node id="728" name="Clerics' Guild, Residential Cloisters" color="#00FFFF">
    <description>A constant light breeze whispers through an arched window, bringing with it the fresh scents of the cloister garden.  The intermittent ringing of bells drifts in reassuringly, bringing the soft melody of devotion into the corridor and forming a dulcet backdrop to the quiet rites of homage which cycle endlessly throughout the guild.</description>
    <position x="30" y="-598" z="0" />
    <arc exit="east" move="east" destination="727" />
    <arc exit="west" move="west" destination="729" />
  </node>
  <node id="729" name="Clerics' Guild, Residential Cloisters" color="#00FFFF">
    <description>Laid end-to-end along the hallway, heavy tapestry rugs render the cool stone floor soft and soundless underfoot and allow a reverential silence to blanket the candlelit corridor.  A magnificent mural occupies one wall, its muted pastel shades describing scenes from the lives of Elanthia's gods and the good men and women of local history.</description>
    <position x="10" y="-598" z="0" />
    <arc exit="east" move="east" destination="728" />
    <arc exit="west" move="west" destination="730" />
  </node>
  <node id="730" name="Clerics' Guild, Residential Cloisters" note="Todo: Go Iron Gate To Cleric-only Area" color="#00FFFF">
    <description>A simple whitewashed corridor runs around three sides of the cloister garden, its occasional arched windows overlooking the tranquil courtyard.  Ranged evenly along one wall, numerous doorways lead into the private rooms of the Guild's resident members.  The quiet murmur of whispered prayers envelopes the corridor in a deep feeling of calm and serenity.</description>
    <position x="-10" y="-598" z="0" />
    <arc exit="east" move="east" destination="729" />
    <arc exit="west" move="west" destination="731" />
  </node>
  <node id="731" name="Clerics' Guild, Residential Cloisters" color="#00FFFF">
    <description>Gentle candlelight illuminates the passageway with a soft golden glow, shining down from ornate iron candelabra and warming the corridor's plain white walls like late evening sunshine.  Great oak beams run the length of the cloister, supporting the vaulted ceiling and suspending the chandeliers at regular intervals along the center of the hallway.</description>
    <position x="-30" y="-598" z="0" />
    <arc exit="east" move="east" destination="730" />
    <arc exit="west" move="west" destination="732" />
  </node>
  <node id="732" name="Clerics' Guild, Residential Cloisters" color="#00FFFF">
    <description>An arched window allows passers-by to pause for a moment and admire the simple beauty of the cloister garden, its every leaf and branch a joyous tribute to the gods who give life to all things.  Inside the corridor, soft natural light blends comfortably with the flickering glow provided by the candelabra overhead, and by the banks of scented devotional candles arranged on iron stands outside each door.</description>
    <position x="-50" y="-598" z="0" />
    <arc exit="east" move="east" destination="731" />
    <arc exit="south" move="south" destination="733" />
  </node>
  <node id="733" name="Clerics' Guild, Residential Cloisters" color="#00FFFF">
    <description>A pair of potted willow trees decorates the hallway here, standing to either side of the corridor and adding shades of silver and green to the soft light in the cloister.  Carefully tended by the residents, the elegant trees grow tall and strong, their lush foliage responding to the love for living things which is nurtured and celebrated in the daily rituals of the guild.</description>
    <position x="-50" y="-578" z="0" />
    <arc exit="north" move="north" destination="732" />
    <arc exit="south" move="south" destination="734" />
  </node>
  <node id="734" name="Clerics' Guild, Residential Cloisters" color="#00FFFF">
    <description>Carved into the white plaster wall, a wide alcove is home to a selection of alabaster figurines, each one representing the benevolent aspect of the deities of Elanthia.  Beneath it, a simple iron stand holds a mass of tiny candles, each offering placed in worshipful thanksgiving for the kindnesses of the Gods.  Every little devotion is lovingly maintained at all times, and carefully replaced before its flame begins to dim.</description>
    <position x="-50" y="-558" z="0" />
    <arc exit="north" move="north" destination="733" />
  </node>
  <node id="735" name="Elite Architecture" note="Elite Architecture|Home Exteriors" color="#FF0000">
    <description>Shards of light glint on metallic inlays between the panels of expensive woods which line the walls of the shop.  Marble tiles and varnished flagstones spread across the floor, the surface polished to a glassy smoothness resembling a deep, still lagoon.  The elegant proprietor, Dulcinara, glides about the store with a natural grace, quietly demonstrating the quality of her wares to the monied folk who travel from afar to seek out her architectural expertise.</description>
    <position x="110" y="-548" z="0" />
    <arc exit="out" move="out" destination="133" />
  </node>
  <node id="736" name="The Bottom Line" note="Bottom Line|Chair Shop" color="#FF0000">
    <description>Warm yellow candlelight illuminates this welcoming cottage, and a log fire crackling in one corner adds to the homey comfort.  Bartina, a portly Dwarven woman with sparkling blue eyes and fat flaxen braids, bustles around the room flapping imaginary specks of dust from her selection of charming chairs.</description>
    <position x="170" y="-538" z="0" />
    <arc exit="out" move="out" destination="137" />
  </node>
  <node id="737" name="Martyr Saedelthorp, Dispensary" note="Dispensary|PHA">
    <description>Piremus the Chemist presides over the hospital's dispensary.  Wounded, battleweary adventurers are sprawled out on an uncomfortable wood bench.  The chemist barks out a name, and one of them slowly, painfully rises to pick up some prescribed medicinal preparations.  Potions, salves, unguents, powders, and pills of all hues line a rack behind the blood-smeared counter.  No one leaves the hospital without paying for an additional dose or two.</description>
    <position x="350" y="-428" z="0" />
    <arc exit="go" move="go hospital backdoor" destination="141" />
  </node>
  <node id="738" name="Gaethrend's Court, Foyer">
    <description>An elaborately ornamented desk serves as a check-in point for travellers seeking a night's rest.  Beside the ancient-looking wooden doorway which leads out, two amazingly detailed stone statues stand guard over the entryway.  You begin to wonder if they are truly the product of genius or perhaps the unfortunate result of some powerful mage's disfavor.  In the corner, a staircase leads up into darkness.</description>
    <position x="350" y="-458" z="0" />
    <arc exit="north" move="north" destination="741" />
    <arc exit="northeast" move="northeast" destination="740" />
    <arc exit="northwest" move="northwest" destination="739" />
    <arc exit="go" move="go ancient door" destination="144" />
    <arc exit="climb" move="climb dark staircase" destination="743" />
  </node>
  <node id="739" name="Gaethrend's Court, Solarium">
    <description>Amongst a variety of unrecognizable red-orange plants, you notice a small riolur bush flourishing in the sunlight.  The ceiling is much lower here but is made up of a number of small multi-colored glass panes which add a curious tint to the atmosphere.</description>
    <position x="340" y="-468" z="0" />
    <arc exit="northeast" move="northeast" destination="742" />
    <arc exit="east" move="east" destination="741" />
    <arc exit="southeast" move="southeast" destination="738" />
  </node>
  <node id="740" name="Gaethrend's Court, Barroom" note="Gaethrend's Court" color="#FF0000">
    <description>Plush red carpet surrounds a glistening pinewood bar where thirsty travellers stop for a taste of Gaethrend's finest brew.  A seemingly endless array of bottles are lined up in front of a classic long bar mirror.  You note a few of the bottles contain actively swirling elixirs, twisting about in their containers as if alive.</description>
    <position x="360" y="-468" z="0" />
    <arc exit="southwest" move="southwest" destination="738" />
    <arc exit="west" move="west" destination="741" />
    <arc exit="northwest" move="northwest" destination="742" />
  </node>
  <node id="741" name="Gaethrend's Court, Promenade">
    <description>A grand glass skylight allows the sun to shine in from above, lending the court a warm glow.  Several booths circle the area, occupied by magicians, astrologers, and various traders of magical wares.  A wrought-iron spiral stairway rises into some scaffolding high above the center of the promenade.</description>
    <position x="350" y="-468" z="0" />
    <arc exit="north" move="north" destination="742" />
    <arc exit="east" move="east" destination="740" />
    <arc exit="south" move="south" destination="738" />
    <arc exit="west" move="west" destination="739" />
  </node>
  <node id="742" name="Gaethrend's Court, Dining Room">
    <description>The quiet atmosphere and simple decor of the dining room soothes your nerves, making this the perfect spot for a relaxing meal with friends.  A regal-looking Eloth maitre d'hotel glides from table to table, keeping careful watch over his domain.</description>
    <position x="350" y="-478" z="0" />
    <arc exit="southeast" move="southeast" destination="740" />
    <arc exit="south" move="south" destination="741" />
    <arc exit="southwest" move="southwest" destination="739" />
  </node>
  <node id="743" name="Gaethrend's Court, Hallway" color="#00FFFF">
    <description>Light seems to follow you as you move about, allowing you to see what's in front of you but very little of what's beyond.  A slight hint of sulfur and garlic is prevalent throughout the hallway.</description>
    <position x="390" y="-458" z="0" />
    <arc exit="northeast" move="northeast" destination="746" />
    <arc exit="northwest" move="northwest" destination="744" />
    <arc exit="climb" move="climb dark staircase" destination="738" />
    <arc exit="go" move="go blue door" destination="747" />
  </node>
  <node id="744" name="Gaethrend's Court, Hallway" color="#00FFFF">
    <description>Light seems to follow you as you move about, allowing you to see what's in front of you but very little of what's beyond.  A slight hint of sulfur and garlic is prevalent throughout the hallway.</description>
    <position x="380" y="-468" z="0" />
    <arc exit="northeast" move="northeast" destination="745" />
    <arc exit="southeast" move="southeast" destination="743" />
    <arc exit="go" move="go green-blue door" destination="750" />
  </node>
  <node id="745" name="Gaethrend's Court, Hallway" color="#00FFFF">
    <description>Light seems to follow you as you move about, allowing you to see what's in front of you but very little of what's beyond.  A slight hint of sulfur and garlic is prevalent throughout the hallway.</description>
    <position x="390" y="-478" z="0" />
    <arc exit="southeast" move="southeast" destination="746" />
    <arc exit="southwest" move="southwest" destination="744" />
    <arc exit="go" move="go green door" destination="749" />
  </node>
  <node id="746" name="Gaethrend's Court, Hallway" color="#00FFFF">
    <description>Light seems to follow you as you move about, allowing you to see what's in front of you but very little of what's beyond.  A slight hint of sulfur and garlic is prevalent throughout the hallway.</description>
    <position x="400" y="-468" z="0" />
    <arc exit="southwest" move="southwest" destination="743" />
    <arc exit="northwest" move="northwest" destination="745" />
    <arc exit="go" move="go blue-green door" destination="748" />
  </node>
  <node id="747" name="Gaethrend's Court, Bedroom">
    <description>This simple room contains everything you need for a good night's rest including a bed, dresser, and personal bath.  Everything here has a light blue tint.  Over the dresser, a mirror shows the reflection of the entire room except for your own, which is disturbingly absent.</description>
    <position x="390" y="-468" z="0" />
    <arc exit="go" move="go blue door" destination="743" />
  </node>
  <node id="748" name="Gaethrend's Court, Bedroom">
    <description>The light in this room is slowly shifting in color, causing the furnishings to appear to change from light blue to light green and back.  A complimentary yellow potion has been left sitting on the nightstand, but what the potion actually does is a subject for speculation.</description>
    <position x="400" y="-458" z="0" />
    <arc exit="go" move="go blue-green door" destination="746" />
  </node>
  <node id="749" name="Gaethrend's Court, Bedroom">
    <description>You are startled by the fact that the entire room seems built at a forty-five degree angle.  Even the small window in the far wall shows a tilted scene, and the overall effect is making you a bit ill.  On the angled dresser next to the bed, three silver spheres rest perfectly still, quietly ignoring the laws of gravity.</description>
    <position x="400" y="-478" z="0" />
    <arc exit="go" move="go green door" destination="745" />
  </node>
  <node id="750" name="Gaethrend's Court, Bedroom">
    <description>The light in this room is slowly shifting in color, causing the furnishings to shift from light green to light blue and back.  A complimentary red potion has been left sitting on the nightstand, but what the potion actually does is a subject for speculation.</description>
    <position x="380" y="-478" z="0" />
    <arc exit="go" move="go green-blue door" destination="744" />
  </node>
  <node id="751" name="Tower East, Air Floor" note="Tower East|Air Floor" color="#00FFFF">
    <description>A dark grey carpet decorated with a pattern of crossing black lightning bolts covers the floor, matching the decoration on the grey-painted walls.  A constant, low thrum hangs just inside the range of hearing, its source nearby but not readily apparent.  Doors spaced in an even circle around the perimeter lead to initiates' private cells.</description>
    <position x="390" y="-20" z="0" />
    <arc exit="up" move="up" destination="752" />
    <arc exit="out" move="out" destination="157" />
    <arc exit="climb" move="climb oak staircase" destination="755" />
  </node>
  <node id="752" name="Tower East, Water Floor" note="Water Floor" color="#00FFFF">
    <description>Deep blue carpeting covers the floor, its surface cut in a manner that suggests the rippling of waves upon the surface of a lake.  Bright blue spirals, representing the element of water, fill the walls between a series of doors leading to initiates' private cells.  The air here is moist and cool upon the skin.</description>
    <position x="390" y="-30" z="0" />
    <arc exit="up" move="up" destination="753" />
    <arc exit="down" move="down" destination="751" />
  </node>
  <node id="753" name="Tower East, Fire Floor" note="Fire Floor" color="#00FFFF">
    <description>Lush, red carpeting covers the floor, muffling any ambient noise into oblivion.  Images of bloated red suns, representing the element of fire, fill the walls between a series of doors leading to initiates' private cells.  The air here is significantly warmer than on the tower's other floors, although the reason is not readily apparent.</description>
    <position x="390" y="-40" z="0" />
    <arc exit="up" move="up" destination="754" />
    <arc exit="down" move="down" destination="752" />
  </node>
  <node id="754" name="Tower East, Aether Floor" note="Aether Floor" color="#00FFFF">
    <description>Carpeting the color of a death shroud covers the floor, devouring the light as hungrily as Aldauth consumes souls.  The walls are devoid of decoration, instead painted a uniform black to match the floor.  Only the doors leading to initiates' cells betray any hint of color in this otherwise cold, bleak room.</description>
    <position x="390" y="-50" z="0" />
    <arc exit="down" move="down" destination="753" />
  </node>
  <node id="755" name="Tower East, Earth Floor" note="Earth Floor" color="#00FFFF">
    <description>Bare, dark soil forms the floor underfoot.  The stony walls surrounding this circular room are similarly devoid of decoration, keeping instead the plain, natural look preferred by those mages who favor the element of Earth.  Doors leading to the initiates' private cells line the walls.</description>
    <position x="390" y="-10" z="0" />
    <arc exit="climb" move="climb oak staircase" destination="751" />
  </node>
  <node id="756" name="Eastern Gate, Guard House" note="E Guard House">
    <description>A few guards listlessly lean against the walls here in this shack.  There is not even anything to sit on in here, to insure they do not fall asleep at their posts.  A Gor'Tog day laborer, in shackles, is questioned by one sullen guard who doesn't seem particularly interested in answers.</description>
    <position x="390" y="40" z="0" />
    <arc exit="out" move="out" destination="162" />
  </node>
  <node id="757" name="Tamsine's Rest" note="Shrine1-01|Tamsine's Rest" color="#A6A3D9">
    <description>A shady clump of sicle saplings cluster around a large, moss-encrusted fragment of pink coral.  Carved into a hollow in the center of the coral landmark is a crude yet moving image of Tamsine, one of the patron goddesses of the town.  Before the simple shrine is a low limestone bench, where the weary traveler might take some rest in the shade, leave offerings of flowers or food, and contemplate matters of the soul and spirit.</description>
    <position x="230" y="100" z="0" />
    <arc exit="east" move="east" destination="164" />
    <arc exit="go" move="go low gate" destination="758" />
  </node>
  <node id="758" name="Tamsine's Rest, Memorial Tea Garden" note="Memorial Tea Garden|water">
    <description>Water burbles over rocks to fill a shallow stone basin, conveniently positioned for visitors wishing to wash their hands upon entering the garden.  Thick cushions of green moss soften the stones and carpet the ground underfoot.  Red azaleas, deep purple irises and white chrysanthemums add vibrant touches of color against the velvety moss.  At the center of the garden, ribbon-tied parchment scrolls flutter from a red maple tree, celebrating the memory of loved ones lost.</description>
    <position x="220" y="100" z="0" />
    <arc exit="go" move="go low gate" destination="757" />
  </node>
  <node id="759" name="Asemath Academy, Library Hall" note="Dictionaries|Languages">
    <description>The library of the Academy is famed far and wide for its large collection of printed works on the Arts and Sciences.  A wall-long shelf holds this treasure securely against time and wearing.  Many comfortable chairs and low tables are scattered about for the ease of readers and several desks are available for the more serious scholar.  Several students are sprawled out in chairs reading and one is at a desk, crouched over a parchment, scribbling away on a notepad.</description>
    <position x="30" y="-272" z="0" />
    <arc exit="go" move="go polished doors" destination="206" />
  </node>
  <node id="760" name="Asemath Academy, Gallery of Fine Arts">
    <description>This room is a gallery for all manner of art.  Paintings adorn the walls and niches hold statues of many sorts.  Large skylights bring in a flattering light and the north end of the room is set aside for use as a studio for painting and sculpting.</description>
    <position x="0" y="-262" z="0" />
    <arc exit="go" move="go stone door" destination="215" />
  </node>
  <node id="761" name="Asemath Academy, Founder's Theatre">
    <description>This theatre is large enough to hold the entire staff and student body as well as at least a hundred more.  Comfortable seating slopes down to a raised stage so that all have an excellent view.  Dedicated to Asemath the Founder, one seat in the front row is always left vacant as a tribute to his efforts in building the Academy named after him.</description>
    <position x="20" y="-262" z="0" />
    <arc exit="go" move="go wooden door" destination="215" />
  </node>
  <node id="762" name="Ragge's Locksmithing, Back Room">
    <description>Taking a good look at some of the other customers, who appear at odd intervals, you find yourself clutching the coins in your pocket a little more closely.  Surreptitiously, you glance around to note that although the room itself is rather nondescript, the clientele is extremely colorful.  In one corner, the rickety folding table is apparently the center of attention, and though it makes you slightly nervous to do so, you quietly make your way over to peruse the merchandise.</description>
    <position x="-30" y="-100" z="0" />
    <arc exit="out" move="out" destination="218" />
    <arc exit="go" move="go trap door" destination="763" />
  </node>
  <node id="763" name="Ragge's Locksmithing, Basement">
    <description>This might be some sort of storeroom, but the contents don't really fit what you know of the shop above.  Though the walls are lined with shelves, very few contain anything approaching what one would expect from a locksmith.  Glints of silver and gold catch your eye, as do the sparkling facets of more than a few pieces of rather expensive looking jewelry.  A barred window looks secure enough, and provides an interesting view of the feet of passersby outside.</description>
    <position x="-30" y="-90" z="0" />
    <arc exit="go" move="go trap door" destination="762" />
  </node>
  <node id="764" name="Mauriga's Botanicals, Root Cellar">
    <description>A stair carpeted with a richly patterned runner leads down to the root cellar when Mauriga prepares and preserves her concoctions, based on ancient clan and family recipes.  Raw materials fill jar after crystal jar, on niches in the earthen walls.  Always needful of ingredients, she happily buys herbs from adventurers and keeps them here as well.  A few serious-looking Elves and Eloths, and a snoozing Halfling, sit around a mixing table, fiddling with scales, scoops, and vials.</description>
    <position x="190" y="-398" z="0" />
    <arc exit="climb" move="climb carpeted stair" destination="219" />
  </node>
  <node id="765" name="Barana's Shipyard, Drying Kiln">
    <description>Heavy stone floors and walls retain a good deal of heat.  This dries the damp river air and makes this large enclosure almost a pleasant resting place.  Thick layers of soot on everything makes it unwise to sit or rest anything valuable on the ground or anywhere else.  Unlike the killing heat needed to fire ceramics, this place is more like a smokehouse.  Green wood is brought here to age and dry under controlled conditions, to assure it remains straight and true.</description>
    <position x="60" y="350" z="0" />
    <arc exit="go" move="go kiln door" destination="244" />
  </node>
  <node id="766" name="Willow Walk, Up a Linden Tree" note="Linden Tree">
    <description>The entire northeast corner of the city can be seen from this vantage point high above the rooftops.  To the north rises the gleaming white block of the Paladin's Guild, tucked up against the city walls marking the edge of the forests to the northeast.  The glowing windows of Gaethrend's Court are visible to the east, and the bustle of the Infirmary and the Empath's Guild lying to the south can be only dimly heard.</description>
    <description>The entire northeast corner of the city can be seen from this vantage point high above the rooftops, lights twinkling through the darkness.  To the north is dimly visible the gleaming white block of the Paladin's Guild, tucked up against the city walls marking the edge of the forests to the northeast.  The pulsating glow of Gaethrend's Court lights the sky to the east, and the bustle of the Infirmary and the Empath's Guild lying to the south can be only dimly heard.</description>
    <position x="240" y="-478" z="0" />
    <arc exit="climb" move="climb tree trunk" destination="252" />
  </node>
  <node id="767" name="Willow Walk, Water Lily Pool" note="Pool">
    <description>Water trickling down from the fountain provides a constant musical backdrop.  Tiny fish swim among the floating water lilies, darting up to the surface occasionally to search for their next meal.  The water, coming from wells far below the surface, remains cool to the touch in every season.</description>
    <position x="260" y="-438" z="0" />
    <arc exit="go" move="go garden" destination="260" />
  </node>
  <node id="768" name="Treetop Perch">
    <description>A small platform wedged between two large limbs provides a stable resting place high in the apple tree.  A canopy of leaves blocking out most of the view of the sky and the ground below gives the perch a feeling of privacy.  It is not exactly quiet here, but the bright song of birds and whisper of a breeze passing over verdant green foilage is pleasant and soothing.  The sturdy trunk of the tree has a couple of steps hammered down the side to aid climbing to the ground below.</description>
    <description>A small platform wedged between two large limbs provides a stable resting place high in the apple tree.  A canopy of leaves that blocks out most of the sky and ground gives the perch a feeling of privacy.  It is not exactly quiet here, but the gentle chirp of crickets and the whispering rush of water in the creek below is pleasant and soothing.  The sturdy trunk of the tree has several steps hammered down the side to aid climbing to the ground below.</description>
    <position x="230" y="-230" z="0" />
    <arc exit="climb" move="climb tree trunk" destination="266" />
  </node>
  <node id="769" name="Barbarian Guild, Champions' Arena" note="Champions' Arena">
    <description>A perimeter of immense granite walls and galleries encloses this stark field of death.  Rough gravel carpets the battleground, the brown stains of blood distinctly visible against the pale rocks, tainting the arena like a scourge.  To the south lies a caged portcullis from which unknown lethal opponents can be unleashed into battle.</description>
    <position x="320" y="-388" z="0" />
    <arc exit="go" move="go portcullis" destination="305" />
  </node>
  <node id="770" name="Barbarian Guild, Arena Stands" note="Arena Stands">
    <description>Ringed by a steel railing, rows of stone seats afford an excellent view of the arena below.  An iron-bound oak door leads deeper into the guild, while a spiral staircase leads back down to the stadium pits.  Keeping a wary eye on those present, a large Gor'Tog guards a leather flap on the far wall.</description>
    <position x="330" y="-398" z="0" />
    <arc exit="climb" move="climb staircase" destination="305" />
    <arc exit="go" move="go oak door" destination="771" />
    <arc exit="go" move="go flap" destination="776" />
  </node>
  <node id="771" name="Barbarian Guild, The Slaughter House">
    <description>Leather chairs line the lounge, allowing the patrons to sit comfortably around wooden tables.  The bartender, Rushleel, stands behind a long teak-topped bar along the northern wall, serving drinks to thirsty warriors.  Directly opposite the bar, samples of the cuilinary delights available from the menu are displayed atop a sideboard.  A large iron-bound oak door leads into the viewing area overlooking the Champions' Arena.</description>
    <position x="340" y="-388" z="0" />
    <arc exit="go" move="go oak door" destination="770" />
  </node>
  <node id="772" name="Thrifty Doors" note="Thrifty Doors|Doors" color="#FF0000">
    <description>Large rectangular wooden tables clutter this small room, each one bowed under the weight of a stack of doors.  Unfinished and second-hand doors lean against the walls and lurch in heaps on the floor, and several of the better specimens hang on chains from the rafters.  A grumpy-looking Dwarf leans against a battered oak counter, squinting suspiciously at customers and sucking noisily on a clay pipe which belches thick brown smoke into the air.</description>
    <position x="-160" y="-240" z="0" />
    <arc exit="go" move="go deobar door" destination="338" />
  </node>
  <node id="773" name="Clerics' Guild, Wine Cellar">
    <description>As your eyes adjust to the sudden darkness, you see several bookshelves that have been converted into criss-crossed wine racks with a corked bottle in each cubby hole.  The air is cool and dry, making this the perfect storage area for the aging liquid.</description>
    <position x="0" y="-548" z="0" />
    <arc exit="climb" move="climb wooden stairway" destination="348" />
    <arc exit="go" move="go sloping tunnel" destination="1006" />
  </node>
  <node id="774" name="Luthier's, Private Showroom" note="Luthier's" color="#FF0000">
    <description>Tiny gaethzen globes light the room, adding a soft gleam to the silks draping the displays and tables that feature some of the luthier's more intricate work, available for his most discriminating clients.  A settee provides seating, and a small tray offers beverages and snacks to entice those shopping into staying longer -- and buying more.  A heavy lined curtain leads back out to the main shop.</description>
    <position x="90" y="-160" z="0" />
    <arc exit="go" move="go lined curtain" destination="401" />
  </node>
  <node id="775" name="Brother Durantine's, Private Salon">
    <description>This small room is for private consultations with Brother Durantine.  A low table and a pair of plain chairs are the only real furnishings.  A small incense burner wafts a heavy musky scent around the room.</description>
    <position x="110" y="10" z="0" />
    <arc exit="out" move="out" destination="407" />
  </node>
  <node id="776" name="Barbarian Guild, Private Seats">
    <description>Several rows of leather-clad seats offer plenty of room to sit and cheer on a favored combatant.  Plush damask draperies cover the back and side walls of this exclusive viewing box, while a polished teak railing separates the spectators from the gladiators below.  Opposite the exit flap, a small buffet offers a few choice tidbits for the parched or hungry pit fanatic.</description>
    <position x="340" y="-398" z="0" />
    <arc exit="go" move="go flap" destination="770" />
  </node>
  <node id="777" name="Barbarian Guild, Atrium">
    <description>Pale pillars of carved ashen granite surge upwards, encircling and supporting a large globular chandelier.  The golden light accentuates the carvings and bathes the atrium in brilliance.</description>
    <position x="330" y="-368" z="0" />
    <arc exit="south" move="south" destination="778" />
    <arc exit="go" move="go archway" destination="783" />
    <arc exit="go" move="go double doors" destination="785" />
    <arc exit="go" move="go flame-shaped opening" destination="786" />
    <arc exit="climb" move="climb stairway" destination="302" />
  </node>
  <node id="778" name="Barbarian Guild, Dormitory Row" color="#00FFFF">
    <description>Large granite tiles stretch the length of the hallway, cushioned only by a jewel-toned runner woven with intricate geometric designs.  The steady flames of iron-banded oil lamps illuminate the wall tapestries and bathe the stone walls in a welcoming glow.  Two large steel sculptures stand like guardians at the entrance of the hallway.</description>
    <position x="330" y="-338" z="0" />
    <arc exit="north" move="north" destination="777" />
    <arc exit="west" move="west" destination="779" />
  </node>
  <node id="779" name="Barbarian Guild, Dormitory Row" color="#00FFFF">
    <description>Large granite tiles stretch the length of the hallway, cushioned only by a jewel-toned runner woven with intricate geometric designs.  The only significant decoration for this portion of the hallway is a vivid wall mosaic depicting a lone man holding aloft a bloodied sword.</description>
    <position x="320" y="-338" z="0" />
    <arc exit="east" move="east" destination="778" />
    <arc exit="west" move="west" destination="780" />
  </node>
  <node id="780" name="Barbarian Guild, Dormitory Row" color="#00FFFF">
    <description>Nestled in a corner between two doors is a polished ebony sculpture in the shape of a snarling wolf.  Padded benches, too low and narrow to comfortably sit upon, provide a place for those wishing to meditate.  A gnarled ironwood war club is clenched within the wolf's snarling maw, one of the many relics on display throughout the guildhall's corridors.</description>
    <position x="310" y="-338" z="0" />
    <arc exit="north" move="north" destination="781" />
    <arc exit="east" move="east" destination="779" />
  </node>
  <node id="781" name="Barbarian Guild, Dormitory Row" color="#00FFFF">
    <description>No ornamentation softens the hallway's stark stone walls.  Grey on grey, ceiling flows into wall into floor with little variation in color or texture.  The monochromatic surroundings are broken by a thick-paned window on the western wall.  Stretching from floor-to-ceiling, the window offers a clear view of the Champions' Square outside.</description>
    <position x="310" y="-368" z="0" />
    <arc exit="north" move="north" destination="782" />
    <arc exit="south" move="south" destination="780" />
  </node>
  <node id="782" name="Barbarian Guild, Common Room" color="#00FFFF">
    <description>The hallway opens up into this spacious circular chamber.  Heavy damask draperies cover the stone walls, broken only by a few iron-banded oil lamps and the doors blocking entrance into their respective living quarters.  Standing like a lone sentinel at the center of the room, an intricately carved totem rises nearly to the ceiling, its commanding presence demanding full attention.</description>
    <position x="310" y="-378" z="0" />
    <arc exit="south" move="south" destination="781" />
  </node>
  <node id="783" name="Barbarian Guild, Vishlan's Wares" note="Vishlan's Wares|Barbarian Shop" color="#FF0000">
    <description>Highly polished mahogany paneling reflects and intensifies the flickering light cast by wrought iron sconces bolted to the walls.  Narrow veins of crimson crystal thread through the black marble floor, spreading across the surface like curling tongues of flame.  Cherry and ebonwood shelves hang along one wall, while a wide mahogany counter contains several displays.</description>
    <position x="340" y="-378" z="0" />
    <arc exit="east" move="east" destination="784" />
    <arc exit="go" move="go ebonwood archway" destination="777" />
  </node>
  <node id="784" name="Barbarian Guild, Vishlan's Wares" color="#FF0000">
    <description>The highly polished mahogony paneling continues on from the main room, reflecting and intensifying the flickering light cast by wrought iron sconces bolted to the walls.  Narrow veins of crimson crystal sparkle in the black marble floor, spreading across the surface like curling tongues of flame.  A rack rests against one wall between an oak table and an ebonwood shelf.</description>
    <position x="350" y="-378" z="0" />
    <arc exit="west" move="west" destination="783" />
  </node>
  <node id="785" name="Barbarian Guild, The Brunken Darbarian" note="Barbarian bar" color="#FF0000">
    <description>Leather chairs line the lounge, allowing the patrons to sit comfortably around wooden tables.  The bartender, Rushleel, stands behind a long teak-topped bar along the northern wall, serving drinks to thirsty warriors.  Directly opposite the bar, samples of the culinary delights available from the menu are displayed atop a sideboard.  A large iron-bound oak door leads into the viewing area overlooking the Champions' Arena.</description>
    <position x="340" y="-338" z="0" />
    <arc exit="go" move="go double doors" destination="777" />
    <arc exit="go" move="go oak door" destination="770" />
  </node>
  <node id="786" name="Barbarian Guild, Antechamber" note="Antechamber">
    <description>Granite benches divide the room into a central square surrounded by a wide onyx-floored walkway.  Within the square, a pillar of twisting flames roar up from a wrought-iron brazier with the commanding vigor of a berserker's rage.  Banners and tapestries depicting fierce battle scenes line the antechamber's walls.</description>
    <position x="340" y="-368" z="0" />
    <arc exit="go" move="go flame-shaped opening" destination="777" />
  </node>
  <node id="787" name="Paladins' Guild, Library">
    <description>A small table surrounded by chairs rests in the center of the room, enclosed on all sides by towering shelves stocked full with books and journals.  The colorful spines of the manuscripts depict the names of masterpieces collected over the years, and some bear tell-tale signs of wear and age.  A large sign with gold-foil lettering hangs behind a mahogany book return desk.</description>
    <position x="355" y="-546" z="0" />
    <arc exit="go" move="go wooden doors" destination="798" />
  </node>
  <node id="788" name="The Crossing, Herald Street" note="tithe box">
    <description>You stand before a pristine white building, two stories high - the Paladins' Guild.  Its roof is angled to catch the rays of the sun, moons and stars through a crystal skylight set into one of the eaves.  The only color is provided by round, stained-glass windows, depicting vignettes from the lives of illustrious paladins of Elanthia's past.  An arched doorway topped by a carved wooden lintel leads inside.</description>
    <position x="210" y="-588" z="0" />
    <arc exit="south" move="south" destination="142" />
    <arc exit="go" move="go arched doorway" destination="789" />
  </node>
  <node id="789" name="Paladins' Guild, Meeting Hall" note="Paladins' Guild">
    <description>Light shines in from above through a large skylight placed in the ceiling of this grand hall.  All of the chairs have been arranged in a circle, representing the symbolic equality of all guild members.  Mounted above the doorway, a shining silver broadsword points skyward.</description>
    <position x="297" y="-536" z="0" />
    <arc exit="east" move="east" destination="791" />
    <arc exit="west" move="west" destination="790" />
    <arc exit="out" move="out" destination="788" />
    <arc exit="go" move="go marble arch" destination="793" />
  </node>
  <node id="790" name="Paladins' Guild, Armory">
    <description>Displays of armor and shields line the walls, some plain save for the scars of battle, some gleaming bright and emblazoned with the devices of noble houses.  Myriad weapons of war and peace sit behind unlocked glass cases, on display until the day when they must once more be lifted in the name of the gods and the Light.  A weapons rack has been fitted into one wall for the express purpose of outfitting those warriors of the Guild who lack the coin for proper gear.</description>
    <position x="287" y="-536" z="0" />
    <arc exit="east" move="east" destination="789" />
  </node>
  <node id="791" name="Paladins' Guild, Chambers">
    <description>Several mats have been spread about this quiet chamber.  A single circular stained-glass window allows light to softly brighten the room.  Simple weapon racks have been placed before each mat, allowing the seeking paladin a room to meditate before his sword, in hopes of visualizing the purest path.</description>
    <position x="307" y="-536" z="0" />
    <arc exit="west" move="west" destination="789" />
    <arc exit="go" move="go soulstone archway" destination="792" />
  </node>
  <node id="792" name="Paladins' Guild, Hallway">
    <description>The hallway walls are lined with portraits of the Guild leaders and tapestries depicting beautiful scenes and ancient heroes hang from the ceiling.  A set of brass-bound ironwood doors stands at the end of the hall.  Flanking the doors are two Gor'Tog-sized suits of gleaming silver ceremonial plate armor, complete with gigantic pole-axes sporting nasty serrated blades.</description>
    <position x="327" y="-536" z="0" />
    <arc exit="out" move="out" destination="791" />
    <arc exit="go" move="go marble arch" destination="794" />
    <arc exit="go" move="go oak door" destination="795" />
    <arc exit="go" move="go ironwood doors" destination="796" />
  </node>
  <node id="793" name="Paladins' Guild, Guild Leader's Office" note="GL Paladin|Verika|RS Paladin" color="#FF8000">
    <description>Despite the dark, foreboding atmosphere in this office, it is strangely comforting.  A large cave bear hide lies on the floor in front of a small fireplace.  Off to the side, a comfortable looking chair is placed adjacent to a bookcase and a small table.  A large desk sits directly opposite the fireplace and fills out the room's meager, but functional, furnishings.</description>
    <position x="297" y="-546" z="0" />
    <arc exit="out" move="out" destination="789" />
  </node>
  <node id="794" name="Paladins' Guild, Training Room" note="Training Room">
    <description>The training room smells of sweat and the air is hot.  Large posters are tacked to the walls amidst racks for weapons and hooks for shields.  The floor is heavily scarred and notched and, although it looks as though it's been swept clean, the deeper gouges are still caked with blood-soaked sawdust.</description>
    <position x="327" y="-516" z="0" />
    <arc exit="out" move="out" destination="792" />
    <arc exit="climb" move="climb stairwell" destination="797" />
  </node>
  <node id="795" name="Paladins' Guild, Portico" note="Portico">
    <description>A covered breezeway, this portico connects the main guildhall with the courtyard and outer buildings of the compound.  The tiled roof covering the long corridor is draped with softly twisting vines and offers shade from the sun in summer and shelter from the elements the rest of the year.  Weary combatants in training are often seen resting here among the greenery.</description>
    <position x="327" y="-556" z="0" />
    <arc exit="north" move="north" destination="799" />
    <arc exit="go" move="go oak door" destination="792" />
  </node>
  <node id="796" name="Paladins' Guild, The Great Chamber" note="Great Chamber">
    <description>Tapestries and flickering torches line the walls of the circular meeting room.  Eight sets of silverwood benches, arranged in ascending rows, face a central speaker's podium.  The topmost row, a full three Tog-lengths above the main floor, sits at eye level with a large chandelier that hangs from the ceiling.</description>
    <position x="347" y="-536" z="0" />
    <arc exit="go" move="go ironwood doors" destination="792" />
    <arc exit="climb" move="climb ironwood staircase" destination="798" />
  </node>
  <node id="797" name="Paladins' Guild, Basement" note="Basement">
    <description>The short stairwell opens up to a shadowy room barely lit by a steel candleholder.  The smell of must indicates a lack of ventilation however, there is a sense of simple tidiness.  A large rug in the center of the room partially covers a dark stone floor that is kept swept and clean.</description>
    <position x="337" y="-516" z="0" />
    <arc exit="climb" move="climb stairwell" destination="794" />
  </node>
  <node id="798" name="Paladins' Guild, Balcony" note="Balcony">
    <description>A well-polished ironwood banister guards the narrow walkway that overlooks the Grand Hallway.  Spanning the length of the wooden floor is a tightly woven rug of forest green that slips beneath a pair of massive wooden double doors, each set with a bronze knocker fashioned into a roaring lion's head.</description>
    <position x="347" y="-546" z="0" />
    <arc exit="climb" move="climb ironwood staircase" destination="796" />
    <arc exit="go" move="go wooden doors" destination="787" />
  </node>
  <node id="799" name="Paladins' Guild, Courtyard">
    <description>Supported by iron lattices, wild rose bushes cling together forming a dense wall of brilliant scarlet against a backdrop of lush evergreens.  Veins of ebony streak through the grey marble flagstones, their pattern spiraling in towards a bronzed statue.  Beyond it, a stone bench with ornate armrests stands watch over an open, iron gate.</description>
    <position x="327" y="-566" z="0" />
    <arc exit="south" move="south" destination="795" />
    <arc exit="go" move="go iron gate" destination="800" />
  </node>
  <node id="800" name="Paladins' Guild, Training Grounds">
    <description>A simple, marbled pathway winds its way around the spacious grassy yard, breaking off in many directions.  Casting a canopy of shade over those engaging in contests of skill is a massive flamethorne tree with a leather-wrapped target dummy swaying from a low, sturdy limb.  To the east, a series of wooden rails peek above the horizon, tracing a distant line of fencing.</description>
    <description>A simple, marbled pathway winds its way around the spacious grassy yard, breaking off in many directions.  Veiling the stars from those engaging in contests of skill is a massive flamethorne tree with a leather-wrapped target dummy swaying from a low, sturdy limb.  To the east, a series of wooden rails peek above the horizon, tracing a distant line of fencing.</description>
    <position x="327" y="-586" z="0" />
    <arc exit="north" move="north" destination="801" />
    <arc exit="northeast" move="northeast" destination="802" />
    <arc exit="west" move="west" destination="803" />
    <arc exit="go" move="go iron gate" destination="799" />
    <arc exit="go" move="go pebbled path" destination="866" />
  </node>
  <node id="801" name="Paladins' Guild, Northern Courtyard">
    <description>A large vine-covered edifice, this building looms over the courtyard and is matched in height only by the guild proper.  Ivy, speckled with tiny violet flowers, twines around the flagstones as they broaden into half-moon shaped steps before a polished ebonwood door.  Hanging from the entryway is an inlaid wooden sign, its darkened lettering set upon a lighter field.  A cobbled drive winds behind the building where artisans are often seen unloading new wares and custom crafted armor and weaponry.</description>
    <position x="327" y="-596" z="0" />
    <arc exit="south" move="south" destination="800" />
    <arc exit="go" move="go ebonwood door" destination="811" />
  </node>
  <node id="802" name="Paladins' Guild, Northeast Courtyard">
    <description>Smooth, multicolored river pebbles line the ground before a large wooden barn.  Tufts of grass peek between the gravel at the stone foundation, the tips of their blades just grazing the redwood slats.  An overhanging chute juts out from above and bits of straw and hay cling tenaciously to the metallic mouth as if afraid to let loose and tumble to the stony floor below.</description>
    <position x="337" y="-596" z="0" />
    <arc exit="southwest" move="southwest" destination="800" />
    <arc exit="go" move="go wooden barn" destination="819" />
  </node>
  <node id="803" name="Paladins' Guild, Western Courtyard">
    <description>The path ends abruptly before an elongated, neatly trimmed building, its tiled roof overhanging rows of double windows that gaze over the courtyard like pairs of unblinking eyes.  Long benches placed on the porch offer a place to sit while removing muddy boots, and young squires are often seen sweeping the long porch under the careful watch of an armored guard.  Standing near the oaken doors, a silent protector and observer, he casts a dark shadow over a nearby bronze spittoon.</description>
    <position x="317" y="-586" z="0" />
    <arc exit="east" move="east" destination="800" />
    <arc exit="go" move="go porch" destination="832" />
  </node>
  <node id="804" name="Paladins' Guild, Sentinel's Way">
    <description>The pebbled path widens into an elongated patio, shaded by a lush copse of evergreen trees.  Their darkened branches provide a canopy of shade and the scent of pine lingers heavily in the air.  A gentle trickling echoes with the passing breeze, indicating a nearby presence of water while the melodic voices of songbirds add to the rustic setting.</description>
    <position x="347" y="-586" z="0" />
    <arc exit="go" move="go path" destination="800" />
    <arc exit="go" move="go vine-covered trellis" destination="805" />
  </node>
  <node id="805" name="Paladins' Guild, Sentinel's Rest">
    <description>Surrounded by lush greenery, the crystal clear waters of a small, limpid pool reflect the sun's light and sparkle brilliantly.  Lily pads speckle the surface, clustering together near the middle and bouncing gently with the ripples from a nearby waterfall.  Several well-kept pebbled paths branch off in opposite directions, each trimmed with small purplish flowers.</description>
    <position x="367" y="-586" z="0" />
    <arc exit="north" move="north" destination="806" />
    <arc exit="northeast" move="northeast" destination="809" />
    <arc exit="east" move="east" destination="808" />
    <arc exit="southeast" move="southeast" destination="810" />
    <arc exit="south" move="south" destination="807" />
    <arc exit="go" move="go vine-covered trellis" destination="804" />
  </node>
  <node id="806" name="Paladins' Guild, Holy Warrior's Promenade" note="Holy Warrior's Promenade" color="#00FFFF">
    <description>Several young saplings are interspersed within the older, taller growths.  Though shielded from the life-giving sun, they are strong and sturdy and thrive heartily.  The meticulously painted fence tapers to an end with one long beam extending diagonally towards the ground.</description>
    <position x="367" y="-596" z="0" />
    <arc exit="east" move="east" destination="809" />
    <arc exit="south" move="south" destination="805" />
    <arc exit="go" move="go winding trail" destination="146" />
  </node>
  <node id="807" name="Paladins' Guild, Holy Warrior's Promenade" color="#00FFFF">
    <description>A neat row of trimmed hedges borders a quaint whitewashed fence, their branches carefully clipped to form a perfect rectangular shape.  Growing in lush clumps, small pale purple flowers edge the colorful pebbled path and fill the air with the sweet scent of lavender.</description>
    <description>A neat row of trimmed hedges borders a quaint whitewashed fence, their branches carefully clipped to form a perfect rectangular shape.  Growing in lush clumps, small flowers edge the colorful pebbled path and fill the air with the sweet scent of lavender.</description>
    <position x="367" y="-576" z="0" />
    <arc exit="north" move="north" destination="805" />
    <arc exit="east" move="east" destination="810" />
  </node>
  <node id="808" name="Paladins' Guild, Holy Warrior's Promenade" color="#00FFFF">
    <description>Twined between the fence's whitewashed slats, wild raspberries cling tenaciously, their branches a thorny tangle.  Nestled among the briars, several clumps of berries dangle heavily -- dark and purple and ready for the picking.  A lush sweet fragrance drifts from their tiny white flowers.</description>
    <position x="377" y="-586" z="0" />
    <arc exit="north" move="north" destination="809" />
    <arc exit="south" move="south" destination="810" />
    <arc exit="west" move="west" destination="805" />
  </node>
  <node id="809" name="Paladins' Guild, Holy Warrior's Promenade" color="#00FFFF">
    <description>A small birdhouse perches atop an iron pole at the intersection of two paths.  A simple thing, capable of holding only one resident, the construct is painted a deep brick red with a white roof.  Several daffodils are planted around its base, their bright yellow color mimicking the sun.</description>
    <position x="377" y="-596" z="0" />
    <arc exit="south" move="south" destination="808" />
    <arc exit="southwest" move="southwest" destination="805" />
    <arc exit="west" move="west" destination="806" />
  </node>
  <node id="810" name="Paladins' Guild, Holy Warrior's Promenade" color="#00FFFF">
    <description>The thick, sturdy boughs of a towering oak tree reach skyward as if seeking to touch the heavens above.  One lone limb sweeps outward over the path, and beneath it the grass has been worn away, leaving nothing but packed, bare dirt behind.  A plank of wood has been fashioned into a swing and tethered to the massive branch, left to dangle loosely from a securely knotted rope.</description>
    <description>The thick, sturdy boughs of a towering oak tree reach skyward as if seeking to touch the very planets above.  One lone limb sweeps outward over the path, and beneath it the grass has been worn away, leaving nothing but packed, bare dirt behind.  A plank of wood has been fashioned into a swing and tethered to the massive branch, left to dangle loosely from a securely knotted rope.</description>
    <position x="377" y="-576" z="0" />
    <arc exit="north" move="north" destination="808" />
    <arc exit="west" move="west" destination="807" />
    <arc exit="northwest" move="northwest" destination="805" />
  </node>
  <node id="811" name="Iprilu's Emporium, Front Room" note="Iprilu's Emporium">
    <description>Embellished with golden accents, the marble walls glitter to life, highlighted by an overhanging chandelier.  An elaborately woven dark blue rug lies before the polished ebonwood door and stretches towards a simple wooden counter that displays a golden plaque.  A nearby set of winding stairs curves its way to the second floor, its gilded gold banister polished to a soft sheen.</description>
    <position x="327" y="-624" z="0" />
    <arc exit="east" move="east" destination="813" />
    <arc exit="west" move="west" destination="812" />
    <arc exit="go" move="go ebonwood door" destination="801" />
    <arc exit="climb" move="climb stairs" destination="814" />
  </node>
  <node id="812" name="Iprilu's Emporium, Garments for the Lord" color="#FF0000">
    <description>A large mahogany counter dominates the back half of the room, bearing a finely tooled wooden display case.  Just within the entrance is a hat stand, its elegantly carved wooden arms heavily laden with goods.  Nearby, a three-tiered shelf has been stocked full with folded items, their colors bright against the darkened wood grain, and at its base rests an oversized chest with silver trimmings.</description>
    <position x="317" y="-624" z="0" />
    <arc exit="east" move="east" destination="811" />
  </node>
  <node id="813" name="Iprilu's Emporium, Garments for the Lady" color="#FF0000">
    <description>Several hanging tapestries decorate the walls, their bright colors portraying vivid scenes of battle.  An overstuffed velvet chair rests near the alcove entrance, with woven shawls carefully draped over the back and a matching footrest at the base.  A walnut wardrobe towers in a nearby corner, its doors propped open on both sides by two well-dressed wicker mannequins.</description>
    <position x="337" y="-624" z="0" />
    <arc exit="west" move="west" destination="811" />
  </node>
  <node id="814" name="Iprilu's Emporium, Landing">
    <description>The staircase gives way to a circular landing, halved by two soulstone arches that shimmer softly, their radiance glimmering off the smooth, polished, marble flooring.  High above glitters a stained-glass skylight portraying a noble Paladin brandishing a silvery sword in combat against a menacing stone gargoyle.</description>
    <position x="327" y="-634" z="0" />
    <arc exit="climb" move="climb stairs" destination="811" />
    <arc exit="go" move="go east archway" destination="815" />
    <arc exit="go" move="go west archway" destination="817" />
  </node>
  <node id="815" name="Iprilu's Emporium, Nook of Shields" color="#FF0000">
    <description>Hanging from the wall are many heavy shields, each with a differing design and some symbolic emblem of the Paladin guild.  The light shimmers over them brightly, accenting their unique craftsmanship and flawless design.  A plush wolf-skin rug covers the floor, muffling heavy footsteps from boot-clad customers.</description>
    <position x="337" y="-634" z="0" />
    <arc exit="east" move="east" destination="816" />
    <arc exit="out" move="out" destination="814" />
  </node>
  <node id="816" name="Iprilu's Emporium, Armor Delights" color="#FF0000">
    <description>A crystal chandelier dangles from the ceiling, its brilliant light bouncing over the highly polished armor positioned over two mannequins lined against the far wall.  An entry table is draped with a lace doily to protect its surface from the heavy items it bears.  Nearby, a hanging rack has been suspended from a long beam, allowing it to spin freely and display a variety of headpieces.</description>
    <position x="347" y="-634" z="0" />
    <arc exit="west" move="west" destination="815" />
  </node>
  <node id="817" name="Iprilu's Emporium, Holy Relics" color="#FF0000">
    <description>The lighting in this room burns softly from hanging oil lanterns, and casts a warm glow over a crystal case along the far wall.  Strangely, the items hanging on the wall are illuminated with more brilliance than the three lanterns can provide and the illusion is given that the light comes from within the objects themselves.  A lone table sits opposite the case, embedded within the shadows and shrouded with a heavy black cloth.</description>
    <position x="317" y="-634" z="0" />
    <arc exit="west" move="west" destination="818" />
    <arc exit="out" move="out" destination="814" />
  </node>
  <node id="818" name="Iprilu's Emporium, Weapons of Fancy" color="#FF0000">
    <description>Mounted over the door is a massive broadsword, its blade serrated and set into a golden hilt.  So enormous is its size, it is obvious it is a piece meant for show and not for battle, for clearly no warrior could lift it alone.  An elongated weapons rack covers the far end of the room, displaying an assortment of swords, while a nearby hanging case holds a variety of smaller weapons over a linen-covered counter.</description>
    <position x="307" y="-634" z="0" />
    <arc exit="east" move="east" destination="817" />
  </node>
  <node id="819" name="Paladins' Guild, Stable" color="#00FF00">
    <description>The scent of horse sweat and well-oiled leather lingers in the air, carried on a gentle cross breeze.  Sunlight filters through the redwood slats, dancing over a thick layer of straw strewn on the aisle floor.  Lined on both sides of the aisle by a series of wooden stalls, shadows emitted from their hulking height fall more heavily on the far end, nearly concealing a stone-encased corner.  A pair of heavy wooden doors leads to the stable's side yard.</description>
    <position x="367" y="-616" z="0" />
    <arc exit="climb" move="climb wooden staircase" destination="820" />
    <arc exit="go" move="go redwood door" destination="802" />
    <arc exit="go" move="go wooden doors" destination="821" />
  </node>
  <node id="820" name="Paladins' Guild, Hayloft" note="Hayloft">
    <description>Bale upon bale of yellowed hay is stacked eight-high against the roughened walls, each one bound by heavy twine.  Scattered bits litter the floor to mix with a fine layer of dust.  An opening in one wall reveals a metal chute overlooking the gravel entryway, its wide mouth large enough to fit two simultaneous bales.</description>
    <position x="367" y="-626" z="0" />
    <arc exit="climb" move="climb wooden staircase" destination="819" />
    <arc exit="go" move="go metal chute" destination="802" />
  </node>
  <node id="821" name="Paladin's Guild, Stable Yard">
    <description>Marred by heavy hoofprints, the dirt is uneven and clumpy.  A three-rail wooden fence surrounds three quarters of the perimeter, its slating painted a bright white.  Various equipment is neatly stacked against the back side of the barn just beside a pair of heavy doors that lead inside.</description>
    <position x="225" y="-616" z="0" />
    <arc exit="southeast" move="southeast" destination="822" />
    <arc exit="go" move="go wooden doors" destination="819" />
  </node>
  <node id="822" name="Paladins' Guild, Side Lawn">
    <description>Velvety grass surrounds the back exposure of the two-story edifice.  From this perspective the pristine marble building looms imposingly against the horizon, the acute angle of the barracks roof lending an illusion of extended height.  Ivy clings to the side of the building, slowly meandering towards the sky and a tall iron staircase, bolted securely into the moldings, runs diagonally from the ground to a tiled archway on the second floor.</description>
    <position x="255" y="-586" z="0" />
    <arc exit="northwest" move="northwest" destination="821" />
    <arc exit="go" move="go gravel pathway" destination="823" />
    <arc exit="go" move="go wooden gate" destination="137" />
    <arc exit="climb" move="climb iron staircase" destination="825" />
  </node>
  <node id="823" name="Paladins' Guild, Jousting Arena">
    <description>Dozens of footprints score the ground from heavy use and continual traffic.  On one side, tall stands provide spectator seating, crowned with brightly burning torches that illuminate the arena with an orange and yellow glow.  A heavy gate leads into the arena proper, guarded by a burly S'kra Mur in full plate mail.</description>
    <description>Dozens of footprints score the ground from heavy use and continual traffic.  On one side, tall stands provide spectator seating, crowned with brightly hued pennants that splash the sky with color.  A heavy gate leads into the arena proper, guarded by a burly S'kra Mur in full plate mail.</description>
    <position x="255" y="-556" z="0" />
    <arc exit="go" move="go gravel pathway" destination="822" />
    <arc exit="go" move="go heavy gate" destination="824" />
  </node>
  <node id="824" name="Paladins' Guild, Jousting Arena" note="Jousting Arena">
    <description>Surrounded by a split-rail fence, the arena floor is a mixture of sand and dirt.  Marred with deep hoof-prints and churned completely in areas, the ground bears the telltale signs of frequent use.  Rows of wooden stands line the far end of the rail for spectator seating, and a wooden observation box towers above them, providing safety for the officiator.</description>
    <position x="255" y="-546" z="0" />
    <arc exit="out" move="out" destination="823" />
  </node>
  <node id="825" name="Paladins' Guild, Back Landing">
    <description>Despite the height, the view is blocked by the barracks and all that can be seen is the yard below and the bustling street beyond the gate.  The landing is narrow, but what lacks in width is made up for in length and can easily hold a large group of people.  A solitary guard stands at the door, carefully eyeing all that pass.</description>
    <position x="255" y="-596" z="0" />
    <arc exit="climb" move="climb iron staircase" destination="822" />
    <arc exit="go" move="go tiled archway" destination="826" />
  </node>
  <node id="826" name="Paladins' Guild, Barracks" color="#00FFFF">
    <description>A colorful archway stands at the end of the hall, providing a view of the balcony beyond.  The murmurs of city life drift through, a constant hubub of activity at all hours.</description>
    <position x="275" y="-596" z="0" />
    <arc exit="south" move="south" destination="827" />
    <arc exit="go" move="go tiled archway" destination="825" />
  </node>
  <node id="827" name="Paladins' Guild, Barracks" color="#00FFFF">
    <description>The wooden floors remain unmarred despite the heavily armored feet that often traipse across it.  A green glass vase sits atop a small three-legged table, displaying a preserved bouquet of jonquils, their vibrant yellow color as bright now as when they were freshly cut.</description>
    <position x="275" y="-586" z="0" />
    <arc exit="north" move="north" destination="826" />
    <arc exit="south" move="south" destination="828" />
  </node>
  <node id="828" name="Paladins' Guild, Barracks" color="#00FFFF">
    <description>An emblazoned shield hangs upon the wall, framed by two small brass oil lanterns, their flames enclosed in glass flumes.  Their dim lighting casts a warm yellow glow over the doorframes throughout the hallway.  A deep scar mars the surface of the oaken floor, remnants of a careless footstep long ago.</description>
    <position x="275" y="-576" z="0" />
    <arc exit="north" move="north" destination="827" />
    <arc exit="climb" move="climb stairwell" destination="829" />
  </node>
  <node id="829" name="Paladins' Guild, Barracks" color="#00FFFF">
    <description>Young squires bustle up and down a secluded stairwell, their arms heavily laden with pieces of their master's armor.  From behind a nearby door, the lingering scent of cabbage wafts through the air, tell-tale signs of a home cooked meal.  At the end of the hallway hangs a painting of a golden lion, its head thrown back in a deep roar, mane flowing wildly around its massive head.</description>
    <position x="285" y="-576" z="0" />
    <arc exit="north" move="north" destination="830" />
    <arc exit="climb" move="climb stairwell" destination="828" />
  </node>
  <node id="830" name="Paladins' Guild, Barracks" color="#00FFFF">
    <description>The soft beige walls are embellished with a golden filigree pattern and contrast tastefully with the deep green rug laid over the wooden flooring.  Interwoven with silvery threads, the plush woolen floor covering bears the Zoluren provincial crest.</description>
    <position x="285" y="-586" z="0" />
    <arc exit="north" move="north" destination="831" />
    <arc exit="south" move="south" destination="829" />
    <arc exit="go" move="go double doors" destination="832" />
  </node>
  <node id="831" name="Paladins' Guild, Barracks" color="#00FFFF">
    <description>An armored figure stands at attention in the corner, its heavy sword raised to its metal-clad brow in a respectful salute.  Hanging lanterns cast a soft sheen over the highly polished wooden flooring and illuminate the dark mahogany walls, highlighting their intricately grained pattern.</description>
    <position x="285" y="-596" z="0" />
    <arc exit="south" move="south" destination="830" />
  </node>
  <node id="832" name="Paladins' Guild, Barracks Front Porch">
    <description>Long wooden flats have been sanded to a smooth finish and comprise the flooring and handrails of this enclosed porch.  Covered by a tiled roof, the enclosure provides a sheltered place to rest and relax after a long and tiring day.  A long bench rests against one rail, directly opposite a hanging porch-swing, both upholstered with soft cushions.</description>
    <position x="305" y="-586" z="0" />
    <arc exit="climb" move="climb steps" destination="803" />
    <arc exit="go" move="go double doors" destination="830" />
  </node>
  <node id="833" name="Order Headquarters, Main Lobby" note="Order Headquarters|Order HQ">
    <description>In stark contrast to the bustling streets outside, the quiet of this office is broken only by the muffled rustlings of a clerk behind a corner desk.  An open door floods the area with light that sparkles off several dozen ivory candles supported on tall golden stands.  Servants and other staff filter up and down the winding staircase and through the arch.  A chaise, its watered-silk cushions a deep shade of blue, provides patrons with a place to enjoy the surrounds.</description>
    <description>Echoing the quiet night streets outside, the tranquil nature of this office offers shelter from the night air.  Mounted in tall, golden stands, ivory candles cast flickering shadows over the wooden floor, their sweet wax scenting the air.  Muffled rustlings of paper can be heard from the room's corner as night clerks shuffle through documents filed on a large desk next to an ornate arch.  Servants and other staff filter up and down the winding staircase.</description>
    <position x="320" y="7" z="0" />
    <arc exit="go" move="go double doors" destination="160" />
    <arc exit="go" move="go arched entrance" destination="988" />
    <arc exit="go" move="go administrator's office" destination="987" />
    <arc exit="go" move="go ornate arch" destination="834" />
    <arc exit="climb" move="climb winding staircase" destination="835" />
  </node>
  <node id="834" name="Order Headquarters, The Crossings Room" note="Crossings Room">
    <description>A sea of lit candles, held high on a multitude of turned candle stands, casts a pale gold glow over the spacious dance floor that almost tangibly beckons to be used.  The rich color of the oak buffet picks up the candle glow tint, and the windows reflect and multiply the slender flames.  Sets of round tables and red velvet chairs cluster in the southern corners of the room, giving respite to the patrons.</description>
    <description>Glossy tiled floors and long oak buffets flank the spacious dance floor.  Sash windows, the panes spotlessly clean and almost invisible, are festooned with brocade draperies.  Small clusters of polished round tables attended by red velvet chairs on turned legs fill the corners, giving tired patrons a spot to rest.</description>
    <position x="330" y="7" z="0" />
    <arc exit="go" move="go ornate arch" destination="833" />
  </node>
  <node id="835" name="Order Headquarters, Second Floor Landing">
    <description>Sunlight drifts in through a bronze-framed oval window and dances over the polished surface of an octagonal parquet table.  Atop it, a crystalline vase holds a tasteful bouquet of brightly colored lilies, suffusing the area with a faint, sweet aroma.  Next to the vase rests a thin, leather-bound journal with an embossed gold title.</description>
    <description>A bronze-framed oval window provides a view of the night sky.  Atop an octagonal parquet table, a bouquet of colorful lilies in a crystalline vase gives off a faint, sweet aroma.  A thin, leather-bound journal with an embossed gold title rests next to the vase.</description>
    <position x="320" y="-11" z="0" />
    <arc exit="north" move="north" destination="838" />
    <arc exit="east" move="east" destination="837" />
    <arc exit="west" move="west" destination="836" />
    <arc exit="northwest" move="northwest" destination="839" />
    <arc exit="climb" move="climb winding staircase" destination="833" />
    <arc exit="climb" move="climb marble steps" destination="951" />
  </node>
  <node id="836" name="Order Headquarters, West Wing">
    <description>Lit by several mounted silver lanterns, the long hallway is interrupted by a series of curtain-draped archways.  The elaborate frames of the entryways are crafted out of ornate woods and enhanced with carved leaf patterns that mimic the trees from which they were cut.  A woven lambswool carpet spans from end to end, its soft nap providing a muffled cushion against even the heaviest footfalls.</description>
    <position x="300" y="-11" z="0" />
    <arc exit="east" move="east" destination="835" />
    <arc exit="go" move="go satinwood archway" destination="843" />
    <arc exit="go" move="go ironwood archway" destination="842" />
    <arc exit="go" move="go acanth archway" destination="841" />
  </node>
  <node id="837" name="Order Headquarters, East Wing">
    <description>Supported by heavily oiled, dark wooden beams, the whitewashed plaster walls add a sense of tidiness to the long hall.  The finish on the wood-framed archways shines warmly, basking in the softened glow of several silver lanterns.  A variegated pattern of leaves twines gently over the curtain-draped supports, each arch bearing a symbolic mark of the tree it once was.</description>
    <position x="340" y="-11" z="0" />
    <arc exit="west" move="west" destination="835" />
    <arc exit="go" move="go rosewood archway" destination="846" />
    <arc exit="go" move="go flamewood archway" destination="845" />
    <arc exit="go" move="go ebonwood archway" destination="844" />
  </node>
  <node id="838" name="Order Headquarters, The Library" note="Order library">
    <description>Long heavy curtains drop from ceiling to floor and are flung wide to allow an abundance of light through the long-paned windows in the northern wall.  Tall shelves of cedar and oak line the east and west walls.  At each small reading desk sits a lantern ready to provide ample light for patrons who choose to read at night.  The hushed stillness is broken only by the soft murmur of conversation between librarians, who return the books left on the small mahogany returns desk.</description>
    <description>Heavy curtains that drop from ceiling to floor cover the windows in the northern wall.  At each small reading desk, a lit lantern provides ample light for patrons who may choose to avail themselves of the plump armchairs.  The hushed stillness is broken only by the soft murmur of conversation between the librarians who quietly go about their business.  As books are returned to the mahogany desk, they put them in their rightful places on the cedar and oak shelves on the east and west walls.</description>
    <position x="320" y="-31" z="0" />
    <arc exit="south" move="south" destination="835" />
  </node>
  <node id="839" name="Order Headquarters, Second Floor Landing">
    <description>Supported by heavily oiled, dark wooden beams, the whitewashed plaster walls add a sense of tidiness to the hall.  The finish on many wood-framed archways shines warmly, basking in the softened glow of several silver lanterns.  A variegated pattern of leaves twines gently over the curtain-draped supports, each arch bearing a symbolic mark of the tree it once was.</description>
    <position x="300" y="-31" z="0" />
    <arc exit="southeast" move="southeast" destination="835" />
    <arc exit="go" move="go golden archway" destination="840" />
  </node>
  <node id="840" name="Order Headquarters, The White Rose Recruitment Office" note="White Rose Recruitment Office|OWR">
    <description>Draped over the archway is a sweeping black silk banner that winds lazily around the bottom edge of a heavy silver-trimmed coat of arms.  Standing sentry at the side is a small three-legged table.  On the far side of the room, an inlaid stand supports a deposit box fastened with a heavy iron lock.  Mounted on the wall behind the stand hangs a shining bronze plaque detailing the Order's governing body.</description>
    <position x="300" y="-41" z="0" />
    <arc exit="go" move="go golden archway" destination="839" />
  </node>
  <node id="841" name="Order Headquarters, The Apostles Recruitment Office" note="Apostles Recruitment Office">
    <description>An embroidered scarlet banner is draped above the archway, enveloping the lower portion of a pristine white coat of arms.  Tucked neatly into a nearby corner is a small three-legged table.  On the far side of the room an oak stand supports a deposit box fastened with a heavy iron lock.  Mounted on the wall behind the stand hangs a bronze plaque detailing the Order's governing body.</description>
    <position x="290" y="-21" z="0" />
    <arc exit="go" move="go acanth archway" destination="836" />
  </node>
  <node id="842" name="Order Headquarters, The Black Fox Recruitment Office" note="Black Fox Recruitment Office|OBF">
    <description>Tucked against the frame of the ironwood arch stands a small three-legged table.  Hung above it, a crescent-shaped silk banner twines loosely over a white tower shield with a bold red chevron that bears an emblazoned image of a small black fox.  On the far side of the room, an inlaid stand supports a deposit box fastened with an iron lock.  Mounted on the wall behind the stand hangs a bronze plaque detailing the ruling body of the Order.</description>
    <position x="290" y="-11" z="0" />
    <arc exit="go" move="go ironwood arch" destination="836" />
  </node>
  <node id="843" name="Order Headquarters, The Tavern Troupe Recruitment Office" note="Tavern Troupe Recruitment Office">
    <description>Poised above the satinwood archway is a sweeping bard-blue banner with golden tassels that fringe the top portion of an elaborate ivory emblem.  Sitting to the side of the entryway is a small three-legged table.  On the far side of the room, a pine stand supports a deposit box fastened with a heavy iron lock.  Mounted on the wall behind the stand hangs a gleaming bronze plaque outlining the Order's governing body.</description>
    <position x="290" y="-1" z="0" />
    <arc exit="go" move="go satinwood archway" destination="836" />
  </node>
  <node id="844" name="Order Headquarters, Iron Circle Recruitment Office" note="Iron Circle Recruitment Office">
    <description>Placed above the archway is a massive gold and black shield etched with the vivid image of a mighty dragon and loosely draped with a banner of scarlet silk.  Atop a nearby table rests an elaborately feathered quill.  Against the far wall, a heavy wooden stand supports a wooden box, fastened with a polished silver lock.  Above it, a brass plaque hangs shimmering softly in the available light.</description>
    <position x="350" y="-21" z="0" />
    <arc exit="go" move="go ebonwood archway" destination="837" />
  </node>
  <node id="845" name="Order Headquarters, Theren Guard Recruitment Office" note="Theren Guard Recruitment Office|OTG">
    <description>A bold silver crest hangs proudly above the archway, which is draped with a sweeping crimson and gold silk banner.  Tucked near the entryway is a small, three-legged table displaying a goose-feather quill.  On the far side of the room, an inlaid stand supports a deposit box fastened with a heavy iron lock.  A shimmering bronze plaque that hangs on the wall by a black chain displays the governing body of the Order.</description>
    <position x="350" y="-11" z="0" />
    <arc exit="go" move="go flamewood archway" destination="837" />
  </node>
  <node id="846" name="Order Headquarters, Dragon Shield Recruitment Office" note="Dragon Shield Recruitment Office|ODS">
    <description>Placed above the archway is a massive gold and black shield etched with the vivid image of a mighty dragon and loosely draped with a banner of scarlet silk.  Atop a nearby table rests an elaborately feathered quill and against the far wall, a heavy wooden stand supports a box fastened with a polished lock.  Above the table hangs a brass plaque shimmering softly in the available light.</description>
    <position x="350" y="-1" z="0" />
    <arc exit="go" move="go rosewood archway" destination="837" />
  </node>
  <node id="847" name="The Healerie, Lecture Hall" note="Lecture Hall">
    <description>Large crystals in the upper corners of this room shed a soft glow on the tiers of comfortable seats that look down on the ebony lectern below.  A velvet curtain covers the wall behind the lectern.</description>
    <description>Large crystals in the upper corners of this room shed a soft glow on the tiers of comfortable seats that look down on the ebony lectern below.  Behind the lectern, inset into the wall, the brightly lit viewing area of The Healerie is clearly visible through the thick crystal.</description>
    <position x="310" y="-458" z="0" />
    <arc exit="go" move="go stone door" destination="431" />
  </node>
  <node id="848" name="Town Hall, Records Storage">
    <description>This cramped, dusty office displays all the standard appointments that mark it as serving an extremely important role in the bureaucracy of the town government.  Dilapidated, make-shift shelves are crammed full of books and papers that bear no evidence of being organized in any useful manner.  Everything is covered with a thick layer of dust, and the walls and ceiling are stained with black from the smoke that rises from the single, small lamp that rests on a high desk in the center of the room.</description>
    <position x="190" y="-66" z="0" />
    <arc exit="go" move="go simple curtain" destination="849" />
    <arc exit="go" move="go arched door" destination="318" />
  </node>
  <node id="849" name="Town Hall Records Office, Booth" note="Item Registration">
    <description>You've entered a space which is wedged between two rows of filing cabinets and sectioned off by a heavy brocade curtain.  In it is a simple modwir desk with an elderly clerk sitting behind it, peering over the mounds of paper which surround him.  He snorts to himself once, mutters something under his breath, then returns to work.</description>
    <position x="180" y="-66" z="0" />
    <arc exit="go" move="go simple curtain" destination="848" />
  </node>
  <node id="850" name="Market Plaza, Foyer" note="Map1j_Market_Plaza.xml|Market Plaza|Plaza">
    <description>The high ceiling and sand rose painted walls make this entry feel open and expansive.  A large round ironwood table is centered on a thickly-piled rug that covers the middle of the polished marble floor.  Large copper urns filled with preserved peacock feathers and fronds have been placed at each corner of a large listings board.  Rich brown leather couches line the opposite wall.</description>
    <position x="309" y="-219" z="0" />
    <arc exit="north" move="north" />
    <arc exit="go" move="go iron gate" destination="380" />
  </node>
  <node id="851" name="Crossing Engineering Society, Crafting Supplies" note="Engineering tools" color="#FF0000">
    <description>Expertly fitted grey marble slabs frame the lower half of the shop's alabaster walls.  Shadows dance at the light produced by carefully arranged copper torch holders about the room.  This area sells a variety of supplies to eager crafters and offers some shelter from the loud noises of productivity emanating from the east.</description>
    <description>Expertly fitted grey marble slabs frame the lower half of the shop's alabaster walls.  A sliver of light shines through a pair of squat windows bordered by well-polished oak molding and fitted with iron bars styled to resemble vines of ivy.  This area sells a variety of supplies to eager crafters and offers some shelter from the loud noises of productivity emanating from the east.</description>
    <position x="-51" y="26" z="0" />
    <arc exit="north" move="north" destination="927" />
    <arc exit="east" move="east" destination="874" />
    <arc exit="west" move="west" destination="925" />
    <arc exit="go" move="go mistwood door" destination="83" />
  </node>
  <node id="852" name="The Crossing, Mongers' Square">
    <description>Shreds of cloth are strewn about the area, intermingled with shattered bones and bodies.  The only remaining indication of the market's former glory is the statue of Divyaush, its bronze smile tinged with sadness in wake of the destruction.  The wrecked husk of the market tent looms silently to the southwest.</description>
    <position x="320" y="-180" z="0" />
    <arc exit="go" move="go walkway ramp" destination="384" />
  </node>
  <node id="853" name="Underground Passageway" note="Map1a_Crossing_Thief.xml">
    <description>This lengthy passageway is clogged with knife-sized bits of sharp debris.  Overhead several massive boulders block out most of the light, and the din of town traffic is reduced to a surflike roar.  No one stops to glance down between the chinks of rubble, leaving your travels unnoticed and undisturbed.</description>
    <position x="230" y="-200" z="1" />
    <arc exit="northeast" move="northeast" />
  </node>
  <node id="854" name="Underground Passageway" note="Map1a_Crossing_Thief.xml">
    <description>Jagged piles of debris line the center of this passageway, chips and shards of large rocks lodged deep in the low ceiling above.  A fine grey dust blankets everything else, sifting into clouds at knee-level from the passage of thieves.</description>
    <position x="419" y="-334" z="1" />
    <arc exit="south" move="south" />
  </node>
  <node id="855" name="A Dank Dark Passage" note="Map1a_Crossing_Thief.xml">
    <description>An obstacle course formed of pillaged packing crates in all sizes, shapes and states of decomposition hinders your movement through the passage.  Straw filling, moldy and brown, lies scattered about, jagged edges of rusty metal implements occasionally jutting above the mess.  This is a good place to walk softly.</description>
    <position x="-80" y="-140" z="0" />
    <arc exit="southwest" move="southwest" />
    <arc exit="go" move="go narrow footholds" destination="32" />
  </node>
  <node id="856" name="A Dank, Cluttered Passage" note="Map1a_Crossing_Thief.xml">
    <description>An obstacle course formed of pillaged packing crates in all sizes, shapes and states of decomposition hinders your movement through the passage.  Straw filling, moldy and brown, lies scattered about, jagged edges of rusty metal implements occasionally jutting above the mess.  This is a good place to walk softly.</description>
    <position x="170" y="280" z="0" />
    <arc exit="northeast" move="northeast" />
    <arc exit="go" move="go loose grill" destination="54" />
  </node>
  <node id="857" name="Sand Spit Tavern, Cellar Room" color="#00FFFF">
    <description>This dank and cheerless place is the tavern's cellar.  Once a wine vault, the moisture and brackish water seeping in from the estuary ruined the wine.  Old barrels, mostly rotted and splintered still stand in a row.  Now largely unused, you have heard lurid tales of smugglers hiding down here to buy and sell and conduct other, less savoury dealings.</description>
    <position x="-290" y="260" z="0" />
    <arc exit="climb" move="climb rickety ladder" destination="858" />
    <arc exit="go" move="go boards" destination="1020" />
  </node>
  <node id="858" name="Sand Spit Tavern, Backroom">
    <description>Behind the bar you find the storage area with barrels and casks of assorted brew.  A pot boy washing up some glasses in a pail of indifferently clean water looks up at you with dull surprise and continues his work.  There is a litter of broken glass here and you wonder if and when the place was last swept out.</description>
    <position x="-290" y="250" z="0" />
    <arc exit="climb" move="climb rickety ladder" destination="857" />
    <arc exit="go" move="go main bar" destination="699" />
    <arc exit="climb" move="climb ladder" destination="857" />
  </node>
  <node id="859" name="The Raven's Court, Secret Passage" note="Map1a_Crossing_Thief.xml">
    <description>Though the cool stone walls are bare, a long maroon runner with pale golden fringe spreads across the length of the floor.  The tunnel's interior is visible only by the overflow of light from the basement beyond.  Despite being underground, a fresh breeze fills the space from an opening overhead cleverly concealed with leafy hedges above.</description>
    <position x="-241" y="6" z="1" />
    <arc exit="southwest" move="southwest" />
    <arc exit="go" move="go hole" destination="550" />
  </node>
  <node id="860" name="Behind the Half Pint Inn" note="Map1a_Crossing_Thief.xml">
    <description>Heavy wooden ale kegs line the small back alley on all sides to form high barriers, save for the area to the southwest that slopes into a dark underground tunnel.  Dimpled glass windows along the building wall prevent the tavern's patrons from noticing any suspicious activity in the cramped lot.  A tangle of blue violet wolfsbane spills over the edges of a faded red flower box toward the cobble below as if attempting a daring escape from its wooden prison.</description>
    <position x="79" y="26" z="1" />
    <arc exit="southwest" move="southwest" />
    <arc exit="go" move="go path" destination="45" />
  </node>
  <node id="861" name="The Raven's Court, Basement" note="Map1a_Crossing_Thief.xml">
    <description>Crowding every inch of wall space, several shelves store everything from empty wine barrels to shiny gardening tools.  Piled into one corner, a collection of overturned boxes are arranged into layered seating like rows in an amphitheatre.  A long vegetable crate has been propped on its side for use as a podium in this makeshift meeting room.</description>
    <position x="-280" y="50" z="1" />
    <arc exit="northeast" move="northeast" />
    <arc exit="go" move="go trapdoor" destination="545" />
  </node>
  <node id="862" name="Outside East Wall, Footpath" note="Map8_Crossing_East_Gate.xml">
    <description>Crumbling mud bricks and loose rock lay in a pile near the sturdy stone town wall.  Sounds of night-hidden creatures rustle in the weeds and nearby brush as they search for prey or leftover scraps.</description>
    <description>Crumbling mud bricks and loose rock lay in a pile near the sturdy stone town wall.  A small field mouse nibbles at a crust of bread, perhaps discarded from the wall workers' lunch portion.</description>
    <position x="450" y="-40" z="0" />
    <arc exit="northeast" move="northeast" />
    <arc exit="south" move="south" />
    <arc exit="climb" move="climb town wall" destination="396" />
  </node>
  <node id="863" name="Brother Durantine's, Storeroom" color="#FF0000">
    <description>Behind the counter, a tiny storeroom lined with shelves holds a selection of seasonal supplies for clerics.  White-robed novices work to stock the shelves, silently brushing past as they lay out items for the perusal of Brother Durantine's favored customers.</description>
    <position x="100" y="0" z="0" />
    <arc exit="out" move="out" destination="407" />
  </node>
  <node id="864" name="Northwall Trail, Wooded Grove" note="Map4_Crossing_West_Gate.xml">
    <description>The sweet smell of wildflowers carried on the breeze mingles with the spicy smell of cedar and juniper.  Sunlight dapples the mossy ground in golden hues and glistens on the dew-laden petals of tiny snowflowers.  A gnarled oak tree, cracked in two by a great tempest's fury, lays beside the trail.</description>
    <description>The sweet smell of wildflowers carried on the breeze mingles with the spicy scent of cedar and juniper.  At the sound of an owl, a startled woodmouse scurries across the trail toward a gnarled and broken oak tree.</description>
    <position x="-321" y="-408" z="0" />
    <arc exit="east" move="east" />
    <arc exit="southwest" move="southwest" />
    <arc exit="climb" move="climb town wall" destination="400" />
  </node>
  <node id="865" name="Crossing Forging Society, Book Store" note="Forging Society|Forging books|Forging prestige" color="#FF0000">
    <description>Freshly chiseled granite walls surround an area where forgers can quickly resupply.  A passageway covered by a leather flap pierces the wall to the south, and from the passage resound the clangs of an anvil chorus.  A simple wooden door leads back outside.</description>
    <position x="332" y="-301" z="0" />
    <arc exit="south" move="south" destination="902" />
    <arc exit="go" move="go wooden door" destination="6" />
  </node>
  <node id="866" name="Paladins' Guild, Sentinel's Way">
    <description>The pebbled path widens into an elongated patio, shaded by a lush copse of evergreen trees.  Their darkened branches provide a canopy of shadows and the scent of pine lingers heavily in the air.  A gentle trickling echoes with the passing breeze, indicating a nearby presence of water while the quiet chirping of crickets adds to the rustic setting.</description>
    <position x="347" y="-586" z="0" />
    <arc exit="go" move="go pebbled path" destination="800" />
    <arc exit="go" move="go vine-covered trellis" destination="867" />
  </node>
  <node id="867" name="Paladins' Guild, Sentinel's Rest">
    <description>Surrounded by lush greenery, the crystal clear waters of a small, limpid pool reflect the nighttime sky and glimmer peacefully.  Lily pads speckle the surface, clustering together near the middle and bouncing gently with the ripples from a nearby waterfall.  Several well-kept pebbled paths branch off in opposite directions, each trimmed with small flowers.</description>
    <description>Surrounded by greenery, the waters of a pool reflect the sun's light.  Lily pads speckle the surface, clustering together near the middle and bouncing gently with the ripples from a nearby waterfall.  Several paths branch off in opposite directions.</description>
    <position x="367" y="-586" z="0" />
    <arc exit="north" move="north" destination="806" />
    <arc exit="northeast" move="northeast" destination="809" />
    <arc exit="east" move="east" destination="808" />
    <arc exit="southeast" move="southeast" destination="810" />
    <arc exit="south" move="south" />
    <arc exit="go" move="go vine-covered trellis" destination="866" />
  </node>
  <node id="868" name="Wildulf Woods, Dense Forest" note="Map4_Crossing_West_Gate.xml">
    <description>Towering trees grow close together here.  Their silvery-green leaves rustle in the breeze and whisper softly to each other, adding to the hushed expectancy of the forest.  A network of interwoven branches forms a canopy overhead with gaps of sky peeking through it.  You catch a glimpse of a dark bird circling high above.</description>
    <position x="-120" y="142" z="0" />
    <arc exit="north" />
    <arc exit="east" />
    <arc exit="south" />
  </node>
  <node id="869" name="Saranna's Sweet Tooth, Tea Room">
    <description>White lace tablecloths ripple silently in the constant draft from a window left ajar, beckoning the weary (or hungry) adventurer to come and sit for awhile.  Centering each table, crystal bowls filled with crimson roses reflect stray beams of light trailing in from the narrow doorway to the southeast.</description>
    <description>White lace tablecloths ripple silently in the constant draft from a window left ajar, beckoning the weary or hungry traveler to come and sit for awhile.  Centering each table, crystal bowls filled with crimson roses reflect stray beams of light trailing in from the narrow doorway to the southeast.</description>
    <position x="80" y="-395" z="0" />
    <arc exit="go" move="go narrow doorway" destination="464" />
  </node>
  <node id="870" name="Barsabe's Grocery, Salesroom" note="Barsabe's Grocery|Grocery" color="#FF0000">
    <description>Every shelf, every counter, every table, every square inch of this spacious shop is crammed with visions and fragrances of culinary delight.  Long ropes of spicy-sweet sausages, huge wheels of aromatic cheeses, and loaves of fresh bread create a tantalizing focal point in the center of the room.  Amid the hustle and bustle of a steady flow of customers, the diminutive (if slightly rotund) proprietor himself takes a moment to smile at you as he puts the finishing touches on some new, delicious creation.</description>
    <position x="110" y="-394" z="0" />
    <arc exit="south" move="south" destination="872" />
    <arc exit="west" move="west" destination="871" />
    <arc exit="out" move="out" destination="129" />
  </node>
  <node id="871" name="Barsabe's Grocery, Deliveries">
    <description>Walls, apparently formed of an endless supply of oaken barrels, tower impressively over your head, testament to the popularity of the town's favorite grocer.  As youths from the kitchen race out to request more of one item or another, the burly workmen grumble somewhat, but nearly stumble over themselves to help the prettier maidens who work at the bakery next door.</description>
    <position x="100" y="-394" z="0" />
    <arc exit="east" move="east" destination="870" />
  </node>
  <node id="872" name="Barsabe's Grocery, Kitchen">
    <description>The clatter of pots, punctuated by the delighted laughter of the kitchen help as they go about their business greets you here.  Drying meats of all shapes and sizes swing merrily from the low-beamed ceiling, as if dancing on the warm breezes created by the regiment of cast iron stoves that ring the room.</description>
    <position x="110" y="-384" z="0" />
    <arc exit="north" move="north" destination="870" />
  </node>
  <node id="873" name="Crossing Outfitting Society, Entry Hall" note="Outfitting Society">
    <description>Thick curtains upon a large, arching window are held open by ornate brass hooks placed on either side of the pane.  Pressed upon one wall are crushed flecks of seashells in varied hues of blues and greens beneath a painted orange sun which have been assembled to resemble a gentle ocean sunset.  Nestled into a corner is a padded chair next to a carved oak table.</description>
    <position x="-15" y="-184" z="0" />
    <arc exit="east" move="east" destination="911" />
    <arc exit="west" move="west" destination="910" />
    <arc exit="go" move="go large door" destination="26" />
  </node>
  <node id="874" name="Crossing Engineering Society, Depot" note="Engineering Society|Engineering supplies" color="#FF0000">
    <description>Grey marble walls give way to alabaster columns framing an open supply depot.  The northern hallway bears a sign indicating it leads to workshops, and a well-used road meanders out to the east.  Crisscrossing wagon ruts in the dirt remain from trips to supply the guild with stone and wood supplies.</description>
    <position x="-41" y="26" z="0" />
    <arc exit="north" move="north" destination="926" />
    <arc exit="west" move="west" destination="851" />
    <arc exit="go" move="go well-used road" destination="82" />
  </node>
  <node id="875" name="Aesthene's Close, Corridor">
    <description>Here you find a nearly intact raised mosaic floor.  Tiny tiles of many colors form patterns unlike any you've ever seen, its beauty still apparent despite the wreckage strewn about.  Touching one of the tiles, you are surprised to find it soft and pliable like cork, which might explain why this part of the corridor has endured the upheaval.  At the southern end, a great boulder has nearly blocked all passage in that direction.</description>
    <position x="-222" y="132" z="0" />
    <arc exit="northeast" move="northeast" destination="876" />
  </node>
  <node id="876" name="Aesthene's Close, Cubiculum">
    <description>Scant light filters in from a narrow section of grating in the ceiling far above.  Looking about, you find yourself hemmed in by walls on three sides.  On the floor, you see a series of battered and broken tiles, remnants of some ancient artisan's work.  After careful study, you believe they depict a wizened old mage holding forth a pulsating crystal.</description>
    <position x="-212" y="122" z="0" />
    <arc exit="southwest" move="southwest" destination="875" />
    <arc exit="go" move="go dark opening" destination="877" />
  </node>
  <node id="877" name="Aesthene's Close, Passageway">
    <description>Cascading nitre hangs thick along the walls of this passageway, which wends into utter darkness.  The fetid remains of a dead rat invite a host of vermin to keep you sorry company.</description>
    <position x="-222" y="122" z="0" />
    <arc exit="go" move="go narrow chasm" destination="878" />
  </node>
  <node id="878" name="Aesthene's Close, Passageway">
    <description>A collapsed hallway twists and turns in the darkness, filled with great piles of stone and rotted timber. </description>
    <position x="-232" y="122" z="0" />
    <arc exit="east" move="east" destination="877" />
    <arc exit="go" move="go narrow opening" destination="879" />
    <arc exit="go" move="go narrow tunnel" destination="676" />
  </node>
  <node id="879" name="Aesthene's Close, The Vaults">
    <description>Rotting deobar planks clotted with reeking sewage comprise the floor of this narrow corridor.  Thin streamers of decayed silk hang from rusting iron sconces, while soggy, mottled tapestries of indeterminate design lie clumped along the baseboards.  Nitre is thick and cloying, and a steamy heat envelopes you.  What is left of the floor slopes like a ramp, leading into darkness.</description>
    <position x="-232" y="132" z="0" />
    <arc exit="north" move="north" destination="878" />
    <arc exit="down" move="down" destination="880" />
  </node>
  <node id="880" name="Aesthene's Close, The Vaults">
    <description>Stone walls and floors echo each footstep as you cautiously make your way along the slippery incline.  A soft scuffling and distant chitter cut through the darkness, assaulting your imagination.</description>
    <position x="-242" y="132" z="0" />
    <arc exit="up" move="up" destination="879" />
    <arc exit="down" move="down" destination="881" />
  </node>
  <node id="881" name="Aesthene's Close, The Vaults">
    <description>Cobblestone strewn with sludge and debris stretches out in this cavernous hold, set with a large iron gate at one end.  Rubble from the broken foundations of the Close lies in piles in each corner. </description>
    <position x="-252" y="132" z="0" />
    <arc exit="south" move="south" destination="882" />
    <arc exit="up" move="up" destination="880" />
    <arc exit="go" move="go iron gate" destination="883" />
  </node>
  <node id="882" name="Aesthene's Close, The Vaults">
    <description>Fetid puddles combined with the absence of fresh air give rise to a suffocating humidity.  Your mind's eye envisions all manner of vermin scaling the moist stone walls or crunching beneath your feet.  There is a scraping sound which echoes from either side of this corridor.</description>
    <position x="-252" y="142" z="0" />
    <arc exit="north" move="north" destination="881" />
    <arc exit="south" move="south" destination="884" />
  </node>
  <node id="883" name="Aesthene's Close, The Vaults">
    <description>Putrid water filters through cracks in the stone walls and cuts moist paths through the clinging nitre.  A large desk lies on its side, swollen and rotting from the surrounding puddles of muck.</description>
    <position x="-252" y="122" z="0" />
    <arc exit="go" move="go iron gate" destination="881" />
  </node>
  <node id="884" name="Aesthene's Close, The Vaults">
    <description>The constant drip of water seeping through the walls becomes immediately irritating as you make your way through this large, dark room.  In some areas, the mire is ankle deep, threatening to slip you into its embrace.  A strong smell of decaying flesh permeates the dank air, but without adequate light, its source remains unknown.</description>
    <position x="-252" y="152" z="0" />
    <arc exit="north" move="north" destination="882" />
    <arc exit="east" move="east" destination="885" />
    <arc exit="south" move="south" destination="887" />
    <arc exit="west" move="west" destination="886" />
  </node>
  <node id="885" name="Aesthene's Close, The Vaults">
    <description>The walls of this corridor are agonizingly close.  Nitre and foul-smelling slime streak your clothing and skin as you move slowly on the pitted stone floor.  A massive pile of rubble at the southern end makes it impossible to continue in that direction.</description>
    <position x="-242" y="152" z="0" />
    <arc exit="west" move="west" destination="884" />
  </node>
  <node id="886" name="Aesthene's Close, The Vaults">
    <description>The walls of this corridor are agonizingly close.  Nitre and foul-smelling slime streak your clothing and skin as you move slowly on the pitted stone floor.  A massive pile of rubble at the southern end makes it impossible to continue in that direction.</description>
    <position x="-262" y="152" z="0" />
    <arc exit="east" move="east" destination="884" />
  </node>
  <node id="887" name="Aesthene's Close, The Vaults">
    <description>In odd contrast to the sparsity of its surrounding rooms, this chamber houses the rotting remnants of someone's sleeping quarters.  A soggy bed snuggles up against one wall, flanked by a broken chair and a sloping nightstand.  A reed torch lies in a puddle of sludge, and a cracked mirror hangs on a slimy wall.  Though its current state is less than inviting, it would appear it was never outfitted for comfort.</description>
    <position x="-252" y="162" z="0" />
    <arc exit="north" move="north" destination="884" />
  </node>
  <node id="888" name="Cavity">
    <description>Clean sand carpets the floor of a cavity burrowing deep into the rock of the cavern.  Worn tapestries of bright colors and simple patterns cover most of the wall space though an old desk sits patiently beneath one particularly fine specimen.</description>
    <position x="-230" y="-190" z="0" />
    <arc exit="north" move="north" destination="889" />
    <arc exit="climb" move="climb rubble mound" destination="417" />
  </node>
  <node id="889" name="Tunnel">
    <description>Narrowing dramatically, the cavity turns back into a tunnel with rough stone walls.  Leading deeper into the bedrock, jagged scrapes and unnatural shapes indicate that this area was man-made.</description>
    <position x="-230" y="-200" z="0" />
    <arc exit="east" move="east" destination="890" />
    <arc exit="south" move="south" destination="888" />
  </node>
  <node id="890" name="Tunnel">
    <description>Cold and narrow, the tunnel makes an acute turn to the northwest, vanishing into deep shadow.</description>
    <position x="-220" y="-200" z="0" />
    <arc exit="west" move="west" destination="889" />
    <arc exit="northwest" move="northwest" destination="891" />
  </node>
  <node id="891" name="Tunnel">
    <description>A heap of stone, remnant of a fairly recent cave-in, effectively ends the tunnel's sojourn.  Overhead the rock creaks and moans, protesting the burden of the city above, and an occasional trickle of dust filters down from the unstable ceiling.</description>
    <position x="-230" y="-210" z="0" />
    <arc exit="southeast" move="southeast" destination="890" />
  </node>
  <node id="892" name="Dintacui Apartments, Second Floor" color="#00FFFF">
    <description>An arm has been sculpted out of one white, rugged corridor wall, from shoulder to outstretched palm.  Beneath it are several lines of poetry in S'Kra script.  A plain stairway leads down to the first floor.</description>
    <position x="-340" y="190" z="0" />
    <arc exit="north" move="north" destination="893" />
    <arc exit="climb" move="climb plain stairway" destination="694" />
  </node>
  <node id="893" name="Dintacui Apartments, Second Floor" color="#00FFFF">
    <description>A circular brass plate as large as a tower shield is firmly mounted upon a wall of this hallway.  Several lines of poetry are carved upon the wall, encircling the plate and the image of an exotic city engraved upon its surface.  A plain stairway leads to the third floor.</description>
    <position x="-340" y="180" z="0" />
    <arc exit="south" move="south" destination="892" />
    <arc exit="climb" move="climb plain stairway" destination="894" />
  </node>
  <node id="894" name="Dintacui Apartments, Third Floor" color="#00FFFF">
    <description>A ship's mast was affixed to the wall here sometime in the past, though its fabric has long since eroded away to leave a barren stump.  A few crudely-etched words are carved in the rock which serves as its base.  A plain stairway leads down to the second floor.</description>
    <position x="-350" y="180" z="0" />
    <arc exit="south" move="south" destination="895" />
    <arc exit="climb" move="climb plain stairway" destination="893" />
  </node>
  <node id="895" name="Dintacui Apartments, Third Floor" color="#00FFFF">
    <description>A giant geometric rose has been sculpted out of the end of this corridor.  Underneath it run several lines of poetry, lit by glowstones emitting softly pearling light.</description>
    <position x="-350" y="190" z="0" />
    <arc exit="north" move="north" destination="894" />
  </node>
  <node id="896" name="Tower South, Earth Floor" color="#00FFFF">
    <description>Bare, dark soil forms the floor underfoot.  The stony walls surrounding this circular room are similarly devoid of decoration, keeping instead the plain, natural look preferred by those mages who favor the element of Earth.  Doors leading to the initiates' private cells line the walls.</description>
    <position x="130" y="270" z="0" />
    <arc exit="climb" move="climb sandstone staircase" destination="602" />
  </node>
  <node id="897" name="Orem's Bathhouse, Women's Locker Room">
    <description>The ladies locker room is sparkling clean.  Decorated in soft pastels, it has stone benches handy for changing.  A sharp-eyed female attendant maintains propriety, though a large sign warns that she is not responsible for items left behind.</description>
    <position x="20" y="-30" z="0" />
    <arc exit="out" move="out" destination="325" />
  </node>
  <node id="898" name="Crossing Alchemy Society, Entrance" note="Alchemy Society|Alchemy prestige" color="#FF0000">
    <description>Ill-fitted boulders jut at odd angles from the damp granite walls.  Even the ceiling looks a bit ramshackle here, as though the entry-way were built with speed more than safety in mind.  A slight draft blows from deep inside the building and carries a mixture of odd smells with it.</description>
    <position x="-1" y="86" z="0" />
    <arc exit="south" move="south" destination="931" />
    <arc exit="go" move="go oak door" destination="82" />
  </node>
  <node id="899" name="The Crossing, Grey Raven Commissary" note="Grey Raven Commissary" color="#FF0000">
    <description>A cedar counter spans the room from wall to wall, topped by a series of brass bars, preventing anyone from reaching the back of the shop where the various wares are displayed.  A wiry clerk stands behind a small opening in the bars, able to securely pass the items for sale out to buyers.  A red door leads back out to the street.</description>
    <position x="170" y="-378" z="0" />
    <arc exit="go" move="go red door" destination="11" />
    <arc exit="go" move="go curtained archway" destination="900" />
  </node>
  <node id="900" name="Grey Raven Commissary, Tattoo Parlor" note="Tattoo Parlor" color="#00FF00">
    <description>Painted a plain ocean-grey, the walls do little to provide aesthetic in this cramped corner of the hut.  A low cedar table displays a variety of dark stains and contains materials for the artist to perform his skilled work.  Adjacent to the workstation, a reclined chair with scarred padding provides the space for clients to occupy during a session.</description>
    <position x="160" y="-378" z="0" />
    <arc exit="go" move="go curtained archway" destination="899" />
  </node>
  <node id="901" name="Thieves' Guild, Den" note="Den">
    <description>Plush velvet armchairs and pillow-laden sofas dot the meticulously appointed room.  A mahogany cart occupies a corner beneath a leaded glass window, its polished surface bearing refreshments.  Elaborately wrought sconces of hammered iron hold white beeswax candles that light the room with their glow.  Along the perimeter of the lush silk rug set in the center of the obsidian-tiled room are dark grey basalt pedestals bearing alabaster busts.</description>
    <position x="-270" y="-110" z="0" />
    <arc exit="go" move="go arch" destination="575" />
    <arc exit="go" move="go dark curtain" destination="986" />
  </node>
  <node id="902" name="Crossing Forging Society, Lobby and Maker's Mark Ordering" note="Maker's Marks" color="#00FF00">
    <description>A chamber with stone walls and a lofty, vaulted ceiling links the rooms of the forge.  Its high arches help to subdue the clangor, letting it rise and echo in the space overhead.  Waves of heat and flickering reddish light from the foundries to the west strive with the scream of the grindstones to the east and the pounding din of metal on metal from the smithies to the south.</description>
    <position x="332" y="-291" z="0" />
    <arc exit="north" move="north" destination="865" />
    <arc exit="east" move="east" destination="905" />
    <arc exit="south" move="south" destination="906" />
    <arc exit="west" move="west" destination="960" />
  </node>
  <node id="903" name="Crossing Forging Society, Foundry" note="Foundry1">
    <description>This area is the one most favored by the knowledgeable smiths in the guild.  Tall, narrow windows in the northern wall admit whatever breaths of air are stirring, occasionally fanning the flames beneath a granite crucible.  Like the two foundries to the south, this one has all needed implements close at hand.</description>
    <position x="312" y="-301" z="0" />
    <arc exit="south" move="south" destination="960" />
  </node>
  <node id="904" name="Crossing Forging Society, Foundry" note="Foundry2">
    <description>Windows high in the vaulted ceiling ventilate the south corner of the foundry, reducing its oven-like temperature to something endurable.  The forms of a granite crucible and a pile of fuel shimmer in the heat waves rising from the orange bricks of the firepits.  Two similar crucibles hang to the north.</description>
    <position x="312" y="-281" z="0" />
    <arc exit="north" move="north" destination="960" />
  </node>
  <node id="905" name="Crossing Forging Society, Tool Store" note="Forging tools|Forging clerk" color="#FF0000">
    <description>Masters and journeyman of the forging craft find a home in this room purchasing tools and ingredients.  Loud thumps and groaning accompany the loading and unloading of goods from storage.</description>
    <position x="352" y="-291" z="0" />
    <arc exit="north" move="north" destination="962" />
    <arc exit="south" move="south" destination="963" />
    <arc exit="west" move="west" destination="902" />
  </node>
  <node id="906" name="Crossing Forging Society, Supplies" note="Forging supplies|deeds|forging deeds" color="#FF0000">
    <description>A chamber with stone walls and a lofty, vaulted ceiling links the rooms of the forge.  Its high arches help to subdue the clangor, letting it rise and echo in the space overhead.  Waves of heat and flickering reddish light from the foundries to the west strive with the scream of the grindstones to the east and the pounding din of metal on metal from the smithies to the south.</description>
    <position x="332" y="-281" z="0" />
    <arc exit="north" move="north" destination="902" />
    <arc exit="go" move="go western arch" destination="907" />
    <arc exit="go" move="go central arch" destination="908" />
    <arc exit="go" move="go eastern arch" destination="909" />
  </node>
  <node id="907" name="Crossing Forging Society, Smithy" note="Smithy1">
    <description>An iron anvil is mounted on a thick oaken stump in the center of the chamber.  Against the wall behind it is the forge, stoked by Yalda's apprentices, where the sword- or shield-to-be is brought to a red-hot glow before being hammered into shape.</description>
    <position x="322" y="-261" z="0" />
    <arc exit="go" move="go arch" destination="906" />
  </node>
  <node id="908" name="Crossing Forging Society, Forge" note="Forge1">
    <description>These small rooms at the back of Yalda's establishment are the shrines of the smiths, housing the furnaces where the glowing metal is heated, tempered, and beaten into shape.  Just a step away from the forge is an iron anvil, bolted to a charred but solid wooden support.</description>
    <position x="332" y="-261" z="0" />
    <arc exit="go" move="go arch" destination="906" />
  </node>
  <node id="909" name="Crossing Forging Society, Smithy" note="Smithy2">
    <description>This eastern chamber of the smithy is equipped like the others, with a forge and anvil for heating and tempering the castings from the foundry.  From time to time, the din of hammers pounding on the heated blanks rings out from the anvils in the other rooms.</description>
    <position x="342" y="-261" z="0" />
    <arc exit="go" move="go arch" destination="906" />
  </node>
  <node id="910" name="Crossing Outfitting Society, Office" note="Outfitting Office">
    <description>Simple yet slightly elegant, the office serves as a second home for Society Master Milline.  Set within the center of the spacious room, upon a neatly woven black rug, is a masterfully carved oak desk and chair.  Matching the setting within the entry of the hall, crushed seashells in blues and greens span the walls in cresting waves.  Upon a fitting dummy is a stunning black nightsilk dress, accented with brilliant orange jewels.</description>
    <position x="-25" y="-184" z="0" />
    <arc exit="east" move="east" destination="873" />
  </node>
  <node id="911" name="Crossing Outfitting Society, Hallway" note="Outfitting prestige|Outfitting clerk" color="#00FF00">
    <description>Painted ivy vines flow the length of the tan colored walls of the hallway.  Set against one wall is a chaise lounge covered with a light green cotton throw.  Light brown mats rest upon the floor before marble, oak, and ivory doorways which lead into several workrooms.</description>
    <position x="-5" y="-184" z="0" />
    <arc exit="north" move="north" destination="912" />
    <arc exit="south" move="south" destination="915" />
    <arc exit="west" move="west" destination="873" />
    <arc exit="go" move="go oak door" destination="922" />
    <arc exit="go" move="go marble door" destination="923" />
    <arc exit="go" move="go ivory door" destination="924" />
  </node>
  <node id="912" name="Crossing Outfitting Society, Book Shop" note="Outfitting books" color="#FF0000">
    <description>Several bookshelves stand within the room, holding the store inventory for sale.  Harried women pass through a beaded curtain and return with more products, ensuring the shop is fully stocked at all times.  To the rear of the shop is a long counter where a line of patrons wait patiently to purchase their goods.</description>
    <position x="-5" y="-194" z="0" />
    <arc exit="east" move="east" destination="913" />
    <arc exit="south" move="south" destination="911" />
  </node>
  <node id="913" name="Crossing Outfitting Society, Tool Shop" note="Outfitting tools" color="#FF0000">
    <description>Though devoid of decoration, rows of shelving line the walls which hold various tools for sale in the shop.  Filling the shelves on the wall are fine spools of thread, flat irons, straight pins and needles -- the absolute essentials for creating the perfect garment.  Tiny cobwebs hang in the corners of the ceiling, strands dangling down to the surfaces below.</description>
    <position x="5" y="-194" z="0" />
    <arc exit="east" move="east" destination="914" />
    <arc exit="west" move="west" destination="912" />
  </node>
  <node id="914" name="Crossing Outfitting Society, Materials Shop" note="Outfitting supplies" color="#FF0000">
    <description>Grand marble tables and shelves fill the room with fashionable product for sale.  Upon the surfaces are a wide variety of stylish fabrics in a broad spectrum of color.</description>
    <position x="15" y="-194" z="0" />
    <arc exit="west" move="west" destination="913" />
  </node>
  <node id="915" name="Crossing Outfitting Society, Hallway">
    <description>Painted groves of trees span the length of the dark green walls of the hallway.  Set against one wall is a chaise lounge covered with a dark green knitted throw.  Light brown mats rest upon the floor before gold, maple, and oak doorways which lead into several workrooms.</description>
    <position x="-5" y="-174" z="0" />
    <arc exit="north" move="north" destination="911" />
    <arc exit="south" move="south" destination="916" />
    <arc exit="go" move="go gold door" destination="919" />
    <arc exit="go" move="go maple door" destination="920" />
    <arc exit="go" move="go oak door" destination="921" />
  </node>
  <node id="916" name="Crossing Outfitting Society, Hallway">
    <description>Painted rose bushes span the length of the dark brown walls of the hallway.  Set against one wall is a chaise lounge covered with a dark green knitted throw.  Light brown mats rest upon the floor before cedar and painted doorways which lead into several workrooms.</description>
    <position x="-5" y="-164" z="0" />
    <arc exit="north" move="north" destination="915" />
    <arc exit="go" move="go painted door" destination="917" />
    <arc exit="go" move="go cedar door" destination="918" />
  </node>
  <node id="917" name="Crossing Outfitting Society, Workroom">
    <description>Hooks and shelves line the light blue walls, holding various tools and spools of thread that are currently not in use.  Next to the painted door is a simple table and chair, a place to take a load off and enjoy a cool drink.</description>
    <position x="15" y="-164" z="0" />
    <arc exit="go" move="go door" destination="916" />
  </node>
  <node id="918" name="Crossing Outfitting Society, Workroom">
    <description>Hooks and shelves line the deep red walls, holding various tools and spools of thread that are currently not in use.  Next to the carved cedar door is a simple table and chair, a place to take a load off and enjoy a cool drink.</description>
    <position x="25" y="-164" z="0" />
    <arc exit="go" move="go door" destination="916" />
  </node>
  <node id="919" name="Crossing Outfitting Society, Weaving Room" note="Weaving1">
    <description>Set in the back of the large workroom is a hefty loom.  Hooks and shelves line the deep purple walls, holding various tools and spools of thread that are currently not in use.  Next to the gold door is a simple table and chair, a place to take a load off and enjoy a cool drink.</description>
    <position x="15" y="-174" z="0" />
    <arc exit="go" move="go door" destination="915" />
  </node>
  <node id="920" name="Crossing Outfitting Society, Weaving Room" note="Weaving2">
    <description>Set in the back of the large workroom is a hefty loom.  Hooks and shelves line the bright orange walls, holding various tools and spools of thread that are currently not in use.  Next to the maple door is a simple table and chair, a place to take a load off and enjoy a cool drink.</description>
    <position x="25" y="-174" z="0" />
    <arc exit="go" move="go door" destination="915" />
  </node>
  <node id="921" name="Crossing Outfitting Society, Weaving Room" note="Weaving3">
    <description>Set in the back of the large workroom is a hefty loom.  Hooks and shelves line the dark green walls, holding various tools and spools of thread that are currently not in use.  Next to the carved oak door is a simple table and chair, a place to take a load off and enjoy a cool drink.</description>
    <position x="35" y="-174" z="0" />
    <arc exit="go" move="go door" destination="915" />
  </node>
  <node id="922" name="Crossing Outfitting Society, Spinning Room" note="Spinning1">
    <description>Fanciful paintings of birds in flight flow across the bright yellow walls.  Beneath a large spinning wheel is a soft white rug trimmed with black fur.  Pressed against the back of the room is a large workbench and chair, a place to relax or work on a project that requires more attention to detail.  A stained oak door leads back out into the hallway.</description>
    <position x="15" y="-184" z="0" />
    <arc exit="go" move="go door" destination="911" />
  </node>
  <node id="923" name="Crossing Outfitting Society, Spinning Room" note="Spinning2">
    <description>Fanciful paintings of birds in flight flow across the dark green walls.  Beneath a large spinning wheel is a soft white rug trimmed with black fur.  Pressed against the back of the room is a large workbench and chair, a place to relax or work on a project that requires more attention to detail.  A polished marble door leads back out into the hallway.</description>
    <position x="25" y="-184" z="0" />
    <arc exit="go" move="go door" destination="911" />
  </node>
  <node id="924" name="Crossing Outfitting Society, Spinning Room" note="Spinning3">
    <description>Fanciful paintings of birds in flight flow across the light blue walls.  Beneath a large spinning wheel is a soft white rug trimmed with black fur.  Pressed against the back of the room is a large workbench and chair, a place to relax or work on a project that requires more attention to detail.  A carved ivory door leads back out into the hallway.</description>
    <position x="35" y="-184" z="0" />
    <arc exit="go" move="go door" destination="911" />
  </node>
  <node id="925" name="Crossing Engineering Society, Rangu's Repair Shop and Bookstore" note="Engineering clerk|Rangu's Repair Shop|Repair Tools|Engineering Books" color="#00FF00">
    <description>A small forge in the corner of this room basks everything in its warmth.  Adjacent to it, a long counter sits cluttered with numerous tools and devices for repairing things.  Bundles of repaired goods rest against the far wall waiting for pickup.</description>
    <position x="-61" y="26" z="0" />
    <arc exit="east" move="east" destination="851" />
  </node>
  <node id="926" name="Crossing Engineering Society, Hallway" note="Engineering Prestige">
    <description>A long hallway cut from smoky alabaster echoes with all sorts of clinks and clanks.  Doors leading to solitary workshops line the walls, manned by attendants waiting to deliver on deed orders.</description>
    <position x="-41" y="16" z="0" />
    <arc exit="south" move="south" destination="874" />
    <arc exit="go" move="go birch door" destination="930" />
    <arc exit="go" move="go oak door" destination="929" />
    <arc exit="go" move="go maple door" destination="928" />
  </node>
  <node id="927" name="Crossing Engineering Society, Talia's Office" note="Engineering Office|Talia's Office">
    <description>Mechanical components of all shapes and sizes lay scattered about the polished marble floor.  A large workbench littered with diagrams sits under a pair of shelves cluttered with widgets and gears.  The office's rear contains a row of overflowing bookcases lacking any semblance of organization.</description>
    <position x="-51" y="16" z="0" />
    <arc exit="south" move="south" destination="851" />
  </node>
  <node id="928" name="Crossing Engineering Society, Workshop" note="Engineering Workshop1">
    <description>This workshop contains several orderly crafting areas established with eye-level oak partitions.  The alabaster walls appear recently washed, and the floor is even lacking in dust buildup.  A pair of attendants waits quietly at the door, moving occasionally to clean a work area or empty the waste bucket.</description>
    <position x="-51" y="6" z="0" />
    <arc exit="go" move="go door" destination="926" />
  </node>
  <node id="929" name="Crossing Engineering Society, Workshop" note="Engineering Workshop2">
    <description>Unfinished stone furniture, statues and more lie spread out across dozens of reinforced tables.  Crafters hurry to finish designs as attendants haul away pieces too large to carry, storing them for later retrieval.</description>
    <position x="-41" y="6" z="0" />
    <arc exit="go" move="go door" destination="926" />
  </node>
  <node id="930" name="Crossing Engineering Society, Workshop" note="Engineering Workshop3">
    <description>Tall alabaster walls encompass rows of tables covered with unfinished stone pieces.  A massive iron gate and a large chain hanging from a system of pulleys and winches dominate the north end of the room.  Attendants stand at the ready to collect and store crafters' furniture that would otherwise be too large to carry.</description>
    <position x="-31" y="6" z="0" />
    <arc exit="go" move="go door" destination="926" />
  </node>
  <node id="931" name="Crossing Alchemy Society, Tool Shop" note="Alchemy tools|Alchemy clerk|press1|grinder1" color="#00FF00">
    <description>Tall oak supply crates flank an extended counter displaying various alchemical tools for sale.  A pair of robed individuals rush about helping customers restock.  You notice the overwhelming combination of smells is somewhat reduced here.</description>
    <position x="-1" y="96" z="0" />
    <arc exit="north" move="north" destination="898" />
    <arc exit="south" move="south" destination="932" />
  </node>
  <node id="932" name="Crossing Alchemy Society, Bookstore" note="Alchemy books" color="#FF0000">
    <description>A haze of dust permeates the air and casts a glow about the wall torches.  A large bookshelf rests against the back wall and a robed figure scurries up and down a ladder to sell tomes and recipes to interested patrons.</description>
    <position x="-1" y="106" z="0" />
    <arc exit="north" move="north" destination="931" />
    <arc exit="south" move="south" destination="933" />
  </node>
  <node id="933" name="Crossing Alchemy Society, Supplies" note="Alchemy supplies|press2|grinder2" color="#FF0000">
    <description>A pungent odor combines with the powder-filled air to make breathing here more difficult.  Racks of spices, herbs, plants and other materials line the walls as attendants scurry about helping customers.  Pewter trays in each corner hold burning incense sticks.  Despite the size and large amount of smoke wafting from each stick, it is nearly impossible to detect even a hint of their scent.</description>
    <position x="-1" y="116" z="0" />
    <arc exit="north" move="north" destination="932" />
    <arc exit="south" move="south" destination="934" />
  </node>
  <node id="934" name="Crossing Alchemy Society, Office" note="Alchemy Office">
    <description>Cut into the granite of the far wall is a shelf containing an elaborate collection of alchemical equipment.  The assortment overshadows the Society Master's desk, a simple piece of oak furniture pushed unceremoniously against the wall.</description>
    <position x="-1" y="126" z="0" />
    <arc exit="north" move="north" destination="933" />
  </node>
  <node id="935" name="Kertigen's Honor" note="Map998_Transports.xml">
    <description>The length of this ferry is filled to capacity with travelers making their way to the opposite bank of the Segoltha.  Several children kneel at the ferry's edge, watching the water lap gently against its side, while a group of Dwarven merchants glance longingly towards land.</description>
    <position x="-206" y="276" z="0" />
    <arc exit="go" move="go south docks" />
    <arc exit="go" move="go north docks" destination="236" />
  </node>
  <node id="936" name="Hodierna's Grace" note="Map998_Transports.xml">
    <description>A few weary travelers lean against a railing at the bow of this ferry, anxiously waiting to reach the opposite bank.  An elderly S'Kra Mur stands alone at the stern, thoughtfully watching the shallow wake of the ferry shiver and become still.</description>
    <position x="-174" y="276" z="0" />
    <arc exit="go" move="go south docks" />
    <arc exit="go" move="go north docks" destination="236" />
  </node>
  <node id="937" name="Estate Holders' Headquarters, Foyer" note="Estate Holders' Headquarters">
    <description>This tasteful entry hall is paneled with a variety of exotic woods.  The parquet floor is patterned in alternately light and dark diamond shapes, surrounding the Estate Holder crest in the center of the room.  Lining the walls are several plush couches for the comfort of those awaiting appointments.</description>
    <position x="-241" y="80" z="0" />
    <arc exit="go" move="go mahogany door" destination="73" />
    <arc exit="go" move="go viewers' hallway" destination="938" />
    <arc exit="go" move="go business hallway" destination="940" />
  </node>
  <node id="938" name="Estate Holders' Headquarters, Spectator Hallway">
    <description>A short hallway leads from the front of the building to the viewing room, where members can watch council meetings.  A slender royal blue runner carpets footfalls, preventing heavy steppers from disturbing those in attendance.  The walls display portraits of prominent estate holders, past and present.</description>
    <position x="-231" y="80" z="0" />
    <arc exit="go" move="go entry foyer" destination="937" />
    <arc exit="go" move="go teak door" destination="939" />
  </node>
  <node id="939" name="Estate Holders' Headquarters, Spectator Gallery">
    <description>This auditorium provides a place from which the council chambers can be viewed when a meeting is in session.  Comfortable benches, padded in port wine-colored velvet, are arrayed in rows facing a glass window which affords a clear look at the proceedings.  The walls are a finely lacquered teak.</description>
    <position x="-231" y="90" z="0" />
    <arc exit="go" move="go teak door" destination="938" />
  </node>
  <node id="940" name="Estate Holders' Headquarters, Office Hallway">
    <description>This wide hallway is somewhat less opulent than the entry foyer and the rooms dedicated to council meetings, reflecting the fact that this is where the day-to-day business takes place.  Several offices open off from here, with frequent visitors coming and going.  The walls display portraits of prominent estate holders, past and present.</description>
    <position x="-262" y="90" z="0" />
    <arc exit="go" move="go entry foyer" destination="937" />
    <arc exit="go" move="go housing doorway" destination="941" />
    <arc exit="go" move="go exchange doorway" destination="942" />
    <arc exit="go" move="go acquisitions doorway" destination="943" />
    <arc exit="go" move="go expansions doorway" destination="944" />
  </node>
  <node id="941" name="Estate Holders' Headquarters, Housing Office" note="Housing Office" color="#00FF00">
    <description>This is a large office with a well-worn counter, several windows each with a Use Next Window, Please sign and apparently one clerk actually working.  Every town in the land seems cursed with lines and waiting and fees.  This office is for the obtaining of permits, licenses and similar matters.</description>
    <position x="-272" y="100" z="0" />
    <arc exit="go" move="go pine doorway" destination="940" />
  </node>
  <node id="942" name="Estate Holders' Headquarters, Home Exchange Office" note="Home Exchange Office" color="#00FF00">
    <description>Tiny, stuffed with old, dusty furniture, and smelling like yesterday's laundry, this office is anything but a testimony to bureaucratic efficiency.  Large piles of yellowing papers spill from cracked file cabinets and lie scattered upon the floor, fallen from large, ungainly stacks on what little desk space is not taken up by piles of mouldering food.</description>
    <position x="-272" y="90" z="0" />
    <arc exit="go" move="go oak doorway" destination="940" />
  </node>
  <node id="943" name="Estate Holders' Headquarters, Office of Acquisitions">
    <description>Maps cover practically every inch of available wall space, with overview maps covering all of Kermoria ranging down to ones detailing individual neighborhoods.  Trays labeled IN and OUT are filled to overflowing, although the IN box is piled deeper by far.  Government officials, landowners and couriers seem to form a parade of traffic through the office.</description>
    <position x="-272" y="80" z="0" />
    <arc exit="go" move="go deobar doorway" destination="940" />
  </node>
  <node id="944" name="Estate Holders' Headquarters, Office of Expansions">
    <description>This office is like a cousin to the Acquisitions Office without all the hubbub.  There are a handful of maps on the wall, with pushpins marking areas for development.  A few office workers are engaged in conversation with merchants and artisans, discussing potential development opportunities.</description>
    <position x="-262" y="80" z="0" />
    <arc exit="go" move="go maple doorway" destination="940" />
  </node>
  <node id="945" name="Bards' Guild, Wine Cellar">
    <description>Strong support beams crisscross the ceiling above, converging towards wide brick columns that stoically maintain the foundation of the guild.  Shallow grooves worn into the floor attest to the memory of several absent storage racks.</description>
    <position x="-100" y="-408" z="0" />
    <arc exit="east" move="east" destination="946" />
  </node>
  <node id="946" name="Bards' Guild, Old Library">
    <description>Time has not been kind to the cornerstone room of the old Bards' Guild, as is evident by the vein-like cracks and discolorations to the aged brick foundation.  Several long black streaks scar the floor at the west wall where a door might have stood -- a visible reminder and striking mystery as to the demise of the missing portal.</description>
    <position x="-90" y="-408" z="0" />
    <arc exit="west" move="west" destination="945" />
  </node>
  <node id="947" name="Raven's Court, Hallway" color="#00FFFF">
    <description>The fanfare of the outer club fades to memory along the quiet hallway, a place where some of the more esteemed members reside.  A repeating pattern of small, gilded fleur-de-lis imbeds the smooth marble walls, while channels of magnificent blue diamonds crisscross amid the design.  Tiny glowstone orbs create a starry effect against the dark ceiling overhead, the subdued lighting casting a soft glow along the length of the wide corridor.</description>
    <position x="-230" y="-50" z="0" />
    <arc exit="east" move="east" destination="948" />
    <arc exit="south" move="south" destination="559" />
  </node>
  <node id="948" name="Raven's Court, Hallway" color="#00FFFF">
    <description>Plush black carpet cuts a wide swath down the broad hallway, softening the footsteps of all who pass.  In the muted light of the glowstone orbs overhead, hues of vibrant azure glint along the diamond-jeweled marble walls, adding to the elegance of the area.  Tucked within an ornately sculpted niche is a breathtaking glaes statue, displayed behind a velvet stanchion rope.</description>
    <position x="-220" y="-50" z="0" />
    <arc exit="east" move="east" destination="949" />
    <arc exit="west" move="west" destination="947" />
  </node>
  <node id="949" name="Raven's Court, Hallway" color="#00FFFF">
    <description>Tiny glowstone orbs overhead create a soft glow along the quiet hallway, the rich black carpet underfoot and glinting channels of blue diamond that crisscross the walls adding to the starlit ambience.  A potted bougainvillea stands against a nearby wall, its velvety white petals scenting the area with their subtly sweet aroma.</description>
    <position x="-210" y="-50" z="0" />
    <arc exit="south" move="south" destination="558" />
    <arc exit="west" move="west" destination="948" />
  </node>
  <node id="950" name="The Raven's Court, Secluded Alcove" note="Secluded Alcove">
    <description>Delicate floral scents blend with a heavier musk, left to lurk in the air from the former occupants' perfume and cologne.  Dimly lit by the subtle glow of the library's lamps, the niche features a smattering of fat pillows upon the carpeted floor and little else.  Uninterrupted save for a small gap, shrouding drapes of rich velvet envelop the area, serving to mute all sound and prevent conversation from reaching potential eavesdroppers in the main room.</description>
    <position x="-200" y="-20" z="0" />
    <arc exit="go" move="go gap" destination="561" />
  </node>
  <node id="951" name="Order Headquarters, Third Floor Landing">
    <description>The darkened heavens gaze down upon the landing through an octagonal skylight, shadowing a golden seal inlaid within the polished wooden flooring.  Washed out by the moonlight, the faded reflection of the seal plays against the room's darkly oiled paneling.  A solitary ebonwood chair tucked into one corner invites visitors to rest their weary bones upon its deep green velvet cushions.</description>
    <position x="419" y="-94" z="0" />
    <arc exit="east" move="east" destination="952" />
    <arc exit="west" move="west" destination="953" />
    <arc exit="climb" move="climb marble steps" destination="835" />
  </node>
  <node id="952" name="Order Headquarters, Third Floor Landing">
    <description>Strung from a heavy wooden cross beam, a row of lanterns casts a soft glow over the high, vaulted ceiling and brings to life gentle shadows along the ivory walls.  Golden nameplates flicker with the warm light cast over them, shimmering softly from their homes upon the faces of wooden doors lining both sides of the hallway.</description>
    <position x="439" y="-94" z="0" />
    <arc exit="west" move="west" destination="951" />
    <arc exit="go" move="go mahogany door" destination="954" />
    <arc exit="go" move="go pine door" destination="955" />
    <arc exit="go" move="go walnut door" destination="956" />
  </node>
  <node id="953" name="Order Headquarters, Third Floor Landing">
    <description>A flocked, dark blue fabric with splashes of iridescent silver decorates this expansive hallway while off-white carpeting muffles footsteps from a nearby attendant.  Small silver engravings dangle within each of the many doorframes, labeling the rooms beyond, and a single, large potted plant reaches velvety branches towards the vaulted ceiling, as if seeking to touch the heavy wooden cross beams.</description>
    <position x="399" y="-94" z="0" />
    <arc exit="east" move="east" destination="951" />
    <arc exit="go" move="go ebonwood door" destination="957" />
    <arc exit="go" move="go sandalwood door" destination="958" />
    <arc exit="go" move="go cedar door" destination="959" />
  </node>
  <node id="954" name="Order Headquarters, Glacis Hall" note="Glacis Hall">
    <description>Edged with a dark mahogany ceiling trim, a magnificent ceiling fresco canopies this spacious hall, its rich oil colors adding a quality of beauty to the simple meeting room.  Painted with meticulous detailing, the image appears almost life-like both in its size and in its craftsmanship.  Resting upon a plush, deep-green expanse of carpet, the speaker's podium partially obscures the view from a tall, wooden-framed picture window as it stands at attention behind several rows of satin cushioned benches.</description>
    <position x="439" y="-104" z="0" />
    <arc exit="go" move="go mahogany door" destination="952" />
  </node>
  <node id="955" name="Order Headquarters, Sithsia Hall" note="Sithsia Hall">
    <description>Walls of soft sky-blue, edged with an antiqued-bronze filigree trim, enclose lustrous light pine flooring.  A richly hued gold-gilded painting hangs securely along one wall, while at the far side of the room cream-colored brocade curtains have been tied back with a golden rope to reveal a multi-paned window.  In the center of the hall a speaker's podium stands before several rows of pine chairs, sitting beneath a large crystal chandelier dangling from the ceiling.</description>
    <position x="449" y="-94" z="0" />
    <arc exit="go" move="go pine door" destination="952" />
  </node>
  <node id="956" name="Order Headquarters, Sorril Hall" note="Sorril Hall">
    <description>The walls are painted sky-blue and embellished with a pattern of mauve roses and white wisteria, adding a brightness to contrast against the midnight blue carpeting.  Spanning the length of the side wall, illuminated by two oil lamps, hangs an elegant, bronze-framed watercolor painting.  A speaker's podium stands before a congregation of velvet-covered chairs, and behind it, a walnut-framed picture window overlooks the city below.</description>
    <position x="439" y="-84" z="0" />
    <arc exit="go" move="go walnut door" destination="952" />
  </node>
  <node id="957" name="Order Headquarters, Ortug Hall" note="Ortug Hall">
    <description>Laid in an alternating pattern of light tan and deep brown, the wooden floor glistens from heavy polishing, free of any scuff or scratch.  The pattern continues down the length of the hall with the vertical planks creating an illusion of elongation that is interrupted only by the thick fur of an enormous honey-hued bear skin rug.  Mounted behind a matching ebonwood table and chairs set hangs a scarlet tapestry edged with an elaborate golden brocade.</description>
    <position x="399" y="-104" z="0" />
    <arc exit="go" move="go ebonwood door" destination="953" />
  </node>
  <node id="958" name="Order Headquarters, Wolfjaw Hall" note="Wolfjaw Hall">
    <description>Lined with a thick wolf skin rug, the wooden flooring blends with the grey and white fur, adding richness to the earthy wall color.  Columns, painted shades of light and dark grey over the tawny background of the walls and spaciously separated, give the room a larger appearance.  A deep burgundy tapestry, trimmed with glinting silver brocade, hangs behind an inlaid sandalwood table.  Several matching brocade-cushioned chairs surround the table, each with a tall, engraved back.</description>
    <position x="389" y="-94" z="0" />
    <arc exit="go" move="go sandalwood door" destination="953" />
  </node>
  <node id="959" name="Order Headquarters, Daffleberry Hall" note="Daffleberry Hall">
    <description>A faint scent of cedar seeps from the wooden paneling and floats through the air, blanketing the hall with a sense of freshness.  Heavily oiled, the panels take on a deep reddish hue and rise from the floor halfway up the wall.  The top portion is painted soft beige and displays a hand-hewn snow-white tapestry adorned with golden tassels and framed by two brass oil lamps.  Atop a plush, snowbeast-pelt rug rest the heavy clawed feet of a massive redwood table and thirteen matching chairs.</description>
    <position x="399" y="-84" z="0" />
    <arc exit="go" move="go cedar door" destination="953" />
  </node>
  <node id="960" name="Crossing Forging Society, Foundry" note="Foundry3">
    <description>Waves of heat, blasting with an almost tangible force, roll from the flames of a brick-lined firepit.  Over the firepit, a blackened granite crucible hangs by stout chains from an oak beam high overhead.  Near the crucible's spout stand stone molds of different shapes, with a pile of fuel within easy reach.  Similar crucibles hang to the north and south.</description>
    <position x="312" y="-291" z="0" />
    <arc exit="north" move="north" destination="903" />
    <arc exit="east" move="east" destination="902" />
    <arc exit="south" move="south" destination="904" />
    <arc exit="west" move="west" destination="961" />
  </node>
  <node id="961" name="Crossing Forging Society, Foundry" note="Foundry4">
    <description>Waves of heat, blasting with an almost tangible force, roll from the flames of a brick-lined firepit.  Over the firepit, a blackened granite crucible hangs by stout chains from an oak beam high overhead.  Near the crucible's spout stand stone molds of different shapes, with a pile of fuel within easy reach.</description>
    <position x="302" y="-291" z="0" />
    <arc exit="east" move="east" destination="960" />
  </node>
  <node id="962" name="Crossing Forging Society, Forge" note="Forge2">
    <description>Several large grindstones on wooden frames stand in the middle of the workroom.  From time to time, a Dwarven apprentice scatters sand over the floor, both for more secure footing and as a safeguard against fire from the sparks cascading off the grindstones.  A high-pitched keening and the smell of hot metal rise from those in use and from others to the south.</description>
    <position x="352" y="-301" z="0" />
    <arc exit="south" move="south" destination="905" />
  </node>
  <node id="963" name="Crossing Forging Society, Forge" note="Forge3">
    <description>The south end of the grindstone room has a few more of the big stone wheels, all in good condition.  Apprentices of Yalda inspect them daily, treating them with oil and checking for chips on the grinding face.  Other grindstones stand to the north.</description>
    <position x="352" y="-281" z="0" />
    <arc exit="north" move="north" destination="905" />
  </node>
  <node id="964" name="Fenwyrthie's, Collectibles" note="Fenwyrthie Collectibles" color="#FF0000">
    <description>Memorabilia from Fenwyrthie's years of travels and collecting are crammed into every available space.  Items are so tightly wedged on the shelves, racks and stands that pulling one threatens to trigger an avalanche of bags, sacks, bits of junk and dust.  A winding maze of tiny trails wends through the tables, trunks and carpets jammed into the small floorspace.</description>
    <position x="222" y="360" z="0" />
    <arc exit="east" move="east" destination="504" />
    <arc exit="west" move="west" destination="965" />
  </node>
  <node id="965" name="Fenwyrthie's, Keepsakes" note="Fenwyrthie Keepsakes" color="#FF0000">
    <description>Trinkets, toys, bags, and tools of all sorts appear strewn onto every available space.  The visual assault of colorful containers along racks, counters, bins, and shelves does nothing to improve the dusty and cob-web ridden state of the shop.  Nearly every inch of the floor space is taken up by sale surfaces, leaving walking room at a minimum.</description>
    <position x="205" y="360" z="0" />
    <arc exit="east" move="east" destination="964" />
  </node>
  <node id="966" name="Empaths' Guild, Sitting Room" note="Sitting Room|Constanze">
    <description>Soft robin's egg blue paper covers the walls of this large room, patterned with delicate arabesques in an even lighter shade of powder blue.  Several gaily-colored painted landscapes complement the rich hue of the paper, their heavy gilt frames resembling windows into perfect summer days.  The vibrant golden oak of the floor is muffled by a sumptuous woolen ivory rug with a deep, luxurious pile.  Several cheerful golden sconces provide bright -- but not harsh -- light, the oil they burn perfuming the air with a fresh citrus scent.</description>
    <position x="290" y="-438" z="0" />
    <arc exit="go" move="go mahogany door" destination="309" />
  </node>
  <node id="967" name="The Crossing, Immortals' Walk" color="#00FFFF">
    <description>A peaceful sanctuary from the bustle of the city beyond, neatly trimmed hedges shield this garden from the main road.  An ornate marble bench rests in the far corner whilst a neatly ordered rock garden frames the entryway.  A series of manicured lawns provide space for a peaceful stroll punctuated by the occasional flowerbed.  Interspersed amongst the flowerbeds, an array of thirty nine diminutive pale marble statues present an interesting distraction from the natural beauty of the gardens.</description>
    <position x="119" y="36" z="0" />
    <arc exit="south" move="south" destination="968" />
    <arc exit="go" move="go hedged archway" destination="44" />
  </node>
  <node id="968" name="The Crossing, Immortals' Walk" color="#00FFFF">
    <description>Resting at the centre of the array of lawns and gardens, a large pond dominates the area.  Unlike the rest of the lawns this area retains an air of chaos.  Randomly placed stepping stones lead to the centre of the pond where a circular bench provides a place to view the entire garden.  An occasional fallen leaf swirls upon the surface guided by the eddies and currents caused by the small stream feeding the pond.</description>
    <position x="119" y="46" z="0" />
    <arc exit="north" move="north" destination="967" />
    <arc exit="east" move="east" destination="971" />
    <arc exit="southeast" move="southeast" destination="972" />
    <arc exit="south" move="south" destination="969" />
    <arc exit="west" move="west" destination="970" />
  </node>
  <node id="969" name="The Crossing, Immortals' Walk" color="#00FFFF">
    <description>Manicured topiary trees have been placed across the lawn, offering a natural playground for games of hide and seek.  Each tree bears an animal carving on its trunk in honour of the Immortals.  At the foot of each tree, a small alcove provides a place for offerings to the gods.  Further back at the edge of the lawn a tiny flower border has been placed in front of a neat row of homes.</description>
    <position x="119" y="56" z="0" />
    <arc exit="north" move="north" destination="968" />
  </node>
  <node id="970" name="The Crossing, Immortals' Walk" color="#00FFFF">
    <description>Dizzying swirls of sand create the setting of a serene rock garden.  Smooth, polished rocks have been placed in symmetrical patterns amidst the golden hued sands.  A single sana'ati wood rake rests near the edge of the rock garden.  A marble box, ornately carved with a swirling pattern houses a collection of additional rocks in a myriad of riverstone hues.</description>
    <position x="109" y="46" z="0" />
    <arc exit="east" move="east" destination="968" />
  </node>
  <node id="971" name="The Crossing, Immortals' Walk" color="#00FFFF">
    <description>Well kept, lush verdant grass spreads like a carpet, occasional splashes of violet and dusky pink blot the lawn.  Along the border of the lawn the foliage has been ordered and structured to provide a sense of calm.  An Ilithi peach tree has been planted in the furthest corner, providing a shaded spot to rest and contemplate the gardens.</description>
    <position x="129" y="46" z="0" />
    <arc exit="west" move="west" destination="968" />
  </node>
  <node id="972" name="The Crossing, Immortals' Walk" color="#00FFFF">
    <description>More of a glade then a garden, a collection of wildflowers borders the area.  Clusters of bushes provide a sweet perfume that drifts through the glade.  A small blanket has been laid out beneath a small pear tree that provides a serene view of the glade.</description>
    <position x="129" y="56" z="0" />
    <arc exit="northwest" move="northwest" destination="968" />
  </node>
  <node id="973" name="Crossing, Item Registration Office">
    <description>Red tile continues its way through the open doorway and stops abruptly at a long wood counter with polished brass bars positioned to form a cage around the clerks.  A soft glow comes from a single lantern placed atop a long row of filing cabinets.  Papers are strewn about the tops of the cabinets and have spilled over onto the floor.</description>
    <position x="130" y="-70" z="0" />
    <arc exit="out" move="out" destination="188" />
    <arc exit="go" move="go simple curtain" destination="974" />
  </node>
  <node id="974" name="Crossing, Registrar's Office" note="Registrar's Office|item registration" color="#00FF00">
    <description>Not actually a separate room, but sectioned off via a tall row of cabinets is a cramped area, just big enough to fit a table.  The red tile is not so spotless here, but rather has a deep wear pattern that leads from the curtain to a chair in front of the Registrar's desk.</description>
    <position x="130" y="-80" z="0" />
    <arc exit="go" move="go simple curtain" destination="973" />
  </node>
  <node id="975" name="The Crossing Meeting Hall, Entrance" note="Crossing Meeting Hall|Meeting Hall">
    <description>Kept very clean and tidy, the walls of the Meeting Hall entrance are covered in stained wood.  Several glass windows are enshrouded in dark crimson curtains, and twin potted plants stand tall on opposite sides of the exit.  A long carpet runs the length of the long hallway, decorated with a loose mosaic pattern that mimics cobblestone.</description>
    <position x="260" y="-375" z="0" />
    <arc exit="north" move="north" destination="976" />
    <arc exit="out" move="out" destination="8" />
    <arc exit="go" move="go red door" destination="979" />
    <arc exit="go" move="go small archway" destination="978" />
  </node>
  <node id="976" name="The Crossing Meeting Hall, Corridor">
    <description>Gaethzen lights illuminate the hallway in wide strips set into the edges of the ceiling.  Darkly stained mahogany paneling covers the walls, and several pictures of the city hang on the walls.  A long carpet runs the length of the hallway, a cobblestone motif making it appear like a well-used road.</description>
    <position x="260" y="-385" z="0" />
    <arc exit="north" move="north" destination="977" />
    <arc exit="south" move="south" destination="975" />
    <arc exit="go" move="go violet door" destination="980" />
    <arc exit="go" move="go blue door" destination="981" />
  </node>
  <node id="977" name="The Crossing Meeting Hall, Corridor">
    <description>Two small lanterns stand on long poles in each corner of the hallway, which ends at a large portrait of the old Ulf'Hara Keep.  Small twin shelves line the walls, with candles giving off a bit of soft light.  Vertical boards of polished and darkly stained mahogany wood cover the walls, giving it a homey feel.</description>
    <position x="260" y="-395" z="0" />
    <arc exit="south" move="south" destination="976" />
    <arc exit="go" move="go yellow door" destination="982" />
    <arc exit="go" move="go green door" destination="983" />
  </node>
  <node id="978" name="The Crossing Meeting Hall, Lounge">
    <description>Candles adorn the many surfaces within the room, casting their fickle, flickering light across the area.  Rough-hewn wooden walls, dressed up by several elaborate paintings, encircle a floor that's covered in carpet.  Long couches are arranged in the middle of the room, set up for quiet talking.</description>
    <position x="270" y="-375" z="0" />
    <arc exit="go" move="go small archway" destination="975" />
  </node>
  <node id="979" name="Red Meeting Room" note="Red Meeting Room">
    <description>Dark red paint covers the low walls of the meeting room, and tasteful red roses grow in stone pots in one corner.  Several rows of high-backed benches are arranged in the center of the room, each finely carved from cedar.  A small table against one wall holds a few refreshments.</description>
    <position x="250" y="-375" z="0" />
    <arc exit="go" move="go red door" destination="975" />
  </node>
  <node id="980" name="Violet Meeting Room" note="Violet Meeting Room">
    <description>Light violet paint covers the low walls of the meeting room, and tasteful purple lilies grow in stone pots in one corner.  Several rows of high-backed benches are arranged in the center of the room, each finely carved from cedar.  A small table against one wall holds a few refreshments.</description>
    <position x="250" y="-385" z="0" />
    <arc exit="go" move="go violet door" destination="976" />
  </node>
  <node id="981" name="Blue Meeting Room" note="Blue Meeting Room">
    <description>Sky blue paint covers the low walls of the meeting room, and tasteful bluebells grow in stone pots in one corner.  Several rows of high-backed benches are arranged in the center of the room, each finely carved from cedar.  A small table against one wall holds a few refreshments.</description>
    <position x="270" y="-385" z="0" />
    <arc exit="go" move="go blue door" destination="976" />
  </node>
  <node id="982" name="Yellow Meeting Room" note="Yellow Meeting Room">
    <description>Sunny yellow paint covers the low walls of the meeting room, and tasteful marigolds grow in stone pots in one corner.  Several rows of high-backed benches are arranged in the center of the room, each finely carved from cedar.  A small table against one wall holds a few refreshments.</description>
    <position x="250" y="-395" z="0" />
    <arc exit="go" move="go yellow door" destination="977" />
  </node>
  <node id="983" name="Green Meeting Room" note="Green Meeting Room">
    <description>Forest green paint covers the low walls of the meeting room, and tasteful ferns grow in stone pots in one corner.  Several rows of high-backed benches are arranged in the center of the room, each finely carved from cedar.  A small table against one wall holds a few refreshments.</description>
    <position x="270" y="-395" z="0" />
    <arc exit="go" move="go green door" destination="977" />
  </node>
  <node id="984" name="Ranger's Guild, The Tree House" note="Tree House">
    <description>This platform perched high in the treetop offers a breathtaking view of the surroundings, and a small spyglass secured to the banister provides an opportunity to get a closer look.  A slight breeze caresses the leaves of the trees with a sound like the voice of nature whispering secrets to those who will listen.  A few leaves occasionally blow down the carved steps leading to the room below.</description>
    <position x="-120" y="-518" z="0" />
    <arc exit="climb" move="climb carved steps" destination="590" />
    <arc exit="climb" move="climb branch" destination="985" />
  </node>
  <node id="985" name="Northwall Trail, Tree Top" note="Map6_Crossing_North_Gate.xml|Northwall trail">
    <description>Faint light streams down through the tree's upper limbs, painting the branches in an eerie, pale hue.  Now and then the surrounding foliage rustles with movement, though whatever is causing it cannot be seen.  Occasionally something glints in the depth of the shadows -- could it be watchful eyes?  But they appear and are gone again so quickly that perhaps they were only a trick of the imagination.</description>
    <description>Natural light filters down through the tree's mighty limbs.  The bark of the trunk is well worn with use, as if something or someone has been using this as a way of getting around.  Often, the leaves overhead flicker with movement as squirrels leap playfully through the canopy.  The tree has several crude carvings on it, apparently done by someone who had nothing better to do.</description>
    <position x="-140" y="-518" z="0" />
    <arc exit="down" move="down" />
    <arc exit="climb" move="climb branch" destination="984" />
  </node>
  <node id="986" name="Thieves' Guild, Master's Den" note="Master's Den">
    <description>Sumptuous curtains of heavy Musparan silk drape from the walls, obscuring them in the hues of eventide.  Crushed velvet divans, dyed a deep plum hue, boast cloth-of-gold pillows.  Underfoot, the granite floors glitter with flecks of precious metals.  A low goldbark table sits in the center of the room.</description>
    <position x="-260" y="-110" z="0" />
    <arc exit="go" move="go dark curtain" destination="901" />
  </node>
  <node id="987" name="Order Headquarters, Administrator's Office" note="Administrator's Office">
    <description>Thick burgundy carpet adds color and warmth throughout the room, a soft contrast to the rich grain of the flamewood walls which enclose the entire room in an intricately carved pattern of ivy.  Gaethzen orbs dangle from chains secured to the thick ceiling beams that traverse the room, bathing the area in a muted golden hue.  Mounted along the wall's upper moulding, elongated planter boxes encircle the room with overflowing ivy that spills forth a multitude of cascading vines, offsetting the tasteful oil paintings and potted palms.</description>
    <position x="320" y="27" z="0" />
    <arc exit="go" move="go teakwood door" destination="833" />
  </node>
  <node id="988" name="Commendable Collectibles, Foyer" note="Commendable Collectibles">
    <description>An immense fish tank dominates the small entryway, illuminated from behind by soft lamps.  Two arches flank the structure to lead further into the shop, and a plush black sofa rests opposite the tank, allowing visitors to take a seat and enjoy the scene.</description>
    <position x="310" y="7" z="1" />
    <arc exit="northeast" move="northeast" destination="989" />
    <arc exit="northwest" move="northwest" destination="990" />
    <arc exit="go" move="go arched entrance" destination="833" />
  </node>
  <node id="989" name="Commendable Collectibles, Showroom" color="#FF0000">
    <description>A richly woven lambswool carpet spreads out across the floor, muffling the footsteps of any who pass over it.  Poised atop the carpet are a wide glass table and a glass display case, holding a large array of jewelry and charms.  Along the far wall, silver and glass hooks present ribbon bars while a selection of additional ribbons and medallions rest upon an adjacent glass rack.</description>
    <position x="320" y="-3" z="1" />
    <arc exit="southwest" move="southwest" destination="988" />
    <arc exit="go" move="go small alcove" destination="991" />
  </node>
  <node id="990" name="Commendable Collectibles, Showroom" color="#FF0000">
    <description>Bright light bathes the room in warmth, radiating from a grand crystal chandelier hanging in the center.  Painted shelves mounted along one wall stretch from the floor to the ceiling, bearing knickknacks and trinkets for sale.  On the opposite wall, two wide racks present an array of shields and swords.</description>
    <position x="300" y="-3" z="1" />
    <arc exit="southeast" move="southeast" destination="988" />
    <arc exit="go" move="go wooden door" destination="992" />
  </node>
  <node id="991" name="Commendable Collectibles, Alcove" color="#FF0000">
    <description>Rich, polished mahogany covers the walls of the area, which is softly lit by a golden gaezthen orb that hangs suspended from the ceiling.  A vibrant tapestry hangs above a small stone fireplace, flanked by a pair of velvet armchairs, which overlooks the clothing rack at the center of the room.</description>
    <position x="320" y="-13" z="1" />
    <arc exit="go" move="go mahogany archway" destination="989" />
  </node>
  <node id="992" name="Commendable Collectibles, Dim Closet" color="#FF0000">
    <description>Dim light emanates from a small lamp, spilling onto a squat wooden counter that stands atop the dark carpet of this tiny closet, piled high with clutter.  Crowded against the back wall, a set of over-stuffed shelves seems to loom precariously over the room.</description>
    <position x="300" y="-13" z="1" />
    <arc exit="go" move="go wooden door" destination="990" />
  </node>
  <node id="993" name="Crossing, Carousel Family Services" note="Family Vault">
    <description>A series of guarded arches line the southern wall.  The complicated framework of iron and timbers spans across the ceiling.  Countless gears, pulleys and weights form the strikingly complex mechanism which drives the Carousel.</description>
    <position x="130" y="-40" z="0" />
    <arc exit="north" move="north" destination="185" />
  </node>
  <node id="994" name="Crossing Enchanting Society, Entrance" note="Enchanting Society">
    <description>A dim and flickering torch provides barely-adequate illumination of the Society's entryway.  The hall immediately forks before a shimmering sign indicating directions down each hall.  Distorted echoes from numerous chanting voices rebound down the hallway and combine to form a somber melody in this acoustically well-placed room.</description>
    <position x="179" y="-474" z="0" />
    <arc exit="go" move="go wide door" destination="139" />
    <arc exit="northeast" move="northeast" destination="995" />
    <arc exit="northwest" move="northwest" destination="998" />
  </node>
  <node id="995" name="Crossing Enchanting Society, Bookstore" note="Enchanting Books" color="#FF0000">
    <description>Aisle after aisle of books stand side by side in this place.  The walls of the hall curve back and forth in a visually confusing fashion, but somehow the bookshelves and cobblestone floor are still aligned perfectly.  Robed attendants stand ready to take book orders.</description>
    <position x="189" y="-484" z="0" />
    <arc exit="north" move="north" destination="996" />
    <arc exit="southwest" move="southwest" destination="994" />
  </node>
  <node id="996" name="Crossing Enchanting Society, Supplies" note="Enchanting Supplies" color="#FF0000">
    <description>Flickering torches are set in bronze sconces that line the walls of the square hall.  A series of shelves with open cubbyholes line the back of the room in tidy rows.  Standing behind a sturdy oak counter, robed attendants stand ready to take supply orders.</description>
    <position x="189" y="-494" z="0" />
    <arc exit="north" move="north" destination="997" />
    <arc exit="south" move="south" destination="995" />
  </node>
  <node id="997" name="Crossing Enchanting Society, Tool Store" note="Enchanting Tools" color="#FF0000">
    <description>Pairs of torches are set at each corner of the triangular room, causing strange shadows to shift and undulate against the rough stone walls.  Open shelving stacked neatly with supplies line the furthest corner of the room.  A trio of robed attendants stands ready to take orders for enchanting tools.</description>
    <position x="189" y="-504" z="0" />
    <arc exit="south" move="south" destination="996" />
  </node>
  <node id="998" name="Crossing Enchanting Society, Rotunda">
    <description>Hooded figures stand within recessed balconies that surround the perfectly circular room.  Their low-pitched chanting echoes through the area with a deep thrumming sound.  Four doors are placed at equal intervals along the curved wall of the rotunda.</description>
    <position x="169" y="-484" z="0" />
    <arc exit="north" move="north" destination="999" />
    <arc exit="southeast" move="southeast" destination="994" />
    <arc exit="go" move="go azure door" destination="1000" />
    <arc exit="go" move="go sienna door" destination="1001" />
    <arc exit="go" move="go cobalt door" destination="1002" />
    <arc exit="go" move="go crimson door" destination="1003" />
  </node>
  <node id="999" name="Crossing Enchanting Society, Society Master's Office">
    <description>A large domed ceiling is magnificently painted into a faithful recreation of the night sky, complete with constellations and moons.  A plump tasseled cushion is placed on the cobblestone floor at the center of the room.</description>
    <position x="169" y="-494" z="0" />
    <arc exit="south" move="south" destination="998" />
  </node>
  <node id="1000" name="Crossing Enchanting Society, Air Workroom" note="1000|Enchanting1|AirEnchanting|EnchantingAir|EAir">
    <description>Azure velvet padding lining the walls and plush carpet covering the cobblestone floor prevent outside sounds from disturbing the peaceful sanctity of the workroom.  A large marble table with cyclone-shaped legs provides ample working space.</description>
    <position x="159" y="-494" z="0" />
    <arc exit="go" move="go azure door" destination="998" />
  </node>
  <node id="1001" name="Crossing Enchanting Society, Earth Workroom" note="1001|Enchanting2|EarthEnchanting|EnchantingEarthEEarth">
    <description>Sienna velvet padding lining the walls and plush carpet covering the cobblestone floor prevent outside sounds from disturbing the peaceful sanctity of the workroom.  A large marble table with mountain-shaped legs provides ample working space.</description>
    <position x="159" y="-484" z="0" />
    <arc exit="go" move="go sienna door" destination="998" />
  </node>
  <node id="1002" name="Crossing Enchanting Society, Water Workroom" note="1002|Enchanting3|WaterEnchanting|EnchantingWater|EWater">
    <description>Cobalt velvet padding lining the walls and plush carpet covering the cobblestone floor prevent outside sounds from disturbing the peaceful sanctity of the workroom.  A large marble table with raindrop-shaped legs provides ample working space.</description>
    <position x="159" y="-474" z="0" />
    <arc exit="go" move="go cobalt door" destination="998" />
  </node>
  <node id="1003" name="Crossing Enchanting Society, Fire Workroom" note="1003|Enchanting4|FireEnchanting|EnchantingFire|EFire">
    <description>Crimson velvet padding lining the walls and plush carpet covering the cobblestone floor prevent outside sounds from disturbing the peaceful sanctity of the workroom.  A large marble table with flame-shaped legs provides ample working space.</description>
    <position x="169" y="-474" z="0" />
    <arc exit="go" move="go crimson door" destination="998" />
  </node>
  <node id="1004" name="The Raven's Court, Indoor Pond" note="Raven Pond">
    <description>Floating lily pads hover gently along the water's surface that ripples from every subtle contact with the fish swimming languidly underneath.  Though only darkness is visible through several etched glass windows, sconces placed along the walls illuminate the area with flickering candlelight.  A collection of cushioned marble benches and potted palms border the small pool, allowing visitors to relax and reflect in a supremely soothing atmosphere.</description>
    <description>Floating lily pads hover gently along the water's surface that ripples from every subtle contact with the fish swimming languidly underneath.  Daylight drenches the area through several glass windows, each etched with an artistic fantasy of flora and fauna.  A collection of cushioned marble benches and potted palms border the small pool, allowing visitors to relax and reflect in a supremely soothing atmosphere.</description>
    <position x="-220" y="30" z="0" />
    <arc exit="climb" move="climb small steps" destination="527" />
  </node>
  <node id="1005" name="Crossing Escape Tunnels, Kuniyo's Egress" note="Map2d_Escape_Tunnels.xml">
    <description>Rough-hewn blocks of sandstone form a tall arch with a stylized metallic eye gleaming at its apex.  The structure curves over a hard-packed path of earth mixed with clay and pine needles that slopes abruptly down and into darkness.  Stray beams of light reveal that this is no dead-end, barely outlining a narrow passage at the foot of the incline.</description>
    <position x="-90" y="-468" z="0" />
    <arc exit="east" move="east" />
  </node>
  <node id="1006" name="Crossing Escape Tunnels, Truffenyi's Way" note="Map2d_Escape_Tunnels.xml">
    <description>A stylized eye of some metallic substance is set at the apex of a granite arch that guards the entrance to this room.  Against one wall, a plank between two stacks of clay bricks forms a makeshift shelf, supporting a row of tallow candles in brass holders.  Their flickering illumination, combined with pervasive dampness, imbues the atmosphere with a topaz-hued glow.</description>
    <position x="-20" y="-548" z="0" />
    <arc exit="south" move="south" />
  </node>
  <node id="1007" name="Crossing Escape Tunnels, Hodierna's Path" note="Map2d_Escape_Tunnels.xml">
    <description>Dense walls hacked out of earth and stone curve around a massive arch centered with a stylized metal eye that shadows a series of unevenly-chiseled steps wending their way down into darkness.  Gloom obscures the area beyond, but a chilly draft from below hints at an opening of some kind.</description>
    <position x="280" y="-448" z="0" />
    <arc exit="south" move="south" />
  </node>
  <node id="1008" name="Korhege Apartments, Second Floor" color="#00FFFF">
    <description>The sand in the corridor's surfaces, frozen in rolling, shaded blue patterns, imitates the flow of waves.  One wall reveals the skeleton of a boulder-sized sponge.  Another swarms with fragments of fish scales, sea-changed into mother-of-pearl.  A stairwell leads to the first floor.</description>
    <position x="-225" y="200" z="0" />
    <arc exit="climb" move="climb stairwell" destination="689" />
    <arc exit="north" destination="1009" />
  </node>
  <node id="1009" name="Korhege Apartments, Second Floor" color="#00FFFF">
    <description>A set of tiles have been inlaid along the blue sandstone walls of this hallway.  Their ivory backgrounds are covered with geometric patterns featuring artemisia, purple variwinkle blossoms and k'dira leaves.  A stairwell leads to the third floor.</description>
    <position x="-225" y="190" z="0" />
    <arc exit="south" destination="1008" />
    <arc exit="climb" move="climb stairwell" destination="1010" />
  </node>
  <node id="1010" name="Korhege Apartments, Third Floor" color="#00FFFF">
    <description>Hundreds of seashell splinters glint like diamond dust in the sandstone hallway.  A hexagonal brass table, narrow and tall, stands unobtrusively to one side.  A stairwell leads to the second floor.</description>
    <position x="-235" y="190" z="0" />
    <arc exit="climb" move="climb stairwell" destination="1009" />
    <arc exit="south" destination="1011" />
  </node>
  <node id="1011" name="Korhege Apartments, Third Floor" color="#00FFFF">
    <description>A small fountain shrine decorates the end of this corridor, bearing an image of Lemicus attended by merfolk.  Amplified by the stone walls, the eternally bubbling water takes on a soft, deep murmur.</description>
    <position x="-235" y="200" z="0" />
    <arc exit="north" destination="1010" />
  </node>
  <node id="1012" name="Merchant Apartments, Second Floor" color="#00FFFF">
    <description>This interior stone corridor is bare save for a green and gold rug and a single, brightly shining glowstone.  Translucent paints have been delicately applied to the latter, creating a splay of soft, geometric shadows upon the far wall.  A staircase leads down to the first floor.</description>
    <position x="-195" y="190" z="0" />
    <arc exit="climb" move="climb staircase" destination="685" />
    <arc exit="south" destination="1012" />
  </node>
  <node id="1013" name="Merchant Apartments, Second Floor" color="#00FFFF">
    <description>A dwarf plovik tree sits quietly in an earthenware pot in one corner of this sandstone corridor.  Its lustrous, splayed leaves draw nourishment from the soft but warm light of numerous glowstones.  A staircase leads up to a third floor.</description>
    <position x="-195" y="200" z="0" />
    <arc exit="north" destination="1012" />
    <arc exit="climb" move="climb staircase" destination="1014" />
  </node>
  <node id="1014" name="Merchant Apartments, Third Floor" color="#00FFFF">
    <description>This spartan corridor has been rendered more lively by a flat-woven, floor-length kelim in deep magenta, black and gold, its fringes laced with tiny, round, brass bells.  Pearlescent glowstones shine softly next to each room.  A staircase leads down to the second floor.</description>
    <position x="-185" y="200" z="0" />
    <arc exit="north" destination="1015" />
    <arc exit="climb" move="climb staircase" destination="1013" />
  </node>
  <node id="1015" name="Merchant Apartments, Third Floor" color="#00FFFF">
    <description>The kelim continues here, its pebble-sized bells jangling with any movement that ruffles its surface.  Above it, recessed in a small alcove of one sandstone wall, a small statue of Hav'roth reclines upon a square-cut throne.</description>
    <position x="-185" y="190" z="0" />
    <arc exit="south" destination="1014" />
  </node>
  <node id="1016" name="Cormyn's House of Heirlooms">
    <description>This private office is a welcome contrast to the front room of the Cormyn's pawnshop.  It appears to be a luxuriously appointed retreat for someone of great wealth and prominence.  Due to its quiet, tasteful decor, you are sure it must be someone other than Cormyn.  An ebony desk and a high-backed leather chair show signs of frequent use.  In the corner, a ceiling-high safe holds secrets to which you are not privy.</description>
    <position x="-77" y="-240" z="0" />
    <arc exit="go" move="go lunat door" destination="433" />
  </node>
  <node id="1017" name="The Seacaves of Peri'el, Tidal Cave" note="The_Seacaves_of_Peri'el.xml|seacaves">
    <description>Water bubbles up from a small spring before it tumbles over the edge of the hill, plunging down a smooth rock chute.  Far below, the water splashes into a crystal blue grotto which sparkles in the sunlight.</description>
    <position x="265" y="160" z="0" />
    <arc exit="out" />
  </node>
  <node id="1018" name="The Healerie, Combat Wing" note="overhealers anonymous|overhealers">
    <description>The corridor widens here, the ceiling arching upwards in a dramatic vaulted style from which lanterns hang to provide lighting.  A practice mat, complete with a display that holds an impressive-sized shield, provides space for training defensive maneuvers and healing while in the thick of combat.  Set behind a painted paper screen depicting battle, a circle of soft chairs surrounds a table topped with a decanter and a vase of pink dahlias.</description>
    <position x="320" y="-448" z="0" />
    <arc exit="west" move="west" destination="431" />
  </node>
  <node id="1019" name="Strand Communal Center, Alchemists' Workshop">
    <description>Shelves and counters line the walls, their surfaces scratched and marred, and the built-in stove is crusted with unidentifiable debris.  Broken bottles sit haphazardly upon the shelves, and a utilitarian unlonchai bucket has been fastened to the floor.  In a tiny skylight, a Wayerd pyramid has been installed for drying herbs and other supplies.  No attempt has been made to add decoration to the room, yet the workaday tools of the practicing alchemist have a certain charm.</description>
    <position x="350" y="260" z="0" />
    <arc exit="go" move="go louvered door" destination="495" />
  </node>
  <node id="1020" name="Sand Spit Tavern, The Raven's Nest">
    <description>A cacophony of cheers and groans emanate from a crowd circled around a rust-stained ring of rags in the center of the makeshift speakeasy.  A series of grunts and shouts sound out over the gathering while groups of cloaked figures shy away from the commotion and cluster together at mismatched sets of well-crafted tables and chairs that are carelessly arranged around the perimeter.  Occasionally, a figure draped in a feathered cloak moves through the dim flickering light in the room to stand near a nondescript box at the jagged entrance.</description>
    <position x="-290" y="270" z="0" />
    <arc exit="out" move="out" destination="857" />
  </node>
  <label text="Shipyard">
    <position x="-20" y="314" z="0" />
  </label>
  <label text="The Strand">
    <position x="183" y="369" z="0" />
  </label>
  <label text="Seardaz Cove">
    <position x="406" y="197" z="0" />
  </label>
  <label text="Segoltha River">
    <position x="-400" y="225" z="0" />
  </label>
  <label text="Town Hall">
    <position x="180" y="-36" z="0" />
  </label>
  <label text="Riverpine Circle">
    <position x="353" y="100" z="0" />
  </label>
  <label text="Trader Market">
    <position x="334" y="-224" z="0" />
  </label>
  <label text="Bank">
    <position x="154" y="24" z="0" />
  </label>
  <label text="Temple">
    <position x="187" y="65" z="0" />
  </label>
  <label text="Trader">
    <position x="-155" y="24" z="0" />
  </label>
  <label text="Guard House">
    <position x="-184" y="94" z="0" />
  </label>
  <label text="Bard">
    <position x="-81" y="-416" z="0" />
  </label>
  <label text="Goldstone">
    <position x="24" y="-434" z="0" />
  </label>
  <label text="Jadewater">
    <position x="130" y="-592" z="0" />
  </label>
  <label text="Willow">
    <position x="219" y="-444" z="0" />
  </label>
  <label text="Empath">
    <position x="250" y="-424" z="0" />
  </label>
  <label text="Asemath">
    <position x="-20" y="-332" z="0" />
  </label>
  <label text="Crofton Walk">
    <position x="80" y="-299" z="0" />
  </label>
  <label text="Barbarian">
    <position x="308" y="-360" z="0" />
  </label>
  <label text="Vaults and">
    <position x="65" y="-94" z="0" />
  </label>
  <label text="Cleric">
    <position x="-15" y="-586" z="0" />
  </label>
  <label text="Raven's Court">
    <position x="-302" y="38" z="0" />
  </label>
  <label text="Midton">
    <position x="190" y="-250" z="0" />
  </label>
  <label text="Ranger">
    <position x="-155" y="-480" z="0" />
  </label>
  <label text="Tower">
    <position x="89" y="222" z="0" />
  </label>
  <label text="South">
    <position x="92" y="234" z="0" />
  </label>
  <label text="Metal Repair">
    <position x="255" y="55" z="0" />
  </label>
  <label text="Sewers">
    <position x="-170" y="-110" z="0" />
  </label>
  <label text="Thief">
    <position x="-300" y="-140" z="0" />
  </label>
  <label text="Pawn">
    <position x="-105" y="-258" z="0" />
  </label>
  <label text="Agility">
    <position x="-167" y="-167" z="0" />
  </label>
  <label text="Locksmith">
    <position x="-55" y="-121" z="0" />
  </label>
  <label text="Bathhouse">
    <position x="-20" y="-80" z="0" />
  </label>
  <label text="Gems">
    <position x="270" y="-94" z="0" />
  </label>
  <label text="Silverfish">
    <position x="-241" y="-84" z="0" />
  </label>
  <label text="Footpads">
    <position x="-281" y="-214" z="0" />
  </label>
  <label text="Ruffians">
    <position x="-281" y="-224" z="0" />
  </label>
  <label text="Silverfish">
    <position x="140" y="160" z="0" />
  </label>
  <label text="Paladin">
    <position x="280" y="-530" z="0" />
  </label>
  <label text="Order HQ">
    <position x="308" y="-50" z="0" />
  </label>
  <label text="West Gate">
    <position x="-345" y="-387" z="0" />
  </label>
  <label text="Northeast Gate">
    <position x="415" y="-450" z="0" />
  </label>
  <label text="East Gate">
    <position x="400" y="64" z="0" />
  </label>
  <label text="North Gate">
    <position x="57" y="-580" z="0" />
  </label>
  <label text="Market Plaza">
    <position x="280" y="-240" z="0" />
  </label>
  <label text="Engineering">
    <position x="-101" y="-13" z="0" />
  </label>
  <label text="Forging Society">
    <position x="322" y="-321" z="0" />
  </label>
  <label text="Music">
    <position x="84" y="-177" z="0" />
  </label>
  <label text="Florist">
    <position x="195" y="-313" z="0" />
  </label>
  <label text="Docks">
    <position x="-27" y="193" z="0" />
  </label>
  <label text="Ferry">
    <position x="-206" y="283" z="0" />
  </label>
  <label text="Landfall Dock">
    <position x="253" y="173" z="0" />
  </label>
  <label text="Aesthene's">
    <position x="-165" y="118" z="0" />
  </label>
  <label text="Sand Spit Tavern">
    <position x="-341" y="276" z="0" />
  </label>
  <label text="Tannery">
    <position x="-65" y="-496" z="0" />
  </label>
  <label text="Communal Center">
    <position x="270" y="325" z="0" />
  </label>
  <label text="Skirr'lolasu">
    <position x="-43" y="218" z="0" />
  </label>
  <label text="Thin Veneer">
    <position x="-183" y="213" z="0" />
  </label>
  <label text="Elmod Close">
    <position x="-395" y="103" z="0" />
  </label>
  <label text="Drelstead Prison">
    <position x="-411" y="76" z="0" />
  </label>
  <label text="Swithen's Court">
    <position x="-395" y="25" z="0" />
  </label>
  <label text="Dintacui Apts.">
    <position x="-361" y="190" z="0" />
  </label>
  <label text="Stamina">
    <position x="250" y="-356" z="0" />
  </label>
  <label text="Taelbert's">
    <position x="-87" y="-435" z="0" />
  </label>
  <label text="Herbs">
    <position x="165" y="-425" z="0" />
  </label>
  <label text="Shoes">
    <position x="375" y="-405" z="0" />
  </label>
  <label text="Discipline">
    <position x="-65" y="-535" z="0" />
  </label>
  <label text="Alchemy">
    <position x="85" y="-500" z="0" />
  </label>
  <label text="Exteriors">
    <position x="-185" y="-258" z="0" />
  </label>
  <label text="Chairs">
    <position x="149" y="-554" z="0" />
  </label>
  <label text="Bakery">
    <position x="52" y="-392" z="0" />
  </label>
  <label text="Caravan">
    <position x="-253" y="-425" z="0" />
  </label>
  <label text="Joust">
    <position x="220" y="-553" z="0" />
  </label>
  <label text="Tamsine">
    <position x="200" y="105" z="0" />
  </label>
  <label text="Tower">
    <position x="394" y="-60" z="0" />
  </label>
  <label text="East">
    <position x="396" y="-47" z="0" />
  </label>
  <label text="Strength">
    <position x="107" y="-238" z="0" />
  </label>
  <label text="Reflex">
    <position x="244" y="-248" z="0" />
  </label>
  <label text="Ushnish">
    <position x="-273" y="-258" z="0" />
  </label>
  <label text="Half Pint">
    <position x="20" y="24" z="0" />
  </label>
  <label text="Grocery">
    <position x="113" y="-401" z="0" />
  </label>
  <label text="Empath Shop">
    <position x="254" y="-504" z="0" />
  </label>
  <label text="Paladin Shop">
    <position x="244" y="-632" z="0" />
  </label>
  <label text="Outfitting Society">
    <position x="-33" y="-216" z="0" />
  </label>
  <label text="Close">
    <position x="-159" y="132" z="0" />
  </label>
  <label text="Thugs">
    <position x="-281" y="-204" z="0" />
  </label>
  <label text="Alchemy">
    <position x="-54" y="87" z="0" />
  </label>
  <label text="Society">
    <position x="-48" y="99" z="0" />
  </label>
  <label text="Amusement Pier">
    <position x="-143" y="239" z="0" />
  </label>
  <label text="&amp; Tenderfoot">
    <position x="125" y="-580" z="0" />
  </label>
  <label text="Society">
    <position x="-98" y="0" z="0" />
  </label>
  <label text="Estate Holders">
    <position x="-268" y="94" z="0" />
  </label>
  <label text="Immortals'">
    <position x="99" y="59" z="0" />
  </label>
  <label text="Walk">
    <position x="109" y="71" z="0" />
  </label>
  <label text="Registration">
    <position x="60" y="-80" z="0" />
  </label>
  <label text="Meeting">
    <position x="202" y="-400" z="0" />
  </label>
  <label text="Hall">
    <position x="223" y="-385" z="0" />
  </label>
  <label text="Enchanting">
    <position x="139" y="-470" z="0" />
  </label>
  <label text="Seacaves">
    <position x="260" y="139" z="0" />
  </label>
</zone>
"""
    }
}
