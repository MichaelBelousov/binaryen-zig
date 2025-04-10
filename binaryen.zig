const std = @import("std");
const byn = @cImport({
    @cInclude("stdlib.h");
    @cInclude("binaryen-c.h");
});

// TODO: don't export
pub const c = byn;

//pub const intrinsics = @import("./wasm_intrinsics.zig");
pub export const _wasm_intrinsics_wat = @embedFile("binaryen-wat-intrinsics").*;
pub usingnamespace @import("./cxa_stubs.zig");

pub const Flags = enum(u32) {
    minimal = 0,
    web = 1 << 0,
    globally = 1 << 1,
    quiet = 1 << 2,
    closed_world = 1 << 3,
    _,

    pub const default = .globally;
};

pub extern fn _binaryenCloneFunction(from: c.BinaryenModuleRef, to: c.BinaryenModuleRef, from_name: [*:0]const u8, to_name: [*:0]const u8) bool;
pub extern fn _BinaryenExpressionPrintStderr(expr: c.BinaryenExpressionRef) void;
pub extern fn _BinaryenModulePrintStderr(module: c.BinaryenModuleRef) void;
/// NOTE: default is globally
pub extern fn _BinaryenModuleValidateWithOpts(module: c.BinaryenModuleRef, flags: Flags) bool;

pub fn freeEmit(buf: []u8) void {
    byn.free(buf.ptr);
}

// NOTE: since this appears to be a bit mask, might be better to make this not an enum
pub const Features = enum(byn.BinaryenFeatures) {
    _,

    pub fn set(features: []const Features) Features {
        var initial: byn.BinaryenFeatures = 0;
        for (features) |feature| {
            initial |= @intFromEnum(feature);
        }
        return @enumFromInt(initial);
    }

    // NOTE: would be nice to force inline these...
    pub fn MVP() Features {
        return @enumFromInt(byn.BinaryenFeatureMVP());
    }
    pub fn Atomics() Features {
        return @enumFromInt(byn.BinaryenFeatureAtomics());
    }
    pub fn BulkMemory() Features {
        return @enumFromInt(byn.BinaryenFeatureBulkMemory());
    }
    pub fn MutableGlobals() Features {
        return @enumFromInt(byn.BinaryenFeatureMutableGlobals());
    }
    pub fn NontrappingFPToInt() Features {
        return @enumFromInt(byn.BinaryenFeatureNontrappingFPToInt());
    }
    pub fn SignExt() Features {
        return @enumFromInt(byn.BinaryenFeatureSignExt());
    }
    pub fn SIMD128() Features {
        return @enumFromInt(byn.BinaryenFeatureSIMD128());
    }
    pub fn ExceptionHandling() Features {
        return @enumFromInt(byn.BinaryenFeatureExceptionHandling());
    }
    pub fn TailCall() Features {
        return @enumFromInt(byn.BinaryenFeatureTailCall());
    }
    pub fn ReferenceTypes() Features {
        return @enumFromInt(byn.BinaryenFeatureReferenceTypes());
    }
    pub fn Multivalue() Features {
        return @enumFromInt(byn.BinaryenFeatureMultivalue());
    }
    pub fn GC() Features {
        return @enumFromInt(byn.BinaryenFeatureGC());
    }
    pub fn Memory64() Features {
        return @enumFromInt(byn.BinaryenFeatureMemory64());
    }
    pub fn RelaxedSIMD() Features {
        return @enumFromInt(byn.BinaryenFeatureRelaxedSIMD());
    }
    pub fn ExtendedConst() Features {
        return @enumFromInt(byn.BinaryenFeatureExtendedConst());
    }
    pub fn Strings() Features {
        return @enumFromInt(byn.BinaryenFeatureStrings());
    }
    pub fn MultiMemory() Features {
        return @enumFromInt(byn.BinaryenFeatureMultiMemory());
    }
    pub fn All() Features {
        return @enumFromInt(byn.BinaryenFeatureAll());
    }
};

pub const Module = opaque {
    pub fn init() *Module {
        const mod = byn.BinaryenModuleCreate();
        return @ptrCast(mod);
    }

    pub fn deinit(self: *Module) void {
        byn.BinaryenModuleDispose(self.c());
    }

    // TODO: remove for my purposes?
    pub fn parseText(wat: [*:0]const u8) *Module {
        const mod = byn.BinaryenModuleParse(wat);
        return @ptrCast(mod);
    }

    // TODO: remove for my purposes?
    pub fn readBinary(wasm: []const u8) *Module {
        const mod = byn.BinaryenModuleRead(@constCast(wasm.ptr), wasm.len);
        return @ptrCast(mod);
    }

    pub fn getFeatures(self: *@This()) Features {
        return @enumFromInt(byn.BinaryenModuleGetFeatures(self.c()));
    }

    pub fn setFeatures(self: *@This(), features: Features) void {
        return byn.BinaryenModuleSetFeatures(self.c(), @intFromEnum(features));
    }

    pub fn emitText(self: *Module) [:0]u8 {
        const buf = byn.BinaryenModuleAllocateAndWriteText(self.c());
        return std.mem.span(buf);
    }
    pub fn emitBinary(self: *Module, source_map_url: ?[*:0]const u8) EmitBinaryResult {
        const result = byn.BinaryenModuleAllocateAndWrite(self.c(), source_map_url);
        const binary_ptr: [*]u8 = @ptrCast(result.binary);
        return .{
            .binary = binary_ptr[0..result.binaryBytes],
            .source_map = std.mem.span(result.sourceMap),
        };
    }
    pub const EmitBinaryResult = struct { binary: []u8, source_map: [:0]u8 };

    pub fn addFunction(
        self: *Module,
        name: [:0]const u8,
        params: Type,
        results: Type,
        var_types: []const Type,
        body: *Expression,
    ) ?*Function {
        const func = byn.BinaryenAddFunction(
            self.c(),
            name.ptr,
            @intFromEnum(params),
            @intFromEnum(results),
            @constCast(@ptrCast(var_types.ptr)),
            @intCast(var_types.len),
            body.c(),
        );
        return @ptrCast(func);
    }

    pub inline fn c(self: *Module) byn.BinaryenModuleRef {
        return @ptrCast(self);
    }
};

