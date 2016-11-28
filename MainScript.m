clear; clc; close all
hold on;

% Initialize parameters
delta_t = .1;
num_iter = 600;
num_intersections = 1;
weight_thresh = 0.1; % 0 means time is added once a vehicle is stopped, 1 means time is added after slowing from max
h = 0.1; % coefficient in weighting function
policy = 2; % 1 is cyclical policy, 2 is weight comparison policy
max_speed = 20; % speed limit of system
yellow_time = max_speed/4;
phase_length = 35; % time of whole intersection cycle
min_time = 5; % minimum time spent in a phase
switch_threshold = 1; % 0 means wait time must be greater to switch, 1 means double
spawn_rate = .2; % average vehicles per second
spawn_type = 'poisson'; % 'poisson'
all_straight = true; % true if no turns exist
num_roads = 4; % number of roads
num_lanes = 3; % number of lanes
lane_width = 3.2;
lane_length = 100;

if all_straight
    straight_list = 1:num_lanes;
    turn_radius = Inf*ones(num_lanes,1);
    turn_length = 2*num_lanes*lane_width*ones(num_lanes,1);
else
    straight_list = 2:num_lanes-1;
    turn_radius = [(lane_width/2) Inf (7*lane_width/2)];
    turn_length = [(pi/2)*(lane_width/2) 2*num_lanes*lane_width (pi/2)*(7*lane_width/2)];
end

inter = MakeIntersection(num_intersections, lane_width, lane_length, num_lanes, all_straight); 
fig = DrawIntersection(inter);

rng(1000)
[road,lane] = SpawnVehicles(spawn_rate, num_roads, num_lanes, 0, delta_t, spawn_type);
time_enter = 0;
% make and draw all Vehicles according to chosen roads and lanes
vehicle = struct;
vehicle = DrawAllVehicles(inter, vehicle, road, lane, time_enter, max_speed);
% This keeps track of last vehicle to spawn in each lane, to check for
% collisions
latest_spawn = zeros(num_roads, num_lanes);

% Play this mj2 file with VLC
vid_obj = VideoWriter('movie.avi','Archival');
vid_obj.FrameRate = 1/delta_t;
open(vid_obj);

% These parameters solve the equations for psi = 2 and T = 10
c = [.54 1.5 1.5 -.95];
weight = @(t) c(1) * (t + c(2))^c(3) + c(4);

