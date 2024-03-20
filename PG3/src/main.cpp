#include <iostream>
#include <llvm/Bitcode/BitcodeWriter.h>
#include <llvm/IR/IRBuilder.h>
#include <llvm/IR/LegacyPassManager.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/Verifier.h>
#include <llvm/Transforms/Scalar.h>
#include <llvm/Transforms/Scalar/GVN.h>
#include <llvm/Transforms/Utils.h>
#include <llvm/Support/FileSystem.h>



using namespace llvm;

int main() {
    LLVMContext context;
    auto *mod = new Module("sampleMod", context);

    // Problem 2: Create a function named `simple` that returns 0.
    FunctionType *simpleFuncType = FunctionType::get(Type::getInt32Ty(context), false);
    Function *simpleFunc = Function::Create(simpleFuncType, Function::ExternalLinkage, "simple", mod);
    BasicBlock *entry = BasicBlock::Create(context, "entry", simpleFunc);
    IRBuilder<> builder(entry);
    builder.CreateRet(ConstantInt::get(Type::getInt32Ty(context), 0));
    verifyFunction(*simpleFunc);

    // Problem 3: Create a function named `add` that adds two 32-bit integers.
    FunctionType *addFuncType = FunctionType::get(Type::getInt32Ty(context), {Type::getInt32Ty(context), Type::getInt32Ty(context)}, false);
    Function *addFunc = Function::Create(addFuncType, Function::ExternalLinkage, "add", mod);
    entry = BasicBlock::Create(context, "entry", addFunc);
    builder.SetInsertPoint(entry);
    Argument *arg1 = &*addFunc->arg_begin();
    Argument *arg2 = &*(addFunc->arg_begin() + 1);
    Value *sum = builder.CreateAdd(arg1, arg2);
    builder.CreateRet(sum);
    verifyFunction(*addFunc);

    // Problem 4: Create a function named `addIntFloat` that adds a 32-bit int and a float.
    FunctionType *addIntFloatFuncType = FunctionType::get(Type::getFloatTy(context), {Type::getInt32Ty(context), Type::getFloatTy(context)}, false);
    Function *addIntFloatFunc = Function::Create(addIntFloatFuncType, Function::ExternalLinkage, "addIntFloat", mod);
    entry = BasicBlock::Create(context, "entry", addIntFloatFunc);
    builder.SetInsertPoint(entry);
    Argument *argInt = &*addIntFloatFunc->arg_begin();
    Argument *argFloat = &*(addIntFloatFunc->arg_begin() + 1);
    Value *floatFromInt = builder.CreateSIToFP(argInt, Type::getFloatTy(context));
    Value *result = builder.CreateFAdd(floatFromInt, argFloat);
    builder.CreateRet(result);
    verifyFunction(*addIntFloatFunc);

    // Problem 5: Create a function named `conditional` with control flow.
//    Adding things together in a linear fashion is fun, but what about temporary variables and control ﬂow? Create a function called ‘conditional‘ , it will take a boolean input ( 1-bit integer) and output a 32-bit integer. Allocate a mutable variable stored on the stack in the entry block. If the input parameter is true, store a ‘3‘ to the variable, else store a ‘5‘ . Using only one add instruction in the entire function, return the value of the stored variable added with ‘1 1‘ . The function should return ‘14‘ if the parameter is true or ‘16‘ if it is false. **DO NOTOPTIMIZE THIS FUNCTION YOURSELF.** The point of this part is to make sure you understand control ﬂow and mutable stack variable
    FunctionType *conditionalFuncType = FunctionType::get(Type::getInt32Ty(context), {Type::getInt1Ty(context)}, false);
    Function *conditionalFunc = Function::Create(conditionalFuncType, Function::ExternalLinkage, "conditional", mod);
    entry = BasicBlock::Create(context, "entry", conditionalFunc);
    builder.SetInsertPoint(entry);
    Argument *condArg = &*conditionalFunc->arg_begin();
    AllocaInst *mutableVar = builder.CreateAlloca(Type::getInt32Ty(context));
    Value *three = ConstantInt::get(Type::getInt32Ty(context), 3);
    Value *five = ConstantInt::get(Type::getInt32Ty(context), 5);
    Value *one = ConstantInt::get(Type::getInt32Ty(context), 11);
    builder.CreateStore(builder.CreateSelect(condArg, three, five), mutableVar);
        Value *res = builder.CreateAdd(builder.CreateLoad(Type::getInt32Ty(context), mutableVar), one);
    builder.CreateRet(res);
    verifyFunction(*conditionalFunc);





    // Problem 6: Create a function named `oneTwoPhi` with phi nodes.
    FunctionType *oneTwoPhiFuncType = FunctionType::get(Type::getInt32Ty(context), {Type::getInt1Ty(context)}, false);
    Function *oneTwoPhiFunc = Function::Create(oneTwoPhiFuncType, Function::ExternalLinkage, "oneTwoPhi", mod);
    entry = BasicBlock::Create(context, "entry", oneTwoPhiFunc);
    builder.SetInsertPoint(entry);
    Argument *phiCondArg = &*oneTwoPhiFunc->arg_begin();
    BasicBlock *trueBlock = BasicBlock::Create(context, "true", oneTwoPhiFunc);
    BasicBlock *falseBlock = BasicBlock::Create(context, "false", oneTwoPhiFunc);
    BasicBlock *mergeBlock = BasicBlock::Create(context, "merge", oneTwoPhiFunc);
    builder.CreateCondBr(phiCondArg, trueBlock, falseBlock);

    builder.SetInsertPoint(trueBlock);
    builder.CreateBr(mergeBlock);

    builder.SetInsertPoint(falseBlock);
    builder.CreateBr(mergeBlock);

    builder.SetInsertPoint(mergeBlock);
    PHINode *phiNode = builder.CreatePHI(Type::getInt32Ty(context), 2);
    phiNode->addIncoming(ConstantInt::get(Type::getInt32Ty(context), 3), trueBlock);
    phiNode->addIncoming(ConstantInt::get(Type::getInt32Ty(context), 5), falseBlock);
    Value *resultPhi = builder.CreateAdd(phiNode, ConstantInt::get(Type::getInt32Ty(context), 11));
    builder.CreateRet(resultPhi);
    verifyFunction(*oneTwoPhiFunc);

    // Problem 7: Create a function named `selection` with the select instruction.
    FunctionType *selectionFuncType = FunctionType::get(Type::getInt32Ty(context), {Type::getInt1Ty(context)}, false);
    Function *selectionFunc = Function::Create(selectionFuncType, Function::ExternalLinkage, "selection", mod);
    entry = BasicBlock::Create(context, "entry", selectionFunc);
    builder.SetInsertPoint(entry);
    Argument *selCondArg = &*selectionFunc->arg_begin();
    Value *valueSelected = builder.CreateSelect(selCondArg, ConstantInt::get(Type::getInt32Ty(context), 3), ConstantInt::get(Type::getInt32Ty(context), 5));
    Value *resultSelection = builder.CreateAdd(valueSelected, ConstantInt::get(Type::getInt32Ty(context), 11));
    builder.CreateRet(resultSelection);
    verifyFunction(*selectionFunc);

    // Step 1 - Export LLVM module.
    std::error_code err;
    raw_fd_ostream outLl("sampleMod.ll", err);
    mod->print(outLl, nullptr);
    outLl.close();

    // Writing bitcode to file.
    std::error_code EC;
    llvm::raw_fd_ostream bitcodeOS("sampleMod.bc", EC, llvm::sys::fs::OF_None);
    WriteBitcodeToFile(*mod, bitcodeOS);
    bitcodeOS.flush();

    // Step 8 - Add LLVM legacy function pass manager and run passes on the functions.
    legacy::FunctionPassManager fpm(mod);
    fpm.add(createPromoteMemoryToRegisterPass());
    fpm.add(createReassociatePass());
    fpm.add(createGVNPass());
    fpm.add(createCFGSimplificationPass());
    fpm.doInitialization();

    for (auto &func : *mod) {
        fpm.run(func);
    }

    return 0;
}
