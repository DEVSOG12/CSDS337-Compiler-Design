#pragma once

#include "../expression.h"

// An expression that converts a boolean value to an integer.
class ASTExpressionBool2Int : public ASTExpression
{
    // Operand to convert.
    std::unique_ptr<ASTExpression> operand;

public:

    // Create a new bool2int expression.
    // operand: Expression to convert from boolean to integer.
    ASTExpressionBool2Int(std::unique_ptr<ASTExpression> operand) : operand(std::move(operand)) {}

    // Create a new bool2int expression.
    // operand: Expression to convert from boolean to integer.
    static auto Create(std::unique_ptr<ASTExpression> operand)
    {
        return std::make_unique<ASTExpressionBool2Int>(std::move(operand));
    }

    // Virtual functions. See base class for details.
    std::unique_ptr<VarType> ReturnType(ASTFunction& func) override;
    bool IsLValue(ASTFunction& func) override;
    llvm::Value* Compile(llvm::IRBuilder<>& builder, ASTFunction& func) override;
    std::string ToString(const std::string& prefix) override;
};
