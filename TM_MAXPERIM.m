function [next_node,next_action_type] = TM_MAXPERIM(empty_nodes,already_fastened_nodes,dists,forces)

%% DEFINITIONS 

% next_node = the index of the next node
% action_type: ' a tightened fastener' or ' a new fastener' 

%% 

if isempty(already_fastened_nodes)
    
    next_node = empty_nodes(1); % doesn't matter where we start from
    next_action_type = 'new fastener';
   
elseif length(already_fastened_nodes) == 1
   
    mx = max(dists(1,empty_nodes')); % the second fastener is intalled at the farthest node
   [~, next_node] = find(dists(1,:) == mx);
   next_action_type = 'new fastener';
    
elseif length(already_fastened_nodes) >= 2
    
    mtlb_idx = already_fastened_nodes + 1; % changing an index from software to matlab language
    minimal = min(forces(mtlb_idx)); 
    if minimal <= 990 
        index = find(forces(mtlb_idx) == minimal);
        next_node = already_fastened_nodes(index) ;
        next_action_type = 'a tightened fastener';
    else
        distsumslst = [empty_nodes,zeros(length(empty_nodes),1)]; % col1 = list of empty nodes, col2 = max distance sums corresponding with the installation of node in col1
        idx = 1;
        while idx <= length(empty_nodes)
            for node=empty_nodes(idx)
       
            node;
            distsum = sum(dists(node,already_fastened_nodes));  % calculating all perimeters
            distsumslst(idx,2) = distsum;
            idx = idx + 1;
            end
        end
    
    
        mx = max(distsumslst(:,2)); % choosing the max perimeter
        [row, ~] = find(distsumslst(:,2) == mx);
        next_node = empty_nodes(row,1); % identifying the node that corresponds to max perimeter
        next_action_type = 'new fastener';
          
    end
end

end
      