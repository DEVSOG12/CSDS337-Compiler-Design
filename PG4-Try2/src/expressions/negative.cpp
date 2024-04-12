#include "negative.h"

std::unique_ptr<VarType> ASTExpressionNegation::ReturnType(ASTFunction& func)
{
    return operand->ReturnType(func); // The return type remains the same as the operand's return type.
}

bool ASTExpressionNegation::IsLValue(ASTFunction& func)
{
    return false; // Negation operation always results in an R-Value.
}

llvm::Value* ASTExpressionNegation::Compile(llvm::IRBuilder<>& builder, ASTFunction& func)
{
    // Negate the operand's value.
    auto operandValue = operand->CompileRValue(builder, func);
    return builder.CreateNeg(operandValue);
}

std::string ASTExpressionNegation::ToString(const std::string& prefix)
{
    return "(-)\n" + prefix + "└──" + operand->ToString(prefix + "   ");
}
