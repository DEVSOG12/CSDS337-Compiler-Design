#ifndef PARSETREE_H
#define PARSETREE_H

// Define your tree node structure
typedef struct TreeNode {
    char* label;
    struct TreeNode** children;
    int num_children;
} TreeNode;

// Function prototypes for creating and manipulating tree nodes
TreeNode* createTreeNode(const char* label);
void addChild(TreeNode* parent, TreeNode* child);
TreeNode* createLeafNode(const char* label);
void printTree(TreeNode* root);
void freeTree(TreeNode* root);

#endif /* PARSETREE_H */
