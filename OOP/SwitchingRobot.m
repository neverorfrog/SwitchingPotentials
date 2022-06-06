classdef SwitchingRobot < Robot
    
    methods
        function obj = SwitchingRobot(R,L,grid)
            obj@Robot(R,L,grid);
            obj.sense = Sense(grid);
            obj.plan = SwitchingPlan(grid);
            obj.act = Act(grid);
        end
        
        function pngSequence(~,samples)
            filename = sprintf('SwitchingPotentials/Latex/presentazione/figure/simulazione/pic%d.png', samples);
            saveas(gcf, filename);
        end
    end
end
