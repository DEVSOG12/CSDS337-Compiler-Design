// negative.cpp

#include "negative.h"

std::unique_ptr<VarType> ASTExpressionNegation::ReturnType(ASTFunction& func) {
    VarTypeSimple* operandType = dynamic_cast<VarTypeSimple*>(operand->ReturnType(func).get());
    if (!operandType)
        throw std::runtime_error("ERROR: Invalid operand type in negation expression!");

    return std::make_unique<VarTypeSimple>(*operandType);
}

bool ASTExpressionNegation::IsLValue(ASTFunction& func) {
    return false;
}

llvm::Value* ASTExpressionNegation::Compile(llvm::IRBuilder<>& builder, ASTFunction& func) {
    llvm::Value* operandValue = operand->Compile(builder, func);

    // Perform negation
    return builder.CreateNeg(operandValue);
}

std::string ASTExpressionNegation::ToString(const std::string& prefix) {
    return "Negation\n" + prefix + "└──" + operand->ToString(prefix + "   ");
}
