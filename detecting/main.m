%% Pre setting

clear;
close all;
clc;

% Detector Load
detector = load('Detector.mat').net;

% Data stack variables
ptCloud_stack   = [''];
human_stack     = [''];
upper_stack     = [''];
DB_stack        = [''];

% Detecting Option choose
detect_option   = 0; % 0: detect only human
detect_cube     = 0; % 0: cuboid

% Parameter set
maxframes   = 200;
z_offset    = 1.2;
confidenceThreshold = 0.35; 

% ROI area size
Detecting_area1     = [-12 12 -3.9 0   -5 5 0 0 0];
Danger_area_hist    = [-12 12 -10 -3.4 -5 5 0 0 0];
Danger_area_detect  = [-12 12 -10 -3.9 -5 5 0 0 0];
Danger_area         = [-12 12 -10 -3.9 -5 5 0 0 0];
Detecting_area2     = [-12 12 -3.9 0   -5 5 0 0 0];


%% Data stack
countpos_thres = 20;                   
countneg_thres = 30; 
R_threshold = 0.30;  
DB = [];

for frame=1:1:maxframes
    
    % Pcd files load -> format : frame0000.pcd or 0000.pcd
    pcd_num = sprintf('%04d',frame);
    pcd_name = strcat('frame',pcd_num,'.pcd');
    ptCloud = pcread(pcd_name);
    
    % Detecting
    [box,score,labels] = detect(detector,ptCloud,'Threshold',confidenceThreshold);
    % Label extract
    boxlabelsHuman = box(labels'=='Human',:);
    boxlabelsCentroid = box(labels'=='Human',:); 
    
    % Point cloud stacking
    ptCloud_stack = [ptCloud_stack ; ptCloud];
    
    % Human detecting box stacking, z offset remove
    if length(box(labels'=='Human',:)) > 0
        human_size = size(boxlabelsHuman);
        for i = 1:1:human_size(1)
            boxlabelsHuman(i,3) = boxlabelsHuman(i,3) - z_offset;
            boxlabelsCentroid(i,4:6) = [0.45 0.45 0.45];
            if detect_cube == 1
                boxlabelsHuman(i,4:6) = [0.3 0.3 0.3];
            end
        end
        human_struct = struct('Human',boxlabelsHuman,'Centroid',boxlabelsCentroid);
        human_stack = [human_stack ; human_struct];
    else 
        human_stack = [human_stack ; struct('Human',[],'Centroid',[])];
    end
    
    % DB stack
    if length(box(labels'=='Human',:)) > 0
        if frame==1
            % DB variable gen, concatnate
            DB = boxlabelsHuman;
            DB_size = size(DB);
            DB_cat = zeros(DB_size(1),4);
            DB = cat(2,DB,DB_cat);
        else
            DB_size = size(DB);
            DB_idx1 = [];
            DB_dist_flag = 0;
            % DB size == detect size
            if DB_size(1) == human_size(1)
                DB_idx3 = [];
                for i=1:1:DB_size(1)
                    % DB idx 
                    DB_idx2 = [];
                    for j=1:1:human_size(1)
                        % DB to detect object distance 
                        DB_idx2 = [DB_idx2;
                                sqrt(abs(DB(i,1)-boxlabelsHuman(j,1))^2 + abs(DB(i,2)-boxlabelsHuman(j,2))^2 + abs(DB(i,3)-boxlabelsHuman(j,3))^2), j];
                    end
                    
                    if min(DB_idx2(:,1))<R_threshold
                       % count up /pos
                       DB(i,10) = DB(i,10) + 1;
                       DB(i,11) = 0;
  
                       %DB update
                       DB(i,1:9) = boxlabelsHuman(find(DB_idx2==min(DB_idx2(:,1))),1:9);
                       DB_idx3 = [DB_idx3;find(DB_idx2==min(DB_idx2(:,1)))];
                    else
                       DB(i,11) = DB(i,11) + 1;
                       DB_dist_flag = 1;
                    end
                end
                if DB_dist_flag == 1
                    DB_idx3 = sort(DB_idx3);
                    DB_idx3 = unique(DB_idx3);
                    size_DB_idx3 = size(DB_idx3);
                    for k=1:1:size_DB_idx3(1)
                            boxlabelsHuman(DB_idx3(size_DB_idx3(1)-(k-1)),:) = [];
                    end
                    if size(boxlabelsHuman) >0
                        boxlabelsHuman_size = size(boxlabelsHuman);
                        boxlabelsHuman_cat = zeros(boxlabelsHuman_size(1),4);
                        DB_cat2 = cat(2,boxlabelsHuman,boxlabelsHuman_cat);
                        DB = cat(1,DB,DB_cat2);
                    end
                end
            elseif DB_size(1) > human_size(1)
                DB_idx3 = [];
                for i=1:1:DB_size(1)
                    % DB idx 
                    DB_idx2 = [];
                    for j=1:1:human_size(1)
                        % DB to detect object distance 
                        DB_idx2 = [DB_idx2;
                                sqrt(abs(DB(i,1)-boxlabelsHuman(j,1))^2 + abs(DB(i,2)-boxlabelsHuman(j,2))^2 + abs(DB(i,3)-boxlabelsHuman(j,3))^2), j];
                    end
                    
                    if min(DB_idx2(:,1))<R_threshold
                       % count up /pos
                       DB(i,10) = DB(i,10) + 1;
                       DB(i,11) = 0;

                       %DB update
                       DB(i,1:9) = boxlabelsHuman(find(DB_idx2==min(DB_idx2(:,1))),1:9);
                       DB_idx3 = [DB_idx3;find(DB_idx2==min(DB_idx2(:,1)))];
                    else
                       %DB(i,10) = 0;
                       DB(i,11) = DB(i,11) + 1;
                       DB_dist_flag = 1;
                    end

                    %DB_idx1 = [DB_idx1;min(DB_idx2(:,1)),boxlabelsHuman(find(DB_idx2==min(DB_idx2(:,1))),:)];
                end
                if DB_dist_flag == 1
                    DB_idx3 = sort(DB_idx3);
                    DB_idx3 = unique(DB_idx3);
                    size_DB_idx3 = size(DB_idx3);
                    for k=1:1:size_DB_idx3(1)
                        % prevent index exceedure
                        size_boxlabelsHuman = size(boxlabelsHuman);
                        if size_boxlabelsHuman(1) >0
                            boxlabelsHuman(DB_idx3(size_DB_idx3(1)-(k-1)),:) = [];
                        end
                    end
                    if size(boxlabelsHuman) >0
                        DB_size = size(boxlabelsHuman);
                        DB_cat = zeros(DB_size(1),4);
                        DB_cat2 = cat(2,boxlabelsHuman,DB_cat);
                        DB = cat(1,DB,DB_cat2);
                    end
                end
            elseif DB_size(1) < human_size(1)
                DB_idx3 = [];
                for i=1:1:DB_size(1)
                    % DB idx 
                    DB_idx2 = [];
                    for j=1:1:human_size(1)
                        % DB to detect object distance 
                        DB_idx2 = [DB_idx2;
                                sqrt(abs(DB(i,1)-boxlabelsHuman(j,1))^2 + abs(DB(i,2)-boxlabelsHuman(j,2))^2 + abs(DB(i,3)-boxlabelsHuman(j,3))^2), j];
                    end
                    
                    if min(DB_idx2(:,1))<R_threshold
                       % count up /pos
                       DB(i,10) = DB(i,10) + 1;
                       DB(i,11) = 0;

                       % DB update
                       DB(i,1:9) = boxlabelsHuman(find(DB_idx2==min(DB_idx2(:,1))),1:9);
                       DB_idx3 = [DB_idx3;find(DB_idx2==min(DB_idx2(:,1)))];
                    else
                       DB(i,11) = DB(i,11) + 1;
                       DB_dist_flag = 1;
                    end
                end
%                 if DB_dist_flag == 1
                    DB_idx3 = sort(DB_idx3);
                    DB_idx3 = unique(DB_idx3);
                    size_DB_idx3 = size(DB_idx3);
                    for k=1:1:size_DB_idx3(1)
                            boxlabelsHuman(DB_idx3(size_DB_idx3(1)-(k-1)),:) = [];
                    end
                    DB_size = size(boxlabelsHuman);
                    DB_cat = zeros(DB_size(1),4);
                    DB_cat2 = cat(2,boxlabelsHuman,DB_cat);
                    DB = cat(1,DB,DB_cat2);
%                 end
            end
            
        end
    else
        DB_size = size(DB);
        for i=1:1:DB_size(1)
            DB(i,11) = DB(i,11) + 1;
        end
    end
    % DB update
    DB_size = size(DB);
    DB_idx4 = [];
    for i = 1:1:DB_size(1)
        if DB(i,10) >= countpos_thres
            DB(i,12) = 1;
        end
        if DB(i,11) >= countneg_thres
            DB(i,12) = 0;
            DB_idx4 = [DB_idx4; i];
        end
    end
    if size(DB_idx4) >0
        DB_idx4 = sort(DB_idx4);
        for i = 1:1:size(DB_idx4)
            idx_size = size(DB_idx4);
            DB(DB_idx4(idx_size(1)-(i-1)),:) = [];
        end
    end

    DB_size = size(DB);
    DB_idx5 = [];
    for i = 1:1:DB_size(1)-1
        for j = i+1:1:DB_size(1)
            if DB(i,1) == DB(j,1) 
                DB_idx5 = [DB_idx5;j];
            end
        end
    end
    if DB_size(1)>0
        DB_idx5 = sort(DB_idx5);
        DB_idx5 = unique(DB_idx5);
        size_DB_idx5 = size(DB_idx5);
        for k=1:1:size_DB_idx5(1)
            DB(DB_idx5(size_DB_idx5(1)-(k-1)),:) = [];
        end
    end
    
    DB_struct = struct('DB',DB);
    DB_stack = [DB_stack ; DB_struct];
end


%% post processing
detectLabel = zeros(maxframes,2);

view_DB_mat = [];
for i = 1:1:maxframes
    box_DB = DB_stack(i).DB;
    view_DB = [];
    size_box_DB = size(box_DB);
    for j=1:1:size_box_DB(1)
        if box_DB(j,12) == 1
            view_DB = [view_DB; box_DB(j,1:13),j];
        end
    end
    
    size_view_DB = size(view_DB);
    if size_view_DB(1) > 0 && i>2
        box_DB_prev = DB_stack(i-1).DB;
        for k = 1:1:size_view_DB(1)
            if box_DB_prev(view_DB(k,14),13) == 0 && view_DB(k,2) >= Danger_area_detect(3) && view_DB(k,2) <= Danger_area_detect(4)
                detectLabel(i,2) = detectLabel(i,2) + 1;
                box_DB(view_DB(k,14),13) = 1;
            elseif box_DB_prev(view_DB(k,14),13) == 1 && view_DB(k,2) >= Danger_area_hist(3) && view_DB(k,2) <= Danger_area_hist(4)
                detectLabel(i,2) = detectLabel(i,2) + 1;
                box_DB(view_DB(k,14),13) = 1;
            elseif box_DB_prev(view_DB(k,14),13) == 1 && view_DB(k,2) <= Danger_area_hist(3) && view_DB(k,2) >= Danger_area_hist(4)
                detectLabel(i,1) = detectLabel(i,1) + 1;
                box_DB(view_DB(k,14),13) = 0;
            elseif box_DB_prev(view_DB(k,14),13) ~= 1 && view_DB(k,2) >= Detecting_area1(3) && view_DB(k,2) <= Detecting_area1(4)
                detectLabel(i,1) = detectLabel(i,1) + 1;
            elseif box_DB_prev(view_DB(k,14),13) ~= 1 && view_DB(k,2) >= Detecting_area2(3) && view_DB(k,2) <= Detecting_area2(4)
                detectLabel(i,1) = detectLabel(i,1) + 1;
            
            end
        end
    else
        detectLabel(i,:) = 0;
    end
    DB_stack(i) = struct('DB',box_DB);
end

%% View Player

close all
% Roi set
xlimits = [-12 12];
ylimits = [-10 0];
zlimits = [-5,5];

player1 = pcplayer(xlimits,ylimits,zlimits);
xlabel(player1.Axes,'X (m)');
ylabel(player1.Axes,'Y (m)');
zlabel(player1.Axes,'Z (m)');


figure(21)
% TODO: 2D ANIMATION

axis([-7 7 -10 0]); title('Bird Eye View of Detection Result', 'FontSize', 14);
yline(Detecting_area1(4)   , '--', {'Detecting'});
yline(Danger_area(4)   , '--', {'Danger'});

% Background
% rectangle('Position', [-7, -10, 14, 10],"FaceColor",[1, 1, 1, 1]);
% Danger
rectangle('Position', [Danger_area(1), -10, Danger_area(2)-Danger_area(1), Danger_area(4)-Danger_area(3)], 'FaceColor', [1, 0, 0, 0.2]);
% Caution
rectangle('Position', [Detecting_area1(1), Detecting_area1(3), Detecting_area1(2)-Detecting_area1(1), Detecting_area1(4)-Detecting_area1(3)], 'FaceColor', [0, 1, 0, 0.2]);

for i = 1:1:maxframes
    % pause for n seconds
    if i==2
        pause(2);
    end
    box_DB = DB_stack(i).DB;
    view_DB = [];
    size_box_DB = size(box_DB);
    for j=1:1:size_box_DB(1)
        if box_DB(j,12) == 1
            view_DB = [view_DB; box_DB(j,1:13)];
        end
    end
    % pointcloud load from stack
    ptCloud = ptCloud_stack(i);
    view(player1,ptCloud);
    box_human = human_stack(i).Human;
    box_DB = DB_stack(i).DB;

    if detect_option == 0
        box_human = human_stack(i).Human;
        if height(view_DB)>0
            showShape('cuboid',view_DB(:,1:9) ,'Parent',player1.Axes,'Opacity',0.1,'Color','magenta','LineWidth',0.5);
        end        
    elseif detect_option == 1
        box_upper = upper_stack(i).Upper;
        showShape('cuboid',[box_upper;box_human] ,'Parent',player1.Axes,'Opacity',0.1,'Color','magenta','LineWidth',0.5);
        showShape('cuboid',[box_upper;box_human] ,'Parent',player2.Axes,'Opacity',0.1,'Color','magenta','LineWidth',0.5);
    end
    
    % 2D Animation
    cla;
    axis([-7 7 -10 0]); title('Bird Eye View of Detection Result', 'FontSize', 14);
    yline(Detecting_area1(4)   , '--', {'Detecting'});
    yline(Danger_area(4)   , '--', {'Detecting'});
    
    % Danger
    rectangle('Position', [Danger_area(1), -10, Danger_area(2)-Danger_area(1), Danger_area(4)-Danger_area(3)], 'FaceColor', [1, 0, 0, 0.2]);
    % Caution
    rectangle('Position', [Detecting_area1(1), Detecting_area1(3), Detecting_area1(2)-Detecting_area1(1), Detecting_area1(4)-Detecting_area1(3)], 'FaceColor', [0, 1, 0, 0.2]);

    if height(view_DB)>0
        circles = [];
        for m = 1:1:height(view_DB)
            if view_DB(m,13)==1
                circles = [circles; viscircles(view_DB(m,1:2), 0.2, "Color", 'red')];
                text(4,-1,'WARNING','Color','red','FontSize',14)
            elseif view_DB(m,13)==0
                circles = [circles; viscircles(view_DB(m,1:2), 0.2, "Color", 'black')];
            end
        end
    end
   
    pause(0.1);
end