pub const Index = byn.BinaryenIndex;

pub const Expression = opaque {
    pub inline fn c(self: *Expression) byn.BinaryenExpressionRef {
        return @ptrCast(self);
    }

    pub const Op = enum(byn.BinaryenOp) {
        _,

        pub inline fn c(self: Op) byn.BinaryenOp {
            return @intFromEnum(self);
        }

        // TODO: mark everything as inline

        pub fn addInt32() Op {
            return @enumFromInt(byn.BinaryenAddInt32());
        }
        pub fn addInt64() Op {
            return @enumFromInt(byn.BinaryenAddInt64());
        }
        pub fn addFloat32() Op {
            return @enumFromInt(byn.BinaryenAddFloat32());
        }
        pub fn addFloat64() Op {
            return @enumFromInt(byn.BinaryenAddFloat64());
        }
        pub fn @"if"() Op {
            return @enumFromInt(byn.BinaryenIf());
        }
        pub fn nop() Op {
            return @enumFromInt(byn.BinaryenNop());
        }
        pub fn localSet() Op {
            return @enumFromInt(byn.BinaryenLocalSet());
        }
        pub fn popcntInt32() Op {
            return @enumFromInt(byn.BinaryenPopcntInt32());
        }
        pub fn popcntInt64() Op {
            return @enumFromInt(byn.BinaryenPopcntInt64());
        }
        pub fn pop() Op {
            return @enumFromInt(byn.BinaryenPop());
        }
        pub fn subInt32() Op {
            return @enumFromInt(byn.BinaryenSubInt32());
        }
        pub fn subInt64() Op {
            return @enumFromInt(byn.BinaryenSubInt64());
        }
        pub fn subFloat32() Op {
            return @enumFromInt(byn.BinaryenSubFloat32());
        }
        pub fn subFloat64() Op {
            return @enumFromInt(byn.BinaryenSubFloat64());
        }
        pub fn divSInt32() Op {
            return @enumFromInt(byn.BinaryenDivSInt32());
        }
        pub fn divUInt32() Op {
            return @enumFromInt(byn.BinaryenDivUInt32());
        }
        pub fn divSInt64() Op {
            return @enumFromInt(byn.BinaryenDivSInt64());
        }
        pub fn divUInt64() Op {
            return @enumFromInt(byn.BinaryenDivUInt64());
        }
        pub fn divFloat32() Op {
            return @enumFromInt(byn.BinaryenDivFloat32());
        }
        pub fn divFloat64() Op {
            return @enumFromInt(byn.BinaryenDivFloat64());
        }
        pub fn mulInt32() Op {
            return @enumFromInt(byn.BinaryenMulInt32());
        }
        pub fn mulInt64() Op {
            return @enumFromInt(byn.BinaryenMulInt64());
        }
        pub fn mulFloat64() Op {
            return @enumFromInt(byn.BinaryenMulFloat64());
        }
        pub fn mulFloat32() Op {
            return @enumFromInt(byn.BinaryenMulFloat32());
        }
        pub fn maxFloat32() Op {
            return @enumFromInt(byn.BinaryenMaxFloat32());
        }
        pub fn maxFloat64() Op {
            return @enumFromInt(byn.BinaryenMaxFloat64());
        }

        pub fn extendS8Int32() Op {
            return @enumFromInt(byn.BinaryenExtendS8Int32());
        }
        pub fn extendS16Int32() Op {
            return @enumFromInt(byn.BinaryenExtendS16Int32());
        }
        pub fn extendS8Int64() Op {
            return @enumFromInt(byn.BinaryenExtendS8Int64());
        }
        pub fn extendS16Int64() Op {
            return @enumFromInt(byn.BinaryenExtendS16Int64());
        }
        pub fn extendS32Int64() Op {
            return @enumFromInt(byn.BinaryenExtendS32Int64());
        }
        pub fn clzInt32() Op {
            return @enumFromInt(byn.BinaryenClzInt32());
        }
        pub fn ctzInt32() Op {
            return @enumFromInt(byn.BinaryenCtzInt32());
        }
        pub fn negFloat32() Op {
            return @enumFromInt(byn.BinaryenNegFloat32());
        }
        pub fn absFloat32() Op {
            return @enumFromInt(byn.BinaryenAbsFloat32());
        }
        pub fn ceilFloat32() Op {
            return @enumFromInt(byn.BinaryenCeilFloat32());
        }
        pub fn floorFloat32() Op {
            return @enumFromInt(byn.BinaryenFloorFloat32());
        }
        pub fn truncFloat32() Op {
            return @enumFromInt(byn.BinaryenTruncFloat32());
        }
        pub fn nearestFloat32() Op {
            return @enumFromInt(byn.BinaryenNearestFloat32());
        }
        pub fn sqrtFloat32() Op {
            return @enumFromInt(byn.BinaryenSqrtFloat32());
        }
        pub fn eqZInt32() Op {
            return @enumFromInt(byn.BinaryenEqZInt32());
        }
        pub fn clzInt64() Op {
            return @enumFromInt(byn.BinaryenClzInt64());
        }
        pub fn ctzInt64() Op {
            return @enumFromInt(byn.BinaryenCtzInt64());
        }
        pub fn negFloat64() Op {
            return @enumFromInt(byn.BinaryenNegFloat64());
        }
        pub fn absFloat64() Op {
            return @enumFromInt(byn.BinaryenAbsFloat64());
        }
        pub fn ceilFloat64() Op {
            return @enumFromInt(byn.BinaryenCeilFloat64());
        }
        pub fn floorFloat64() Op {
            return @enumFromInt(byn.BinaryenFloorFloat64());
        }
        pub fn truncFloat64() Op {
            return @enumFromInt(byn.BinaryenTruncFloat64());
        }
        pub fn nearestFloat64() Op {
            return @enumFromInt(byn.BinaryenNearestFloat64());
        }
        pub fn sqrtFloat64() Op {
            return @enumFromInt(byn.BinaryenSqrtFloat64());
        }
        pub fn eqZInt64() Op {
            return @enumFromInt(byn.BinaryenEqZInt64());
        }
        pub fn extendSInt32() Op {
            return @enumFromInt(byn.BinaryenExtendSInt32());
        }
        pub fn extendUInt32() Op {
            return @enumFromInt(byn.BinaryenExtendUInt32());
        }
        pub fn wrapInt64() Op {
            return @enumFromInt(byn.BinaryenWrapInt64());
        }
        pub fn truncSFloat32ToInt32() Op {
            return @enumFromInt(byn.BinaryenTruncSFloat32ToInt32());
        }
        pub fn truncSFloat32ToInt64() Op {
            return @enumFromInt(byn.BinaryenTruncSFloat32ToInt64());
        }
        pub fn truncUFloat32ToInt32() Op {
            return @enumFromInt(byn.BinaryenTruncUFloat32ToInt32());
        }
        pub fn truncUFloat32ToInt64() Op {
            return @enumFromInt(byn.BinaryenTruncUFloat32ToInt64());
        }
        pub fn truncSFloat64ToInt32() Op {
            return @enumFromInt(byn.BinaryenTruncSFloat64ToInt32());
        }
        pub fn truncSFloat64ToInt64() Op {
            return @enumFromInt(byn.BinaryenTruncSFloat64ToInt64());
        }
        pub fn truncUFloat64ToInt32() Op {
            return @enumFromInt(byn.BinaryenTruncUFloat64ToInt32());
        }
        pub fn truncUFloat64ToInt64() Op {
            return @enumFromInt(byn.BinaryenTruncUFloat64ToInt64());
        }
        pub fn reinterpretFloat32() Op {
            return @enumFromInt(byn.BinaryenReinterpretFloat32());
        }
        pub fn reinterpretFloat64() Op {
            return @enumFromInt(byn.BinaryenReinterpretFloat64());
        }
        pub fn convertSInt32ToFloat32() Op {
            return @enumFromInt(byn.BinaryenConvertSInt32ToFloat32());
        }
        pub fn convertSInt32ToFloat64() Op {
            return @enumFromInt(byn.BinaryenConvertSInt32ToFloat64());
        }
        pub fn convertUInt32ToFloat32() Op {
            return @enumFromInt(byn.BinaryenConvertUInt32ToFloat32());
        }
        pub fn convertUInt32ToFloat64() Op {
            return @enumFromInt(byn.BinaryenConvertUInt32ToFloat64());
        }
        pub fn convertSInt64ToFloat32() Op {
            return @enumFromInt(byn.BinaryenConvertSInt64ToFloat32());
        }
        pub fn convertSInt64ToFloat64() Op {
            return @enumFromInt(byn.BinaryenConvertSInt64ToFloat64());
        }
        pub fn convertUInt64ToFloat32() Op {
            return @enumFromInt(byn.BinaryenConvertUInt64ToFloat32());
        }
        pub fn convertUInt64ToFloat64() Op {
            return @enumFromInt(byn.BinaryenConvertUInt64ToFloat64());
        }
        pub fn promoteFloat32() Op {
            return @enumFromInt(byn.BinaryenPromoteFloat32());
        }
        pub fn demoteFloat64() Op {
            return @enumFromInt(byn.BinaryenDemoteFloat64());
        }
        pub fn reinterpretInt32() Op {
            return @enumFromInt(byn.BinaryenReinterpretInt32());
        }
        pub fn reinterpretInt64() Op {
            return @enumFromInt(byn.BinaryenReinterpretInt64());
        }

        pub fn andInt32() Op {
            return @enumFromInt(byn.BinaryenAndInt32());
        }
        pub fn orInt32() Op {
            return @enumFromInt(byn.BinaryenOrInt32());
        }
        pub fn xorInt32() Op {
            return @enumFromInt(byn.BinaryenXorInt32());
        }
        pub fn eqInt32() Op {
            return @enumFromInt(byn.BinaryenEqInt32());
        }
        pub fn neInt32() Op {
            return @enumFromInt(byn.BinaryenNeInt32());
        }
        pub fn ltSInt32() Op {
            return @enumFromInt(byn.BinaryenLtSInt32());
        }
        pub fn ltUInt32() Op {
            return @enumFromInt(byn.BinaryenLtUInt32());
        }
        pub fn leSInt32() Op {
            return @enumFromInt(byn.BinaryenLeSInt32());
        }
        pub fn leUInt32() Op {
            return @enumFromInt(byn.BinaryenLeUInt32());
        }
        pub fn gtSInt32() Op {
            return @enumFromInt(byn.BinaryenGtSInt32());
        }
        pub fn gtUInt32() Op {
            return @enumFromInt(byn.BinaryenGtUInt32());
        }
        pub fn geSInt32() Op {
            return @enumFromInt(byn.BinaryenGeSInt32());
        }
        pub fn geUInt32() Op {
            return @enumFromInt(byn.BinaryenGeUInt32());
        }

        pub fn andInt64() Op {
            return @enumFromInt(byn.BinaryenAndInt64());
        }
        pub fn orInt64() Op {
            return @enumFromInt(byn.BinaryenOrInt64());
        }
        pub fn xorInt64() Op {
            return @enumFromInt(byn.BinaryenXorInt64());
        }
        pub fn eqInt64() Op {
            return @enumFromInt(byn.BinaryenEqInt64());
        }
        pub fn neInt64() Op {
            return @enumFromInt(byn.BinaryenNeInt64());
        }
        pub fn ltSInt64() Op {
            return @enumFromInt(byn.BinaryenLtSInt64());
        }
        pub fn ltUInt64() Op {
            return @enumFromInt(byn.BinaryenLtUInt64());
        }
        pub fn leSInt64() Op {
            return @enumFromInt(byn.BinaryenLeSInt64());
        }
        pub fn leUInt64() Op {
            return @enumFromInt(byn.BinaryenLeUInt64());
        }
        pub fn gtSInt64() Op {
            return @enumFromInt(byn.BinaryenGtSInt64());
        }
        pub fn gtUInt64() Op {
            return @enumFromInt(byn.BinaryenGtUInt64());
        }
        pub fn geSInt64() Op {
            return @enumFromInt(byn.BinaryenGeSInt64());
        }
        pub fn geUInt64() Op {
            return @enumFromInt(byn.BinaryenGeUInt64());
        }

        // FIXME: I deeply already hate writing this boiler plate could generate
        // but I already started using the raw c interface downstream
        pub fn andFloat32() Op {
            return @enumFromInt(byn.BinaryenAndFloat32());
        }
        pub fn orFloat32() Op {
            return @enumFromInt(byn.BinaryenOrFloat32());
        }
        pub fn xorFloat32() Op {
            return @enumFromInt(byn.BinaryenXorFloat32());
        }
        pub fn eqFloat32() Op {
            return @enumFromInt(byn.BinaryenEqFloat32());
        }
        pub fn neFloat32() Op {
            return @enumFromInt(byn.BinaryenNeFloat32());
        }
        pub fn ltSFloat32() Op {
            return @enumFromInt(byn.BinaryenLtSFloat32());
        }
        pub fn ltFloat32() Op {
            return @enumFromInt(byn.BinaryenLtFloat32());
        }
        pub fn leSFloat32() Op {
            return @enumFromInt(byn.BinaryenLeSFloat32());
        }
        pub fn leFloat32() Op {
            return @enumFromInt(byn.BinaryenLeFloat32());
        }
        pub fn gtSFloat32() Op {
            return @enumFromInt(byn.BinaryenGtSFloat32());
        }
        pub fn gtFloat32() Op {
            return @enumFromInt(byn.BinaryenGtFloat32());
        }
        pub fn geSFloat32() Op {
            return @enumFromInt(byn.BinaryenGeSFloat32());
        }
        pub fn geFloat32() Op {
            return @enumFromInt(byn.BinaryenGeFloat32());
        }

        // FIXME: I deeply already hate writing this boiler plate could generate
        // but I already started using the raw c interface downstream
        pub fn andFloat64() Op {
            return @enumFromInt(byn.BinaryenAndFloat64());
        }
        pub fn orFloat64() Op {
            return @enumFromInt(byn.BinaryenOrFloat64());
        }
        pub fn xorFloat64() Op {
            return @enumFromInt(byn.BinaryenXorFloat64());
        }
        pub fn eqFloat64() Op {
            return @enumFromInt(byn.BinaryenEqFloat64());
        }
        pub fn neFloat64() Op {
            return @enumFromInt(byn.BinaryenNeFloat64());
        }
        pub fn ltSFloat64() Op {
            return @enumFromInt(byn.BinaryenLtSFloat64());
        }
        pub fn ltFloat64() Op {
            return @enumFromInt(byn.BinaryenLtFloat64());
        }
        pub fn leSFloat64() Op {
            return @enumFromInt(byn.BinaryenLeSFloat64());
        }
        pub fn leFloat64() Op {
            return @enumFromInt(byn.BinaryenLeFloat64());
        }
        pub fn gtSFloat64() Op {
            return @enumFromInt(byn.BinaryenGtSFloat64());
        }
        pub fn gtFloat64() Op {
            return @enumFromInt(byn.BinaryenGtFloat64());
        }
        pub fn geSFloat64() Op {
            return @enumFromInt(byn.BinaryenGeSFloat64());
        }
        pub fn geFloat64() Op {
            return @enumFromInt(byn.BinaryenGeFloat64());
        }

        // strings
        pub fn BinaryenStringNewLossyUTF8Array() Op {
            return byn.BinaryenStringNewLossyUTF8Array();
        }
        pub fn BinaryenStringNewWTF16Array() Op {
            return byn.BinaryenStringNewWTF16Array();
        }
        pub fn BinaryenStringNewFromCodePoint() Op {
            return byn.BinaryenStringNewFromCodePoint();
        }
        pub fn BinaryenStringMeasureUTF8() Op {
            return byn.BinaryenStringMeasureUTF8();
        }
        pub fn BinaryenStringMeasureWTF16() Op {
            return byn.BinaryenStringMeasureWTF16();
        }
        pub fn BinaryenStringEncodeLossyUTF8Array() Op {
            return byn.BinaryenStringEncodeLossyUTF8Array();
        }
        pub fn BinaryenStringEncodeWTF16Array() Op {
            return byn.BinaryenStringEncodeWTF16Array();
        }
        pub fn BinaryenStringEqEqual() Op {
            return byn.BinaryenStringEqEqual();
        }
        pub fn BinaryenStringEqCompare() Op {
            return byn.BinaryenStringEqCompare();
        }
    };

    pub inline fn localGet(module: *Module, index: Index, type_: Type) *Expression {
        return @ptrCast(byn.BinaryenLocalGet(module.c(), index, @intFromEnum(type_)));
    }

    pub inline fn binaryOp(module: *Module, op: Op, lhs: *Expression, rhs: *Expression) *Expression {
        return @ptrCast(byn.BinaryenBinary(module.c(), op.c(), lhs.c(), rhs.c()));
    }

    pub inline fn unaryOp(module: *Module, op: Op, expr: *Expression) *Expression {
        return @ptrCast(byn.BinaryenUnary(module.c(), op.c(), expr.c()));
    }

    pub inline fn stringConst(module: *Module, name: [:0]const u8) !*Expression {
        return @as(?*Expression, @ptrCast(byn.BinaryenStringConst(module.c(), name.ptr))) orelse {
            return error.Null;
        };
    }

    pub const Literal = struct {
        c: byn.struct_binaryenLiteral,

        pub inline fn int64(value: i64) Literal {
            return .{ .c = byn.BinaryenLiteralInt64(value) };
        }

        pub inline fn float64(value: f64) Literal {
            return .{ .c = byn.BinaryenLiteralFloat64(value) };
        }
    };

    pub inline fn @"const"(module: *Module, literal: Literal) *Expression {
        return byn.BinaryenConst(module, literal.c);
    }

    // $ grep ') BinaryenExpressionRef' .zig-cache/o/a5ca0d35ed4df445a517afd4426eb0e2/cimport.zig \
    // | grep -Po '\w+(?=\()' | sed 's,^,//,' | sort -u | putclip

    //BinaryenArrayCopy
    //BinaryenArrayCopyGetDestIndex
    //BinaryenArrayCopyGetDestRef
    //BinaryenArrayCopyGetLength
    //BinaryenArrayCopyGetSrcIndex
    //BinaryenArrayCopyGetSrcRef
    //BinaryenArrayGet
    //BinaryenArrayGetGetIndex
    //BinaryenArrayGetGetRef
    //BinaryenArrayLen
    //BinaryenArrayLenGetRef
    //BinaryenArrayNew
    //BinaryenArrayNewData
    //BinaryenArrayNewFixed
    //BinaryenArrayNewFixedGetValueAt
    //BinaryenArrayNewFixedRemoveValueAt
    //BinaryenArrayNewGetInit
    //BinaryenArrayNewGetSize
    //BinaryenArraySet
    //BinaryenArraySetGetIndex
    //BinaryenArraySetGetRef
    //BinaryenArraySetGetValue
    //BinaryenAtomicCmpxchg
    //BinaryenAtomicCmpxchgGetExpected
    //BinaryenAtomicCmpxchgGetPtr
    //BinaryenAtomicCmpxchgGetReplacement
    //BinaryenAtomicFence
    //BinaryenAtomicLoad
    //BinaryenAtomicNotify
    //BinaryenAtomicNotifyGetNotifyCount
    //BinaryenAtomicNotifyGetPtr
    //BinaryenAtomicRMW
    //BinaryenAtomicRMWGetPtr
    //BinaryenAtomicRMWGetValue
    //BinaryenAtomicStore
    //BinaryenAtomicWait
    //BinaryenAtomicWaitGetExpected
    //BinaryenAtomicWaitGetPtr
    //BinaryenAtomicWaitGetTimeout
    //BinaryenBinary
    //BinaryenBinaryGetLeft
    //BinaryenBinaryGetRight

    pub fn block(module: *Module, name: ?[:0]const u8, children: []*Expression, @"type": Type) !*Expression {
        return @as(?*Expression, @ptrCast(byn.BinaryenBlock(
            module.c(),
            @as([*c]const u8, @ptrCast(name)),
            @ptrCast(children.ptr),
            @intCast(children.len),
            @intFromEnum(@"type"),
        ))) orelse {
            return error.Null;
        };
    }

    //BinaryenBlockGetChildAt
    //BinaryenBlockRemoveChildAt
    //BinaryenBreak
    //BinaryenBreakGetCondition
    //BinaryenBreakGetValue
    //BinaryenBrOn
    //BinaryenBrOnGetRef
    //BinaryenCall
    //BinaryenCallGetOperandAt
    //BinaryenCallIndirect
    //BinaryenCallIndirectGetOperandAt
    //BinaryenCallIndirectGetTarget
    //BinaryenCallIndirectRemoveOperandAt
    //BinaryenCallRef
    //BinaryenCallRefGetOperandAt
    //BinaryenCallRefGetTarget
    //BinaryenCallRefRemoveOperandAt
    //BinaryenCallRemoveOperandAt
    //BinaryenConst
    //BinaryenDataDrop
    //BinaryenDrop
    //BinaryenDropGetValue
    //BinaryenElementSegmentGetOffset
    //BinaryenExpressionCopy
    //BinaryenFunctionGetBody
    //BinaryenGlobalGet
    //BinaryenGlobalGetInitExpr
    //BinaryenGlobalSet
    //BinaryenGlobalSetGetValue
    //BinaryenI31Get
    //BinaryenI31GetGetI31
    //BinaryenIf
    //BinaryenIfGetCondition
    //BinaryenIfGetIfFalse
    //BinaryenIfGetIfTrue
    //BinaryenLoad
    //BinaryenLoadGetPtr
    //BinaryenLocalGet
    //BinaryenLocalSet
    //BinaryenLocalSetGetValue
    //BinaryenLocalTee
    //BinaryenLoop
    //BinaryenLoopGetBody
    //BinaryenMemoryCopy
    //BinaryenMemoryCopyGetDest
    //BinaryenMemoryCopyGetSize
    //BinaryenMemoryCopyGetSource
    //BinaryenMemoryFill
    //BinaryenMemoryFillGetDest
    //BinaryenMemoryFillGetSize
    //BinaryenMemoryFillGetValue
    //BinaryenMemoryGrow
    //BinaryenMemoryGrowGetDelta
    //BinaryenMemoryInit
    //BinaryenMemoryInitGetDest
    //BinaryenMemoryInitGetOffset
    //BinaryenMemoryInitGetSize
    //BinaryenMemorySize
    //BinaryenNop
    //BinaryenPop
    //BinaryenRefAs
    //BinaryenRefAsGetValue
    //BinaryenRefCast
    //BinaryenRefCastGetRef
    //BinaryenRefEq
    //BinaryenRefEqGetLeft
    //BinaryenRefEqGetRight
    //BinaryenRefFunc
    //BinaryenRefI31
    //BinaryenRefI31GetValue
    //BinaryenRefIsNull
    //BinaryenRefIsNullGetValue
    //BinaryenRefNull
    //BinaryenRefTest
    //BinaryenRefTestGetRef
    //BinaryenRethrow
    //BinaryenReturn
    //BinaryenReturnCall
    //BinaryenReturnCallIndirect
    //BinaryenReturnGetValue
    //BinaryenSelect
    //BinaryenSelectGetCondition
    //BinaryenSelectGetIfFalse
    //BinaryenSelectGetIfTrue
    //BinaryenSIMDExtract
    //BinaryenSIMDExtractGetVec
    //BinaryenSIMDLoad
    //BinaryenSIMDLoadGetPtr
    //BinaryenSIMDLoadStoreLane
    //BinaryenSIMDLoadStoreLaneGetPtr
    //BinaryenSIMDLoadStoreLaneGetVec
    //BinaryenSIMDReplace
    //BinaryenSIMDReplaceGetValue
    //BinaryenSIMDReplaceGetVec
    //BinaryenSIMDShift
    //BinaryenSIMDShiftGetShift
    //BinaryenSIMDShiftGetVec
    //BinaryenSIMDShuffle
    //BinaryenSIMDShuffleGetLeft
    //BinaryenSIMDShuffleGetRight
    //BinaryenSIMDTernary
    //BinaryenSIMDTernaryGetA
    //BinaryenSIMDTernaryGetB
    //BinaryenSIMDTernaryGetC
    //BinaryenStore
    //BinaryenStoreGetPtr
    //BinaryenStoreGetValue
    //BinaryenStringConcat
    //BinaryenStringConcatGetLeft
    //BinaryenStringConcatGetRight
    //BinaryenStringConst
    //BinaryenStringEncode
    //BinaryenStringEncodeGetArray
    //BinaryenStringEncodeGetStart
    //BinaryenStringEncodeGetStr
    //BinaryenStringEq
    //BinaryenStringEqGetLeft
    //BinaryenStringEqGetRight
    //BinaryenStringIterMove
    //BinaryenStringIterNext
    //BinaryenStringMeasure
    //BinaryenStringMeasureGetRef
    //BinaryenStringNew
    //BinaryenStringNewGetEnd
    //BinaryenStringNewGetRef
    //BinaryenStringNewGetStart
    //BinaryenStringSliceIter
    //BinaryenStringSliceWTF
    //BinaryenStringSliceWTFGetEnd
    //BinaryenStringSliceWTFGetRef
    //BinaryenStringSliceWTFGetStart
    //BinaryenStringWTF16Get
    //BinaryenStringWTF16GetGetPos
    //BinaryenStringWTF16GetGetRef
    //BinaryenStringWTF8Advance
    //BinaryenStructGet
    //BinaryenStructGetGetRef
    //BinaryenStructNew
    //BinaryenStructNewGetOperandAt
    //BinaryenStructNewRemoveOperandAt
    //BinaryenStructSet
    //BinaryenStructSetGetRef
    //BinaryenStructSetGetValue
    //BinaryenSwitch
    //BinaryenSwitchGetCondition
    //BinaryenSwitchGetValue
    //BinaryenTableGet
    //BinaryenTableGetGetIndex
    //BinaryenTableGrow
    //BinaryenTableGrowGetDelta
    //BinaryenTableGrowGetValue
    //BinaryenTableSet
    //BinaryenTableSetGetIndex
    //BinaryenTableSetGetValue
    //BinaryenTableSize
    //BinaryenThrow
    //BinaryenThrowGetOperandAt
    //BinaryenThrowRemoveOperandAt
    //BinaryenTry
    //BinaryenTryGetBody
    //BinaryenTryGetCatchBodyAt
    //BinaryenTryRemoveCatchBodyAt
    //BinaryenTupleExtract
    //BinaryenTupleExtractGetTuple
    //BinaryenTupleMake
    //BinaryenTupleMakeGetOperandAt
    //BinaryenTupleMakeRemoveOperandAt
    //BinaryenUnary
    //BinaryenUnaryGetValue
    //BinaryenUnreachable
    //ExpressionRunnerRunAndDispose
    //RelooperRenderAndDispose
};

