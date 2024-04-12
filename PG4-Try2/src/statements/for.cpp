#include "for.h"

std::unique_ptr<VarType> ASTStatementFor::StatementReturnType(ASTFunction& func)
{
    // It is completely possible for a for's condition to never be true, so even if it does return something, it's not confirmed.
    return nullptr;
}

void ASTStatementFor::Compile(llvm::Module& mod, llvm::IRBuilder<>& builder, ASTFunction& func)
{
    // Create basic blocks for control flow.
    llvm::Function* function = builder.GetInsertBlock()->getParent();
    llvm::BasicBlock* entryBlock = builder.GetInsertBlock();
    llvm::BasicBlock* conditionBlock = llvm::BasicBlock::Create(builder.getContext(), "condition", function);
    llvm::BasicBlock* bodyBlock = llvm::BasicBlock::Create(builder.getContext(), "body", function);
    llvm::BasicBlock* incrementBlock = llvm::BasicBlock::Create(builder.getContext(), "increment", function);
    llvm::BasicBlock* endBlock = llvm::BasicBlock::Create(builder.getContext(), "end", function);

    // If the initialization statement exists, compile it.
    if (init)
    {
        init->Compile(mod, builder, func);
    }

    // Jump to the condition block.
    builder.CreateBr(conditionBlock);

    // Compile the condition.
    builder.SetInsertPoint(conditionBlock);
    llvm::Value* conditionValue = nullptr;
    if (condition)
    {
        conditionValue = condition->CompileRValue(builder, func);
    }
    else
    {
        // If the condition is not provided, just jump to the body block.
        builder.CreateBr(bodyBlock);
    }

    // Check the condition. If it's false, jump to the end block.
    if (conditionValue)
    {
        builder.CreateCondBr(conditionValue, bodyBlock, endBlock);
    }

    // Compile the body block.
    builder.SetInsertPoint(bodyBlock);
    if (body)
    {
        body->Compile(mod, builder, func);
    }

    // Jump to the increment block.
    builder.CreateBr(incrementBlock);

    // Compile the increment block.
    builder.SetInsertPoint(incrementBlock);
    if (increment)
    {
        increment->Compile(mod, builder, func);
    }

    // Jump back to the condition block to check the condition again.
    builder.CreateBr(conditionBlock);

    // Set the insert point to the end block.
    builder.SetInsertPoint(endBlock);
}

std::string ASTStatementFor::ToString(const std::string& prefix)
{
    std::string output = "for\n";
    output += prefix + "├──" + (init ? init->ToString(prefix + "│  ") : "null") + "\n";
    output += prefix + "├──" + (condition ? condition->ToString(prefix + "│  ") : "null") + "\n";
    output += prefix + "├──" + (increment ? increment->ToString(prefix + "│  ") : "null") + "\n";
    output += prefix + "└──" + (body ? body->ToString(prefix + "   ") : "null") + "\n";
    return output;
}   