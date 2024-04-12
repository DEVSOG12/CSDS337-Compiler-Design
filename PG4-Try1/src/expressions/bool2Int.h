// bool2Int.h

#pragma once

#include "../expression.h"

// An expression that converts a boolean value to an integer.
class ASTExpressionBool2Int : public ASTExpression {
public:
    // Create a new boolean to integer conversion expression.
    // expr: The expression to convert to an integer.
    ASTExpressionBool2Int(std::unique_ptr<ASTExpression> expr) : expr(std::move(expr)) {}

    // Create a new boolean to integer conversion expression.
    // expr: The expression to convert to an integer.
    static std::unique_ptr<ASTExpressionBool2Int> Create(std::unique_ptr<ASTExpression> expr) {
        return std::make_unique<ASTExpressionBool2Int>(std::move(expr));
    }

    // Virtual functions. See base class for details.
    std::unique_ptr<VarType> ReturnType(ASTFunction& func) override;
    bool IsLValue(ASTFunction& func) override;
    llvm::Value* Compile(llvm::IRBuilder<>& builder, ASTFunction& func) override;
    std::string ToString(const std::string& prefix) override;

private:
    // The expression to convert to an integer.
    std::unique_ptr<ASTExpression> expr;
};
