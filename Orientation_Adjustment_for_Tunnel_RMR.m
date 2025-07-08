function [results, summary] =Orientation_Adjustment_for_Tunnel_RMR(jointData, tunnel_direction, varargin)

% Limitation of Bieniawski's method==> what is the meaning of a discontinuity perpendicular or parallel to a tunnel==>
% My assumption==> In this code in Rule B: Strike perpendicular to tunnel (acute angle between discontinuity and tunnel > 35°)
    
    % Close any existing RMR GUI figures from previous runs
    existingFigs = findall(0, 'Type', 'figure', 'Name', 'Simple RMR Joint Orientation Analysis');
    if ~isempty(existingFigs)
        close(existingFigs);
    end
    
    % Parse optional arguments
    p = inputParser;
    addParameter(p, 'showGUI', true, @islogical);
    parse(p, varargin{:});
    
    showGUI = p.Results.showGUI;
    
    % Input validation and processing
    if nargin < 1 || isempty(jointData)
        error('Joint data is required. Please provide structured array with dipDirection and dip fields.');
    end
    
    % Validate tunnel direction
    if nargin < 2 || isempty(tunnel_direction)
        tunnel_direction = 0; % Default to North
    end
    tunnel_direction = mod(tunnel_direction, 360);
    
    % Validate and process input data
    jointSets = processInputData(jointData);
    
    % Calculate RMR scores for all joint sets
    for i = 1:length(jointSets)
        [jointSets(i).rmrScore, jointSets(i).category] = calculateRMRScore(jointSets(i).dipDirection, jointSets(i).dip, tunnel_direction);
        jointSets(i).favorability = getFavorabilityLevel(jointSets(i).rmrScore);
    end
    
    % Prepare output results
    results = jointSets;
    summary = generateSummary(jointSets);
    
    % Display results to command window
    displayResults(results, summary, tunnel_direction);
    
    % Show GUI if requested and wait for it to close
    if showGUI
        createGUI(jointSets, tunnel_direction);
    end
end

function jointSets = processInputData(jointData)
    % Validate input structure
    if ~isstruct(jointData)
        error('Input must be a structured array');
    end
    
    % Check required fields
    if ~isfield(jointData, 'dipDirection') || ~isfield(jointData, 'dip')
        error('Input structure must contain dipDirection and dip fields');
    end
    
    % Validate data ranges
    for i = 1:length(jointData)
        if jointData(i).dipDirection < 0 || jointData(i).dipDirection > 360
            warning('Joint %d: dipDirection %.1f° is outside valid range [0-360°]', i, jointData(i).dipDirection);
        end
        if jointData(i).dip < 0 || jointData(i).dip > 90
            warning('Joint %d: dip %.1f° is outside valid range [0-90°]', i, jointData(i).dip);
        end
    end
    
    % Process and normalize data
    jointSets = [];
    for i = 1:length(jointData)
        jointSets(i).dipDirection = mod(jointData(i).dipDirection, 360);
        jointSets(i).dip = max(0, min(90, jointData(i).dip));
        
        % Add name if not provided
        if isfield(jointData, 'name') && ~isempty(jointData(i).name)
            jointSets(i).name = jointData(i).name;
        else
            jointSets(i).name = sprintf('Joint Set %d', i);
        end
    end
end

function summary = generateSummary(jointSets)
    % Generate comprehensive summary
    scores = [jointSets.rmrScore];
    
    summary.totalJointSets = length(jointSets);
    summary.averageScore = mean(scores);
    summary.minScore = min(scores);
    summary.maxScore = max(scores);
    
    % Find critical joint set
    [~, criticalIdx] = min(scores);
    summary.criticalJointSet = jointSets(criticalIdx);
    
    % Count by category
    categories = {jointSets.category};
    uniqueCategories = unique(categories);
    for i = 1:length(uniqueCategories)
        count = sum(strcmp(categories, uniqueCategories{i}));
        summary.categoryCount.(strrep(uniqueCategories{i}, ' ', '_')) = count;
    end
    
    % Overall assessment
    if summary.minScore >= 0
        summary.overallAssessment = 'Generally Favorable';
    elseif summary.minScore >= -2
        summary.overallAssessment = 'Moderately Favorable';
    elseif summary.minScore >= -5
        summary.overallAssessment = 'Requires Attention';
    else
        summary.overallAssessment = 'High Risk - Requires Immediate Attention';
    end
