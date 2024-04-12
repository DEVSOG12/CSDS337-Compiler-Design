#include "comparison.h"

std::unique_ptr<VarType> ASTExpressionComparison::ReturnType(ASTFunction& func)
{
    return VarTypeSimple::BoolType.Copy();
}

bool ASTExpressionComparison::IsLValue(ASTFunction& func)
{
    return false; // Comparison expressions always result in R-Values.
}

llvm::Value* ASTExpressionComparison::Compile(llvm::IRBuilder<>& builder, ASTFunction& func)
{
    VarTypeSimple* returnType;
    if (!ASTExpression::CoerceTypes(func, a1, a2, returnType)) // This will force our arguments to be the same type and outputs which one it is.
        throw std::runtime_error("ERROR: Can not coerce types in comparison expression! Are they all booleans, ints, and floats?");

    // Get values. Operations only work on R-Values.
    auto a1Val = a1->CompileRValue(builder, func);
    auto a2Val = a2->CompileRValue(builder, func);

    if (returnType->Equals(&VarTypeSimple::IntType))
    {
        switch (type)
        {
            case Equal: return builder.CreateICmpEQ(a1Val, a2Val);
            case NotEqual: return builder.CreateICmpNE(a1Val, a2Val);
            case LessThan: return builder.CreateICmpSLT(a1Val, a2Val);
            case LessThanOrEqual: return builder.CreateICmpSLE(a1Val, a2Val);
            case GreaterThan: return builder.CreateICmpSGT(a1Val, a2Val);
            case GreaterThanOrEqual: return builder.CreateICmpSGE(a1Val, a2Val);
        }
    }
    else if (returnType->Equals(&VarTypeSimple::FloatType))
    {
        switch (type)
        {
            case Equal: return builder.CreateFCmpOEQ(a1Val, a2Val); // Use ordered operations to not allow NANS.
            case NotEqual: return builder.CreateFCmpONE(a1Val, a2Val);
            case LessThan: return builder.CreateFCmpOLT(a1Val, a2Val);
            case LessThanOrEqual: return builder.CreateFCmpOLE(a1Val, a2Val);
            case GreaterThan: return builder.CreateFCmpOGT(a1Val, a2Val);
            case GreaterThanOrEqual: return builder.CreateFCmpOGE(a1Val, a2Val);
        }
    }

    // How did we get here?
    throw std::runtime_error("ERROR: Did not return value from comparison. Unsuccessful coercion of values or invalid comparison type!");
}

std::string ASTExpressionComparison::ToString(const std::string& prefix)
{
    std::string op;
    switch (type)
    {
        case Equal: op = "=="; break;
        case NotEqual: op = "!="; break;
        case LessThan: op = "<"; break;
        case LessThanOrEqual: op = "<="; break;
        case GreaterThan: op = ">"; break;
        case GreaterThanOrEqual: op = ">="; break;
    }
    std::string ret = "(" + op + ")\n";
    ret += prefix + "├──" + a1->ToString(prefix + "│  ");
    ret += prefix + "└──" + a2->ToString(prefix + "   ");
    return ret;
}
