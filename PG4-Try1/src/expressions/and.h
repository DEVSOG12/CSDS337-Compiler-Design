// and.h

#pragma once

#include "../expression.h"

// An expression that performs logical AND operation.
class ASTExpressionAnd : public ASTExpression {
public:
    // Create a new logical AND expression.
    // operand1: First operand.
    // operand2: Second operand.
    ASTExpressionAnd(std::unique_ptr<ASTExpression> operand1, std::unique_ptr<ASTExpression> operand2)
            : operand1(std::move(operand1)), operand2(std::move(operand2)) {}

    // Create a new logical AND expression.
    // operand1: First operand.
    // operand2: Second operand.
    static std::unique_ptr<ASTExpressionAnd> Create(std::unique_ptr<ASTExpression> operand1, std::unique_ptr<ASTExpression> operand2) {
        return std::make_unique<ASTExpressionAnd>(std::move(operand1), std::move(operand2));
    }

    // Virtual functions. See base class for details.
    std::unique_ptr<VarType> ReturnType(ASTFunction& func) override;
    bool IsLValue(ASTFunction& func) override;
    llvm::Value* Compile(llvm::IRBuilder<>& builder, ASTFunction& func) override;
    std::string ToString(const std::string& prefix) override;

private:
    // First operand.
    std::unique_ptr<ASTExpression> operand1;
    // Second operand.
    std::unique_ptr<ASTExpression> operand2;
};
