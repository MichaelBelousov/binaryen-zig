const std = @import("std");
const byn = @cImport({
    @cInclude("stdlib.h");
    @cInclude("binaryen-c.h");
});

//pub const intrinsics = @import("./wasm_intrinsics.zig");
pub export const _wasm_intrinsics_wat = @embedFile("binaryen-wat-intrinsics").*;
pub usingnamespace @import("./cxa_stubs.zig");

pub fn freeEmit(buf: []u8) void {
    byn.free(buf.ptr);
}

pub const Module = opaque {
    pub fn init() *Module {
        const mod = byn.BinaryenModuleCreate();
        return @ptrCast(mod);
    }
    pub fn deinit(self: *Module) void {
        byn.BinaryenModuleDispose(self.c());
    }

    // TODO: error handling
    pub fn parseText(wat: [*:0]const u8) *Module {
        const mod = byn.BinaryenModuleParse(wat);
        return @ptrCast(mod);
    }
    // TODO: error handling
    pub fn readBinary(wasm: []const u8) *Module {
        const mod = byn.BinaryenModuleRead(@constCast(wasm.ptr), wasm.len);
        return @ptrCast(mod);
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
        name: [*:0]const u8,
        params: Type,
        results: Type,
        var_types: []const Type,
        body: *Expression,
    ) *Function {
        const func = byn.BinaryenAddFunction(
            self.c(),
            name,
            @intFromEnum(params),
            @intFromEnum(results),
            @constCast(@ptrCast(var_types.ptr)),
            @intCast(var_types.len),
            body.c(),
        );
        return @ptrCast(func);
    }

    inline fn c(self: *Module) byn.BinaryenModuleRef {
        return @ptrCast(self);
    }
};

pub const Index = byn.BinaryenIndex;

pub const Expression = opaque {
    pub const Op = enum(byn.BinaryenOp) {
        _,

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

        inline fn c(self: Op) byn.BinaryenOp {
            return @intFromEnum(self);
        }
    };

    inline fn c(self: *Expression) byn.BinaryenExpressionRef {
        return @ptrCast(self);
    }

    pub inline fn localGet(module: *Module, index: Index, type_: Type) *Expression {
        return @ptrCast(byn.BinaryenLocalGet(module.c(), index, @intFromEnum(type_)));
    }

    pub inline fn binaryOp(module: *Module, op: Op, lhs: *Expression, rhs: *Expression) *Expression {
        return @ptrCast(byn.BinaryenBinary(module.c(), op.c(), lhs.c(), rhs.c()));
    }
};

pub const Function = opaque {
    inline fn c(self: *@This()) byn.BinaryenFunctionRef {
        return @ptrCast(self);
    }
};

pub const BasicHeapType = byn.BinaryenBasicHeapType;
pub const HeapType = byn.BinaryenHeapType;
pub const PackedType = byn.BinaryenPackedType;

pub const TypeBuilder = opaque {
    inline fn c(self: *@This()) byn.TypeBuilderRef {
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

    pub fn setStructType(self: *@This(), index: Index, fieldTypes: []Type, fieldPackedTypes: []PackedType, fieldMutables: []bool) void {
        std.debug.assert(fieldTypes.len == fieldMutables.len and fieldTypes.len == fieldPackedTypes.len);
        return byn.TypeBuilderSetStructType(self.c(), index, @ptrCast(fieldTypes.ptr), @ptrCast(fieldPackedTypes.ptr), fieldMutables.ptr, fieldTypes.len);
    }

    pub fn setArrayType(self: *@This(), index: Index, elementType: Type, elementPackedType: PackedType, elementMutable: c_int) void {
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
        inline fn c(self: *@This()) byn.RelooperBlockRef {
            return @ptrCast(self);
        }
    };

    inline fn c(self: *@This()) byn.RelooperRef {
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

pub const Type = enum(usize) {
    _,

    pub fn none() Type {
        return @enumFromInt(byn.BinaryenTypeNone());
    }
    pub fn int32() Type {
        return @enumFromInt(byn.BinaryenTypeInt32());
    }
    pub fn int64() Type {
        return @enumFromInt(byn.BinaryenTypeInt64());
    }
    pub fn float32() Type {
        return @enumFromInt(byn.BinaryenTypeFloat32());
    }
    pub fn float64() Type {
        return @enumFromInt(byn.BinaryenTypeFloat64());
    }
    pub fn vec128() Type {
        return @enumFromInt(byn.BinaryenTypeVec128());
    }
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
