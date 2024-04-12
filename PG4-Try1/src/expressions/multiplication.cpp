// multiplication.cpp

#include "multiplication.h"

std::unique_ptr<VarType> ASTExpressionMultiplication::ReturnType(ASTFunction& func) {
    VarTypeSimple* typeA = dynamic_cast<VarTypeSimple*>(a1->ReturnType(func).get());
    VarTypeSimple* typeB = dynamic_cast<VarTypeSimple*>(a2->ReturnType(func).get());

    if (!typeA || !typeB)
        throw std::runtime_error("ERROR: Invalid operand types in multiplication expression!");

    // Ensure both operands are of the same type
    if (!typeA->Equals(typeB))
        throw std::runtime_error("ERROR: Operands of multiplication expression must have the same type!");

    return std::make_unique<VarTypeSimple>(*typeA);
}

bool ASTExpressionMultiplication::IsLValue(ASTFunction& func) {
    return false;
}

llvm::Value* ASTExpressionMultiplication::Compile(llvm::IRBuilder<>& builder, ASTFunction& func) {
    llvm::Value* leftValue = a1->Compile(builder, func);
    llvm::Value* rightValue = a2->Compile(builder, func);

    // Perform multiplication
    return builder.CreateMul(leftValue, rightValue);
}

std::string ASTExpressionMultiplication::ToString(const std::string& prefix) {
    std::string str = prefix + "Multiplication\n";
    str += a1->ToString(prefix + "  ");
    str += a2->ToString(prefix + "  ");
    return str;
}
