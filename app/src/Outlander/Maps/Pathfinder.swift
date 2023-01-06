//
//  Pathfinder.swift
//  Outlander
//
//  Created by Joe McBride on 11/7/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class TreeNode {
    var id: String
    var parent: TreeNode?

    var h: Int = 0
    var g: Int = 0

    var f: Int {
        h + g
    }

    init(id: String, parent: TreeNode? = nil) {
        self.id = id
        self.parent = parent
    }

    func print() -> String {
        "TreeNode id=\(id) h=\(h) g=\(g) f=\(f)"
    }
}

extension TreeNode: Comparable, Hashable {
    static func < (lhs: TreeNode, rhs: TreeNode) -> Bool {
        lhs.f < rhs.f
    }

    static func > (lhs: TreeNode, rhs: TreeNode) -> Bool {
        lhs.f > rhs.f
    }

    static func == (lhs: TreeNode, rhs: TreeNode) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(parent)
        hasher.combine(f)
    }
}

class Pathfinder {
    private let log = LogManager.getLog(String(describing: Pathfinder.self))

    func findPath(start: String, target: String, zone: MapZone) -> [String] {
        var openList: [TreeNode] = []
        var closedList: [TreeNode] = []

        guard let startNode = zone.room(id: start), let endNode = zone.room(id: target) else {
            return []
        }

        openList.append(TreeNode(id: startNode.id))

        var found: TreeNode?

        var count = 0

        while let current = nodeWithLowestFScore(openList) {
            log.info("checking: \(current.print())")
            count += 1

            closedList.append(current)
            openList.remove(at: openList.firstIndex(of: current)!)

            if current.id == endNode.id {
                found = current
                break
            }

            guard let currentMapNode = zone.room(id: current.id) else {
                return []
            }

            var currentArcs: [TreeNode] = []

            for arc in currentMapNode.filteredArcs {
                log.info("checking arc \(arc.move) \(arc.destination) cost: \(arc.moveCost)")
                guard let room = zone.room(id: arc.destination) else {
                    continue
                }

                // ignore arcs that point to the current room
                // ignore duplicate arcs that point to a room that already has been evaluated
                guard room.id != current.id, !isInList(currentArcs, node: room) else {
                    continue
                }

                // see if already on closed list
                guard !isInList(closedList, node: room) else {
                    continue
                }

                let moveCost = zone.moveCostForNode(node: currentMapNode, toNode: endNode, arc: arc)

                let newNode = TreeNode(id: room.id, parent: current)
                newNode.g = current.g + moveCost
                newNode.h = zone.heuristic(node: room, endNode: endNode)

                currentArcs.append(newNode)
            }

            var arcsToAdd: [TreeNode] = []

            for node in currentArcs {
                if let openNode = openList.first(where: { $0.id == node.id }) {
                    if node.f > openNode.f {
                        continue
                    }
                }

                arcsToAdd.append(node)
            }

            let display = arcsToAdd.map { $0.print() }
            if display.count > 0 {
                log.info("adding to open list \(display)")
            }

            openList.append(contentsOf: arcsToAdd.sorted(by: { $0.f < $1.f }))
        }

        log.info("Checked \(count) nodes")

        // back track from the end node
        if let node = found {
            log.info("found \(node.id)")
            return backTrack(node)
        }

        // there is no route
        return []
    }

    func nodeWithLowestFScore(_ list: [TreeNode]) -> TreeNode? {
        list.sorted { $0.f < $1.f }.first
    }

    func getNode(_ list: [TreeNode], mapNode: MapNode) -> TreeNode? {
        list.first { $0.id == mapNode.id }
    }

    func isInList(_ list: [TreeNode], node: MapNode) -> Bool {
        list.first { $0.id == node.id } != nil
    }

    func backTrack(_ path: TreeNode) -> [String] {
        var shortestPath: [String] = []
        var step: TreeNode? = path

        repeat {
            if step?.parent != nil {
                shortestPath.insert(step!.id, at: 0)
            }
            step = step?.parent
        } while step?.parent != nil

        if step != nil {
            shortestPath.insert(step!.id, at: 0)
        }

        log.info("shortest path: \(shortestPath)")

        return shortestPath
    }
}
