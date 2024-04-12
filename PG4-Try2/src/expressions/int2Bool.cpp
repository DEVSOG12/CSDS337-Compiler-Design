#include "int2Bool.h"

std::unique_ptr<VarType> ASTExpressionInt2Bool::ReturnType(ASTFunction& func)
{
    return VarTypeSimple::BoolType.Copy(); // Int2Bool returns a bool.
}

bool ASTExpressionInt2Bool::IsLValue(ASTFunction& func)
{
    return false; // Int2Bool expression always results in an R-Value.
}

llvm::Value* ASTExpressionInt2Bool::Compile(llvm::IRBuilder<>& builder, ASTFunction& func)
{
    // Make sure operand is a valid int type.
    if (!operand->ReturnType(func)->Equals(&VarTypeSimple::IntType))
        throw std::runtime_error("ERROR: Expected integer operand in int2bool but got another type instead!");

    // Get the integer value.
    auto intValue = operand->CompileRValue(builder, func);

    // Convert the integer to a boolean value.
    // We consider any non-zero integer as true, and zero as false.
    return builder.CreateICmpNE(intValue, llvm::ConstantInt::get(intValue->getType(), 0));
}

std::string ASTExpressionInt2Bool::ToString(const std::string& prefix)
{
    return "int2bool\n" + prefix + "└──" + operand->ToString(prefix + "   ");
}
