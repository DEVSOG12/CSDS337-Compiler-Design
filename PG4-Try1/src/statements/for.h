// ASTStatementFor.h

#pragma once

#include "../expression.h"
#include "../statement.h"

class ASTStatementFor : public ASTStatement {
public:
    // Create a new for statement.
    // body: The body of the for loop.
    // init: The initialization statement.
    // condition: The condition to check for each iteration.
    // increment: The increment statement.
    ASTStatementFor(std::unique_ptr<ASTStatement> body, std::unique_ptr<ASTStatement> init, std::unique_ptr<ASTExpression> condition, std::unique_ptr<ASTStatement> increment) : body(std::move(body)), init(std::move(init)), condition(std::move(condition)), increment(std::move(increment)) {}

    // Create a new for statement.
    // body: The body of the for loop.
    // init: The initialization statement.
    // condition: The condition to check for each iteration.
    // increment: The increment statement.
    static auto Create(std::unique_ptr<ASTStatement> body, std::unique_ptr<ASTStatement> init, std::unique_ptr<ASTExpression> condition, std::unique_ptr<ASTStatement> increment) {
        return std::make_unique<ASTStatementFor>(std::move(body), std::move(init), std::move(condition), std::move(increment));
    }

    // Virtual functions. See base class for details.
    std::unique_ptr<VarType> StatementReturnType(ASTFunction& func) override;
    void Compile(llvm::Module& mod, llvm::IRBuilder<>& builder, ASTFunction& func) override;
    std::string ToString(const std::string& prefix) override;

private:
    std::unique_ptr<ASTStatement> body;
    std::unique_ptr<ASTStatement> init;
    std::unique_ptr<ASTExpression> condition;
    std::unique_ptr<ASTStatement> increment;
};
