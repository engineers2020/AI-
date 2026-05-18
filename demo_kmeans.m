function demo_kmeans()
% K-Means聚类 - 交互式学习模块
%
% 功能：
%   1. 逐步展示K-Means聚类的迭代过程（分配→更新质心→重复）
%   2. 可调节聚类数K，实时观察聚类结果变化
%   3. 点击图表添加新数据点
%   4. 显示SSE（组内平方和）随迭代的变化
%
% 操作提示：
%   - "单步"按钮逐步观察每次迭代的分配与更新
%   - "自动运行"观看完整收敛过程
%   - "重置"重新初始化质心

    % ═══════════════════════════════════════
    % 初始化
    % ═══════════════════════════════════════
    K = 4;
    isRunning = false;
    iterCount = 0;
    converged = false;

    % 生成带自然聚类的数据
    rng(88);
    nClusters_true = 5;
    X = [];
    for i = 1:nClusters_true
        X = [X; randn(40, 2) * 0.7 + randn(1, 2) * 2.5];
    end

    clusterColors = lines(10);

    % ═══════════════════════════════════════
    % 创建图形界面
    % ═══════════════════════════════════════
    fig = figure('Name', 'K-Means聚类 - 交互式学习', ...
                 'NumberTitle', 'off', ...
                 'Position', [100, 60, 1100, 700], ...
                 'MenuBar', 'none', ...
                 'ToolBar', 'none', ...
                 'Color', [0.15, 0.15, 0.22], ...
                 'CloseRequestFcn', @onClose);

    % 拖拽状态: 0=无, 1=质心, 2=数据点
    dragIdx = 0; dragType = 0;
    set(fig, 'WindowButtonDownFcn', @onMouseDown);
    set(fig, 'WindowButtonUpFcn', @onMouseUp);

    % ─── 标题 ───
    uicontrol('Style', 'text', ...
              'String', 'K-Means 聚类算法', ...
              'FontSize', 20, ...
              'FontWeight', 'bold', ...
              'ForegroundColor', [0, 0, 0], ...
              'Units', 'normalized', ...
              'Position', [0.02, 0.93, 0.3, 0.05]);

    % ─── 控制栏 ───
    uicontrol('Style', 'text', ...
              'String', 'K值:', ...
              'FontSize', 12, ...
              'ForegroundColor', [0, 0, 0], ...
              'Units', 'normalized', ...
              'Position', [0.02, 0.87, 0.05, 0.03]);
    kSlider = uicontrol('Style', 'slider', ...
                        'Min', 2, 'Max', 10, 'Value', 4, ...
                        'SliderStep', [1/8, 1/8], ...
                        'Units', 'normalized', ...
                        'Position', [0.07, 0.87, 0.12, 0.025], ...
                        'BackgroundColor', [0.25, 0.25, 0.35], ...
                        'Callback', @(src,~) onKChange());
    kLabel = uicontrol('Style', 'text', ...
                       'String', 'K = 4', ...
                       'FontSize', 12, ...
                       'FontWeight', 'bold', ...
                       'ForegroundColor', [0, 0, 0], ...
                       'Units', 'normalized', ...
                       'Position', [0.20, 0.87, 0.06, 0.03]);

    btnStep = uicontrol('Style', 'pushbutton', ...
                        'String', '单步', ...
                        'FontSize', 12, ...
                        'FontWeight', 'bold', ...
                        'ForegroundColor', [1,1,1], ...
                        'BackgroundColor', [0.2, 0.65, 0.35], ...
                        'Units', 'normalized', ...
                        'Position', [0.30, 0.865, 0.05, 0.035], ...
                        'Callback', @(~,~) onStep());
    btnAuto = uicontrol('Style', 'pushbutton', ...
                        'String', '自动运行', ...
                        'FontSize', 12, ...
                        'FontWeight', 'bold', ...
                        'ForegroundColor', [1,1,1], ...
                        'BackgroundColor', [0.3, 0.5, 0.75], ...
                        'Units', 'normalized', ...
                        'Position', [0.36, 0.865, 0.07, 0.035], ...
                        'Callback', @(~,~) onAutoRun());
    btnResetKmeans = uicontrol('Style', 'pushbutton', ...
                               'String', '重置质心', ...
                               'FontSize', 12, ...
                               'ForegroundColor', [1,1,1], ...
                               'BackgroundColor', [0.65, 0.25, 0.25], ...
                               'Units', 'normalized', ...
                               'Position', [0.44, 0.865, 0.07, 0.035], ...
                               'Callback', @(~,~) onReset());
    btnNewData = uicontrol('Style', 'pushbutton', ...
                           'String', '新数据', ...
                           'FontSize', 12, ...
                           'ForegroundColor', [1,1,1], ...
                           'BackgroundColor', [0.55, 0.35, 0.65], ...
                           'Units', 'normalized', ...
                           'Position', [0.52, 0.865, 0.06, 0.035], ...
                           'Callback', @(~,~) onNewData());

    iterLabel = uicontrol('Style', 'text', ...
                          'String', '迭代: 0 | 未收敛', ...
                          'FontSize', 12, ...
                          'FontWeight', 'bold', ...
                          'ForegroundColor', [0, 0, 0], ...
                          'Units', 'normalized', ...
                          'Position', [0.62, 0.87, 0.2, 0.03]);
    sseLabel = uicontrol('Style', 'text', ...
                         'String', 'SSE: --', ...
                         'FontSize', 12, ...
                         'FontWeight', 'bold', ...
                         'ForegroundColor', [0, 0, 0], ...
                         'Units', 'normalized', ...
                         'Position', [0.82, 0.87, 0.15, 0.03]);

    % ─── 绘图区域 ───
    ax = axes('Parent', fig, ...
              'Position', [0.05, 0.06, 0.52, 0.78], ...
              'Color', [0.06, 0.06, 0.10], ...
              'XColor', [0.6, 0.62, 0.68], ...
              'YColor', [0.6, 0.62, 0.68]);

    % SSE曲线
    axSSE = axes('Parent', fig, ...
                 'Position', [0.64, 0.06, 0.34, 0.30], ...
                 'Color', [0.06, 0.06, 0.10], ...
                 'XColor', [0.6, 0.62, 0.68], ...
                 'YColor', [0.6, 0.62, 0.68]);

    % 说明面板
    uicontrol('Style', 'text', ...
              'String', '', ...
              'Units', 'normalized', ...
              'Position', [0.64, 0.40, 0.34, 0.42], ...
              'BackgroundColor', [0.10, 0.10, 0.16]);
    infoAx = axes('Parent', fig, ...
                  'Position', [0.65, 0.41, 0.32, 0.40], ...
                  'Color', 'none', ...
                  'Visible', 'off');

    % 初始化质心和分配
    assignments = zeros(size(X, 1), 1);
    centroids = [];
    sseHistory = [];

    initCentroids();
    assignAndDraw();

    % ═══════════════════════════════════════
    % K-Means 核心函数
    % ═══════════════════════════════════════
    function initCentroids()
        n = size(X, 1);
        idx = randperm(n, K);
        centroids = X(idx, :);
        assignments = zeros(n, 1);
        iterCount = 0;
        converged = false;
        sseHistory = [];
    end

    function sse = computeSSE()
        sse = 0;
        for i = 1:size(X, 1)
            sse = sse + sum((X(i,:) - centroids(assignments(i),:)).^2);
        end
    end

    function assignStep()
        n = size(X, 1);
        for i = 1:n
            dists = sum((centroids - X(i,:)).^2, 2);
            [~, assignments(i)] = min(dists);
        end
    end

    function updateStep()
        for c = 1:K
            idx = (assignments == c);
            if any(idx)
                centroids(c,:) = mean(X(idx,:), 1);
            end
        end
    end

    function [changed] = kmeansStep()
        oldCentroids = centroids;
        assignStep();
        updateStep();
        iterCount = iterCount + 1;
        changed = norm(centroids - oldCentroids) > 1e-6;
        if ~changed
            converged = true;
        end
        sseHistory(end+1) = computeSSE();
    end

    % ═══════════════════════════════════════
    % 绘制函数
    % ═══════════════════════════════════════
    function drawClusters()
        cla(ax); hold(ax, 'on');

        for c = 1:K
            idx = (assignments == c);
            if any(idx)
                scatter(ax, X(idx,1), X(idx,2), 50, clusterColors(c,:), ...
                        'filled', 'MarkerEdgeColor', [1,1,1], ...
                        'MarkerEdgeAlpha', 0.3, 'LineWidth', 0.6);
            end
            % 绘制质心
            plot(ax, centroids(c,1), centroids(c,2), 'p', ...
                 'Color', clusterColors(c,:), 'MarkerSize', 18, ...
                 'MarkerFaceColor', clusterColors(c,:), ...
                 'MarkerEdgeColor', [1,1,1], 'LineWidth', 2);
        end

        title(ax, sprintf('K-Means聚类  (K=%d, 迭代=%d)', K, iterCount), ...
              'FontSize', 14, 'FontWeight', 'bold', 'Color', [1,1,1]);
        xlabel(ax, '特征 X_1', 'Color', [0.7,0.72,0.78]);
        ylabel(ax, '特征 X_2', 'Color', [0.7,0.72,0.78]);
        grid(ax, 'on');
        hold(ax, 'off');
    end

    function drawSSECurve()
        cla(axSSE); hold(axSSE, 'on');
        if ~isempty(sseHistory)
            plot(axSSE, 0:length(sseHistory)-1, sseHistory, '-o', ...
                 'Color', [0.3, 0.85, 1.0], 'LineWidth', 1.5, ...
                 'MarkerSize', 4, 'MarkerFaceColor', [0.3, 0.85, 1.0]);
        end
        title(axSSE, 'SSE变化曲线', 'FontSize', 12, ...
              'FontWeight', 'bold', 'Color', [1,1,1]);
        xlabel(axSSE, '迭代次数', 'Color', [0.7,0.72,0.78]);
        ylabel(axSSE, 'SSE', 'Color', [0.7,0.72,0.78]);
        axSSE.FontSize = 10;
        grid(axSSE, 'on');
        hold(axSSE, 'off');
    end

    function drawInfo()
        cla(infoAx); axis(infoAx, 'off');
        lines = {
            'K-Means 聚类算法原理', ''
            '目标：将N个样本划分为K个簇，', ''
            '使每个样本到所属簇质心的距离之和最小', ''
            '', ''
            '算法步骤：', ''
            '  1. 随机初始化K个质心', ''
            '  2. 分配：将每个样本分配到', ''
            '     距离最近的质心所在的簇', ''
            '  3. 更新：重新计算每个簇的质心', ''
            '  4. 重复步骤2-3直到收敛', ''
            '', ''
            '收敛条件：', ''
            '  质心位置不再显著变化', ''
            '', ''
            'SSE (组内平方和)：', ''
            '  SSE = sum of squared distances', ''
            '  SSE越小，聚类越紧凑', ''
            '  SSE不再下降时算法收敛', ''
            '', ''
            '操作提示：', ''
            '  "单步"逐步观察每次迭代', ''
            '  "自动运行"观看完整过程', ''
            '  点击图表添加新数据点', ''
            '  调节K值观察不同聚类数', ''
        };
        yT = 0.97;
        for i = 1:size(lines,1)
            txt = lines{i,1};
            if isempty(txt), yT = yT - 0.005; continue; end
            isT = (i==1 || ~isempty(strfind(txt, '目标')) || ...
                        ~isempty(strfind(txt, '步骤')) || ...
                        ~isempty(strfind(txt, '收敛')) || ...
                        ~isempty(strfind(txt, 'SSE')) || ...
                        ~isempty(strfind(txt, '提示')));
            fs = 12.5; fw = 'bold'; clr = [1,0.85,0.3];
            if ~isT, fs = 10; fw = 'normal'; clr = [0.78,0.80,0.86]; end
            text(infoAx, 0.02, yT, txt, 'FontSize', fs, ...
                 'FontWeight', fw, 'Color', clr, 'VerticalAlignment', 'top');
            yT = yT - 0.03;
        end
    end

    function assignAndDraw()
        assignStep();
        sseHistory = [computeSSE()];
        drawClusters();
        drawSSECurve();
        drawInfo();
        updateLabels();
    end

    function updateLabels()
        if converged
            iterLabel.String = sprintf('迭代: %d | 已收敛', iterCount);
        else
            iterLabel.String = sprintf('迭代: %d | 未收敛', iterCount);
        end
        if ~isempty(sseHistory)
            sseLabel.String = sprintf('SSE: %.2f', sseHistory(end));
        end
    end

    % ═══════════════════════════════════════
    % 回调函数
    % ═══════════════════════════════════════
    function onKChange()
        K = round(kSlider.Value);
        kLabel.String = ['K = ' num2str(K)];
        isRunning = false; pause(0.05);
        initCentroids();
        assignAndDraw();
    end

    function onStep()
        if converged, return; end
        kmeansStep();
        drawClusters();
        drawSSECurve();
        updateLabels();
    end

    function onAutoRun()
        isRunning = true;
        while isRunning && ~converged && ishandle(fig) && iterCount < 200
            kmeansStep();
            drawClusters();
            drawSSECurve();
            updateLabels();
            drawnow;
            pause(0.3);
        end
        isRunning = false;
    end

    function onReset()
        isRunning = false; pause(0.05);
        initCentroids();
        assignAndDraw();
    end

    function onNewData()
        isRunning = false; pause(0.05);
        rng('shuffle');
        X_new = [];
        nc = randi(3, 1, 5) + 2;  % 3-7 true clusters
        for i = 1:nc
            X_new = [X_new; randn(35, 2) * 0.7 + randn(1,2) * 2.5];
        end
        X = X_new;
        initCentroids();
        assignAndDraw();
    end

    function onClickPlot(~, ~)
        pt = get(ax, 'CurrentPoint');
        newX = pt(1, 1:2);
        if newX(1) >= xlim(ax,1) && newX(1) <= xlim(ax,2) && ...
           newX(2) >= ylim(ax,1) && newX(2) <= ylim(ax,2)
            X = [X; newX];
            if ~isempty(centroids)
                assignStep();
                drawClusters();
                updateLabels();
            end
        end
    end

    function onClose(~, ~)
        isRunning = false;
        pause(0.05);
        delete(gcf);
    end

    % ─── 鼠标拖拽: 质心 > 数据点 > 添加 ───
    function onMouseDown(~, ~)
        if ~ishandle(fig), return; end
        pt = get(ax, 'CurrentPoint');
        mx = pt(1,1); my = pt(1,2);
        xl = xlim(ax); yl = ylim(ax);
        if mx < xl(1) || mx > xl(2) || my < yl(1) || my > yl(2)
            return;
        end

        % 优先检测质心（星形标记）
        if ~isempty(centroids)
            cDists = sqrt((centroids(:,1)-mx).^2 + (centroids(:,2)-my).^2);
            [minCDist, cIdx] = min(cDists);
            if minCDist < 0.5
                dragIdx = cIdx; dragType = 1;
                set(fig, 'WindowButtonMotionFcn', @onMouseMove);
                return;
            end
        end

        % 其次检测数据点
        if ~isempty(X)
            dDists = sqrt((X(:,1)-mx).^2 + (X(:,2)-my).^2);
            [minDDist, dIdx] = min(dDists);
            if minDDist < 0.3
                dragIdx = dIdx; dragType = 2;
                set(fig, 'WindowButtonMotionFcn', @onMouseMove);
                return;
            end
        end

        % 空白处 -> 添加数据点
        X = [X; mx, my];
        if ~isempty(centroids)
            assignStep();
            drawClusters();
            updateLabels();
        end
    end

    function onMouseMove(~, ~)
        if dragIdx == 0 || ~ishandle(fig), return; end
        pt = get(ax, 'CurrentPoint');
        mx = pt(1,1); my = pt(1,2);
        xl = xlim(ax); yl = ylim(ax);
        mx = max(xl(1), min(xl(2), mx));
        my = max(yl(1), min(yl(2), my));

        if dragType == 1
            centroids(dragIdx,:) = [mx, my];
        else
            X(dragIdx,:) = [mx, my];
            if ~isempty(centroids)
                assignStep();
            end
        end
        drawClusters();
        updateLabels();
    end

    function onMouseUp(~, ~)
        dragIdx = 0; dragType = 0;
        if ishandle(fig)
            set(fig, 'WindowButtonMotionFcn', '');
        end
    end
end
