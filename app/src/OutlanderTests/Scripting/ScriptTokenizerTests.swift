//
//  ScriptTokenizerTests.swift
//  Outlander
//
//  Created by Joe McBride on 2/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import XCTest

class ScriptTokenizerTests: XCTestCase {
    func test_comments() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("# a comment")

        switch token {
        case let .comment(text):
            XCTAssertEqual(text, "# a comment")
        default:
            XCTFail("wrong token value")
        }
    }

    func test_echo() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("echo hello world")

        switch token {
        case let .echo(text):
            XCTAssertEqual(text, "hello world")
        default:
            XCTFail("wrong token value")
        }
    }

    func test_exit() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("exit")

        switch token {
        case .exit:
            XCTAssertTrue(true)
        default:
            XCTFail("wrong token value")
        }
    }

    func test_goto() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("goto label")

        switch token {
        case let .goto(label, args):
            XCTAssertEqual(label, "label")
            XCTAssertEqual(args, "")
        default:
            XCTFail("wrong token value")
        }
    }

    func test_tokenizes_goto_with_args() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("goto label arg1 arg2")

        switch token {
        case let .goto(label, args):
            XCTAssertEqual(label, "label")
            XCTAssertEqual(args, "arg1 arg2")
        default:
            XCTFail("wrong token value")
        }
    }

    func test_labels() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("mylabel:")

        switch token {
        case let .label(label):
            XCTAssertEqual(label, "mylabel")
        default:
            XCTFail("wrong token value")
        }
    }

    func test_ignores_text_after_label() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("mylabel: something something")

        switch token {
        case let .label(label):
            XCTAssertEqual(label, "mylabel")
        default:
            XCTFail("wrong token value")
        }
    }

    func test_match() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("match one two")

        switch token {
        case let .match(label, value):
            XCTAssertEqual(label, "one")
            XCTAssertEqual(value, "two")
        default:
            XCTFail("wrong token value")
        }
    }

    func test_matchre() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("matchre one two")

        switch token {
        case let .matchre(label, value):
            XCTAssertEqual(label, "one")
            XCTAssertEqual(value, "two")
        default:
            XCTFail("wrong token value: \(String(describing: token))")
        }
    }

    func test_put() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("put hello friends")

        switch token {
        case let .put(put):
            XCTAssertEqual(put, "hello friends")
        default:
            XCTFail("wrong token value")
        }
    }

    func test_put_with_commands() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("put #echo a message")

        switch token {
        case let .put(put):
            XCTAssertEqual(put, "#echo a message")
        default:
            XCTFail("wrong token value")
        }
    }

    func test_waitfor() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("waitfor abcd")

        switch token {
        case let .waitfor(msg):
            XCTAssertEqual(msg, "abcd")
        default:
            XCTFail("wrong token value")
        }
    }

    func test_action() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("action put hello when Sorry")

        switch token {
        case let .action(className, action, trigger):
            XCTAssertEqual(className, "")
            XCTAssertEqual(action, "put hello")
            XCTAssertEqual(trigger, "Sorry")
        default:
            XCTFail("wrong token value")
        }
    }

    func test_action_with_class() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("action (mapper) put hello when Sorry")

        switch token {
        case let .action(className, action, trigger):
            XCTAssertEqual(className, "mapper")
            XCTAssertEqual(action, "put hello")
            XCTAssertEqual(trigger, "Sorry")
        default:
            XCTFail("wrong token value")
        }
    }

    func test_action_toggle() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("action (mapper) on")

        switch token {
        case let .actionToggle(className, toggle):
            XCTAssertEqual(className, "mapper")
            XCTAssertEqual(toggle, "on")
        default:
            XCTFail("wrong token value")
        }
    }

    func test_action_invalid() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("action whoops")
        XCTAssertNil(token)
    }
    
    func test_action_eval() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("action put hello when eval 1==1")

        switch token {
        case let .actionEval(className, action, expression):
            XCTAssertEqual(className, "")
            XCTAssertEqual(action, "put hello")
            
            switch expression {
            case let .value(txt):
                XCTAssertEqual(txt, "1==1")
            default:
                XCTFail("wrong expression value")
            }
        default:
            XCTFail("wrong token value")
        }
    }
    
    func test_action_eval_with_class() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("action (myclass) put hello when eval $bleeding = 1")

        switch token {
        case let .actionEval(className, action, expression):
            XCTAssertEqual(className, "myclass")
            XCTAssertEqual(action, "put hello")
            
            switch expression {
            case let .value(txt):
                XCTAssertEqual(txt, "$bleeding = 1")
            default:
                XCTFail("wrong expression value")
            }
        default:
            XCTFail("wrong token value")
        }
    }

    func test_if_arg_0_then() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("if_0 then echo hello")

        switch token {
        case let .ifArgSingle(number, command):
            XCTAssertEqual(number, 0)

            switch command {
            case let .echo(text):
                XCTAssertEqual(text, "hello")
            default:
                XCTFail("wrong command value, found \(String(describing: command.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_if_arg_0_no_then() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("if_0 echo hello")

        switch token {
        case let .ifArgSingle(number, command):
            XCTAssertEqual(number, 0)

            switch command {
            case let .echo(text):
                XCTAssertEqual(text, "hello")
            default:
                XCTFail("wrong command value, found \(String(describing: command.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_if_arg_0_brace() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("if_0 { ")

        switch token {
        case let .ifArg(number):
            XCTAssertEqual(number, 0)
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_if_arg_0_brace_with_then() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("if_0 then { ")

        switch token {
        case let .ifArg(number):
            XCTAssertEqual(number, 0)
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_if_arg_0_needs_brace() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("if_0  ")

        switch token {
        case let .ifArgNeedsBrace(number):
            XCTAssertEqual(number, 0)
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_if_arg_0_needs_brace_with_then() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("if_0 then ")

        switch token {
        case let .ifArgNeedsBrace(number):
            XCTAssertEqual(number, 0)
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_if_single() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("if 1==1 then echo hello ")

        switch token {
        case let .ifSingle(expression, token):
            switch expression {
            case let .value(text):
                XCTAssertEqual(text, "1==1")

                switch token {
                case let .echo(text):
                    XCTAssertEqual(text, "hello")
                default:
                    XCTFail("wrong value, found \(String(describing: token.description))")
                }
            default:
                XCTFail("wrong expression value, found \(String(describing: expression.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_if_single_parens_no_spaces() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("if(1==1) then echo hello ")

        switch token {
        case let .ifSingle(expression, token):
            switch expression {
            case let .value(text):
                XCTAssertEqual(text, "(1==1)")

                switch token {
                case let .echo(text):
                    XCTAssertEqual(text, "hello")
                default:
                    XCTFail("wrong value, found \(String(describing: token.description))")
                }
            default:
                XCTFail("wrong expression value, found \(String(describing: expression.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_if_with_brace() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("if 1==1 {")

        switch token {
        case let .if(expression):
            switch expression {
            case let .value(text):
                XCTAssertEqual(text, "1==1")
            default:
                XCTFail("wrong expression value, found \(String(describing: expression.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_if_with_brace_and_then() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("if 1==1 then {")

        switch token {
        case let .if(expression):
            switch expression {
            case let .value(text):
                XCTAssertEqual(text, "1==1")
            default:
                XCTFail("wrong expression value, found \(String(describing: expression.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_if_with_brace_and_then_scenario_2() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("if $powerwalk == 1 then {")

        switch token {
        case let .if(expression):
            switch expression {
            case let .value(text):
                XCTAssertEqual(text, "$powerwalk == 1")
            default:
                XCTFail("wrong expression value, found \(String(describing: expression.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_if_with_brace_parens_no_spaces() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("if(1==1){")

        switch token {
        case let .if(expression):
            switch expression {
            case let .value(text):
                XCTAssertEqual(text, "(1==1)")
            default:
                XCTFail("wrong expression value, found \(String(describing: expression.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_if_without_brace() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("if 1==1")

        switch token {
        case let .ifNeedsBrace(expression):
            switch expression {
            case let .value(text):
                XCTAssertEqual(text, "1==1")
            default:
                XCTFail("wrong expression value, found \(String(describing: expression.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_if_without_brace_and_then() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("if 1==1 then")

        switch token {
        case let .ifNeedsBrace(expression):
            switch expression {
            case let .value(text):
                XCTAssertEqual(text, "1==1")
            default:
                XCTFail("wrong expression value, found \(String(describing: expression.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_else_if_single_line() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("else if 1==1 then echo hello")

        switch token {
        case let .elseIfSingle(expression, token):
            switch expression {
            case let .value(text):
                XCTAssertEqual(text, "1==1")

                switch token {
                case let .echo(text):
                    XCTAssertEqual(text, "hello")
                default:
                    XCTFail("wrong value, found \(String(describing: token.description))")
                }
            default:
                XCTFail("wrong expression value, found \(String(describing: expression.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_else_if_single_line_with_brackets() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("else if 1==1 { echo hello }")

        switch token {
        case let .elseIfSingle(expression, token):
            switch expression {
            case let .value(text):
                XCTAssertEqual(text, "1==1")

                switch token {
                case let .echo(text):
                    XCTAssertEqual(text, "hello")
                default:
                    XCTFail("wrong value, found \(String(describing: token.description))")
                }
            default:
                XCTFail("wrong expression value, found \(String(describing: expression.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_else_if_single_line_with_brackets_no_spaces() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("else if 1==1 {echo hello}")

        switch token {
        case let .elseIfSingle(expression, token):
            switch expression {
            case let .value(text):
                XCTAssertEqual(text, "1==1")

                switch token {
                case let .echo(text):
                    XCTAssertEqual(text, "hello")
                default:
                    XCTFail("wrong value, found \(String(describing: token.description))")
                }
            default:
                XCTFail("wrong expression value, found \(String(describing: expression.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_else_if_with_brace() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("else if 1==1 {")

        switch token {
        case let .elseIf(expression):
            switch expression {
            case let .value(text):
                XCTAssertEqual(text, "1==1")
            default:
                XCTFail("wrong expression value, found \(String(describing: expression.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_else_if_with_brace_and_then() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("else if 1==1 then {")

        switch token {
        case let .elseIf(expression):
            switch expression {
            case let .value(text):
                XCTAssertEqual(text, "1==1")
            default:
                XCTFail("wrong expression value, found \(String(describing: expression.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_else_if_without_brace() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("else if 1==1")

        switch token {
        case let .elseIfNeedsBrace(expression):
            switch expression {
            case let .value(text):
                XCTAssertEqual(text, "1==1")
            default:
                XCTFail("wrong expression value, found \(String(describing: expression.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_else_if_without_brace_and_then() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("else if 1==1 then")

        switch token {
        case let .elseIfNeedsBrace(expression):
            switch expression {
            case let .value(text):
                XCTAssertEqual(text, "1==1")
            default:
                XCTFail("wrong expression value, found \(String(describing: expression.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_else_if_with_leading_brace_without_end_brace_and_then() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("} else if 1==1 then")

        switch token {
        case let .elseIfNeedsBrace(expression):
            switch expression {
            case let .value(text):
                XCTAssertEqual(text, "1==1")
            default:
                XCTFail("wrong expression value, found \(String(describing: expression.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_else_if_with_leading_brace_with_end_brace_and_then() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("} else if 1==1 then {")

        switch token {
        case let .elseIf(expression):
            switch expression {
            case let .value(text):
                XCTAssertEqual(text, "1==1")
            default:
                XCTFail("wrong expression value, found \(String(describing: expression.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_else_with_brace() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("else {")

        switch token {
        case .else:
            XCTAssertTrue(true)
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_else_with_brace_and_then() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("else then {")

        switch token {
        case .else:
            XCTAssertTrue(true)
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_else_without_brace() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("else")

        switch token {
        case .elseNeedsBrace:
            XCTAssertTrue(true)
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_else_without_brace_and_then() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("else then")

        switch token {
        case .elseNeedsBrace:
            XCTAssertTrue(true)
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_else_single_line_with_then() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("else then echo hello")

        switch token {
        case let .elseSingle(token):
            switch token {
            case let .echo(text):
                XCTAssertEqual(text, "hello")
            default:
                XCTFail("wrong value, found \(String(describing: token.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_else_single_line_without_then() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("else echo hello")

        switch token {
        case let .elseSingle(token):
            switch token {
            case let .echo(text):
                XCTAssertEqual(text, "hello")
            default:
                XCTFail("wrong value, found \(String(describing: token.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }

    func test_else_single_line_without_then_with_brackets() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("else { echo hello }")

        switch token {
        case let .elseSingle(token):
            switch token {
            case let .echo(text):
                XCTAssertEqual(text, "hello")
            default:
                XCTFail("wrong value, found \(String(describing: token.description))")
            }
        default:
            XCTFail("wrong token value, found \(String(describing: token?.description))")
        }
    }
}
