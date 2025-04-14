websave('example_data','https://github.com/piermorel/gramm/raw/master/sample_data/example_data.mat'); %Download data from repository
load example_data;
g=gramm('x',cars.Model_Year,'y',cars.MPG,'color',cars.Cylinders, ...
    'subset',cars.Cylinders~=3 & cars.Cylinders~=5); %Select cars that are not 3 or 5 cylinders;
g.stat_glm();
g.geom_point("dodge",0.5); 
g.draw();
g.export_d3('file_name','github','export_path','dev/','x', 'Model_Year', 'y', 'MPG', 'title','Cars Plot');
