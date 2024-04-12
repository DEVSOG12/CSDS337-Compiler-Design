#include "../function.h"

#include "for.h"

std::unique_ptr<VarType> ASTStatementFor::StatementReturnType(ASTFunction& func)
{
    // The return type of a for statement is typically void, as it doesn't return a value.
    return nullptr;
}

void ASTStatementFor::Compile(llvm::Module& mod, llvm::IRBuilder<>& builder, ASTFunction& func)
{
    auto bodyBB  = llvm::BasicBlock::Create(mod.getContext(), "forbody", builder.GetInsertBlock()->getParent());
    // Compile the initialization statement.
    init->Compile(mod, builder, func);

    // Create basic blocks for the loop.
    llvm::Function* llvmFunc = builder.GetInsertBlock()->getParent();
    llvm::BasicBlock* loopBB = llvm::BasicBlock::Create(mod.getContext(), "loop", llvmFunc);
    llvm::BasicBlock* afterBB = llvm::BasicBlock::Create(mod.getContext(), "afterloop", llvmFunc);

    // Jump to the loop block.
    builder.CreateBr(loopBB);
    builder.SetInsertPoint(loopBB);

    // Compile the condition expression.
    llvm::Value* condValue = condition->Compile(builder, func);

    // Convert the condition value to a boolean (i1) type.
    condValue = builder.CreateICmpNE(condValue, llvm::ConstantInt::get(mod.getContext(), llvm::APInt(1, 0)), "loopcond");

    // Create a branch instruction based on the condition.
    builder.CreateCondBr(condValue, bodyBB, afterBB);

    // Set the insertion point for the loop body.
    builder.SetInsertPoint(bodyBB);

    // Compile the loop body.
    body->Compile(mod, builder, func);

    // Compile the increment statement.
    increment->Compile(mod, builder, func);

    // Jump back to the loop block.
    builder.CreateBr(loopBB);

    // Set the insertion point after the loop.
    builder.SetInsertPoint(afterBB);
}

std::string ASTStatementFor::ToString(const std::string& prefix)
{
    // Generate a string representation of the for statement.
    std::string result = prefix + "For Statement\n";
    result += prefix + "Initialization:\n" + init->ToString(prefix + "  ");
    result += prefix + "Condition:\n" + condition->ToString(prefix + "  ");
    result += prefix + "Increment:\n" + increment->ToString(prefix + "  ");
    result += prefix + "Body:\n" + body->ToString(prefix + "  ");
    return result;
}