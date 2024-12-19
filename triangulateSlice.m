function trList = triangulateSlice(w,h,markerList)

    m1 = [-w*0.1, -h*0.1, -w*0.1, -h*0.1];
    m2 = [w*1.1, -h*0.1, w*1.1, -h*0.1];
    m3 = [-w*0.1, h*1.1, -w*0.1, h*1.1];
    m4 = [w*1.1, h*1.1, w*1.1, h*1.1];

    trimarkers = {m1,m2,m3,m4};
    
    % Create a list of triangles
    trList = cell(0);
    trList = [trList, Triangle(1,2,3,trimarkers)];
    trList = [trList, Triangle(2,3,4,trimarkers)];

    edges = zeros(size(markerList,1)+4 , size(markerList,1)+4);
    edges(1,2) = 2;
    edges(1,3) = 2;
    edges(2,3) = 2;
    edges(2,4) = 2;
    edges(3,4) = 2;

    
    for i = 1:size(markerList,1)
        m = markerList(i,:);

        x = double(m(3));
        y = double(m(4));
        found = false;

        remove = cell(0);
        idxToRemove = zeros(length(trList),1,'logical');
        for j = 1:length(trList)
            tri = trList(j);
            if found || all(~isnan(tri.intri(x,y)))
                found = true;
            end
            if tri.incirc(x,y)
                remove = [remove, tri];
                idxToRemove(j) = true;
            end
        end

        if found
            for j = 1:length(remove)
                tri = remove(j);
                edges(tri.a, tri.b) = edges(tri.a, tri.b) - 1;
                edges(tri.a, tri.c) = edges(tri.a, tri.c) - 1;
                edges(tri.b, tri.c) = edges(tri.b, tri.c) - 1;
            end
            trList(logical(idxToRemove)) = [];
            trimarkers = [trimarkers, m];

            newtriangles = cell(0);
            for j = 1:size(edges,1)
                for k = 1:size(edges,1)
                    if edges(j,k) == 1
                        tri = Triangle(j,k,length(trimarkers), trimarkers);
                        
                        if ~any(isnan(tri.decomp),'all')
                            newtriangles = [newtriangles, tri];
                        end
                    end
                end
            end

            trList = [trList, newtriangles];

            for j = 1:length(newtriangles)
                tri = newtriangles(j);

                edges(tri.a, tri.b) = edges(tri.a, tri.b) + 1;
                edges(tri.a, tri.c) = edges(tri.a, tri.c) + 1;
                edges(tri.b, tri.c) = edges(tri.b, tri.c) + 1;
            end
        end
    end
end



