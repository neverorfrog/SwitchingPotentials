classdef VirtualBypassing < Bypassing
    
    properties
        gradXO; gradYO; %the bypassing potential of the detected obstacle at time tau
        P1; %punto in cui si passa dal bypassante virtuale a quello reale
        P2; %punto in cui si passa dal bypassante all'attrattivo
    end
    
    methods
        function obj = decision(obj,robot,dObstacle)
            decision@Bypassing(obj,robot,dObstacle);
            if norm([robot.xc robot.yc] - obj.P1) < 0.1
                robot.setState(RealBypassing(obj));
            end
        end
        
        function obj = VirtualBypassing(robot,dO)
            %Posizione del robot,dell'ostacolo e del goal
            pose = robot.getPose(); grid = robot.grid;
            xr = pose(1); yr = pose(2); thetar = pose(3);
            xo0 = dO.xc; yo0 = dO.yc; thetao0 = dO.theta;
            angle = atan2(sin(thetar),cos(thetar));
            xg = grid.goal(1); yg = grid.goal(2);
            
            %Inizio calcolo potenziale bypassante
            m = tan(thetar); xo = xo0 - xr; yo = yo0 - yr;
            %1. Calcolo di h (il raggio della circonferenza attorno all'ostacolo reale)
            dist = norm([xo0 yo0] - [xr yr]);
            angdiff = abs(atan2(sin(thetao0-thetar),cos(thetao0-thetar)));
            h = (dist+1+(angdiff/pi))/3;
            %2. Calcolo delle due circonferenze papabili per l'ostacolo virtuale
            load yOmega; yOmega = double(subs(yOmega(:)));
            xOmega = -m*yOmega;
            d = double(sqrt(xOmega.^2 + yOmega.^2));
            %3. Scelta del verso di bypass dell'ostacolo reale
            oSense = obj.chooseSense(dO,pose); %dO = detected obstacle
            %4. Decido quale circonferenza va bene per il verso di bypass
            bool1 = abs(norm(xOmega))>0.01 && sign(xOmega(1))==sign(xOmega(2));
            bool2 = abs(norm(yOmega))>0.01 && sign(yOmega(1))==sign(yOmega(2));
            if bool1 || bool2 %Ho due circonferenze dallo stesso lato
                [~,indiceC] = min(d);
            else %Non ho due circonferenze dallo stesso lato
                if oSense == "clock" %voglio la circonferenza sinistra
                    indiceC = (sign(sin(angle)) == sign(xOmega(1))) + 1;
                else %voglio quella destra
                    indiceC = ~(sign(sin(angle)) == sign(xOmega(1))) + 1;
                end
            end
            %5. Estraggo la circonferenza che mi serve
            xOmega = xOmega(indiceC) + xr; yOmega = yOmega(indiceC) + yr;
            dOmega = d(indiceC); xo = xo0; yo = yo0;
            %6. Decido come sara l'ostacolo virtuale in base al senso di bypass
            vObstacle = Obstacle(xOmega,yOmega,[0;0]);
            if oSense == "counterclock"
                vSense = "clock"; indiceP2 = 2;
            else
                vSense = "counterclock"; indiceP2 = 1;
            end
            %7. Calcolo P1
            centerDir = [xo,yo]-[xOmega,yOmega];
            centerDir = centerDir/norm(centerDir);
            obj.P1 = [xOmega yOmega] + dOmega*centerDir;
            k = grid.coord2index(obj.P1);
            %8. Calcolo P2
            load xp2yp2;
            obj.P2 = double(subs(solxp2(indiceP2)));
            syms xp2; xp2 = obj.P2(1);
            obj.P2(2) = double(subs(solyp2(indiceP2)));
            j = grid.coord2index(obj.P2);
            %9. Infine calcolo gli antigradienti nell'ostacolo reale e virtuale
            agradX = robot.attractive.gradX; agradY = robot.attractive.gradY;
            cO = norm([agradX(j(1),j(2)) agradY(j(1),j(2))])*h;
            [obj.gradXO,obj.gradYO] = obj.antigradient(dO,grid,cO,oSense);
            cV = norm([obj.gradXO(k(1),k(2)) obj.gradYO(k(1),k(2))])*dOmega;
            [obj.gradX,obj.gradY] = obj.antigradient(vObstacle,grid,cV,vSense);
            
            %Plotting dei risultati per testing
            omega = nsidedpoly(2000, 'Center', [xOmega yOmega], 'Radius', dOmega);
            plot(omega, 'FaceColor', 'b');
            obst = nsidedpoly(2000, 'Center', [xo yo], 'Radius', double(h));
            plot(obst, 'FaceColor', 'r');
            plot(obj.P2(1),obj.P2(2),"+k","linewidth",2);
            plot(obj.P1(1),obj.P1(2),"+b","linewidth",2);
        end
        
        %% Scelto del senso (antiorario o orario)
        function sense = chooseSense(~,obstacle,pose)
            xr = pose(1); yr = pose(2); thetar = pose(3);
            phi = atan2(obstacle.yc - yr,obstacle.xc - xr);
            %Ostacolo fermo
            if obstacle.v(1) == 0 && obstacle.v(2) == 0
                if phi - thetar > 0
                    sense = "counterclock";
                else
                    sense = "clock";
                end
                return;
            end
            %Ostacolo in movimento
            alphav = atan2(obstacle.v(2),obstacle.v(1));
            vphi = pi/2 - phi + alphav;
            vphi = atan2(sin(vphi),cos(vphi));
            if cos(vphi) > 0
                sense = "clock";
            else
                sense = "counterclock";
            end
        end
        
        %% Calcolo antigradiente dato c e il verso di percorrenza
        function [gx,gy] = antigradient(~,obstacle,grid,c,sense)
            xo = obstacle.xc; yo = obstacle.yc;
            %Calcolo del gradiente
            X = grid.X; Y = grid.Y;
            gx = c*(Y(:,1)-yo)./((X(1,:)-xo).^2+(Y(:,1)-yo).^2+0.00001);
            gy = c*(xo-X(1,:))./((X(1,:)-xo).^2+(Y(:,1)-yo).^2+0.00001);
            if sense == "counterclock"
                gx = -gx; gy = -gy;
            end
        end
    end
end
