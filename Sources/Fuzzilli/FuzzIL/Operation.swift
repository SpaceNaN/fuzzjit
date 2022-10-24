// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// An operation in the FuzzIL language.
///
/// Operations can be shared between different programs since they do not contain any
/// program specific data.
public class Operation {
    /// The attributes of this operation.
    let attributes: Attributes

    /// The context in which the operation can exist
    let requiredContext: Context

    /// The context that this operations opens
    let contextOpened: Context

    /// The number of input variables to this operation.
    private let numInputs_: UInt16
    var numInputs: Int {
        return Int(numInputs_)
    }

    /// The number of newly created variables in the current scope.
    private let numOutputs_: UInt16
    var numOutputs: Int {
        return Int(numOutputs_)
    }

    /// The number of newly created variables in the inner scope if one is created.
    private let numInnerOutputs_: UInt16
    var numInnerOutputs: Int {
        return Int(numInnerOutputs_)
    }

    /// The index of the first variadic input.
    private let firstVariadicInput_: UInt16
    var firstVariadicInput: Int {
        assert(attributes.contains(.isVariadic))
        return Int(firstVariadicInput_)
    }

    init(numInputs: Int, numOutputs: Int, numInnerOutputs: Int = 0, firstVariadicInput: Int = -1, attributes: Attributes = [], requiredContext: Context = .javascript, contextOpened: Context = .empty) {
        assert(attributes.contains(.isVariadic) == (firstVariadicInput != -1))
        assert(firstVariadicInput == -1 || firstVariadicInput <= numInputs)
        self.attributes = attributes
        self.requiredContext = requiredContext
        self.contextOpened = contextOpened
        self.numInputs_ = UInt16(numInputs)
        self.numOutputs_ = UInt16(numOutputs)
        self.numInnerOutputs_ = UInt16(numInnerOutputs)
        self.firstVariadicInput_ = attributes.contains(.isVariadic) ? UInt16(firstVariadicInput) : 0
    }

    /// Possible attributes of an operation.
    struct Attributes: OptionSet {
        let rawValue: UInt16

        // The operation is pure, i.e. returns the same output given
        // the same inputs (in practice, for simplicity we only mark
        // operations without inputs as pure) and doesn't have any
        // side-effects. As such, two identical pure operations can
        // always be replaced with just one.
        static let isPure             = Attributes(rawValue: 1 << 0)
        // This operation can be mutated in a meaningful way.
        // The rough rule of thumbs is that every Operation subclass that has additional members should be mutable.
        // Example include integer values (LoadInteger), string values (LoadProperty and CallMethod), or Arrays (CallFunctionWithSpread).
        // However, if mutations are not interesting or meaningful, or if the value space is very small (e.g. a boolean), it may make sense
        // to not make the operation mutable to not degrade mutation performance (by causing many meaningless mutations).
        // An example of such an exception is the isStrict member of function definitions: the value space is two (true or false)
        // and mutating the isStrict member is probably not very interesting compared to mutations on other operations.
        static let isMutable          = Attributes(rawValue: 1 << 1)
        // The operation performs a subroutine call.
        static let isCall             = Attributes(rawValue: 1 << 2)
        // The operation is the start of a block.
        static let isBlockStart       = Attributes(rawValue: 1 << 3)
        // The operation is the end of a block.
        static let isBlockEnd         = Attributes(rawValue: 1 << 4)
        // The block opened or closed by this operation is some form of loop.
        static let isLoop             = Attributes(rawValue: 1 << 5)
        // The operation is used for internal purposes and should not
        // be visible to the user (e.g. appear in emitted samples).
        static let isInternal         = Attributes(rawValue: 1 << 7)
        // The operation behaves like an (unconditional) jump. Any
        // code until the next block end is therefore dead code.
        static let isJump             = Attributes(rawValue: 1 << 8)
        // The operation can take a variable number of inputs.
        // The firstVariadicInput contains the index of the first variadic input.
        static let isVariadic          = Attributes(rawValue: 1 << 9)
        // The operation propagates the surrounding context.
        static let propagatesSurroundingContext = Attributes(rawValue: 1 << 10)
        // The instruction resumes the context from before its parent context.
        // This is useful for example for BeginSwitch and BeginSwitchCase.
        static let resumesSurroundingContext = Attributes(rawValue: 1 << 11)
    }
}

class Nop: Operation {
    // NOPs can have "pseudo" outputs. These should not be used by other instructions
    // and they should not be present in the lifted code, i.e. a NOP should just be
    // ignored during lifting.
    // These pseudo outputs are used to simplify some algorithms, e.g. minimization,
    // which needs to replace instructions with NOPs while keeping the variable numbers
    // contiguous. They can also serve as placeholders for future instructions.
    init(numOutputs: Int = 0) {
        // We need an empty context here as .script is default and we want to be able to minimize in every context.
        super.init(numInputs: 0, numOutputs: numOutputs, requiredContext: [])
    }
}


// Expose the name of an operation as instance and class variable
extension Operation {
    var name: String {
        return String(describing: type(of: self))
    }

    class var name: String {
        return String(describing: self)
    }
}
