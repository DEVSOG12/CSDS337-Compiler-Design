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


    // Hello World
    FunctionType *helloWorldFuncType = FunctionType::get(Type::getVoidTy(context), false);
    Function *helloWorldFunc = Function::Create(helloWorldFuncType, Function::ExternalLinkage, "helloWorld", mod);
    entry = BasicBlock::Create(context, "entry", helloWorldFunc);
    builder.SetInsertPoint(entry);
    Value *helloWorldStr = builder.CreateGlobalStringPtr("Hello, World!\n");
    builder.CreateCall(mod->getOrInsertFunction("puts", Type::getInt32Ty(context), Type::getInt8PtrTy(context), nullptr), helloWorldStr);
    builder.CreateRetVoid();
    verifyFunction(*helloWorldFunc);

    // Make a function’s arguments mutable local to the function by storing them into stack variables.
    FunctionType *mutableArgsFuncType = FunctionType::get(Type::getInt32Ty(context), {Type::getInt32Ty(context), Type::getInt32Ty(context)}, false);
    Function *mutableArgsFunc = Function::Create(mutableArgsFuncType, Function::ExternalLinkage, "mutableArgs", mod);
    entry = BasicBlock::Create(context, "entry", mutableArgsFunc);
    builder.SetInsertPoint(entry);
    Argument *mutableArg1 = &*mutableArgsFunc->arg_begin();
    Argument *mutableArg2 = &*(mutableArgsFunc->arg_begin() + 1);
    AllocaInst *mutableArg1Stack = builder.CreateAlloca(Type::getInt32Ty(context));
    AllocaInst *mutableArg2Stack = builder.CreateAlloca(Type::getInt32Ty(context));
    builder.CreateStore(mutableArg1, mutableArg1Stack);
    builder.CreateStore(mutableArg2, mutableArg2Stack);
    Value *sumMutableArgs = builder.CreateAdd(builder.CreateLoad(Type::getInt32Ty(context), mutableArg1Stack), builder.CreateLoad(Type::getInt32Ty(context), mutableArg2Stack));
    builder.CreateRet(sumMutableArgs);
    verifyFunction(*mutableArgsFunc);

    // Declare the ‘malloc‘ and ‘free‘ functions and call them in diﬀerent functions to play with heap memory.
    FunctionType *mallocFuncType = FunctionType::get(Type::getInt8PtrTy(context), {Type::getInt64Ty(context)}, false);
    Function *mallocFunc = Function::Create(mallocFuncType, Function::ExternalLinkage, "malloc", mod);
    FunctionType *freeFuncType = FunctionType::get(Type::getVoidTy(context), {Type::getInt8PtrTy(context)}, false);
    Function *freeFunc = Function::Create(freeFuncType, Function::ExternalLinkage, "free", mod);
    FunctionType *heapMemoryFuncType = FunctionType::get(Type::getInt32Ty(context), false);
    Function *heapMemoryFunc = Function::Create(heapMemoryFuncType, Function::ExternalLinkage, "heapMemory", mod);
    entry = BasicBlock::Create(context, "entry", heapMemoryFunc);
    builder.SetInsertPoint(entry);
    Value *mallocCall = builder.CreateCall(mallocFunc, ConstantInt::get(Type::getInt64Ty(context), 8));
    builder.CreateCall(freeFunc, mallocCall);
    builder.CreateRet(ConstantInt::get(Type::getInt32Ty(context), 0));
    verifyFunction(*heapMemoryFunc);

    // Make a while or for loop with LLVM.
    FunctionType *whileLoopFuncType = FunctionType::get(Type::getInt32Ty(context), false);
    Function *whileLoopFunc = Function::Create(whileLoopFuncType, Function::ExternalLinkage, "whileLoop", mod);
    entry = BasicBlock::Create(context, "entry", whileLoopFunc);
    builder.SetInsertPoint(entry);
    AllocaInst *whileLoopVar = builder.CreateAlloca(Type::getInt32Ty(context));
    builder.CreateStore(ConstantInt::get(Type::getInt32Ty(context), 0), whileLoopVar);
    BasicBlock *whileCond = BasicBlock::Create(context, "whileCond", whileLoopFunc);
    BasicBlock *whileBody = BasicBlock::Create(context, "whileBody", whileLoopFunc);
    BasicBlock *whileEnd = BasicBlock::Create(context, "whileEnd", whileLoopFunc);
    builder.CreateBr(whileCond);
    builder.SetInsertPoint(whileCond);
    Value *whileCondVal = builder.CreateLoad(Type::getInt32Ty(context), whileLoopVar);
    builder.CreateCondBr(builder.CreateICmpSLT(whileCondVal, ConstantInt::get(Type::getInt32Ty(context), 10)), whileBody, whileEnd);
    builder.SetInsertPoint(whileBody);
    Value *whileBodyVal = builder.CreateLoad(Type::getInt32Ty(context), whileLoopVar);
    builder.CreateStore(builder.CreateAdd(whileBodyVal, ConstantInt::get(Type::getInt32Ty(context), 1)), whileLoopVar);
    builder.CreateBr(whileCond);
    builder.SetInsertPoint(whileEnd);
    builder.CreateRet(builder.CreateLoad(Type::getInt32Ty(context), whileLoopVar));
    verifyFunction(*whileLoopFunc);


    return 0;
}