pub const Function = opaque {
    pub inline fn c(self: *@This()) byn.BinaryenFunctionRef {
        return @ptrCast(self);
    }
};

// Bit zero indicates whether the type is `shared`, so we need to leave it
// free.
pub const BasicHeapType = enum(byn.BinaryenBasicHeapType) {
    ext = 0 << 1,
    func = 1 << 1,
    cont = 2 << 1,
    any = 3 << 1,
    eq = 4 << 1,
    i31 = 5 << 1,
    struct_ = 6 << 1,
    array = 7 << 1,
    exn = 8 << 1,
    string = 9 << 1,
    none = 10 << 1,
    noext = 11 << 1,
    nofunc = 12 << 1,
    nocont = 13 << 1,
    noexn = 14 << 1,
};

pub const HeapType = byn.BinaryenHeapType;

pub const TypeBuilder = opaque {
    pub inline fn c(self: *@This()) byn.TypeBuilderRef {
        return @ptrCast(self);
    }

    pub fn create(size: Index) *@This() {
        return byn.TypeBuilderCreate(size);
    }

    pub fn grow(self: *@This(), count: Index) void {
        return byn.TypeBuilderGrow(self.c(), count);
    }

    pub fn getSize(self: *@This()) Index {
        return byn.TypeBuilderGetSize(self.c());
    }

    pub fn setSignatureType(self: *@This(), index: Index, paramTypes: Type, resultTypes: Type) void {
        return byn.TypeBuilderSetSignatureType(self.c(), index, @intFromEnum(paramTypes), @intFromEnum(resultTypes));
    }

    pub fn setStructType(self: *@This(), index: Index, fieldTypes: []Type, fieldPackedTypes: []Type.Field.Packed, fieldMutables: []bool) void {
        std.debug.assert(fieldTypes.len == fieldMutables.len and fieldTypes.len == fieldPackedTypes.len);
        return byn.TypeBuilderSetStructType(self.c(), index, @ptrCast(fieldTypes.ptr), @ptrCast(fieldPackedTypes.ptr), fieldMutables.ptr, fieldTypes.len);
    }

    pub fn setArrayType(self: *@This(), index: Index, elementType: Type, elementPackedType: Type.Field.Packed, elementMutable: c_int) void {
        return byn.TypeBuilderSetArrayType(self.c(), index, @intFromEnum(elementType), @intFromEnum(elementPackedType), elementMutable);
    }

    pub fn getTempHeapType(self: *@This(), index: Index) HeapType {
        return byn.TypeBuilderGetTempHeapType(self.c(), index);
    }

    pub fn getTempTupleType(self: *@This(), types: []Type) Type {
        return @enumFromInt(byn.TypeBuilderGetTempTupleType(self.c(), @ptrCast(types.ptr), types.len));
    }

    pub fn getTempRefType(self: *@This(), heapType: HeapType, nullable: c_int) Type {
        return @enumFromInt(byn.TypeBuilderGetTempRefType(self.c(), heapType, nullable));
    }

    pub fn setSubType(self: *@This(), index: Index, superType: HeapType) void {
        return byn.TypeBuilderSetSubType(self.c(), index, superType);
    }

    pub fn setOpen(self: *@This(), index: Index) void {
        return byn.TypeBuilderSetOpen(self.c(), index);
    }

    pub fn createRecGroup(self: *@This(), index: Index, length: Index) void {
        return byn.TypeBuilderCreateRecGroup(self.c(), index, length);
    }

    pub const ErrorReason = enum(byn.TypeBuilderErrorReason) {
        _,

        pub fn selfSupertype() @This() {
            return byn.TypeBuilderErrorReasonSelfSupertype();
        }
        pub fn invalidSupertype() @This() {
            return byn.TypeBuilderErrorReasonInvalidSupertype();
        }
        pub fn forwardSupertypeReference() @This() {
            return byn.TypeBuilderErrorReasonForwardSupertypeReference();
        }
        pub fn forwardChildReference() @This() {
            return byn.TypeBuilderErrorReasonForwardChildReference();
        }
    };

    pub fn buildAndDispose(self: *@This(), heapTypes: [:0]HeapType, errorIndex: ?*Index, errorReason: ?*ErrorReason) bool {
        return byn.TypeBuilderBuildAndDispose(self.c(), heapTypes, errorIndex, errorReason);
    }

    pub fn setTypeName(module: *Module, heapType: HeapType, name: [:0]const u8) void {
        return byn.BinaryenModuleSetTypeName(module, heapType, name);
    }

    pub fn setFieldName(module: *Module, heapType: HeapType, index: Index, name: [:0]const u8) void {
        return byn.BinaryenModuleSetFieldName(module, heapType, index, name);
    }
};

