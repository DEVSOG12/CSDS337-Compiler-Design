#include "subtraction.h"

std::unique_ptr<VarType> ASTExpressionSubtraction::ReturnType(ASTFunction& func)
{
    // Determine the return type based on the types of the operands.
    // Example implementation:
    VarType* type1 = a1->ReturnType(func).get();
    VarType* type2 = a2->ReturnType(func).get();

    // Perform type checking and determine the return type.
    // Example logic:
    if (type1->Equals(&VarTypeSimple::FloatType) || type2->Equals(&VarTypeSimple::FloatType))
    {
        return VarTypeSimple::FloatType.Copy();
    }
    else
    {
        return VarTypeSimple::IntType.Copy();
    }
}

bool ASTExpressionSubtraction::IsLValue(ASTFunction& func)
{
    // Subtract expression result is not an L-Value.
    return false;
}

llvm::Value* ASTExpressionSubtraction::Compile(llvm::IRBuilder<>& builder, ASTFunction& func)
{
    // Compile LLVM IR code for the subtraction expression.
    // Example implementation:
    llvm::Value* left = a1->Compile(builder, func);
    llvm::Value* right = a2->Compile(builder, func);
    return builder.CreateSub(left, right, "subtmp");
}

std::string ASTExpressionSubtraction::ToString(const std::string& prefix)
{
    // Generate a string representation of the subtraction expression.
    // Example implementation:
    return prefix + "Subtraction: (" + a1->ToString("") + " - " + a2->ToString("") + ")";
}