classdef Triangle

    properties(Access = public)
        a = uint16(0);
        b = uint16(0);
        c = uint16(0);

        A
        B
        C

        minx = 0;
        miny = 0;
        maxx = 0;
        maxy = 0;

        decomp
        den;
        Mdenx;
        Mdeny;
        r2den;
    end



    methods(Access=public)

        % -----------------------------------------------------------------
        function self = Triangle(a,b,c,points)
            % Points é una cella di vettori

            p = round([a,b,c]);         % Maybe useless
            p = sort(p);

            self.a = p(1);
            self.b = p(2);
            self.c = p(3);
            
            self.A = points{self.a};
            ax = self.A(3);
            ay = self.A(4);

            self.B = points{self.b};
            bx = self.B(3);
            by = self.B(4);

            self.C = points{self.c};
            cx = self.C(3);
            cy = self.C(4);

            self.minx = min([ax,bx,cx]);
            self.miny = min([ay,by,cy]);
            self.maxx = max([ax,bx,cx]);
            self.maxy = max([ay,by,cy]);

            temp = [bx-ax, by-ay, 0;...
                    cx-ax, cy-ay, 0;...
                    ax, ay, 1];
            self.decomp = inv(temp);


            a2 = norm([bx,by] - [cx,cy])^2;
            b2 = norm([ax,ay] - [cx,cy])^2;
            c2 = norm([ax,ay] - [bx,by])^2;

            fa = a2*(b2+c2-a2);
            fb = b2*(c2+a2-b2);
            fc = c2*(a2+b2-c2);

            self.den = fa+fb+fc;
            self.Mdenx = fa*ax + fb*bx + fc*cx;
            self.Mdeny = fa*ay + fb*by + fc*cy;
            self.r2den = norm([ax*self.den, ay*self.den] - [self.Mdenx, self.Mdeny])^2;
        end

        % -----------------------------------------------------------------
        function bool = eq(self, obj)
            % Override equality == operator between triangles
            if isequal(class(obj),'Triangle')
                equalA = self.a == obj.a;
                equalB = self.b == obj.b;
                equalC = self.c == obj.c;

                bool = equalA && equalB && equalC;
            else
                bool = false;
            end
        end
        
        % -----------------------------------------------------------------
        function bool = incirc(self,x,y)
            % Determines whether a point is 
            distSquared = norm([x*self.den,y*self.den] - [self.Mdenx,self.Mdeny])^2;
            bool = distSquared < self.r2den;
        end

        % -----------------------------------------------------------------
        function output = intri(self,x,y)
            condition = x<self.minx || x>self.maxx || y<self.miny || y>self.maxy;
            if condition
                output = nan;
                return
            end

            uv1 = [x,y,1] * self.decomp;
            condition = uv1(1)<0 || uv1(1)>1 || uv1(2)<0 || uv1(2)>1 || uv1(1)+uv1(2)>1;
            if condition
                output = nan;
                return
            end
            output = uv1;
        end
        
        % -----------------------------------------------------------------
        function output = transform(self,x,y)
            uv1 = self.intri(x,y);

            if isnan(uv1)
                output = nan;
                return
            end
            output = [self.A(1)+(self.B(1)-self.A(1))*uv1(1)+(self.C(1)-self.A(1))*uv1(2),...
                self.A(2)+(self.B(2)-self.A(2))*uv1(1)+(self.C(2)-self.A(2))*uv1(2)];
        end

        % -----------------------------------------------------------------
        function output = transformFast(self,x,y)

            uv1 = [x,y,1] * self.decomp;
            condition = uv1(1)<0 || uv1(1)>1 || uv1(2)<0 || uv1(2)>1 || uv1(1)+uv1(2)>1;
            if condition
                output = nan;
            else
                output = [self.A(1)+(self.B(1)-self.A(1))*uv1(1)+(self.C(1)-self.A(1))*uv1(2),...
                self.A(2)+(self.B(2)-self.A(2))*uv1(1)+(self.C(2)-self.A(2))*uv1(2)];
            end
        end
    end


end