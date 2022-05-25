classdef Sense
    properties
        robot;
        grid;
    end
    
    methods
        function obj = Sense(robot,grid)
            obj.robot = robot;
            obj.grid = grid;
        end
        
        %% Method that looks in a radius rv and a tube T(t) if there are any obstacles
        function [detections,distances] = scan(robot,grid)
            n = grid.obstacles.length;
            detections = zeros(n,1); distances = zeros(n,1);
            for j = 1 : n
                o = obstacles(j);
                if o.bypassed == false
                    distances(j) = inf;
                else
                    distances(j) = norm([r.xc r.yc] - [o.xc o.yc]);
                end
                detections(j) = (distances(j) <= robot.rv || isinf(distances(j))) && tube(robot,grid.G,o);
            end
        end
        
        %% Method that builds the tube T(t)
        function result = tube(robot,goal,obstacle)
            rm = 3.5;
            angle = atan2(goal(2)-robot.yc,goal(1)-robot.xc);
            deltaX = rm/2*sin(angle); deltaY = rm/2*cos(angle);
            x1 = robot.xc + deltaX; y1 = robot.yc - deltaY;
            x4 = robot.xc - deltaX; y4 = robot.yc + deltaY;
            x2 = goal(1) + deltaX; y2 = goal(2) - deltaY;
            x3 = goal(1) - deltaX; y3 = goal(2) + deltaY;
            
            m14 = (y4-y1)/(x4-x1); q14 = m14*x1 - y1;
            if abs(m14) > exp(10)
                v14 = (obstacle.xc - x1);
            else
                v14 = (obstacle.yc - m14*obstacle.xc + q14);
            end
            
            m12 = (y2-y1)/(x2-x1); q12 = m12*x1 - y1;
            if abs(m12) > exp(10)
                v12 = (x1 - obstacle.xc);
            else
                v12 = (obstacle.yc - m12*obstacle.xc + q12);
            end
            
            m34 = (y4-y3)/(x4-x3); q34 = m34*x3 - y3;
            if abs(m34) > exp(10)
                v34 = (x4 - obstacle.xc);
            else
                v34 = (obstacle.yc - m34*obstacle.xc + q34);
            end
            
            if (angle >= 0 && angle <= pi/2) %first quadrant
                result1 = v14 >= 0;
                result2 = v12 >= 0; result3 = v34 <= 0;
            elseif (angle > pi/2 && angle < pi) %second quadrant
                result1 = v14 >= 0;
                result2 = v12 <= 0; result3 = v34 >= 0;
            elseif (angle >= -pi && angle <= -pi/2 || angle == pi ) %third quadrant
                result1 = v14 <= 0;
                result2 = v12 <= 0; result3 = v34 >= 0;
            else %fourth quadrant
                result1 = v14 <= 0;
                result2 = v12 >= 0; result3 = v34 <= 0;
            end
            result = result1 && result2 && result3;
        end
    end
end

