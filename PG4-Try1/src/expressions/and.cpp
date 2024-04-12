// and.cpp

#include "and.h"

std::unique_ptr<VarType> ASTExpressionAnd::ReturnType(ASTFunction& func) {
    return VarTypeSimple::BoolType.Copy();
}

bool ASTExpressionAnd::IsLValue(ASTFunction& func) {
    return false;
}

llvm::Value* ASTExpressionAnd::Compile(llvm::IRBuilder<>& builder, ASTFunction& func) {
    // Create basic blocks
    llvm::BasicBlock* entryBlock = builder.GetInsertBlock();
    llvm::BasicBlock* evalSecondBlock = llvm::BasicBlock::Create(builder.getContext(), "and_eval_second", entryBlock->getParent());
    llvm::BasicBlock* continueBlock = llvm::BasicBlock::Create(builder.getContext(), "and_continue", entryBlock->getParent());

    // Jump to evaluation of second operand
    builder.CreateBr(entryBlock);
    builder.SetInsertPoint(entryBlock);
    llvm::Value* firstOperand = operand1->Compile(builder, func);
    builder.CreateCondBr(firstOperand, evalSecondBlock, continueBlock);

    // Evaluate second operand
    builder.SetInsertPoint(evalSecondBlock);
    llvm::Value* secondOperand = operand2->Compile(builder, func);
    builder.CreateBr(continueBlock);

    // Continue after evaluation
    builder.SetInsertPoint(continueBlock);

    // Logical AND operation
    llvm::PHINode* phiNode = builder.CreatePHI(builder.getInt1Ty(), 2);
    phiNode->addIncoming(builder.getInt1(true), entryBlock);
    phiNode->addIncoming(secondOperand, evalSecondBlock);
    return phiNode;
}


std::string ASTExpressionAnd::ToString(const std::string& prefix) {
    std::string str = prefix + "Logical And\n";
    str += operand1->ToString(prefix + "  ");
    str += operand2->ToString(prefix + "  ");
    return str;
}