switch_time = Inf;
inter(1).green = [1 3];
previous_state = 1;
title_str = 'green light on vertical road';
t = 0;
% Run simulation 
for t = delta_t*(1:num_iter)
    
    % Calculates weight in each lane
    W = [0 0];
    if ~isempty(fieldnames(vehicle))
        for i = 1:length(vehicle)
            if (vehicle(i).time_enter ~= -1 && vehicle(i).time_leave == -1 && ismember(vehicle(i).lane,1:num_lanes))
                switch vehicle(i).road
                    case 1
                        W(1) = W(1) + weight(vehicle(i).wait);
                    case 2
                        W(2) = W(2) + weight(vehicle(i).wait);
                    case 3
                        W(1) = W(1) + weight(vehicle(i).wait);
                    case 4
                        W(2) = W(2) + weight(vehicle(i).wait);
                end
            end
        end
    end
    
    % Yellow light time needs to be function of max velocity! Not a
    % function of phase_length
    if policy == 1
        if mod(t,phase_length) < phase_length/2 - yellow_time
            inter(1).green = [1 3];
            title_str = 'green light on vertical road';
        elseif mod(t,phase_length) < phase_length/2
            inter(1).green = [];
            title_str = 'yellow light on vertical road';
        elseif mod(t,phase_length) < phase_length - yellow_time
            inter(1).green = [2 4];
            title_str = 'green light on horizontal road';
        else
            inter(1).green = [];
            title_str = 'yellow light on horizontal road';
        end

    elseif policy == 2 
        if switch_time < yellow_time
            inter(1).green = [];
            if previous_state == 1
                title_str = 'yellow light on horizontal road';
            elseif previous_state == 2
                title_str = 'yellow light on vertical road';
            end
        elseif switch_time < yellow_time + min_time
            if previous_state == 1
                title_str = 'green light on vertical road';
                inter(1).green = [1 3];
            elseif previous_state == 2
                title_str = 'green light on horizontal road';
                inter(1).green = [2 4];
            end
        else  % if switching is an option
            if previous_state == 2 && (W(1) - W(2))/W(2) > switch_threshold
                switch_time = 0;
                inter(1).green = [1 3];
                previous_state = 1;
            elseif previous_state == 1 && (W(2) - W(1))/W(1) > switch_threshold
                switch_time = 0;
                inter(1).green = [2 4];
                previous_state = 2;
            end
        end
        
    end
    title([sprintf('t = %3.f, ',t) title_str])
    text_box = uicontrol('style','text');
    if policy == 2
        text_str = ['Custom Wait Time Policy     ';
            '  vertical weight = ', sprintf('%8.2f',W(1));
            'horizontal weight = ', sprintf('%8.2f',W(2))];
    elseif policy == 1
        text_str = ['Fixed Cycle Policy          ';
            '  vertical weight = ', sprintf('%8.2f',W(1)); 
            'horizontal weight = ', sprintf('%8.2f',W(2))];
    else
        text_str = ['  vertical weight =   ', sprintf('%8.2f',W(1)); 
            'horizontal weight = ', sprintf('%8.2f',W(2))];
    end
    set(text_box,'String',text_str)
    set(text_box,'Units','characters')
    set(text_box,'Position', [6 6 50 5])
    
    % set(textBox,'Position',[200 200 100 50])
    
    % if vehicle is nonempty, run dynamics, update wait, and draw vehicle
    if ~isempty(fieldnames(vehicle))
        vehicle = RunDynamics(inter, vehicle, straight_list, turn_radius, turn_length, t, delta_t);
        for i = 1:length(vehicle)
            if vehicle(i).velocity <= weight_thresh*vehicle(i).max_velocity
                vehicle(i).wait = vehicle(i).wait + delta_t;
            end
            if isfield(vehicle, 'figure')
                delete(vehicle(i).figure);
            end
            if (vehicle(i).time_leave == -1 && vehicle(i).time_enter ~= -1)
                vehicle(i).figure = DrawVehicle(vehicle(i));
            end
        end
    end
    
    pause(0.05)
    current_frame = getframe(gcf);
    writeVideo(vid_obj, current_frame);
    
    % Now spawn new vehicles
    [road,lane] = SpawnVehicles(spawn_rate, num_roads, num_lanes, t, delta_t, spawn_type);
    if isempty(fieldnames(vehicle(1))) 
        ctr = 0; % overwrites the empty vehicle
    else
        ctr = length(vehicle); % count number of cars already spawned
    end
    if ~isnan(road) % if spawned at least one
        for j = 1:length(road) % assign every car its road and lane
            % If the last vehicle to spawn in the lane is too close, don't
            % spawn
            if latest_spawn(road(j),lane(j)) == 0 || ...
              norm(vehicle(latest_spawn(road(j),lane(j))).position - ...
              vehicle(latest_spawn(road(j),lane(j))).starting_point, 2) > ...
              4*vehicle(latest_spawn(road(j),lane(j))).length
                [vehicle] = MakeVehicle(inter, vehicle, (ctr + 1), lane(j), road(j), t, max_speed);
                latest_spawn(road(j),lane(j)) = ctr + 1;
                ctr = ctr + 1;
            end
        end
    end
    
    switch_time = switch_time + delta_t;
end

close(vid_obj);
close(gcf);

% Post processing
total_time = 0;
total_wait_time = 0;
total_weighted_wait_time = 0;
for i = 1:length(vehicle)
    time = vehicle(i).time_leave - vehicle(i).time_enter;
    if time > 0
        total_time = total_time + time;
    end
    total_wait_time = total_wait_time + vehicle(i).wait;
    total_weighted_wait_time = total_weighted_wait_time + weight(vehicle(i).wait);
end

% TO DO LIST
% All the random stuff mentioned in the code already
% Program motion in intersection
% Make stops more accurate, have vehicles correct at slow speed, or just lock into destination when close
% When extending to multiple intersections, have vehicle(i).wait reset when entering a new intersection
% Initialize vehicle structs, make it a fixed size
% Make an option to run without graphics
% Use tic toc to figure out where MATLAB bottlenecks already
% Make phase change trigger match LaTeX doc, use eta and check that W(1) > eta*W(2)