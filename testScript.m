clear; clc; close all

% %% Julio's Test
% 
% % create default Intersection
% [inters2] = makeIntersection2(); 
% 
% % draw Intersection
% [FIG2] = drawIntersection(inters2);
% 
% % hold on to figure, future plots on same figure
% hold on;
% 
% % declare vehicle structure
% vehicle2 = struct;
% 
% % Spawn Vehicles
% lambda = 2; road = 4; lane = 3;
% [road,lane] = poissonSpawn(lambda, road, lane);
% time_enter = 0;
% t = 0;
% if isnan(road) == 0
%     for i = 1:length(road)
%         [vehicle2] = makeVehicle(inters2,vehicle2, i, lane(i), road(i), time_enter);
%         vehicle2(i).figure = drawVehicle(vehicle2(i), t);
%     end
% end


%% Evan's Test

% create default Intersection
[inters] = makeIntersection2(); 

% draw Intersection
[FIG] = drawIntersection(inters);

% hold on to figure, future plots on same figure
hold on;

% declare vehicle structure
vehicle = struct;

% initialize simulation parameters
t = 0;
delta_t = .1;
phase_length = 30; % time of whole intersection cycle
num_iter = 0.5*phase_length/delta_t;

% % first vehicle
% i = 1; % vehicle number
% road = 4; % vehicle road
% lane = 3; % vehicle lane
% time_enter = 0;
% % here false stands for 'not empty'
% [vehicle] = makeVehicle(inters, vehicle, i, lane, road, time_enter);
% vehicle(i).figure = drawVehicle(vehicle(i));
% 
% % second vehicle
% i = 2; % vehicle number
% road = 1; % vehicle road
% lane = 2; % vehicle lane
% time_enter = 0;
% [vehicle] = makeVehicle(inters, vehicle, i, lane, road, time_enter);
% vehicle(i).figure = drawVehicle(vehicle(i));

%--------------------------------------------------------------------------
% SPAWN VEHICLES  !!!USE THIS INSTEAD IF YOU WANT TO SPAWN RANDOMLY!!!
lambda = 2*delta_t; % spawn rate, average vehicles per second
num_roads = 4; % number of roads
num_lanes = 3; % number of lanes
% randomly choose roads and lanes (generally returns a vector)
[road,lane] = poissonSpawn(lambda, num_roads, num_lanes); 
time_enter = 0;
% make and draw all Vehicles according to chosen roads and lanes
[vehicle]= drawAllVehicles(inters, vehicle, road, lane, time_enter);
% END OF SPAWNING
%--------------------------------------------------------------------------

% Play this mj2 file with VLC
vid_obj = VideoWriter('movie.avi','Archival');
vid_obj.FrameRate = 1/delta_t;
open(vid_obj);

% run simulation 
for t = delta_t*(1:num_iter)
    
    % Yellow light time needs to be function of max velocity! Not a
    % function of phase_length
    if mod(t,phase_length) < 2*phase_length/5
        inters(1).green = [1 3];
    elseif mod(t,phase_length) < phase_length/2
        inters(1).green = [];
    elseif mod(t,phase_length) < 9*phase_length/10
        inters(1).green = [2 4];
    else
        inters(1).green = [];
    end
    
    % if vehicle is nonempty, run dynamics
    if ~isempty(fieldnames(vehicle))
        vehicle = runDynamics(inters, vehicle, t, delta_t);
        for i = 1:length(vehicle)
            delete(vehicle(i).figure);
            if (vehicle(i).time_leave == -1 && vehicle(i).time_enter ~= -1)
                vehicle(i).figure = drawVehicle(vehicle(i));
            end
        end
        title(sprintf('t = %3.f',t))
    end
    
    % Spawn vehicles at each time step
    % [road,lane] = poissonSpawn(lambda, num_roads, num_lanes); 
    % time_enter = 0;
    % make and draw all Vehicles according to chosen roads and lanes
    % [vehicle]= makeAllVehicles(inters, vehicle, road, lane, time_enter, t, false);
    
    pause(0.05)
    current_frame = getframe;
    writeVideo(vid_obj, current_frame);
    
    % Now spawn new vehicles
    [road,lane] = poissonSpawn(lambda, num_roads, num_lanes); 
    in_queue = length(vehicle); % count number of cars already in the intersection
    if isnan(road) == 0 % if spawned at least one
        for j = 1:length(road) %assign every car its road and lane
            [vehicle] = makeVehicle(inters,vehicle, (in_queue + j), lane(j), road(j), t);
        end
    end
end

close(vid_obj);