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
//    func findPathQueue(start: String, target: String, zone: MapZone) -> [String] {
//        guard let startNode = zone.room(id: start), let endNode = zone.room(id: target) else {
//            return []
//        }
//
//        var frontier = PriorityQueue(ascending: true, startingValues: [TreeNode(id: startNode.id)])
//
//        return []
//    }

    func findPath(start: String, target: String, zone: MapZone) -> [String] {
        var openList: [TreeNode] = []
        var closedList: [TreeNode] = []

        guard let startNode = zone.room(id: start), let endNode = zone.room(id: target) else {
            return []
        }

        openList.append(TreeNode(id: startNode.id))

        var found: TreeNode?

        while let current = nodeWithLowestFScore(list: openList) {
//            print("checking: \(current.id)")

            closedList.append(current)
            openList.remove(at: openList.firstIndex(of: current)!)

            if isInList(closedList, node: endNode) {
                found = current
                break
            }

            guard let currentMapNode = zone.room(id: current.id) else {
                return []
            }

            for arc in currentMapNode.filteredArcs {
//                print("checking arc \(arc.move) \(arc.destination) cost: \(arc.moveCost)")
                guard let room = zone.room(id: arc.destination) else {
                    continue
                }

                guard !isInList(closedList, node: room) else {
                    continue
                }

                let treeNode = getNode(openList, mapNode: room)
                let moveCost = zone.moveCostForNode(node: currentMapNode, toNode: endNode, arc: arc)

                if let node = treeNode {
                    node.parent = current
                    node.g = current.g + moveCost
                } else {
                    let newNode = TreeNode(id: room.id, parent: current)
                    newNode.g = current.g + moveCost
                    newNode.h = zone.heuristic(node: room, endNode: endNode)
                    openList.append(newNode)
                }
            }
        }

        // back track from the end node
        if let node = found {
            print("pathfinder found \(node.id)")
            return backTrack(node)
        }

        // there is no route
        return []
    }

    func getNode(_ list: [TreeNode], mapNode: MapNode) -> TreeNode? {
        list.first { $0.id == mapNode.id }
    }

    func nodeWithLowestFScore(list: [TreeNode]) -> TreeNode? {
        list.sorted { $0.f < $1.f }.first
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

        return shortestPath
    }
}
