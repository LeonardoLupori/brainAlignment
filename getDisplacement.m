function [dx, dy] = getDisplacement(xq, yq, triangleList, minMax)


% Collect minimum and maximum X and Y for all triangles in order to filter
% out triangles that are not relevant for the queried [xq, yq] point
% mx = [triangleList.minx];
% Mx = [triangleList.maxx];
% my = [triangleList.miny];
% My = [triangleList.maxy];

mx = minMax(1,:);
Mx = minMax(2,:);
my = minMax(3,:);
My = minMax(4,:);


% First pick only triangles relevant to the queried point
validTriangles = (xq>mx) & (xq<Mx) & (yq>my) & (yq<My);

% Further refine the remaining tirangles based on their transformation
% output
indexes = find(validTriangles);
for i = 1:length(indexes)
    % Do the transformation
    uv1 = [xq,yq,1] * triangleList(indexes(i)).decomp;
    
    toReject = uv1(1)<0 || uv1(1)>1 || uv1(2)<0 || uv1(2)>1 || uv1(1)+uv1(2)>1;
    if toReject
        validTriangles(indexes(i)) = false;
        transformedCoord = nan;
    else
        A = triangleList(indexes(i)).A;
        B = triangleList(indexes(i)).B;
        C = triangleList(indexes(i)).C;
        transformedCoord = [A(1)+(B(1)-A(1))*uv1(1)+(C(1)-A(1))*uv1(2),...
            A(2)+(B(2)-A(2))*uv1(1)+(C(2)-A(2))*uv1(2)];
        break
    end
end

dx = transformedCoord(1) - xq;
dy = transformedCoord(2) - yq;



