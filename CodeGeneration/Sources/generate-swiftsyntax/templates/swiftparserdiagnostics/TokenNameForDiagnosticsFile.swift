//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax
import SwiftSyntaxBuilder
import SyntaxSupport
import Utils

let tokenNameForDiagnosticFile = SourceFileSyntax(leadingTrivia: copyrightHeader) {
  DeclSyntax("@_spi(RawSyntax) import SwiftSyntax")

  try! ExtensionDeclSyntax("extension TokenKind") {
    try! VariableDeclSyntax("var nameForDiagnostics: String") {
      try! SwitchExprSyntax("switch self") {
        SwitchCaseSyntax("case .eof:") {
          StmtSyntax(#"return "end of file""#)
        }

        for token in SYNTAX_TOKENS where token.swiftKind != "keyword" {
          SwitchCaseSyntax("case .\(raw: token.swiftKind):") {
            StmtSyntax("return #\"\(raw: token.nameForDiagnostics)\"#")
          }
        }
        SwitchCaseSyntax("case .keyword(let keyword):") {
          StmtSyntax("return String(syntaxText: keyword.defaultText)")
        }
      }
    }
  }
}
