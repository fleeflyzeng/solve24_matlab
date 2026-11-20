function solve24_2(nums, target)
    % solve24([15 2 6 16])
    % solve24([3 3 12 13], 36)
    % 支持重复数字，自动合并本质相同的解

    if nargin < 1
        fprintf('未输入参数，使用默认测试：15 2 6 16\n');
        nums = [15 2 6 16];
    end
    if nargin < 2
        target = 24;
    end

    nums = nums(:).';
    perms_list = perms(nums);
    all_exprs = {};
    all_norm = {};

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
                % 生成规范化版本：把数字替换为排序索引
                norm_e = canonicalize(e, x);
                % 检查是否已存在
                isdup = false;
                for j = 1:length(all_norm)
                    if strcmp(norm_e, all_norm{j})
                        isdup = true;
                        break;
                    end
                end
                if ~isdup
                    all_exprs = [all_exprs; {e}];  %#ok<AGROW>
                    all_norm = [all_norm; {norm_e}];  %#ok<AGROW>
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

% ============ 规范化：把数字替换为索引 ============
function s = canonicalize(e, x)
    % 把表达式中的数字替换为 {idx}，idx 按数值排序
    % 例如 x=[3 3 12 13]，3->0, 3->0, 12->1, 13->2
    % 这样交换相同数字位置的表达式归一化为同一个
    [~, order] = sort(x);
    % 给相同值分配相同索引
    idx_map = zeros(size(x));
    next_id = 0;
    for i = 1:length(x)
        if i > 1 && abs(x(order(i)) - x(order(i-1))) < 1e-10
            idx_map(order(i)) = idx_map(order(i-1));
        else
            idx_map(order(i)) = next_id;
            next_id = next_id + 1;
        end
    end

    s = e;
    % 按长度降序替换，避免 "12" 被 "1" 和 "2" 误替换
    tokens = {};
    for i = 1:length(x)
        tokens{i} = num2str(x(i));
    end
    [~, len_order] = sort(cellfun(@length, tokens), 'descend');
    for i = len_order
        s = strrep(s, tokens{i}, ['{' num2str(idx_map(i)) '}']);
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