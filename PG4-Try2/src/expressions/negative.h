#pragma once

#include "../expression.h"

// An expression that negates its operand.
class ASTExpressionNegation : public ASTExpression
{
    // Operand to negate.
    std::unique_ptr<ASTExpression> operand;

public:

    // Create a new negation expression.
    // operand: Expression to negate.
    explicit ASTExpressionNegation(std::unique_ptr<ASTExpression> operand) : operand(std::move(operand)) {}

    // Create a new negation expression.
    // operand: Expression to negate.
    static auto Create(std::unique_ptr<ASTExpression> operand)
    {
        return std::make_unique<ASTExpressionNegation>(std::move(operand));
    }

    // Virtual functions. See base class for details.
    std::unique_ptr<VarType> ReturnType(ASTFunction& func) override;
    bool IsLValue(ASTFunction& func) override;
    llvm::Value* Compile(llvm::IRBuilder<>& builder, ASTFunction& func) override;
    std::string ToString(const std::string& prefix) override;
};
