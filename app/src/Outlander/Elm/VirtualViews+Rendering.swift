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

    func removeDelegate() {
        self.delegate = nil
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
            let b = NSButton(frame: NSRect(x: 0, y: 0, width: 100, height: 25))
            render(button, into: b)
            return b

        case let ._vitalBarItem(item):
            let b = VitalBarItemView()
            render(item, into: b)
            return b

        case let ._textField(textField):
            let result = NSTextField(frame: NSRect(x: 0, y: 100, width: 100, height: 30))
            render(textField, into: result)
            return result

        case let ._textView(textView):
            let result = ScrollableTextView(frame: NSRect(x: 0, y: 0, width: 500, height: 500))
            render(textView, into: result)
            return result

        case let ._stackView(stackView):
            let views = stackView.views.map { render(view: $0) }
            let result = NSStackView()
            render(stackView, into: result)

            for view in views {
//                result.append(view)
                result.addArrangedSubview(view)
            }

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
        b.setButtonType(.momentaryLight)
        b.bezelStyle = .roundRect
    }

    private mutating func render(_ textField: TextField<Message>, into f: NSTextField) {
        f.removeDelegate()

        f.stringValue = textField.text

        if let action = textField.onChange {
            let cb = self.callback
            let target = f.onTextChanged { value in
                cb(action(value))
            }
            strongReferences.append(target)
        }
    }

    private mutating func render(_ textView: TextView<Message>, into f: ScrollableTextView) {
        let attributes = [
            NSAttributedString.Key.foregroundColor : NSColor.white
        ]
        let str = NSAttributedString(string: textView.text, attributes: attributes)
        f.textView.textStorage?.append(str)
        f.textView.scrollToEndOfDocument(nil)
    }

    private mutating func render(_ vitalBarItem: VitalBarItem, into bar: VitalBarItemView) {
        bar.text = vitalBarItem.text
        bar.value = vitalBarItem.value
        bar.backgroundColor = vitalBarItem.backgroundColor
    }

    // this does *not* render the children
    private func render(_ stackView: StackView<Message>, into result: NSStackView) {
        result.distribution = stackView.distribution
        result.alignment = stackView.alignment
        result.orientation = stackView.axis == .vertical
            ? NSUserInterfaceLayoutOrientation.vertical
            : NSUserInterfaceLayoutOrientation.horizontal
        result.spacing = CGFloat(stackView.spacing)
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

        case let ._textView(textView):
            guard let result = existing as? ScrollableTextView else {
                removeChildViewController(for: existing)
                return render(view: view)
            }
            render(textView, into: result)
            return result

        case let ._vitalBarItem(item):
            guard let result = existing as? VitalBarItemView else {
                removeChildViewController(for: existing)
                return render(view: view)
            }
            render(item, into: result)
            return result

        case let ._stackView(stackView):
            guard let result = existing as? NSStackView else {
                removeChildViewController(for: existing)
                return render(view: view)
            }

            for (index, existingSubview) in result.subviews.enumerated() {

                guard index < stackView.views.count else {
                    result.removeArrangedSubview(existingSubview)
                    existingSubview.removeFromSuperview()
                    continue
                }

                let sub = stackView.views[index]
                let new = update(view: sub, into: existingSubview)
                if new !== existingSubview {
                    result.removeArrangedSubview(existingSubview)
                    existingSubview.removeFromSuperview()
                    result.insertArrangedSubview(new, at: Int(index))
                }

                new.translatesAutoresizingMaskIntoConstraints = false
            }
            
            render(stackView, into: result)
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
                let newView = r.update(view: view, into: change.view.subviews.first ?? OView())

                if change.view.subviews.count == 0 || newView !== change.view.subviews[0] {
                    if change.view.subviews.count != 0 {
                        change.view.subviews[0].removeFromSuperview()
                    }
                    change.view.addSubview(newView)
                    newView.translatesAutoresizingMaskIntoConstraints = false

                    if (useLayoutGuide) {
                    }

//                    change.view.anchor.apply(to: [newView])

                    change.view.addConstraints([
                        newView.topAnchor.constraint(equalTo: change.view.topAnchor),
                        newView.bottomAnchor.constraint(equalTo: change.view.bottomAnchor),
                        newView.leadingAnchor.constraint(equalTo: change.view.leadingAnchor),
                        newView.trailingAnchor.constraint(equalTo: change.view.trailingAnchor)
                    ])
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