end

function displayResults(results, summary, tunnel_direction)
    % Display results in command window
    fprintf('\n=== RMR JOINT ORIENTATION ANALYSIS RESULTS ===\n');
    fprintf('Tunnel Direction: %.0f° (%.0f° from North)\n', tunnel_direction, tunnel_direction);
    fprintf('Analysis Date: %s\n\n', datestr(now));
    
    % Individual results
    fprintf('INDIVIDUAL JOINT SET ANALYSIS:\n');
    fprintf('%-15s %-12s %-8s %-10s %-18s\n', 'Joint Set', 'Dip Dir.', 'Dip', 'RMR Score', 'Category');
    fprintf('%-15s %-12s %-8s %-10s %-18s\n', repmat('-', 1, 15), repmat('-', 1, 12), repmat('-', 1, 8), repmat('-', 1, 10), repmat('-', 1, 18));
    
    for i = 1:length(results)
        fprintf('%-15s %-12.0f° %-8.0f° %-10d %-18s\n', ...
            results(i).name, results(i).dipDirection, results(i).dip, ...
            results(i).rmrScore, results(i).category);
    end
    
    % Summary statistics
    fprintf('\nSUMMARY STATISTICS:\n');
    fprintf('Total Joint Sets: %d\n', summary.totalJointSets);
    fprintf('Average RMR Score: %.1f\n', summary.averageScore);
    fprintf('Score Range: %d to %d\n', summary.minScore, summary.maxScore);
    fprintf('Overall Assessment: %s\n', summary.overallAssessment);
    
    % Critical analysis
    fprintf('\nCRITICAL ANALYSIS:\n');
    fprintf('Most Critical Joint Set: %s\n', summary.criticalJointSet.name);
    fprintf('Lowest RMR Score: %d\n', summary.criticalJointSet.rmrScore);
    fprintf('Category: %s\n', summary.criticalJointSet.category);
    fprintf('Orientation: Dip Direction %.0f°, Dip %.0f°\n', ...
        summary.criticalJointSet.dipDirection, summary.criticalJointSet.dip);
    
    % Category distribution
    fprintf('\nCATEGORY DISTRIBUTION:\n');
    fields = fieldnames(summary.categoryCount);
    for i = 1:length(fields)
        category = strrep(fields{i}, '_', ' ');
        count = summary.categoryCount.(fields{i});
        fprintf('%s: %d joint set(s)\n', category, count);
    end
    
    fprintf('\n=== END OF ANALYSIS ===\n\n');
end

