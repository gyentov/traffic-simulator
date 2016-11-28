function vehicle = DrawAllVehicles(inter, vehicle, road, lane, time, max_speed)
    
    %number of Vehicles in Queue
    if ~isfield(vehicle, 'length')
        in_queue = 0;
    else
        in_queue = length(vehicle); 
    end
    
    % Draw all old vehicles and current time
    if in_queue > 0
        for i = 1:in_queue
            vehicle(i).figure = DrawVehicle(vehicle(i));
        end
    end
    
    % Now assign and draw new vehicles
    if isnan(road) == false
        % number of new Vehicles Spawned
        num_spawned = length(road);
        % make assignments and draw

        for j = 1:num_spawned
            [vehicle] = MakeVehicle(inter, vehicle, in_queue + j, lane(j), road(j), time, max_speed);
            vehicle(in_queue+j).figure = DrawVehicle(vehicle(in_queue+j));
        end
    end
end