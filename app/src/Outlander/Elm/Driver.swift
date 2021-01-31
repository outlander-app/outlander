//
//  Driver.swift
//  Outlander
//
//  Created by Joseph McBride on 7/21/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Cocoa
import Foundation

final class Driver<Model, Message> {
    private var model: Model
    private var strongReferences = StrongReferences()
    private(set) var viewController = NSViewController()

    private let updateState: (inout Model, Message) -> [Command<Message>]
    private let computeView: (Model) -> ViewController<Message>

    init(_ initial: Model,
         update: @escaping (inout Model, Message) -> [Command<Message>],
         view: @escaping (Model) -> ViewController<Message>)
    {
        model = initial
        updateState = update
        computeView = view

        let subview = OView()

        viewController.view = subview

        strongReferences = view(model).render(callback: asyncSend, change: &viewController)
    }

    func asyncSend(action: Message) {
        DispatchQueue.main.async { [unowned self] in
            self.run(action: action)
        }
    }

    func run(action: Message) {
        assert(Thread.current.isMainThread)
        let commands = updateState(&model, action)
        refresh()
        for command in commands {
            interpret(command: command)
        }
    }

    func interpret(command: Command<Message>) {
        command.run(Context(viewController: viewController, send: asyncSend))
    }

    func refresh() {
        // subscriptionManager.update(subscriptions: fetchSubscriptions(model))
        strongReferences = computeView(model).render(callback: asyncSend, change: &viewController)
    }
}