function createGUI(jointSets, tunnel_direction)
    % Create main figure
    fig = figure('Name', 'Simple RMR Joint Orientation Analysis', ...
                 'Position', [50, 50, 1000, 700], ...
                 'NumberTitle', 'off', ...
                 'MenuBar', 'none', ...
                 'ToolBar', 'none', ...
                 'Color', [0.95, 0.95, 0.95], ...
                 'Units', 'normalized');
    
    % Store data in figure
    setappdata(fig, 'jointSets', jointSets);
    setappdata(fig, 'tunnel_direction', tunnel_direction);
    
    % Set resize callback
    set(fig, 'ResizeFcn', @(src, evt) resizeCallback(src, evt));
    
    % Initial layout
    updateLayout(fig);
    
    % Wait for figure to be closed
    uiwait(fig);
    
    % Resize callback function
    function resizeCallback(src, ~)
        updateLayout(src);
    end
    
    % Layout update function
    function updateLayout(figHandle)
        if ~ishandle(figHandle) || ~isvalid(figHandle)
            return;
        end
        
        % Clear existing UI elements except legend
        children = get(figHandle, 'Children');
        for i = 1:length(children)
            if isvalid(children(i)) && ~strcmp(get(children(i), 'Tag'), 'legend_panel')
                delete(children(i));
            end
        end
        
        % Get current joint sets and tunnel direction
        currentJointSets = getappdata(figHandle, 'jointSets');
        current_tunnel_direction = getappdata(figHandle, 'tunnel_direction');
        if isempty(currentJointSets)
            currentJointSets = jointSets;
            setappdata(figHandle, 'jointSets', currentJointSets);
        end
        if isempty(current_tunnel_direction)
            current_tunnel_direction = tunnel_direction;
            setappdata(figHandle, 'tunnel_direction', current_tunnel_direction);
        end
        
        numSets = length(currentJointSets);
        
        % Calculate optimal grid layout
        [rows, cols] = calculateOptimalLayout(numSets);
        
        % Title
        titleText = sprintf('RMR Joint Orientation Analysis - Tunnel Direction: %.0f°', current_tunnel_direction);
        uicontrol('Parent', figHandle, 'Style', 'text', ...
                  'String', titleText, ...
                  'Units', 'normalized', ...
                  'Position', [0.05, 0.92, 0.9, 0.05], ...
                  'FontSize', 16, 'FontWeight', 'bold', ...
                  'BackgroundColor', [0.95, 0.95, 0.95]);
        
        % Only Close button (Export button removed)
        uicontrol('Parent', figHandle, 'Style', 'pushbutton', ...
                  'String', 'Close', ...
                  'Units', 'normalized', ...
                  'Position', [0.05, 0.02, 0.08, 0.05], ...
                  'FontSize', 12, 'FontWeight', 'bold', ...
                  'Callback', @(~,~) close(figHandle));
        
        % Calculate layout parameters
        plotAreaTop = 0.87;
        plotAreaBottom = 0.25;
        plotAreaHeight = plotAreaTop - plotAreaBottom;
        
        showLegend = numSets > 1;
        if showLegend
            plotAreaRight = 0.78;
        else
            plotAreaRight = 0.95;
        end
        plotAreaLeft = 0.05;
        plotAreaWidth = plotAreaRight - plotAreaLeft;
        
        plotWidth = plotAreaWidth / cols;
        plotHeight = plotAreaHeight / rows;
        
        % Create subplot axes for each joint set
        for i = 1:numSets
            % Calculate grid position
            col = mod(i-1, cols) + 1;
            row = ceil(i/cols);
            
            % Calculate normalized position
            marginX = plotWidth * 0.05;
            marginY = plotHeight * 0.15;
            
            left = plotAreaLeft + (col-1) * plotWidth + marginX;
            bottom = plotAreaTop - row * plotHeight + marginY;
            width = plotWidth - 2 * marginX;
            height = plotHeight - 2 * marginY;
            
            % Ensure minimum size
            width = max(width, 0.15);
            height = max(height, 0.15);
            
            % Create axes
            ax = axes('Parent', figHandle, 'Units', 'normalized', ...
                     'Position', [left, bottom, width, height]);
            
            % Draw visualization
            drawJointVisualization(ax, currentJointSets(i), current_tunnel_direction);
            
            % Add score text
            scoreText = sprintf('Dip Dir: %.0f°, Dip: %.0f°\nRMR Score: %d\nCategory: %s', ...
                               currentJointSets(i).dipDirection, currentJointSets(i).dip, ...
                               currentJointSets(i).rmrScore, currentJointSets(i).category);
            
            textBottom = bottom - marginY * 1.3;
            textHeight = marginY * 1.1;
            
            uicontrol('Parent', figHandle, 'Style', 'text', ...
                      'String', scoreText, ...
                      'Units', 'normalized', ...
                      'Position', [left - marginX * 0.5, textBottom, width + marginX, textHeight], ...
                      'FontSize', 10, 'FontWeight', 'bold', ...
                      'BackgroundColor', getScoreColor(currentJointSets(i).rmrScore), ...
                      'HorizontalAlignment', 'center');
        end
        
        % Add legend if multiple plots
        if showLegend
            createLegend(figHandle);
        end
        
        % Enable 3D rotation
        rotate3d(figHandle, 'on');
    end
