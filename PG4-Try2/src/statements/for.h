#pragma once

#include "../expression.h"
#include "../statement.h"

// For loop statement.
class ASTStatementFor : public ASTStatement
{
    // Initialization statement.
    std::unique_ptr<ASTStatement> init;

    // Condition to check.
    std::unique_ptr<ASTExpression> condition;

    // Increment statement.
    std::unique_ptr<ASTStatement> increment;

    // Body of the loop.
    std::unique_ptr<ASTStatement> body;

public:
    // Create a new for statement.
    // init: Initialization statement.
    // condition: Condition to check.
    // increment: Increment statement.
    // body: Body of the loop.
    ASTStatementFor(std::unique_ptr<ASTStatement> init,
                    std::unique_ptr<ASTExpression> condition,
                    std::unique_ptr<ASTStatement> increment,
                    std::unique_ptr<ASTStatement> body)
        : init(std::move(init)), condition(std::move(condition)), increment(std::move(increment)), body(std::move(body)) {}

    // Create a new for statement.
    // init: Initialization statement.
    // condition: Condition to check.
    // increment: Increment statement.
    // body: Body of the loop.
    static auto Create(std::unique_ptr<ASTStatement> init,
                       std::unique_ptr<ASTExpression> condition,
                       std::unique_ptr<ASTStatement> increment,
                       std::unique_ptr<ASTStatement> body)
    {
        return std::make_unique<ASTStatementFor>(std::move(init), std::move(condition), std::move(increment), std::move(body));
    }

    // Virtual functions. See base class for details.
    std::unique_ptr<VarType> StatementReturnType(ASTFunction& func) override;
    void Compile(llvm::Module& mod, llvm::IRBuilder<>& builder, ASTFunction& func) override;
    std::string ToString(const std::string& prefix) override;
};