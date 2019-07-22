//
//  Driver.swift
//  Outlander
//
//  Created by Joseph McBride on 7/21/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation
import Cocoa

class OView : NSView {
    override var isFlipped: Bool {
        return true
    }
}

final class Driver<Model, Message> {
    private var model: Model
    private var strongReferences: StrongReferences = StrongReferences()
    private(set) var viewController: NSViewController = NSViewController()
    
    private let updateState: (inout Model, Message) -> [Command<Message>]
    private let computeView: (Model) -> ViewController<Message>

    init(_ initial: Model,
         update: @escaping (inout Model, Message) -> [Command<Message>],
         view: @escaping (Model) -> ViewController<Message>) {

        self.model = initial
        self.updateState = update
        self.computeView = view

        viewController.view = OView()
        
        strongReferences = view(model).render(callback: self.asyncSend, change: &viewController)
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
        command.run(Context(viewController: viewController, send: self.asyncSend))
    }

    func refresh() {
        //subscriptionManager.update(subscriptions: fetchSubscriptions(model))
        strongReferences = computeView(model).render(callback: self.asyncSend, change: &viewController)
    }
}
