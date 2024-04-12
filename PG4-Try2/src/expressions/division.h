#pragma once

#include "../expression.h"

// An expression that divides one operand by another.
class ASTExpressionDivision : public ASTExpression
{
    // Operands to work with.
    std::unique_ptr<ASTExpression> a1;
    std::unique_ptr<ASTExpression> a2;

    // Return type to cache.
    VarTypeSimple* returnType = nullptr;

public:

    // Create a new division expression.
    // a1: Numerator expression.
    // a2: Denominator expression.
    ASTExpressionDivision(std::unique_ptr<ASTExpression> a1, std::unique_ptr<ASTExpression> a2) : a1(std::move(a1)), a2(std::move(a2)) {}

    // Create a new division expression.
    // a1: Numerator expression.
    // a2: Denominator expression.
    static auto Create(std::unique_ptr<ASTExpression> a1, std::unique_ptr<ASTExpression> a2)
    {
        return std::make_unique<ASTExpressionDivision>(std::move(a1), std::move(a2));
    }

    // Virtual functions. See base class for details.
    std::unique_ptr<VarType> ReturnType(ASTFunction& func) override;
    bool IsLValue(ASTFunction& func) override;
    llvm::Value* Compile(llvm::IRBuilder<>& builder, ASTFunction& func) override;
    std::string ToString(const std::string& prefix) override;
};
