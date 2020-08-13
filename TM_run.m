clear all; close all; format short g; clc; 

%% PREPARATION

% PATHs 

% Please modify these paths both in this script and script.log file. 
path="C:\TAHIR\Docs\Master\MastersITALY\Verona\35thModellingweekStPetersburg\codes";
pathslaves=append(path, '\data\fastener_stiffness_1E2\slaves.slv');
cmdsim=append(path, '\Simulator_batch -open=script.log');

% THE OPTIMAL CONFIGURATION

optimal_config = importdata('optimal_configuration.dat');
opt_data = optimal_config.data

% DATA
fastened_nodes = opt_data(opt_data(:,6) == 1000) % these are nodes where fasteners will eventually have to be installed. 
node_coords = opt_data(fastened_nodes',2:3) % Z coordinate remains the same, so we will slice only for X and Y coords. 
gaps = opt_data(:,5) 
num_nodes = length(fastened_nodes); 

% defining a matrix of relative distances between fasteners installed in fastened_nodes 
X = opt_data(:,2); Y = opt_data(:,3);
X_t = X'; Y_t = Y'; 
dX = X - X_t; dY = Y - Y_t; 
dists = triu(sqrt(dX.^2 + dY.^2)); % note that this matrix is symmetric, dists(i,j) = distance between node_coords(i) and node_coords(j)

% stats
ideal_gap_mean = sum(gaps) / length(gaps)
ideal_gap_stdev = std(gaps)
mean_tol = 0.01  
stdev_tol = 0.02 

% collecting gaps, forces, mean and variance at each installation step. 
updated_gaps = zeros(40,40);
updated_forces = zeros(40,40);
updated_gaps_mean = zeros(1,40);
updated_gaps_stdev = zeros(1,40);
t = zeros(30,1); % we store how much time it took to install each consequative fasteners and run the simulation


%% ALGORITHM RUN

action_count = 0;
empty_nodes = fastened_nodes; % at start we have a full empty nodes list, but the list will be shortening as we progress.
already_fastened_nodes = double.empty(20,0);  % listed NOT in the order of installation (no repeated nodes)
fastening_order = double.empty(30,0); % here we list fasteners in the order of installation, including repeated nodes 
action_types = cell(30,1); % ordered list of action_types for each performed action ( the worst case scenario is 40 actions)
forces = zeros(40,1); % initial forces are 0 and gaps are at maximum = 6 mm. 


for count=1:40   
   
    delete results.dat
    delete results_allNodes.dat
    delete results_allGaps.dat
        
    if isempty(empty_nodes) && (sum(forces(already_fastened_nodes) > 990) == length(forces(already_fastened_nodes)))
        return
    elseif ~isempty(empty_nodes)
        [next_node,next_action_type] = TM_MAXPERIM(empty_nodes,already_fastened_nodes,dists,forces); % here you get the next action (either install a fastener in node j, or tighten a fast in node h) 
    end
        
    % UPDATED ARRAYS (different from what's given in results.dat)
    action_count = action_count + 1; % indicates that we successfully performed the action
    fastening_order = [fastening_order,next_node];
    action_types(count) = {next_action_type}; % must be either 'a tightened fastener' or 'a new fastener'
    
    if ismember(next_node,already_fastened_nodes)
        % we don't change the already_fastened_nodes! but we change fastening_order list. 
    else
        already_fastened_nodes = [already_fastened_nodes, next_node]; % add our new fastened node to the list of already fastened ones
        empty_nodes = empty_nodes(empty_nodes ~= next_node); % next_node is fastened, hence no longer belongs to empty_nodes list      
    end
    
    % FOR DISPLAY
    action_count
    empty_nodes
    already_fastened_nodes
    fastening_order
    action_types
    
    % UPDATE .slv FILE
    % slv file contains the updated order of installation. It is fed into
    % software that updates gaps, forces and simulates the changes.
    fileID = fopen(pathslaves, 'w');
    fastening_order_str = num2str(fastening_order);
    fprintf(fileID, '%s', fastening_order_str);
    fclose(fileID);
    
    % SIMULATION RUN
     tic; system(cmdsim); t(action_count,1)=toc; % we calculate how much time it took to simulate each action 
   
    % UPDATED results.dat
    results=importdata('results.dat');
    updated_results = results.data;
    
    % STATISTICS RECALCULATION  and UPDATED GAPS, FORCES
    updated_gaps(:,action_count) = updated_results(1:40,5);
    updated_forces(:,action_count) = updated_results(1:40,6)
    updated_gaps_mean(1,action_count) = mean(updated_gaps(:,action_count))
    updated_gaps_stdev(1,action_count) = std(updated_gaps(:,action_count))
    forces = updated_results(1:40,6);
    
    % ACTION STOP CRITERIA 
    if (abs(updated_gaps_mean(1,action_count) - ideal_gap_mean) <= mean_tol) && (abs(updated_gaps_stdev(1,action_count) - ideal_gap_stdev) <= stdev_tol)   
        return % we are in the confidence interval, an acceptable uniform distribution of gaps
    else
        continue % not there yet, need to perform more actions
    end 
 
end


%% ANALYSIS OF FINAL RESULTS

action_count
empty_nodes
already_fastened_nodes 
sequence = {fastening_order, action_types}
updated_gaps
updated_forces
updated_gaps_mean
updated_gaps_stdev
t


