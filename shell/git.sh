#!/bin/bash

DEFAULT_BRANCH="tools"  # 默认分支
REMOTE_NAME="origin"   # 远程仓库名称

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

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
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        print_error "当前目录不是 Git 仓库！"
        exit 1
    fi
    print_success "确认：当前目录是 Git 仓库"
}

# 检查远程仓库连接
check_remote() {
    if ! git remote | grep -q "$REMOTE_NAME"; then
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

# 选择分支（支持自定义或默认）
select_branch() {
    print_info "当前本地分支列表："
    git branch --list | sed 's/*/→/'  
    echo -e "\n${YELLOW}请输入要操作的分支名（默认：$DEFAULT_BRANCH）：${NC}"
    read -r input_branch
    # 如果用户没输入，使用默认分支
    if [ -z "$input_branch" ]; then
        BRANCH="$DEFAULT_BRANCH"
    else
        BRANCH="$input_branch"
    fi
    # 检查分支是否存在
    if ! git branch --list "$BRANCH" &>/dev/null; then
        print_warn "分支 $BRANCH 不存在，是否创建并切换？(y/n)"
        read -r create_branch
        if [ "$create_branch" = "y" ] || [ "$create_branch" = "Y" ]; then
            git checkout -b "$BRANCH"
            print_success "已创建并切换到分支：$BRANCH"
        else
            print_error "分支不存在，退出脚本"
            exit 1
        fi
    else
        # 切换到目标分支
        git checkout "$BRANCH"
        print_success "已切换到分支：$BRANCH"
    fi
}

# 获取提交信息
get_commit_msg() {
    echo -e "\n${YELLOW}请输入提交信息：${NC}"
    read -r commit_msg
    # 检查提交信息是否为空
    while [ -z "$commit_msg" ]; do
        print_error "提交信息不能为空！"
        echo -e "${YELLOW}请重新输入提交信息：${NC}"
        read -r commit_msg
    done
    COMMIT_MSG="$commit_msg"
}

main() {
    print_info "===== Git 自动化脚本开始执行 ====="

    # 检查 Git 仓库
    check_git_repo
    
    # 检查远程仓库
    check_remote
    
    # 选择/切换分支
    select_branch
    
    # 拉取远程最新代码（避免冲突）
    print_info "拉取 $REMOTE_NAME/$BRANCH 最新代码..."
    if git pull "$REMOTE_NAME" "$BRANCH"; then
        print_success "拉取最新代码成功"
    else
        print_error "拉取代码失败（可能有冲突），请手动处理后重新运行脚本"
        exit 1
    fi

    # 检查是否有需要提交或者修改过的文件
    if  git status | grep "working tree clean"; then
        echo "没有内容需要提交"
    fi
    
    # 添加所有修改的文件
    print_info "添加所有修改的文件到暂存区..."
    git add .
    # 检查添加结果
    if [ $? -eq 0 ]; then
        print_success "文件添加成功"
    else
        print_error "文件添加失败"
        exit 1
    fi
    
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
    echo -e "${YELLOW}是否强制推送？（谨慎使用！仅本地分支超前远程时用，输入 y 表示强制推送，否则为普通推送）：${NC}"
    read -r force_push
    if [ "$force_push" = "y" ]; then
        print_warn "执行强制推送...（风险操作）"
        git push -f "$REMOTE_NAME" "$BRANCH"
    else
        git push "$REMOTE_NAME" "$BRANCH"
    fi
    # 检查推送结果
    if [ $? -eq 0 ]; then
        print_success "代码推送成功！"
    else
        print_error "推送失败，请检查网络或分支权限"
        exit 1
    fi
    
    print_info "===== Git 自动化脚本执行完成 ====="
    print_success "当前分支：$BRANCH，提交信息：$COMMIT_MSG"
}

quick_git() {
    COMMIT_MSG=$(date +"%Y-%m-%d %H:%M:%S")
    git add .
    git commit -m "Auto commit : $COMMIT_MSG"
    print_success "Quick Git 成功提交"
}

if [ "$1" == "q" ]; then
    quick_git
else
    main
fi

# main