pub const Relooper = opaque {
    const Block = opaque {
        pub inline fn c(self: *@This()) byn.RelooperBlockRef {
            return @ptrCast(self);
        }
    };

    pub inline fn c(self: *@This()) byn.RelooperRef {
        return @ptrCast(self);
    }

    // fn RelooperCreate(module: BinaryenModuleRef) RelooperRef;
    pub fn create(mod: *Module) *Relooper {
        const relooper = byn.RelooperCreate(mod.c());
        return @ptrCast(relooper);
    }

    // fn RelooperRenderAndDispose(relooper: RelooperRef, entry: RelooperBlockRef, labelHelper: BinaryenIndex) BinaryenExpressionRef;
    pub fn renderAndDispose(self: *@This(), entry: *Block, label_helper: Index) *Expression {
        return byn.RelooperRenderAndDispose(self.c(), entry, label_helper);
    }

    // fn RelooperAddBranch(from: RelooperBlockRef, to: RelooperBlockRef, condition: BinaryenExpressionRef, code: BinaryenExpressionRef) void;
    pub fn addBranch(self: *@This(), from: *Block, to: *Block, condition: *Expression, code: *Expression) *Expression {
        return byn.RelooperAddBranch(self.c(), from, to, condition, code);
    }

    // fn RelooperAddBranchForSwitch(from: RelooperBlockRef, to: RelooperBlockRef, indexes: [*c]BinaryenIndex, numIndexes: BinaryenIndex, code: BinaryenExpressionRef) void;
    pub fn addBranchForSwitch(self: *@This(), from: *Block, to: *Block, indices: []Index, code: *Expression) *Expression {
        return byn.RelooperAddBranchForSwitch(self.c(), from, to, indices.ptr, @intCast(indices.len), code);
    }

    // fn RelooperAddBlock(relooper: RelooperRef, code: BinaryenExpressionRef) RelooperBlockRef;
    pub fn addBlock(self: *@This(), code: *Expression) *Block {
        return byn.RelooperAddBlock(self.c(), code);
    }

    // fn RelooperAddBlockWithSwitch(relooper: RelooperRef, code: BinaryenExpressionRef, condition: BinaryenExpressionRef) RelooperBlockRef;
    pub fn addBlockWithSwitch(self: *@This(), code: *Expression, condition: *Expression) *Block {
        return byn.RelooperAddBlockWithSwitch(self.c(), code.c(), condition.c());
    }
};

