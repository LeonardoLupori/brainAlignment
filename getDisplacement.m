function [dx, dy] = getDisplacement(xq, yq, triangleList, minMax)
% GETDISPLACEMENT Compute displacement vector at a query point using triangulated transformation
%
% SYNTAX:
%   [dx, dy] = getDisplacement(xq, yq, triangleList, minMax)
%
% DESCRIPTION:
%   Computes the displacement vector (dx, dy) for a query point (xq, yq) by 
%   finding the triangle that contains the point and applying the corresponding
%   barycentric coordinate transformation. Uses a two-stage filtering approach:
%   first by bounding box, then by barycentric coordinate validation.
%
% INPUTS:
%   xq          - double scalar, x-coordinate of query point
%   yq          - double scalar, y-coordinate of query point  
%   triangleList - 1×N array of Triangle objects, each containing:
%                  • decomp: 3×3 transformation matrix (inverse barycentric)
%                  • A, B, C: vertex coordinates [ref_x, ref_y, img_x, img_y]
%                  • minx, maxx, miny, maxy: bounding box coordinates
%   minMax      - 4×N double array with triangle bounds:
%                  Row 1: minimum x-coordinates for each triangle
%                  Row 2: maximum x-coordinates for each triangle
%                  Row 3: minimum y-coordinates for each triangle
%                  Row 4: maximum y-coordinates for each triangle

% Extract bounds
mx = minMax(1,:);
Mx = minMax(2,:);
my = minMax(3,:);
My = minMax(4,:);

% First pick only triangles relevant to the queried point
validTriangles = (xq > mx) & (xq < Mx) & (yq > my) & (yq < My);

% Initialize output variables
dx = NaN;
dy = NaN;

% Check if any triangles are potentially valid
if ~any(validTriangles)
    return;
end

% Further refine the remaining triangles based on their transformation output
indexes = find(validTriangles);

for i = 1:length(indexes)
    idx = indexes(i);
    
    % Check if decomp matrix is valid
    if any(isnan(triangleList(idx).decomp), 'all')
        continue;
    end
    
    % Do the transformation
    try
        uv1 = [xq, yq, 1] * triangleList(idx).decomp;
    catch
        continue; % Skip this triangle if matrix multiplication fails
    end
    
    % Check barycentric coordinates with small tolerance for numerical precision
    tolerance = 1e-10;
    toReject = uv1(1) < -tolerance || uv1(1) > 1 + tolerance || ...
               uv1(2) < -tolerance || uv1(2) > 1 + tolerance || ...
               uv1(1) + uv1(2) > 1 + tolerance;
    
    if ~toReject
        % Found a valid triangle, calculate transformation
        A = triangleList(idx).A;
        B = triangleList(idx).B;
        C = triangleList(idx).C;
        
        % Calculate transformed coordinates
        transformedCoord = [A(1) + (B(1) - A(1)) * uv1(1) + (C(1) - A(1)) * uv1(2), ...
                           A(2) + (B(2) - A(2)) * uv1(1) + (C(2) - A(2)) * uv1(2)];
        
        dx = transformedCoord(1) - xq;
        dy = transformedCoord(2) - yq;
        break; % Exit loop once we find a valid triangle
    end
end

% If no triangle was found, the point is outside the triangulated region
% dx and dy remain NaN
end