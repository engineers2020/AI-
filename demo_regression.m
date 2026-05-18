function demo_regression()
% 多项式回归分析 - 交互式学习模块
%
% 功能：
%   1. 可视化多项式回归对数据的拟合效果
%   2. 通过调节多项式阶数，直观理解过拟合与欠拟合
%   3. 支持L2正则化（Ridge回归），观察正则化对过拟合的抑制效果
%   4. 实时显示训练误差和测试误差，帮助选择最佳模型
%
% 操作提示：
%   - 拖动"多项式阶数"滑块观察拟合效果
%   - 拖动"正则化强度"滑块抑制过拟合
%   - 对比训练误差与测试误差判断模型好坏

    % ═══════════════════════════════════════
    % 生成数据：正弦函数 + 噪声
    % ═══════════════════════════════════════
    rng(99);
    n = 30;
    x = linspace(-1, 1, n)';
    y_true = sin(2 * pi * x);
    noise = randn(n, 1) * 0.3;
    y = y_true + noise;

    % 划分训练集和测试集
    trainIdx = 1:2:n;
    testIdx = 2:2:n;
    xTrain = x(trainIdx); yTrain = y(trainIdx);
    xTest = x(testIdx);   yTest = y(testIdx);

    degree = 3;
    lambda = 0;

    % ═══════════════════════════════════════
    % 创建图形界面
    % ═══════════════════════════════════════
    fig = figure('Name', '回归分析 - 交互式学习', ...
                 'NumberTitle', 'off', ...
                 'Position', [120, 80, 1100, 700], ...
                 'MenuBar', 'none', ...
                 'ToolBar', 'none', ...
                 'Color', [0.15, 0.15, 0.22]);

    % 拖拽状态变量
    dragIdx = 0;
    dragSet = 0;
    set(fig, 'WindowButtonDownFcn', @onMouseDown);
    set(fig, 'WindowButtonUpFcn', @onMouseUp);

    % ─── 标题 ───
    uicontrol('Style', 'text', ...
              'String', '多项式回归分析', ...
              'FontSize', 20, ...
              'FontWeight', 'bold', ...
              'ForegroundColor', [0, 0, 0], ...
              'Units', 'normalized', ...
              'Position', [0.02, 0.93, 0.3, 0.05]);

    % ─── 控制栏 ───
    uicontrol('Style', 'text', ...
              'String', '多项式阶数:', ...
              'FontSize', 12, ...
              'ForegroundColor', [0, 0, 0], ...
              'Units', 'normalized', ...
              'Position', [0.02, 0.87, 0.1, 0.03]);
    degSlider = uicontrol('Style', 'slider', ...
                          'Min', 1, 'Max', 18, 'Value', 3, ...
                          'SliderStep', [1/17, 1/17], ...
                          'Units', 'normalized', ...
                          'Position', [0.12, 0.87, 0.15, 0.025], ...
                          'BackgroundColor', [0.25, 0.25, 0.35], ...
                          'Callback', @(~,~) onParamChange());
    degLabel = uicontrol('Style', 'text', ...
                         'String', '阶数 = 3', ...
                         'FontSize', 12, ...
                         'FontWeight', 'bold', ...
                         'ForegroundColor', [0, 0, 0], ...
                         'Units', 'normalized', ...
                         'Position', [0.28, 0.87, 0.08, 0.03]);

    uicontrol('Style', 'text', ...
              'String', '正则化强度 (lambda):', ...
              'FontSize', 12, ...
              'ForegroundColor', [0, 0, 0], ...
              'Units', 'normalized', ...
              'Position', [0.38, 0.87, 0.15, 0.03]);
    lamSlider = uicontrol('Style', 'slider', ...
                          'Min', -6, 'Max', 2, 'Value', -6, ...
                          'Units', 'normalized', ...
                          'Position', [0.53, 0.87, 0.12, 0.025], ...
                          'BackgroundColor', [0.25, 0.25, 0.35], ...
                          'Callback', @(~,~) onParamChange());
    lamLabel = uicontrol('Style', 'text', ...
                         'String', 'lambda = 0.0000', ...
                         'FontSize', 12, ...
                         'FontWeight', 'bold', ...
                         'ForegroundColor', [0, 0, 0], ...
                         'Units', 'normalized', ...
                         'Position', [0.66, 0.87, 0.12, 0.03]);

    btnNewData = uicontrol('Style', 'pushbutton', ...
                           'String', '重新生成数据', ...
                           'FontSize', 11, ...
                           'ForegroundColor', [1,1,1], ...
                           'BackgroundColor', [0.55, 0.35, 0.65], ...
                           'Units', 'normalized', ...
                           'Position', [0.82, 0.865, 0.12, 0.035], ...
                           'Callback', @(~,~) onNewData());

    % 误差标签
    trainErrLabel = uicontrol('Style', 'text', ...
                              'String', '训练RMSE: --', ...
                              'FontSize', 12, ...
                              'FontWeight', 'bold', ...
                              'ForegroundColor', [0, 0, 0], ...
                              'Units', 'normalized', ...
                              'Position', [0.02, 0.83, 0.2, 0.03]);
    testErrLabel = uicontrol('Style', 'text', ...
                             'String', '测试RMSE: --', ...
                             'FontSize', 12, ...
                             'FontWeight', 'bold', ...
                             'ForegroundColor', [0, 0, 0], ...
                             'Units', 'normalized', ...
                             'Position', [0.25, 0.83, 0.2, 0.03]);
    statusLabel = uicontrol('Style', 'text', ...
                            'String', '', ...
                            'FontSize', 13, ...
                            'FontWeight', 'bold', ...
                            'Units', 'normalized', ...
                            'Position', [0.50, 0.83, 0.3, 0.03]);

    % ═══════════════════════════════════════
    % 绘图区域
    % ═══════════════════════════════════════
    ax = axes('Parent', fig, ...
              'Position', [0.06, 0.06, 0.55, 0.74], ...
              'Color', [0.06, 0.06, 0.10], ...
              'XColor', [0.6, 0.62, 0.68], ...
              'YColor', [0.6, 0.62, 0.68]);

    % 右侧：误差曲线
    axErr = axes('Parent', fig, ...
                 'Position', [0.66, 0.06, 0.32, 0.30], ...
                 'Color', [0.06, 0.06, 0.10], ...
                 'XColor', [0.6, 0.62, 0.68], ...
                 'YColor', [0.6, 0.62, 0.68]);

    % 右侧：说明
    uicontrol('Style', 'text', ...
              'String', '', ...
              'Units', 'normalized', ...
              'Position', [0.66, 0.40, 0.32, 0.42], ...
              'BackgroundColor', [0.10, 0.10, 0.16]);
    infoAx = axes('Parent', fig, ...
                  'Position', [0.67, 0.41, 0.30, 0.40], ...
                  'Color', 'none', ...
                  'Visible', 'off');

    % 存储所有阶数的误差
    allTrainErr = zeros(1, 18);
    allTestErr = zeros(1, 18);

    % ═══════════════════════════════════════
    % 核心回归函数
    % ═══════════════════════════════════════
    function w = polyFit(xData, yData, d, lam_val)
        % Ridge回归闭式解
        Xd = zeros(length(xData), d+1);
        for i = 0:d
            Xd(:, i+1) = xData.^i;
        end
        I = eye(d+1);
        I(1,1) = 0;  % 不惩罚偏置项
        w = (Xd' * Xd + lam_val * I) \ (Xd' * yData);
    end

    function yPred = polyPredict(w, xData)
        yPred = zeros(size(xData));
        for i = 0:length(w)-1
            yPred = yPred + w(i+1) * xData.^i;
        end
    end

    function rmse = computeRMSE(yTrue, yPred)
        rmse = sqrt(mean((yTrue - yPred).^2));
    end

    % ═══════════════════════════════════════
    % 绘制函数
    % ═══════════════════════════════════════
    function drawRegression()
        cla(ax); hold(ax, 'on');

        % 真实函数
        xFine = linspace(-1.2, 1.2, 200)';
        yFine = sin(2*pi*xFine);
        plot(ax, xFine, yFine, '--', 'Color', [0.5, 0.52, 0.58], ...
             'LineWidth', 1.5);

        % 拟合曲线
        w = polyFit(xTrain, yTrain, degree, lambda);
        yFit = polyPredict(w, xFine);

        % 判断是否过拟合
        trainRMSE = computeRMSE(yTrain, polyPredict(w, xTrain));
        testRMSE  = computeRMSE(yTest,  polyPredict(w, xTest));

        allTrainErr(degree) = trainRMSE;
        allTestErr(degree) = testRMSE;

        % 根据过拟合程度选择颜色
        if degree <= 2
            fitColor = [0.3, 0.6, 1.0];     % 蓝 - 欠拟合
        elseif degree <= 5
            fitColor = [0.2, 0.85, 0.45];   % 绿 - 适中
        else
            fitColor = [1.0, 0.4, 0.3];     % 红 - 过拟合
        end

        plot(ax, xFine, yFit, '-', 'Color', fitColor, 'LineWidth', 2.5);

        % 训练数据
        scatter(ax, xTrain, yTrain, 60, [0.3, 0.85, 1.0], 'filled', ...
                'MarkerEdgeColor', [1,1,1], 'MarkerEdgeAlpha', 0.5, 'LineWidth', 0.8);
        % 测试数据
        scatter(ax, xTest, yTest, 60, [1.0, 0.55, 0.3], 'filled', ...
                'MarkerEdgeColor', [1,1,1], 'MarkerEdgeAlpha', 0.5, 'LineWidth', 0.8);

        title(ax, sprintf('多项式回归 (阶数=%d, lambda=%.4f)', degree, lambda), ...
              'FontSize', 14, 'FontWeight', 'bold', 'Color', [1,1,1]);
        xlabel(ax, 'X', 'Color', [0.7,0.72,0.78]);
        ylabel(ax, 'Y', 'Color', [0.7,0.72,0.78]);
        xlim(ax, [-1.3, 1.3]); ylim(ax, [-1.8, 1.8]);
        ax.FontSize = 11;
        grid(ax, 'on');

        legend(ax, '真实函数 sin(2pix)', ...
               sprintf('拟合曲线 (阶数%d)', degree), ...
               '训练集', '测试集', ...
               'Location', 'northeast', 'FontSize', 9);
        hold(ax, 'off');

        % 更新误差标签
        trainErrLabel.String = sprintf('训练RMSE: %.4f', trainRMSE);
        testErrLabel.String  = sprintf('测试RMSE: %.4f', testRMSE);

        if degree <= 2
            statusLabel.String = '欠拟合区域 - 模型太简单';
            statusLabel.ForegroundColor = [0.3, 0.6, 1.0];
        elseif degree <= 5
            statusLabel.String = '较好拟合区域';
            statusLabel.ForegroundColor = [0.2, 0.85, 0.45];
        else
            gap = testRMSE - trainRMSE;
            statusLabel.String = sprintf('过拟合区域! (测试-训练 = %.4f)', gap);
            statusLabel.ForegroundColor = [1.0, 0.4, 0.3];
        end
    end

    function drawErrorCurve()
        cla(axErr); hold(axErr, 'on');
        dRange = 1:18;
        validTrain = allTrainErr(dRange);
        validTest  = allTestErr(dRange);
        validTrain(validTrain == 0) = NaN;
        validTest(validTest == 0) = NaN;

        plot(axErr, dRange, validTrain, '-o', 'Color', [0.3, 0.85, 1.0], ...
             'LineWidth', 1.5, 'MarkerSize', 3, 'MarkerFaceColor', [0.3, 0.85, 1.0]);
        plot(axErr, dRange, validTest, '-s', 'Color', [1.0, 0.55, 0.3], ...
             'LineWidth', 1.5, 'MarkerSize', 3, 'MarkerFaceColor', [1.0, 0.55, 0.3]);

        % 标记当前阶数
        if degree >= 1 && degree <= 18
            plot(axErr, degree, allTrainErr(degree), 'o', ...
                 'Color', [0.3, 0.85, 1.0], 'MarkerSize', 10, 'LineWidth', 2);
            plot(axErr, degree, allTestErr(degree), 's', ...
                 'Color', [1.0, 0.55, 0.3], 'MarkerSize', 10, 'LineWidth', 2);
        end

        title(axErr, '训练/测试误差 vs 多项式阶数', 'FontSize', 11, ...
              'FontWeight', 'bold', 'Color', [1,1,1]);
        xlabel(axErr, '多项式阶数', 'Color', [0.7,0.72,0.78]);
        ylabel(axErr, 'RMSE', 'Color', [0.7,0.72,0.78]);
        axErr.FontSize = 9;
        xlim(axErr, [0.5, 18.5]);
        grid(axErr, 'on');
        legend(axErr, '训练误差', '测试误差', 'Location', 'best', 'FontSize', 8);
        hold(axErr, 'off');
    end

    function drawInfo()
        cla(infoAx); axis(infoAx, 'off');
        lines = {
            '多项式回归原理', ''
            '目标：用多项式函数拟合数据', ''
            '  y = w0 + w1*x + w2*x^2 + ... + wd*x^d', ''
            '', ''
            '拟合流程：', ''
            '  1. 构造设计矩阵 [1, x, x^2, ..., x^d]', ''
            '  2. 求解 Ridge 回归闭式解:', ''
            '     w = (X''X + lambda*I) \ X''y', ''
            '', ''
            '多项式阶数的影响：', ''
            '  阶数太低 -> 欠拟合', ''
            '    模型太简单，无法捕捉数据规律', ''
            '  阶数适中 -> 较好拟合', ''
            '    平衡拟合能力与泛化性能', ''
            '  阶数太高 -> 过拟合', ''
            '    模型太复杂，拟合了噪声', ''
            '    训练误差低但测试误差高', ''
            '', ''
            '正则化 (lambda) 的作用：', ''
            '  惩罚大权重，降低模型复杂度', ''
            '  缓解过拟合，提升泛化能力', ''
            '', ''
            '提示：', ''
            '  对比训练/测试误差曲线', ''
            '  寻找两曲线差距最小的阶数', ''
        };
        yT = 0.97;
        for i = 1:size(lines,1)
            txt = lines{i,1};
            if isempty(txt), yT = yT - 0.005; continue; end
            isT = (i==1 || ~isempty(strfind(txt, '目标')) || ...
                        ~isempty(strfind(txt, '拟合流程')) || ...
                        ~isempty(strfind(txt, '影响')) || ...
                        ~isempty(strfind(txt, '正则化')) || ...
                        ~isempty(strfind(txt, '提示')));
            fs = 12; fw = 'bold'; clr = [1,0.85,0.3];
            if ~isT, fs = 9.5; fw = 'normal'; clr = [0.78,0.80,0.86]; end
            text(infoAx, 0.02, yT, txt, 'FontSize', fs, ...
                 'FontWeight', fw, 'Color', clr, 'VerticalAlignment', 'top', ...
                 'Interpreter', 'none');
            yT = yT - 0.027;
        end
    end

    function onParamChange()
        degree = round(degSlider.Value);
        lambda = 10^lamSlider.Value;
        degLabel.String = ['阶数 = ' num2str(degree)];
        lamLabel.String = ['lambda = ' sprintf('%.4f', lambda)];
        drawRegression();
        drawErrorCurve();
        drawInfo();
    end

    function onNewData()
        rng('shuffle');
        y = y_true + randn(n, 1) * 0.3;
        yTrain = y(trainIdx);
        yTest = y(testIdx);
        allTrainErr = zeros(1, 18);
        allTestErr = zeros(1, 18);
        drawRegression();
        drawErrorCurve();
    end

    % ─── 鼠标拖拽数据点 ───
    function onMouseDown(~, ~)
        if ~ishandle(fig), return; end
        pt = get(ax, 'CurrentPoint');
        mx = pt(1,1); my = pt(1,2);
        xl = xlim(ax); yl = ylim(ax);
        if mx < xl(1) || mx > xl(2) || my < yl(1) || my > yl(2)
            return;
        end

        % 查找最近的数据点（训练集+测试集）
        allX = [xTrain; xTest];
        allY = [yTrain; yTest];
        dx = allX - mx; dy = allY - my;
        dists = sqrt(dx.^2 + dy.^2);
        [minDist, idx] = min(dists);

        if minDist < 0.25
            if idx <= length(xTrain)
                dragIdx = idx; dragSet = 1;
            else
                dragIdx = idx - length(xTrain); dragSet = 2;
            end
            set(fig, 'WindowButtonMotionFcn', @onMouseMove);
        end
    end

    function onMouseMove(~, ~)
        if dragIdx == 0 || ~ishandle(fig), return; end
        pt = get(ax, 'CurrentPoint');
        my = pt(1,2);
        yl = ylim(ax);
        my = max(yl(1), min(yl(2), my));

        if dragSet == 1
            yTrain(dragIdx) = my;
        else
            yTest(dragIdx) = my;
        end
        drawRegression();
        drawErrorCurve();
    end

    function onMouseUp(~, ~)
        dragIdx = 0; dragSet = 0;
        if ishandle(fig)
            set(fig, 'WindowButtonMotionFcn', '');
        end
    end

    % ─── 初始绘制 ───
    drawRegression();
    drawErrorCurve();
    drawInfo();
end