end

% Helper functions (unchanged from original)
function [rows, cols] = calculateOptimalLayout(numPlots)
    if numPlots == 1
        rows = 1; cols = 1;
    elseif numPlots == 2
        rows = 1; cols = 2;
    elseif numPlots <= 4
        rows = 2; cols = 2;
    elseif numPlots <= 6
        rows = 2; cols = 3;
    elseif numPlots <= 9
        rows = 3; cols = 3;
    elseif numPlots <= 12
        rows = 3; cols = 4;
    else
        cols = ceil(sqrt(numPlots));
        rows = ceil(numPlots / cols);
    end
end

function drawJointVisualization(ax, jointSet, tunnel_direction)
    cla(ax);
    hold(ax, 'on');
    
    % Convert tunnel direction to radians (clockwise from North)
    tunnel_rad = deg2rad(tunnel_direction);
    
    % Calculate tunnel direction vector in 3D coordinate system
    % North (0°) corresponds to +Y axis
    % East (90°) corresponds to +X axis
    tunnel_dir_x = sin(tunnel_rad);
    tunnel_dir_y = cos(tunnel_rad);
    tunnel_dir_z = 0;
    
    % Draw tunnel (horizontal cylinder oriented along tunnel direction)
    [X_cyl, Y_cyl, Z_cyl] = cylinder(0.5, 20);
    
    % Create tunnel along Y-axis first (default direction), then rotate
    tunnel_length = 4;
    
    % Transform cylinder from Z-axis to Y-axis orientation
    X_base = X_cyl;
    Y_base = (Z_cyl - 0.5) * tunnel_length;  % Along Y-axis
    Z_base = Y_cyl;
    
    % Now rotate around Z-axis by tunnel_direction angle
    % Fixed rotation matrix for clockwise rotation when viewed from +Z
    cos_angle = cos(tunnel_rad);
    sin_angle = sin(tunnel_rad);
    
    % Apply rotation to each point (fixed sign for proper clockwise rotation)
    X_tunnel = X_base * cos_angle + Y_base * sin_angle;
    Y_tunnel = -X_base * sin_angle + Y_base * cos_angle;
    Z_tunnel = Z_base;  % Z coordinates remain unchanged for horizontal tunnel
    
    surf(ax, X_tunnel, Y_tunnel, Z_tunnel, 'FaceColor', [0.6, 0.6, 0.6], ...
         'FaceAlpha', 0.8, 'EdgeColor', 'none');
    
    % Add tunnel direction arrow - positioned to be half inside and half outside tunnel
    arrow_length = 1.2;
    
    % Position arrow to start from tunnel entrance and extend outward
    % Calculate tunnel entrance position (back end of tunnel)
    tunnel_entrance_x = -tunnel_dir_x * tunnel_length/2;
    tunnel_entrance_y = -tunnel_dir_y * tunnel_length/2;
    
    % Arrow starts from halfway back into the tunnel from entrance
    arrow_start_x = tunnel_entrance_x - tunnel_dir_x * arrow_length/2;
    arrow_start_y = tunnel_entrance_y - tunnel_dir_y * arrow_length/2;
    arrow_start_z = 0;
    
    % Arrow vector direction (same as tunnel direction)
    arrow_vector_x = tunnel_dir_x * arrow_length;
    arrow_vector_y = tunnel_dir_y * arrow_length;
    arrow_vector_z = 0;
    
    quiver3(ax, arrow_start_x, arrow_start_y, arrow_start_z, ...
            arrow_vector_x, arrow_vector_y, arrow_vector_z, ...
            'k', 'LineWidth', 3, 'MaxHeadSize', 0.4);
    
    % Add tunnel direction text (positioned at the bottom/start of the arrow)
    text_pos_x = arrow_start_x - arrow_vector_x * 0.2;
    text_pos_y = arrow_start_y - arrow_vector_y * 0.2;
    text_pos_z = arrow_start_z;
    
    text(ax, text_pos_x, text_pos_y, text_pos_z, ...
         'Tunnel', ...
         'FontSize', 8, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    
    % Draw joint plane
    dipDir_rad = deg2rad(jointSet.dipDirection);
    dip_rad = deg2rad(jointSet.dip);
    
    % Calculate plane normal vector
    normal = [sin(dip_rad) * sin(dipDir_rad), ...
              sin(dip_rad) * cos(dipDir_rad), ...
              cos(dip_rad)];
    
    % Create two orthogonal vectors in the plane
    % Strike vector: perpendicular to dip direction in horizontal plane
    strike_vector = [-cos(dipDir_rad), sin(dipDir_rad), 0];
    
    % Dip vector: in the plane, perpendicular to strike
    dip_vector = cross(normal, strike_vector);
    dip_vector = dip_vector / norm(dip_vector); % Normalize
    
    % Create plane vertices
    planeSize = 1.5;
    corners = [-1, -1; 1, -1; 1, 1; -1, 1] * planeSize;
    
    x = zeros(1, 4);
    y = zeros(1, 4);
    z = zeros(1, 4);
    
    for i = 1:4
        point = corners(i, 1) * strike_vector + corners(i, 2) * dip_vector;
        x(i) = point(1);
        y(i) = point(2);
        z(i) = point(3);
    end
    
    % Draw the joint plane
    planeColor = getJointColor(jointSet.category);
    patch(ax, x, y, z, planeColor, 'FaceAlpha', 0.8, 'EdgeColor', 'black', 'LineWidth', 1);
    
    % Add normal vector arrow (black)
    center = [0, 0, 0];
    normal_scaled = normal * 0.8;
    quiver3(ax, center(1), center(2), center(3), ...
            normal_scaled(1), normal_scaled(2), normal_scaled(3), ...
            'k', 'LineWidth', 2, 'MaxHeadSize', 0.3);
    
    % Calculate dip direction (horizontal projection of normal vector)
    dip_direction_vector = [sin(dipDir_rad), cos(dipDir_rad), 0];
    dip_direction_scaled = dip_direction_vector * 1.2;
    
    % Add dip direction arrow (red) - horizontal projection
    quiver3(ax, center(1), center(2), center(3), ...
            dip_direction_scaled(1), dip_direction_scaled(2), dip_direction_scaled(3), ...
            'r', 'LineWidth', 2, 'MaxHeadSize', 0.3);
    
    % Calculate strike direction (perpendicular to dip direction, horizontal)
    % Strike = Dip Direction - 90 degrees
    strike_direction_rad = dipDir_rad - pi/2;
    strike_direction_vector = [sin(strike_direction_rad), cos(strike_direction_rad), 0];
    strike_scaled = strike_direction_vector * 1.2;
    
    % Add strike direction arrow (blue)
    quiver3(ax, center(1), center(2), center(3), ...
            strike_scaled(1), strike_scaled(2), strike_scaled(3), ...
            'b', 'LineWidth', 2, 'MaxHeadSize', 0.3);
    
    % Calculate dip vector (direction of steepest descent on the plane)
    % Dip vector points down the plane in the dip direction
    dip_vector_3d = [sin(dipDir_rad) * cos(dip_rad), ...
                     cos(dipDir_rad) * cos(dip_rad), ...
                     -sin(dip_rad)]; % Negative Z for downward direction
    dip_vector_scaled = dip_vector_3d * 1.2;
    
    % Add dip vector arrow (green) - shows actual dip on the plane
    quiver3(ax, center(1), center(2), center(3), ...
            dip_vector_scaled(1), dip_vector_scaled(2), dip_vector_scaled(3), ...
            'g', 'LineWidth', 2, 'MaxHeadSize', 0.3);
    
    % Add text labels for the arrows
    text(ax, normal_scaled(1)*1.1, normal_scaled(2)*1.1, normal_scaled(3)*1.1, ...
         'Normal', 'FontSize', 8, 'Color', 'black', 'FontWeight', 'bold');
    text(ax, dip_direction_scaled(1)*1.1, dip_direction_scaled(2)*1.1, dip_direction_scaled(3)*1.1, ...
         'Dip Dir', 'FontSize', 8, 'Color', 'red', 'FontWeight', 'bold');
    text(ax, strike_scaled(1)*1.1, strike_scaled(2)*1.1, strike_scaled(3)*1.1, ...
         'Strike', 'FontSize', 8, 'Color', 'blue', 'FontWeight', 'bold');
    text(ax, dip_vector_scaled(1)*1.1, dip_vector_scaled(2)*1.1, dip_vector_scaled(3)*1.1, ...
         'Dip', 'FontSize', 8, 'Color', 'green', 'FontWeight', 'bold');
    
    % Calculate strike angle relative to North (Y-axis)
    strike_angle = (jointSet.dipDirection - 90);
    if strike_angle < 0
        strike_angle = strike_angle + 360;
    end
    
    % Add orientation information text
    text(ax, -1.8, 1.8, 1.2, sprintf('Strike: %.0f°', strike_angle), ...
         'FontSize', 9, 'FontWeight', 'bold', 'Color', 'blue');
    text(ax, -1.8, 1.8, 0.9, sprintf('Dip Dir: %.0f°', jointSet.dipDirection), ...
         'FontSize', 9, 'FontWeight', 'bold', 'Color', 'red');
    text(ax, -1.8, 1.8, 0.6, sprintf('Dip: %.0f°', jointSet.dip), ...
         'FontSize', 9, 'FontWeight', 'bold', 'Color', 'green');
    
    % Add tunnel direction information
    text(ax, -1.8, 1.8, 0.3, sprintf('Tunnel: %.0f°', tunnel_direction), ...
         'FontSize', 9, 'FontWeight', 'bold', 'Color', 'black');
    
    % Set axes properties
    axis(ax, 'equal');
    xlim(ax, [-2, 2]);
    ylim(ax, [-2.5, 2.5]);
    zlim(ax, [-1.5, 1.5]);
    xlabel(ax, 'X (East)', 'FontSize', 8);
    ylabel(ax, 'Y (North)', 'FontSize', 8);
    zlabel(ax, 'Z (Up)', 'FontSize', 8);
    title(ax, jointSet.name, 'FontSize', 12, 'FontWeight', 'bold');
    grid(ax, 'on');
    view(ax, 45, 30);
    
    hold(ax, 'off');
end

function createLegend(fig)
    % Check if legend exists and delete it
    existingLegend = findobj(fig, 'Tag', 'legend_panel');
    if ~isempty(existingLegend)
        delete(existingLegend(isvalid(existingLegend)));
    end
    
    legendPanel = uipanel('Parent', fig, 'Title', 'RMR Category Legend', ...
                         'Units', 'normalized', ...
                         'Position', [0.82, 0.25, 0.16, 0.4], ...
                         'FontSize', 12, 'FontWeight', 'bold', ...
                         'Tag', 'legend_panel');
    
    categories = {'Very Favorable', 'Favorable', 'Fair', 'Unfavorable', 'Very Unfavorable'};
    
    for i = 1:length(categories)
        y_pos = 0.8 - (i-1) * 0.15;
        
        % Color box
        uicontrol('Parent', legendPanel, 'Style', 'text', ...
                  'String', '    ', ...
                  'Units', 'normalized', ...
                  'Position', [0.05, y_pos, 0.15, 0.08], ...
                  'BackgroundColor', getJointColor(categories{i}));
        
        % Text
        uicontrol('Parent', legendPanel, 'Style', 'text', ...
                  'String', categories{i}, ...
                  'Units', 'normalized', ...
                  'Position', [0.22, y_pos, 0.75, 0.08], ...
                  'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.95, 0.95, 0.95]);
    end
end

function [score, category] = calculateRMRScore(dipDirection, dip, tunnel_direction)
    % Normalize angles
    dipDirection = mod(dipDirection, 360);
    dip = max(0, min(90, dip));
    tunnel_direction = mod(tunnel_direction, 360);
    
    % Calculate strike angle (perpendicular to dip direction)
    strike_angle = mod(dipDirection - 90, 360);
    
    % Calculate acute angle between strike and tunnel axis
    angle_diff_strike = abs(strike_angle - tunnel_direction);
    if angle_diff_strike > 180
        angle_diff_strike = 360 - angle_diff_strike;
    end
    if angle_diff_strike > 90
        angle_diff_strike = 180 - angle_diff_strike;
    end
    
    % Rule A: Low dip angles (0-20°)
    if dip <= 20
        category = 'Fair';
        score = -5;
        return;
    end
    
    % Calculate acute angle between dip direction and tunnel direction
    angle_diff_dip = abs(dipDirection - tunnel_direction);
    acute_angle_dip = min(angle_diff_dip, 360 - angle_diff_dip);
    
    % Classify direction type
    if acute_angle_dip <= 30
        direction_type = 1; % with the dip
    elseif acute_angle_dip >= 150
        direction_type = -1; % against the dip
    else
        direction_type = 0; % intermediate
    end
    
    % Rule B: Strike perpendicular to tunnel (acute angle > 35°)
    if angle_diff_strike > 35
        if direction_type == 1      % With the dip
            if dip > 45
                category = 'Very Favorable';
                score = 0;
            else
                category = 'Favorable';
                score = -2;
            end
        elseif direction_type == -1 % Against the dip
            if dip > 45
                category = 'Fair';
                score = -5;
            else
                category = 'Unfavorable';
                score = -10;
            end
        else                       % Intermediate
            if dip > 45
                category = 'Favorable';
                score = -2;
            else
                category = 'Fair';
                score = -5;
            end
        end
    % Rule C: Strike parallel to tunnel (acute angle <= 45°)
    else
        if dip > 45
            category = 'Very Unfavorable';
            score = -12;
        else
            category = 'Fair';
            score = -5;
        end
    end
end

function favorability = getFavorabilityLevel(score)
    if score >= 0
        favorability = 'Excellent';
    elseif score >= -2
        favorability = 'Good';
    elseif score >= -5
        favorability = 'Moderate';
    elseif score >= -10
        favorability = 'Poor';
    else
        favorability = 'Critical';
    end
end

function color = getJointColor(category)
    % Color based on category instead of score
    if ischar(category)
        switch category
            case 'Very Favorable'
                color = [0, 0.8, 0];      % Green
            case 'Favorable'
                color = [0.5, 1, 0.5];    % Light green
            case 'Fair'
                color = [1, 1, 0];        % Yellow
            case 'Unfavorable'
                color = [1, 0.5, 0];      % Orange
            case 'Very Unfavorable'
                color = [1, 0, 0];        % Red
            otherwise
                color = [0.7, 0.7, 0.7];  % Gray for unknown
        end
    else
        % Fallback for numeric scores (legacy support)
        if category >= 0
            color = [0, 0.8, 0];      % Green
        elseif category >= -2
            color = [0.5, 1, 0.5];    % Light green
        elseif category >= -5
            color = [1, 1, 0];        % Yellow
        elseif category >= -10
            color = [1, 0.5, 0];      % Orange
        else
            color = [1, 0, 0];        % Red
        end
    end
end

function color = getScoreColor(score)
    if score >= 0
        color = [0.8, 1, 0.8];      % Light green
    elseif score >= -2
        color = [0.9, 1, 0.9];      % Very light green
    elseif score >= -5
        color = [1, 1, 0.8];        % Light yellow
    elseif score >= -10
        color = [1, 0.9, 0.8];      % Light orange
    else
        color = [1, 0.8, 0.8];      % Light red
    end
end