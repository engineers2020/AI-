function demo_knn()
% KNN分类器 - 交互式学习模块
%
% 核心功能：
%   1. 展示KNN算法在二维特征空间上的分类决策边界
%   2. 调整K值，实时观察决策边界变化
%   3. 切换距离度量（欧氏距离/曼哈顿距离）
%   4. 切换投票策略（多数表决/距离加权）
%   5. 点击添加数据点观察分类效果

    K = 5; addClass = 1; distMetric = 1; weighted = false;

    rng(42);
    X = [randn(50,2)*0.9+[-2,-2]; randn(50,2)*0.9+[2,2]; randn(50,2)*0.9+[-2,3]];
    Y = [ones(50,1); 2*ones(50,1); 3*ones(50,1)];
    classColors = [0.2,0.6,0.85; 0.85,0.35,0.2; 0.2,0.75,0.45];
    className = {'类别1','类别2','类别3'};
    distNames = {'欧氏','曼哈顿'};

    % ═══ 界面 ═══
    fig = figure('Name','KNN分类器 - 交互式学习','NumberTitle','off',...
        'Position',[120,80,1050,680],'MenuBar','none','ToolBar','none',...
        'Color',[0.12,0.12,0.18],'CloseRequestFcn',@onClose);

    % 拖拽状态
    dragIdx = 0;
    set(fig, 'WindowButtonDownFcn', @onMouseDown);
    set(fig, 'WindowButtonUpFcn', @onMouseUp);

    uicontrol('Style','text','String','KNN分类器','FontSize',20,...
        'FontWeight','bold','ForegroundColor',[0,0,0],'Units','normalized',...
        'Position',[0.02,0.93,0.2,0.05]);

    % K值
    uicontrol('Style','text','String','K值:','FontSize',12,...
        'ForegroundColor',[0,0,0],'Units','normalized',...
        'Position',[0.02,0.87,0.05,0.03]);
    kSlider = uicontrol('Style','slider','Min',1,'Max',25,'Value',5,...
        'SliderStep',[1/24,1/24],'Units','normalized',...
        'Position',[0.07,0.87,0.13,0.025],...
        'BackgroundColor',[0.25,0.25,0.35],...
        'Callback',@(src,~) onKChange());
    kLabel = uicontrol('Style','text','String','K = 5','FontSize',13,...
        'FontWeight','bold','ForegroundColor',[0,0,0],...
        'Units','normalized','Position',[0.21,0.87,0.07,0.03]);

    % 距离度量
    uicontrol('Style','text','String','距离:','FontSize',11,...
        'ForegroundColor',[0,0,0],'Units','normalized',...
        'Position',[0.30,0.87,0.05,0.03]);
    distPopup = uicontrol('Style','popupmenu',...
        'String',{'欧氏距离','曼哈顿距离'},'Value',1,'FontSize',10,...
        'Units','normalized','Position',[0.35,0.872,0.08,0.026],...
        'BackgroundColor',[0.2,0.2,0.3],'ForegroundColor',[1,1,1],...
        'Callback',@(src,~) onDistChange());

    % 加权投票
    wgtBtn = uicontrol('Style','pushbutton','String','加权:关','FontSize',10,...
        'ForegroundColor',[1,1,1],'BackgroundColor',[0.3,0.3,0.4],...
        'Units','normalized','Position',[0.44,0.87,0.06,0.025],...
        'Callback',@(~,~) onWeightToggle());

    % 类别选择
    uicontrol('Style','text','String','点击添加:','FontSize',11,...
        'ForegroundColor',[0,0,0],'Units','normalized',...
        'Position',[0.52,0.87,0.07,0.03]);
    classBtns = gobjects(1,3);
    for c=1:3
        classBtns(c) = uicontrol('Style','pushbutton','String',className{c},...
            'FontSize',11,'ForegroundColor',[1,1,1],...
            'BackgroundColor',classColors(c,:)*0.8,'Units','normalized',...
            'Position',[0.59+(c-1)*0.07,0.865,0.065,0.035],...
            'Callback',@(src,~) onSelectClass(src));
    end

    % 重新生成按钮
    uicontrol('Style','pushbutton','String','重新生成数据','FontSize',11,...
        'ForegroundColor',[1,1,1],'BackgroundColor',[0.55,0.35,0.65],...
        'Units','normalized','Position',[0.82,0.865,0.1,0.035],...
        'Callback',@(~,~) onRegenerate());

    countLabel = uicontrol('Style','text','String','总样本:150',...
        'FontSize',11,'ForegroundColor',[0,0,0],...
        'Units','normalized','Position',[0.92,0.87,0.07,0.03]);

    % ═══ 绘图区域 ═══
    ax = axes('Parent',fig,'Position',[0.06,0.06,0.55,0.78],...
        'Color',[0.04,0.04,0.08],'XColor',[0.5,0.54,0.62],...
        'YColor',[0.5,0.54,0.62]);
    uicontrol('Style','text','String','','Units','normalized',...
        'Position',[0.65,0.06,0.33,0.78],...
        'BackgroundColor',[0.08,0.08,0.12]);
    infoAx = axes('Parent',fig,'Position',[0.67,0.08,0.29,0.74],...
        'Color','none','Visible','off');

    % ═══ 核心函数 ═══
    function pred = knnClassify(pts)
        nPts = size(pts,1); pred = zeros(nPts,1);
        for i=1:nPts
            if distMetric==1
                dists = sum((X-pts(i,:)).^2,2);
            else
                dists = sum(abs(X-pts(i,:)),2);
            end
            [~,idx] = sort(dists);
            if weighted
                dk = dists(idx(1:K)); dk(dk<1e-10)=1e-10;
                w = 1./sqrt(dk+1e-8); topY = Y(idx(1:K));
                wSum = [sum(w(topY==1)),sum(w(topY==2)),sum(w(topY==3))];
                [~,pred(i)] = max(wSum);
            else
                pred(i) = mode(Y(idx(1:K)));
            end
        end
    end

    % ═══ 绘制 ═══
    function updatePlot()
        xR = [min(X(:,1))-1.5,max(X(:,1))+1.5];
        yR = [min(X(:,2))-1.5,max(X(:,2))+1.5];
        [xG,yG] = meshgrid(linspace(xR(1),xR(2),55),...
                           linspace(yR(1),yR(2),55));
        gridPred = reshape(knnClassify([xG(:),yG(:)]),size(xG));

        cla(ax); hold(ax,'on');
        cmap = classColors;
        for c=1:3
            mask = (gridPred==c);
            [~,h] = contourf(ax,xG,yG,double(mask),[0.5,0.5],...
                'LineColor','none');
            if ~isempty(h)
                set(h,'FaceAlpha',0.15,'FaceColor',cmap(c,:));
            end
        end
        contour(ax,xG,yG,gridPred,'LineWidth',1.2,...
            'LineColor',[0.55,0.58,0.65],'LevelStep',1);
        for c=1:3
            idx=(Y==c);
            scatter(ax,X(idx,1),X(idx,2),55,cmap(c,:),'filled',...
                'MarkerEdgeColor',[1,1,1],'MarkerEdgeAlpha',0.4,'LineWidth',0.7);
        end

        wgtStr=''; if weighted, wgtStr=',加权'; end
        title(ax,sprintf('KNN (K=%d,%s%s)',K,distNames{distMetric},wgtStr),...
            'FontSize',14,'FontWeight','bold','Color',[1,1,1]);
        xlabel(ax,'X_1','Color',[0.7,0.72,0.78]);
        ylabel(ax,'X_2','Color',[0.7,0.72,0.78]);
        xlim(ax,xR); ylim(ax,yR); ax.FontSize=11;
        grid(ax,'on'); hold(ax,'off');

        % 信息面板
        cla(infoAx); axis(infoAx,'off');
        wgtStr2='多数表决';
        if weighted, wgtStr2='距离加权(1/d)'; end
        lines={
            'KNN 算法原理',''
            '基于实例学习: K个最近邻投票',''
            '', ''
            ['K = ',num2str(K),' | ',distNames{distMetric},'距离'],''
            ['策略: ',wgtStr2],''
            '', ''
            'K值影响:',''
            '  K小 -> 边界复杂, 易过拟合',''
            '  K大 -> 边界平滑, 易欠拟合',''
            '', ''
            '距离度量对比:',''
            '  欧氏: 直线距离',''
            '  曼哈顿: 坐标轴距离',''
            '', ''
            ['总样本:',num2str(size(X,1))],''
            '类别数:3',''
        };
        yT=0.97;
        for i=1:size(lines,1)
            txt=lines{i,1};
            if isempty(txt), yT=yT-0.008; continue; end
            isT=(i==1||~isempty(strfind(txt,'K值影响'))||...
                ~isempty(strfind(txt,'距离度量')));
            fs=13;fw='bold';clr=[1,0.85,0.3];
            if ~isT, fs=10;fw='normal';clr=[0.72,0.75,0.82]; end
            text(infoAx,0.02,yT,txt,'FontSize',fs,'FontWeight',fw,...
                'Color',clr,'VerticalAlignment','top');
            yT=yT-0.028;
        end
        countLabel.String=['总样本:' num2str(size(X,1))];
    end

    % ═══ 回调 ═══
    function onKChange()
        K=round(kSlider.Value); kLabel.String=['K=' num2str(K)];
        updatePlot();
    end
    function onDistChange()
        distMetric=get(distPopup,'Value'); updatePlot();
    end
    function onWeightToggle()
        weighted=~weighted;
        if weighted
            wgtBtn.String='加权:开';
            wgtBtn.BackgroundColor=[0.2,0.65,0.35];
        else
            wgtBtn.String='加权:关';
            wgtBtn.BackgroundColor=[0.3,0.3,0.4];
        end
        updatePlot();
    end
    function onSelectClass(src)
        for c=1:3
            if strcmp(src.String,className{c})
                addClass=c; classBtns(c).FontSize=13;
            else
                classBtns(c).FontSize=11;
            end
        end
    end
    function onClickPlot(~,~)
        pt=get(ax,'CurrentPoint'); newX=pt(1,1:2);
        xl=xlim(ax); yl=ylim(ax);
        if newX(1)>=xl(1)&&newX(1)<=xl(2)&&newX(2)>=yl(1)&&newX(2)<=yl(2)
            X(end+1,:)=newX; Y(end+1,:)=addClass; updatePlot();
        end
    end
    function onRegenerate()
        rng('shuffle');
        centers=randn(3,2)*2.5;
        X=[randn(50,2)*0.8+centers(1,:); randn(50,2)*0.8+centers(2,:);
           randn(50,2)*0.8+centers(3,:)];
        Y=[ones(50,1);2*ones(50,1);3*ones(50,1)]; updatePlot();
    end
    function onClose(~,~)
        pause(0.05); delete(gcf);
    end

    % ─── 鼠标拖拽与点击 ───
    function onMouseDown(~,~)
        if ~ishandle(fig), return; end
        pt = get(ax, 'CurrentPoint');
        mx = pt(1,1); my = pt(1,2);
        xl = xlim(ax); yl = ylim(ax);
        if mx < xl(1) || mx > xl(2) || my < yl(1) || my > yl(2)
            return;
        end

        % 查找最近的数据点
        dists = sqrt((X(:,1)-mx).^2 + (X(:,2)-my).^2);
        [minDist, idx] = min(dists);

        if minDist < 0.4
            dragIdx = idx;
            set(fig, 'WindowButtonMotionFcn', @onMouseMove);
        else
            % 空白处点击 -> 添加新数据点
            X(end+1,:) = [mx, my]; Y(end+1,:) = addClass; updatePlot();
        end
    end

    function onMouseMove(~,~)
        if dragIdx == 0 || ~ishandle(fig), return; end
        pt = get(ax, 'CurrentPoint');
        mx = pt(1,1); my = pt(1,2);
        xl = xlim(ax); yl = ylim(ax);
        mx = max(xl(1), min(xl(2), mx));
        my = max(yl(1), min(yl(2), my));
        X(dragIdx,:) = [mx, my];
        updatePlot();
    end

    function onMouseUp(~,~)
        dragIdx = 0;
        if ishandle(fig)
            set(fig, 'WindowButtonMotionFcn', '');
        end
    end

    updatePlot();
end
