% Data for two lines
x = linspace(0, 10, 100);
y1 = sin(x);
y2 = cos(x);

% Create a table to store the data, with duplicated 'x' for both lines
% x_combined = [x, x]';
% y_combined = [y1, y2]';Í
x_combined = (x)';
y_combined = (y1)';
% line_labels = [repmat({'sin(x)'}, 100, 1); repmat({'cos(x)'}, 100, 1)];
line_labels=[repmat({'sin(x)'}, 100, 1);];
data = table(x_combined, y_combined, line_labels, 'VariableNames', {'x', 'y', 'line'});
%%
A = 1;
% Initialize gramm object
g = gramm('x', data.x, 'y', A*data.y, 'color', data.line);

% Set plot type to line
g.geom_line();

% Set y-axis limits
g.axe_property('YLim', [-1.5 1.5]);

% Set title and axis labels
g.set_title('Plot of sin(x)');
g.set_names('x', 'X-Axis', 'y', 'Y-Axis', 'color', 'Function');

% Draw the plot
figure('Position', [100 100 800 600]);
g.draw();
% g.export('file_name','my_figure','export_path','./','file_type','pdf')

% TODO: Problem with export_path
g.export_d3('file_name','my_d3_line','export_path','dev/','x', 'X-Axis', 'y', 'Y-Axis','title','Plot of sin(x)');

%% 条形图测试
% 创建条形图数据
categories = {'A', 'B', 'C', 'D', 'E'};
values = [10, 25, 15, 30, 20];
bar_data = table(categories', values', 'VariableNames', {'category', 'value'});

% 初始化gramm对象
g_bar = gramm('x', bar_data.category, 'y', bar_data.value);

% 设置图表类型为条形图
g_bar.geom_bar();

% 设置标题和轴标签
g_bar.set_title('Bar Chart Example');
g_bar.set_names('x', 'Categories', 'y', 'Values');

% 绘制图表
figure('Position', [100 100 800 600]);
g_bar.draw();

% 导出条形图为D3.js
g_bar.export_d3('file_name','my_d3_bar','export_path','dev/','x', 'Categories', 'y', 'Values','title','Bar Chart Example');

% %% 数值型x轴的条形图测试
% % 创建数值型x轴的条形图数据
% x_values = [1, 2, 3, 4, 5];
% y_values = [12, 19, 8, 15, 22];
% numeric_bar_data = table(x_values', y_values', 'VariableNames', {'x', 'y'});
% 
% % 初始化gramm对象
% g_numeric_bar = gramm('x', numeric_bar_data.x, 'y', numeric_bar_data.y);
% 
% % 设置图表类型为条形图
% g_numeric_bar.geom_bar();
% 
% % 设置标题和轴标签
% g_numeric_bar.set_title('Numeric Bar Chart Example');
% g_numeric_bar.set_names('x', 'X Values', 'y', 'Y Values');
% 
% % 绘制图表
% figure('Position', [100 100 800 600]);
% g_numeric_bar.draw();
% 
% % 导出数值型条形图为D3.js
% g_numeric_bar.export_d3('file_name','my_d3_numeric_bar','export_path','dev/','x', 'X Values', 'y', 'Y Values','title','Numeric Bar Chart Example');

%% 抖动图测试 - 分类型x轴
% 创建抖动图数据（每个类别多个值）
categories = {'A', 'B', 'C', 'D', 'E'};
values = [];
x_values = [];
for i = 1:length(categories)
    % 为每个类别生成10个随机值
    values = [values; randn(10,1) * 2 + 20];
    x_values = [x_values; repmat(categories(i), 10, 1)];
end
jitter_data = table(x_values, values, 'VariableNames', {'category', 'value'});

% 初始化gramm对象
g_jitter = gramm('x', jitter_data.category, 'y', jitter_data.value);

% 设置图表类型为抖动图
g_jitter.geom_jitter('width', 0.2, 'height', 0);

% 设置标题和轴标签
g_jitter.set_title('Jitter Plot Example (Categorical)');
g_jitter.set_names('x', 'Categories', 'y', 'Values');

% 绘制图表
figure('Position', [100 100 800 600]);
g_jitter.draw();

% 导出抖动图为D3.js
g_jitter.export_d3('file_name','my_d3_jitter_categorical','export_path','dev/','x', 'Categories', 'y', 'Values','title','Jitter Plot Example (Categorical)');

% %% 抖动图测试 - 数值型x轴
% % 创建数值型x轴的抖动图数据
% x_values = [];
% y_values = [];
% for i = 1:5
%     % 为每个x值生成8个随机y值
%     x_values = [x_values; repmat(i, 8, 1)];
%     y_values = [y_values; randn(8,1) * 0.5 + i * 2];
% end
% numeric_jitter_data = table(x_values, y_values, 'VariableNames', {'x', 'y'});

% % 初始化gramm对象
% g_numeric_jitter = gramm('x', numeric_jitter_data.x, 'y', numeric_jitter_data.y);

% % 设置图表类型为抖动图
% g_numeric_jitter.geom_jitter('width', 0.2, 'height', 0);

% % 设置标题和轴标签
% g_numeric_jitter.set_title('Jitter Plot Example (Numeric)');
% g_numeric_jitter.set_names('x', 'X Values', 'y', 'Y Values');

% % 绘制图表
% figure('Position', [100 100 800 600]);
% g_numeric_jitter.draw();

% % 导出数值型抖动图为D3.js
% g_numeric_jitter.export_d3('file_name','my_d3_jitter_numeric','export_path','dev/','x', 'X Values', 'y', 'Y Values','title','Jitter Plot Example (Numeric)');