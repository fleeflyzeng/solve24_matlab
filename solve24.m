function solve24(nums, target)
    % solve24([15 2 6 16])
    % solve24([3 3 12 13], 36)
    %
    % 无参数直接 Run 时，自动用 [15 2 6 16] 测试

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

    for p = 1:size(perms_list,1)
        x = perms_list(p,:);
        expr0 = cell(1,length(x));
        for k = 1:length(x)
            expr0{k} = num2str(x(k));
        end

        [res, ~] = search(x, expr0, target, 1e-6);
        all_exprs = [all_exprs; res(:)];  %#ok<AGROW>
    end

    if isempty(all_exprs)
        fprintf('无解！\n');
        return;
    end

    all_exprs = unique(cellstr(all_exprs));
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

            % 新 nums：去掉 i，把 j 位置换成新值
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