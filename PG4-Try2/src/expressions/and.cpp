#include "and.h"

std::unique_ptr<VarType> ASTExpressionAnd::ReturnType(ASTFunction& func)
{
    return VarTypeSimple::BoolType.Copy(); // Return type is bool.
}

bool ASTExpressionAnd::IsLValue(ASTFunction& func)
{
    return false; // AND expression result is not an L-Value.
}

llvm::Value* ASTExpressionAnd::Compile(llvm::IRBuilder<>& builder, ASTFunction& func)
{
    // Create basic blocks for control flow.
    llvm::Function* function = builder.GetInsertBlock()->getParent();
    llvm::BasicBlock* entryBlock = builder.GetInsertBlock();
    llvm::BasicBlock* checkRightBlock = llvm::BasicBlock::Create(builder.getContext(), "checkRight", function);
    llvm::BasicBlock* contBlock = llvm::BasicBlock::Create(builder.getContext(), "cont", function);

    // Evaluate the first operand.
    llvm::Value* result = operand1->Compile(builder, func);

    // If the first operand is true, evaluate the second operand.
    builder.CreateCondBr(result, checkRightBlock, contBlock);

    // Emit code for checking the second operand.
    builder.SetInsertPoint(checkRightBlock);
    llvm::Value* result2 = operand2->Compile(builder, func);
    builder.CreateBr(contBlock);

    // Set insertion point to the continuation block.
    builder.SetInsertPoint(contBlock);

    // Phi node to select the final result.
    llvm::PHINode* phiNode = builder.CreatePHI(llvm::Type::getInt1Ty(builder.getContext()), 2);
    phiNode->addIncoming(llvm::ConstantInt::getFalse(builder.getContext()), entryBlock);
    phiNode->addIncoming(result2, checkRightBlock);

    return phiNode;
}

std::string ASTExpressionAnd::ToString(const std::string& prefix)
{
    std::string ret = "&&\n";
    ret += prefix + "├──" + operand1->ToString(prefix + "│  ");
    ret += prefix + "└──" + operand2->ToString(prefix + "   ");
    return ret;
}
