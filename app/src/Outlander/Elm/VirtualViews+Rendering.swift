//
//  VirtualViews+Rendering.swift
//  Outlander
//
//  Created by Joseph McBride on 7/21/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation
import Cocoa

struct StrongReferences {
    private var handlers: [Any] = []
    
    init() {}
    
    mutating func append(_ obj: Any) {
        handlers.append(obj)
    }
    
    mutating func append(contentsOf other: [Any]) {
        handlers.append(contentsOf: other)
    }
}

class TargetAction: NSObject { // todo: removeTarget?
    var handle: () -> ()

    init(_ handle: @escaping () -> ()) {
        self.handle = handle
    }

    @objc func performAction(sender: NSButton) {
        handle()
    }
}

class TextFieldDelegate : NSObject, NSTextFieldDelegate {
    
    var handle: (String) -> ()
    
    init(_ handle: @escaping (String) -> ()) {
        self.handle = handle
    }

    func controlTextDidChange(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else {
            return
        }

        self.handle(textField.stringValue)
    }
}

extension NSButton {
    func onClick(_ onClick: @escaping () -> ()) -> TargetAction {
        let ta = TargetAction(onClick)
        self.addTarget(ta, action: #selector(TargetAction.performAction(sender:)))
        return ta
    }

    func addTarget(_ target: AnyObject, action: Selector) {
        self.target = target
        self.action = action
    }

    func removeTarget(_ target: AnyObject?, action: Selector?) {
        self.target = target
        self.action = action
    }
}

extension NSTextField {
    func onTextChanged(_ onTextChanged: @escaping (String) -> ()) -> TextFieldDelegate {
        let target = TextFieldDelegate(onTextChanged)
        self.delegate = target
        return target
    }
}

struct Renderer<Message> {
    var strongReferences = StrongReferences()

    private let callback: (Message) -> ()
    private let container: NSViewController

    var addedChildViewControllers: [NSViewController] = []
    var removedChildViewControllers: [NSViewController] = []

    init(callback: @escaping (Message) -> (), container: NSViewController) {
        self.callback = callback
        self.container = container
    }
    
    mutating func render(view: View<Message>) -> NSView {
        switch view {
        case let ._button(button):
            let b = NSButton(frame: NSMakeRect(0, 0, 100, 100))
            render(button, into: b)
            return b

        case let ._textField(textField):
            let result = NSTextField()
            render(textField, into: result)
            return result

        case ._customLayout(let views):
            let container = OView()
            container.translatesAutoresizingMaskIntoConstraints = false
            for (v,c) in views {
                let sub = render(view: v)
                container.addSubview(sub)
                sub.translatesAutoresizingMaskIntoConstraints = false
                container.addConstraints(c.map { $0(sub, container) })
            }
            return container
        }
    }
    
    private mutating func render(_ button: Button<Message>, into b: NSButton) {
        b.removeTarget(nil, action: nil)

        if let action = button.onClick {
            let cb = self.callback
            let target = TargetAction { cb(action) }
            strongReferences.append(target)
            b.addTarget(target, action: #selector(TargetAction.performAction(sender:)))
        }

        b.title = button.text

//        b.backgroundColor = .orangeTint
//        b.setTitleColor(.white, for: .normal)
//        b.titleLabel?.font = .preferredFont(forTextStyle: .headline)
//        b.layer.cornerRadius = 4
    }

    private mutating func render(_ textField: TextField<Message>, into result: NSTextField) {
    }
    
    mutating func removeChildViewController(for view: NSView) {
        guard let i = container.children.firstIndex(where: { $0.view == view }) else { return }
        
        let child = container.children[i]
        removedChildViewControllers.append(child)
    }

    mutating func update(view: View<Message>, into existing: NSView) -> NSView {
        switch view {
        case let ._button(button):
            guard let b = existing as? NSButton else {
                removeChildViewController(for: existing)
                return render(view: view)
            }
            render(button, into: b)
            return b
        
        case let ._textField(textField):
            guard let result = existing as? NSTextField else {
                removeChildViewController(for: existing)
                return render(view: view)
            }
            render(textField, into: result)
            return result

        case ._customLayout(_):
            fatalError()
        }
    }
}

extension ViewController {
    func render(callback: @escaping (Message) -> (), change: inout NSViewController) -> StrongReferences {
        switch self {
            case let ._viewController(view, useLayoutGuide):
                if type(of: change) != NSViewController.self {
                    change = NSViewController()
                }

                var r = Renderer(callback: callback, container: change)
//                change.view.backgroundColor = .white
                let newView = r.update(view: view, into: change.view.subviews.first ?? OView())

                if change.view.subviews.count == 0 || newView !== change.view.subviews[0] {
                    if change.view.subviews.count != 0 {
                        change.view.subviews[0].removeFromSuperview()
                    }
                    change.view.addSubview(newView)
//                    newView.translatesAutoresizingMaskIntoConstraints = false
                    
                    if (useLayoutGuide) {
                    }
                    
//                    let verticalAnchors: Anchors
//                    let horizontalAnchors: Anchors = useLayoutGuide ? change.view.layoutMarginsGuide : change.view
                    
//                    change.view.addConstraints([
//                        newView.topAnchor.constraint(equalTo: change.view)
//                    ])
                }

                for removed in r.removedChildViewControllers {
                    removed.removeFromParent()
                }
                for added in r.addedChildViewControllers {
                    change.addChild(added)
                }
                
                return r.strongReferences
        }
    }
}
