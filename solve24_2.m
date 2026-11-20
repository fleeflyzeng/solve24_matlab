function solve24_2(nums, target)
    % solve24([2 2 3 4])
    % solve24([15 2 6 16])
    % solve24([3 3 12 13], 36)

    if nargin < 1
        fprintf('未输入参数，使用默认测试：2 2 3 4\n');
        nums = [2 2 3 4];
    end
    if nargin < 2
        target = 24;
    end

    nums = nums(:).';
    perms_list = perms(nums);
    all_exprs = {};
    all_sigs = {};

    for p = 1:size(perms_list,1)
        x = perms_list(p,:);
        expr0 = cell(1,length(x));
        for k = 1:length(x)
            expr0{k} = num2str(x(k));
        end

        [res, ~] = search(x, expr0, target, 1e-6);
        if ~isempty(res)
            for i = 1:length(res)
                e = res{i};
                % 解析表达式树
                tree = parse_expr(e);
                % 归一化树
                norm_tree = normalize_tree(tree);
                % 生成签名（用于去重）
                sig = tree_to_string(norm_tree);
                % 检查重复
                isdup = false;
                for j = 1:length(all_sigs)
                    if strcmp(sig, all_sigs{j})
                        isdup = true;
                        break;
                    end
                end
                if ~isdup
                    all_exprs = [all_exprs; {e}];  %#ok<AGROW>
                    all_sigs = [all_sigs; {sig}];  %#ok<AGROW>
                end
            end
        end
    end

    if isempty(all_exprs)
        fprintf('无解！\n');
        return;
    end

    fprintf('共找到 %d 种不同算式：\n', length(all_exprs));
    for i = 1:length(all_exprs)
        fprintf('  %s = %g\n', all_exprs{i}, target);
    end
end

% ============ 递归搜索 ============
function [out_exprs, out_vals] = search(nums, exprs, target, tol)
    n = length(nums);
    out_exprs = {};
    out_vals  = [];

    if n == 1
        if abs(nums(1) - target) < tol
            out_exprs = {exprs{1}};
            out_vals  = nums(1);
        end
        return;
    end

    for i = 1:n
        for j = 1:n
            if i == j
                continue
            end

            a = nums(i);
            b = nums(j);

            idx = 1:n;
            idx(i) = [];
            new_nums = nums(idx);
            j_new = j - (j > i);

            ops = {'+','-','*','/'};
            for op = 1:4
                if op == 4 && abs(b) < tol
                    continue
                end

                switch op
                    case 1, v = a + b;
                    case 2, v = a - b;
                    case 3, v = a * b;
                    case 4, v = a / b;
                end

                new_nums(j_new) = v;
                new_exprs = exprs(idx);
                new_exprs{j_new} = ['(' exprs{i} ops{op} exprs{j} ')'];

                [sub_e, sub_v] = search(new_nums, new_exprs, target, tol);
                if ~isempty(sub_e)
                    out_exprs = [out_exprs; sub_e(:)];
                    out_vals  = [out_vals;  sub_v(:)];
                end
            end
        end
    end
end

% ============ 解析表达式为树 ============
function tree = parse_expr(s)
    s = strtrim(s);
    % 如果整体被括号包裹且是完整包裹，去掉
    while startsWith(s, '(') && endsWith(s, ')') && is_balanced(s)
        s = s(2:end-1);
    end
    % 找顶层运算符
    op_pos = find_top_op(s);
    if isempty(op_pos)
        tree = {'num', s};  % 叶子：数字
    else
        left = strtrim(s(1:op_pos-1));
        right = strtrim(s(op_pos+1:end));
        tree = {s(op_pos), parse_expr(left), parse_expr(right)};
    end
end

function balanced = is_balanced(s)
    depth = 0;
    for i = 1:length(s)
        if s(i) == '(', depth = depth + 1;
        elseif s(i) == ')', depth = depth - 1;
        end
        if depth < 0, balanced = false; return; end
    end
    balanced = (depth == 0);
end

function pos = find_top_op(s)
    depth = 0;
    pos = [];
    for i = 1:length(s)
        if s(i) == '(', depth = depth + 1;
        elseif s(i) == ')', depth = depth - 1;
        elseif depth == 0
            if s(i) == '+' || s(i) == '-'
                pos = i;
                return;
            elseif isempty(pos) && (s(i) == '*' || s(i) == '/')
                pos = i;
            end
        end
    end
end

% ============ 归一化树 ============
function t = normalize_tree(t)
    if ~iscell(t) || strcmp(t{1}, 'num')
        return;
    end
    % 递归归一化子节点
    left = normalize_tree(t{2});
    right = normalize_tree(t{3});
    op = t{1};

    % 交换律：+ 和 * 时，按字符串排序子节点
    if op == '+' || op == '*'
        % 展平同操作符合并：(a+b)+c -> {op, a, b, c}
        leaves = collect_flat(left, op);
        leaves = [leaves, collect_flat(right, op)];
        % 排序
        leaves = sort_leaves(leaves);
        % 重新构建左结合树
        t = leaves{1};
        for i = 2:length(leaves)
            t = {op, t, leaves{i}};
        end
    else
        t = {op, left, right};
    end
end

function leaves = collect_flat(t, op)
    if iscell(t) && ~strcmp(t{1}, 'num') && t{1} == op
        leaves = [collect_flat(t{2}, op), collect_flat(t{3}, op)];
    else
        leaves = {t};
    end
end

function leaves = sort_leaves(leaves)
    % 按字符串表示排序
    strs = cellfun(@tree_to_string, leaves, 'UniformOutput', false);
    [~, order] = sort(strs);
    leaves = leaves(order);
end

% ============ 树转字符串 ============
function s = tree_to_string(t)
    if strcmp(t{1}, 'num')
        s = t{2};
    else
        left = tree_to_string(t{2});
        right = tree_to_string(t{3});
        s = ['(' left t{1} right ')'];
    end
end