pub const Type = enum(byn.BinaryenType) {
    // converted from binaryen/src/wasm-type.h, the binaryen-c.h file says core type values can
    // be cached and will never change (also they're (TODO, check) probably in the wasm spec)
    pub const Basic = enum(u32) {
        none = 0,
        @"unreachable" = 1,
        i32 = 2,
        i64 = 3,
        f32 = 4,
        f64 = 5,
        v128 = 6,
    };

    none = @intFromEnum(Basic.none),
    @"unreachable" = @intFromEnum(Basic.@"unreachable"),
    i32 = @intFromEnum(Basic.i32),
    i64 = @intFromEnum(Basic.i64),
    f32 = @intFromEnum(Basic.f32),
    f64 = @intFromEnum(Basic.f64),
    v128 = @intFromEnum(Basic.v128),

    _,

    pub fn funcref() Type {
        return @enumFromInt(byn.BinaryenTypeFuncref());
    }
    pub fn externref() Type {
        return @enumFromInt(byn.BinaryenTypeExternref());
    }
    pub fn anyref() Type {
        return @enumFromInt(byn.BinaryenTypeAnyref());
    }
    pub fn eqref() Type {
        return @enumFromInt(byn.BinaryenTypeEqref());
    }
    pub fn i31ref() Type {
        return @enumFromInt(byn.BinaryenTypeI31ref());
    }
    pub fn structref() Type {
        return @enumFromInt(byn.BinaryenTypeStructref());
    }
    pub fn arrayref() Type {
        return @enumFromInt(byn.BinaryenTypeArrayref());
    }
    pub fn stringref() Type {
        return @enumFromInt(byn.BinaryenTypeStringref());
    }
    pub fn stringviewWTF8() Type {
        return @enumFromInt(byn.BinaryenTypeStringviewWTF8());
    }
    pub fn stringviewWTF16() Type {
        return @enumFromInt(byn.BinaryenTypeStringviewWTF16());
    }
    pub fn stringviewIter() Type {
        return @enumFromInt(byn.BinaryenTypeStringviewIter());
    }
    pub fn nullref() Type {
        return @enumFromInt(byn.BinaryenTypeNullref());
    }
    pub fn nullExternref() Type {
        return @enumFromInt(byn.BinaryenTypeNullExternref());
    }
    pub fn nullFuncref() Type {
        return @enumFromInt(byn.BinaryenTypeNullFuncref());
    }
    pub fn unreachable_() Type {
        return @enumFromInt(byn.BinaryenTypeUnreachable());
    }

    // TODO: idk about this
    pub const Field = struct {
        pub const Packed = enum(byn.BinaryenPackedType) {
            _,

            pub fn int8() Packed {
                return @enumFromInt(byn.BinaryenPackedTypeInt8());
            }
        };
    };

    /// Not a real type. Used as the last parameter to BinaryenBlock to let
    /// the API figure out the type instead of providing one.
    pub fn auto() Type {
        return @enumFromInt(byn.BinaryenTypeAuto());
    }

    pub fn create(value_types: []const Type) Type {
        return @enumFromInt(byn.BinaryenTypeCreate(
            @constCast(@ptrCast(value_types.ptr)),
            @intCast(value_types.len),
        ));
    }

    pub fn arity(self: Type) u32 {
        return byn.BinaryenTypeArity(@intFromEnum(self));
    }

    pub fn expand(self: Type, allocator: std.mem.Allocator) ![]Type {
        const buf = try allocator.alloc(Type, self.arity());
        byn.BinaryenTypeExpand(@intFromEnum(self), @ptrCast(buf.ptr));
        return buf;
    }
};
