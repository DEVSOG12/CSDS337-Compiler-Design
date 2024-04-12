#include "bool.h"

std::unique_ptr<VarType> ASTExpressionBool::ReturnType(ASTFunction& func)
{
    return VarTypeSimple::BoolType.Copy(); // Return type is bool.
}

bool ASTExpressionBool::IsLValue(ASTFunction& func)
{
    return false; // Constant bool expression is not an L-Value.
}

llvm::Value* ASTExpressionBool::Compile(llvm::IRBuilder<>& builder, ASTFunction& func)
{
    // Create LLVM constant bool value.
    return llvm::ConstantInt::get(builder.getContext(), llvm::APInt(1, value ? 1 : 0, false));
}

std::string ASTExpressionBool::ToString(const std::string& prefix)
{
    return value ? "true" : "false";
}
