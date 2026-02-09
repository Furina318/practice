#!/bin/bash

# TODO 补充完成内容（不一定有TODO提示）并找出存在的问题修改

DEFAULT_BRANCH=""  
REMOTE_NAME=""   

# 颜色常量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

# 打印信息函数
print_info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# 检查是否为 Git 仓库
check_git_repo() {
    if ! git rev-parse --is-inside-work-tree &>/dev/null then
        print_error "当前目录不是 Git 仓库！"
        exit 1
    fi
    print_success "确认：当前目录是 Git 仓库"
}

# 检查远程仓库连接
check_remote() {
    if ! git remote | grep -q "$REMOTE_NAME" then
        print_error "远程仓库 $REMOTE_NAME 不存在！"
        exit 1
    fi
    # 测试远程连接
    if ! git fetch "$REMOTE_NAME" &>/dev/null; then
        print_warn "远程仓库 $REMOTE_NAME 连接可能异常（但继续执行）"
    else
        print_success "确认：远程仓库 $REMOTE_NAME 连接正常"
    fi
}

# TODO 选择分支（支持自主动选择或默认），如果分支不存在则询问是否创建
select_branch() {
    print_info "当前本地分支列表："
    git branch --list | sed 's/*/→/'  
}

# TODO 获取提交信息
get_commit_msg() {
    echo -e "\n${YELLOW}请输入提交信息：${NC}"
    read -r commit_msg
}

main() {
    print_info "===== Git 自动化脚本开始执行 ====="
    
    
    # 拉取远程最新代码（避免冲突）
    print_info "拉取 $REMOTE_NAME/$BRANCH 最新代码..."
    if git pull "$REMOTE_NAME" "$BRANCH"; then
        print_success "拉取最新代码成功"
    else
        print_error "拉取代码失败（可能有冲突），请手动处理后重新运行脚本"
        exit 1
    fi

    # TODO 检查是否有需要提交或者修改过的文件,如果没有则提示用户并退出脚本

    
    # 添加所有修改的文件
    print_info "添加所有修改的文件到暂存区..."
    git add .
    # TODO 检查添加结果
    
    # 获取并确认提交信息
    get_commit_msg
    print_info "确认提交信息：$COMMIT_MSG"
    echo -e "${YELLOW}是否确认提交？(y/n)${NC}"
    read -r confirm_commit
    if [ "$confirm_commit" != "y" ] && [ "$confirm_commit" != "Y" ]; then
        print_info "用户取消提交，脚本退出"
        exit 0
    fi
    
    # 提交代码
    print_info "提交代码..."
    if git commit -m "$COMMIT_MSG"; then
        print_success "代码提交成功"
    else
        print_error "提交失败（可能没有修改的文件）"
        exit 1
    fi
    
    # 推送代码到远程
    print_info "推送代码到 $REMOTE_NAME/$BRANCH..."
    echo -e "${YELLOW}是否强制推送？（谨慎使用！仅本地分支超前远程时用，输入 yes 表示强制推送，no为普通推送）：${NC}"
    read -r force_push
    if [ "$force_push" = "yes" ]; then
        print_warn "执行强制推送...（风险操作）"
        git push "$REMOTE_NAME" "$BRANCH"
    else
        git push -f "$REMOTE_NAME" "$BRANCH"
    fi
    # TODO　检查推送结果
    
    # TODO 打印脚本执行完成的提示 + 最终成功信息 
    
}

main